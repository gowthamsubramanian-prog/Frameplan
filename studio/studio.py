#!/usr/bin/env python3
"""Cinematic Content Studio — shared database and workflow tool.

The single writer for data/studio.db. Every command prints JSON on stdout.
Exit codes: 0 ok, 1 error, 3 blocked by an approval gate or the budget.

    python3 studio/studio.py init
    python3 studio/studio.py --help
"""
from __future__ import annotations

import argparse
import csv
import datetime as dt
import difflib
import hashlib
import json
import os
import re
import sqlite3
import sys
from pathlib import Path
from urllib.parse import urlsplit

ROOT = Path(__file__).resolve().parent.parent
SCHEMA = Path(__file__).resolve().parent / "schema.sql"
CONFIG = Path(__file__).resolve().parent / "config" / "studio.json"
SCHEMA_VERSION = "2"

EXIT_ERROR = 1
EXIT_BLOCKED = 3

# (stage, approval gate that must be approved before ENTERING the stage)
WORKFLOWS = {
    "A": ("Original creative idea", [
        ("idea", None), ("research", None), ("concept", None),
        ("creative_direction", "concept"), ("storyboard", None), ("shot_list", None),
        ("production_plan", None), ("shoot", None), ("edit", None), ("qa", None),
        ("export", "export"), ("publish", "publish"), ("done", None)]),
    "B": ("Inspiration-based production", [
        ("ingest", None), ("analysis", None), ("technique_extraction", None),
        ("adaptation", None), ("storyboard", "concept"), ("shot_list", None),
        ("production_plan", None), ("shoot", None), ("edit", None), ("qa", None),
        ("export", "export"), ("publish", "publish"), ("done", None)]),
    "C": ("Reference video replication", [
        ("ingest_video", None), ("footage_analysis", None), ("shot_breakdown", None),
        ("movement_analysis", None), ("replication_shot_list", None),
        ("manifest_proposal", None), ("production_plan", None), ("done", None)]),
    "D": ("AI-assisted cinematic production", [
        ("concept", None), ("prompt_engineering", "concept"),
        ("generation", "paid_generation"), ("review", None), ("refine", None),
        ("edit", None), ("effects", None), ("grade", None),
        ("export", "export"), ("done", None)]),
    "E": ("Motion graphics production", [
        ("topic", None), ("research", None), ("proposal", None),
        ("style_options", "concept"), ("production", "style"), ("review", None),
        ("export", "export"), ("done", None)]),
}

GATES = ("concept", "style", "asset_change", "paid_generation", "export", "publish",
         "manifest_update")

ROUTE_RULES = [  # first match wins
    ("E", r"motion graphic|mograph|explainer|animated (title|text|chart|infographic)|kinetic (type|text)|infographic"),
    ("C", r"\.(mp4|mov|m4v|mkv)\b|replicat|recreate (this|the) (video|reel|footage)|shot[- ]by[- ]shot|break ?down (this|the) (video|reel|footage)|uploaded (video|footage)"),
    ("D", r"\bai[- ](video|image|generated|assisted)|\bkling\b|higgsfield|text[- ]to[- ](video|image)|image[- ]to[- ]video|generate (a|an|the|some) (clip|video|image)|\bsora\b"),
    ("B", r"https?://|instagram|pinterest|\breel i saved|inspired by|inspiration|reference (link|image|photo)|saved (pin|post|collection)|moodboard"),
]


# ---------------------------------------------------------------- helpers
def now() -> str:
    return dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def out(obj) -> None:
    print(json.dumps(obj, indent=2, ensure_ascii=False))


class StudioError(Exception):
    def __init__(self, msg: str, code: int = EXIT_ERROR, **extra):
        super().__init__(msg)
        self.code = code
        self.extra = extra


def db_path() -> Path:
    return Path(os.environ.get("STUDIO_DB") or (ROOT / "data" / "studio.db"))


def dump_path() -> Path:
    return db_path().with_suffix(".sql")


def config() -> dict:
    return json.loads(CONFIG.read_text())


def connect(create: bool = False) -> sqlite3.Connection:
    p = db_path()
    if not p.exists():
        if dump_path().exists():           # fresh clone: rebuild from the committed snapshot
            p.parent.mkdir(parents=True, exist_ok=True)
            con = sqlite3.connect(p)
            con.executescript(dump_path().read_text())
            con.commit()
            con.close()
        elif not create:
            raise StudioError(f"No database at {p}. Run: python3 studio/studio.py init")
    p.parent.mkdir(parents=True, exist_ok=True)
    con = sqlite3.connect(p)
    con.row_factory = sqlite3.Row
    con.execute("PRAGMA foreign_keys = ON")
    if not create:
        v = schema_version(con)
        if v != SCHEMA_VERSION:
            con.close()
            raise StudioError(f"Database schema is version {v}, this tool needs {SCHEMA_VERSION}. "
                              "Run: python3 studio/studio.py init  (it upgrades in place, keeping all rows)")
    return con


def schema_version(con) -> str | None:
    if not con.execute("SELECT 1 FROM sqlite_master WHERE name='meta'").fetchone():
        return None
    r = con.execute("SELECT value FROM meta WHERE key='schema_version'").fetchone()
    return r[0] if r else None


ACCESS_V1_TO_V2 = {"not_attempted": "unreviewed", "inaccessible": "blocked", "accessible": "reviewed_images"}


def migrate_v1_to_v2(con) -> dict:
    """Widen inspirations.access_status to Agent 00's five states. Keeps every row."""
    ddl = re.search(r"CREATE TABLE IF NOT EXISTS inspirations \(.*?\n\);", SCHEMA.read_text(), re.S).group(0)
    n = con.execute("SELECT COUNT(*) FROM inspirations").fetchone()[0]
    con.commit()
    con.execute("PRAGMA foreign_keys = OFF")
    con.execute("BEGIN")
    con.execute(ddl.replace("IF NOT EXISTS inspirations", "inspirations_v2"))
    case = " ".join(f"WHEN '{a}' THEN '{b}'" for a, b in ACCESS_V1_TO_V2.items())
    con.execute(
        "INSERT INTO inspirations_v2(id,source_type,title,title_norm,creator,notes,access_status,access_detail,"
        "analysis_status,analysis_json,analysis_basis,source_meta_json,created_at) "
        f"SELECT id,source_type,title,title_norm,creator,notes,CASE access_status {case} END,access_detail,"
        "analysis_status,analysis_json,analysis_basis,source_meta_json,created_at FROM inspirations")
    con.execute("DROP TABLE inspirations")
    con.execute("ALTER TABLE inspirations_v2 RENAME TO inspirations")
    con.execute("COMMIT")
    con.execute("PRAGMA foreign_keys = ON")
    bad = con.execute("PRAGMA foreign_key_check").fetchall()
    if bad:
        raise StudioError(f"migration left {len(bad)} broken links; restore data/studio.sql and report this")
    return {"from": "1", "to": "2", "inspirations_kept": n}


def next_id(con: sqlite3.Connection, prefix: str) -> str:
    row = con.execute("SELECT next FROM id_counters WHERE prefix=?", (prefix,)).fetchone()
    n = row["next"] if row else 1
    con.execute("INSERT INTO id_counters(prefix,next) VALUES(?,?) "
                "ON CONFLICT(prefix) DO UPDATE SET next=excluded.next", (prefix, n + 1))
    return f"{prefix}-{n:04d}"


def norm_text(s: str) -> str:
    return re.sub(r"[^a-z0-9]+", " ", (s or "").lower()).strip()


def norm_url(url: str) -> str:
    """Duplicate-detection key. The original URL is always stored unmodified."""
    u = urlsplit(url.strip())
    host = (u.hostname or "").lower()
    host = re.sub(r"^(www|m|au|in|uk)\.", "", host)
    path = re.sub(r"/+$", "", u.path)
    if host == "instagram.com":
        m = re.search(r"/(p|reel|reels|tv)/([A-Za-z0-9_-]+)", path)
        if m:                               # drop username prefix, query, img_index
            kind = "reel" if m.group(1) in ("reel", "reels") else m.group(1)
            return f"instagram.com/{kind}/{m.group(2)}"
        return f"instagram.com{path.lower()}"
    if host.endswith("pinterest.com") or host == "pin.it":
        m = re.search(r"/pin/(\d+)", path)
        if m:
            return f"pinterest.com/pin/{m.group(1)}"
        return f"{'pin.it' if host == 'pin.it' else 'pinterest.com'}{path}"
    if host in ("youtu.be",):
        return f"youtube.com/watch/{path.strip('/')}"
    q = "&".join(sorted(p for p in u.query.split("&")
                        if p and not re.match(r"(utm_|fbclid|igsh|stkn|si=|ref=)", p)))
    return f"{host}{path}" + (f"?{q}" if q else "")


def row(con, table: str, id_: str) -> sqlite3.Row:
    r = con.execute(f"SELECT * FROM {table} WHERE id=?", (id_,)).fetchone()
    if not r:
        raise StudioError(f"{id_} not found in {table}")
    return r


def as_dict(r: sqlite3.Row | None) -> dict | None:
    return dict(r) if r else None


def read_arg(value: str) -> str:
    """'@path' reads a file, '-' reads stdin, anything else is literal."""
    if value == "-":
        return sys.stdin.read()
    if value.startswith("@"):
        return Path(value[1:]).read_text()
    return value


def stage_names(workflow: str) -> list[str]:
    return [s for s, _ in WORKFLOWS[workflow][1]]


def latest_approval(con, project_id: str, gate: str) -> sqlite3.Row | None:
    return con.execute("SELECT * FROM approvals WHERE project_id=? AND gate=? "
                       "ORDER BY rowid DESC LIMIT 1", (project_id, gate)).fetchone()


def gate_open(con, project_id: str, gate: str) -> tuple[bool, str]:
    a = latest_approval(con, project_id, gate)
    if not a:
        return False, f"no '{gate}' approval has been requested for {project_id}"
    if a["status"] != "approved":
        return False, f"latest '{gate}' approval {a['id']} is {a['status']}"
    return True, a["id"]


# ---------------------------------------------------------------- init / snapshot
def cmd_init(a):
    con = connect(create=True)
    before = schema_version(con)
    migrated = migrate_v1_to_v2(con) if before == "1" else None
    con.executescript(SCHEMA.read_text())
    con.execute("INSERT OR REPLACE INTO meta(key,value) VALUES('schema_version',?)", (SCHEMA_VERSION,))
    con.execute("INSERT OR IGNORE INTO meta(key,value) VALUES('created_at',?)", (now(),))
    con.commit()
    tables = [r[0] for r in con.execute(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY 1")]
    out({"ok": True, "db": str(db_path()), "schema_version": SCHEMA_VERSION, "migrated": migrated, "tables": tables})


def cmd_snapshot(a):
    """Write a text dump next to the database so state can be committed to git."""
    con = connect()
    # sqlite_sequence is internal; AUTOINCREMENT counters rebuild themselves on restore.
    text = "\n".join(l for l in con.iterdump() if "sqlite_sequence" not in l) + "\n"
    dump_path().write_text(text)
    out({"ok": True, "snapshot": str(dump_path()), "bytes": len(text)})


# ---------------------------------------------------------------- routing
def route(text: str) -> dict:
    t = text.lower()
    for wf, pattern in ROUTE_RULES:
        m = re.search(pattern, t)
        if m:
            return {"workflow": wf, "name": WORKFLOWS[wf][0], "matched": m.group(0)}
    return {"workflow": "A", "name": WORKFLOWS["A"][0], "matched": None}


IMAGE_EXT = {".jpg", ".jpeg", ".png", ".webp", ".heic", ".heif", ".gif", ".tif", ".tiff", ".bmp", ".arw", ".dng"}
VIDEO_EXT = {".mp4", ".mov", ".m4v", ".mkv", ".avi", ".webm", ".mts", ".mxf"}
FIRST_SPECIALIST = {
    "A": "main session (concept development; search the inspiration catalog first)",
    "B": "inspiration-intelligence (Agent 00): catalogue and analyse the reference",
    "C": "inspiration-intelligence (Agent 00) with studio/video_probe.py: shot breakdown",
    "D": "main session for the concept, then generation-director",
    "E": "motion-director skill, given the owner's actual subject",
}
NO_DEFAULTS = ("The subject is whatever the owner supplied. Never substitute a sample, example or built-in "
               "topic, and never assume a domain, audience or platform the owner did not name.")

# name pattern, what it needs, workflows it fits
SPECIALISTS = {
    "motion-director": (r"motion[- ]?director", "a title or subject for a motion-graphics piece", {"E"}),
    "cinematic-reel-storyboard": (r"storyboard", "a reference video", {"C"}),
    "inspiration-intelligence": (r"agent ?00|inspiration[- ]intelligence", "a reference: an image, video or link", {"B", "C"}),
    "generation-director": (r"generation[- ]?director", "a project with an approved concept", {"A", "B", "D"}),
    "qa-reviewer": (r"qa[- ]?reviewer|quality review", "an output file to review", {"A", "B", "D", "E"}),
}
FILLER = (r"\b(please|now|then|ok|okay|yes|proceed|continue|resume|carry on|go ahead|next|keep going|start|begin|"
          r"run|use|try|test|testing|tests|tested|with|the|a|an|on|to|and|of|for|my|our|skill|agent|subagent|"
          r"specialist|it|this|that|again|step|stage|work|working|project)\b")
CONTINUE = r"^\W*(please\s+)?(continue|resume|carry on|proceed|go ahead|next|keep going)\b"
NEW_PROJECT = r"\bnew (project|idea|concept|shoot|reel|video)\b|\bstart (a|another) "


def current_project(con) -> sqlite3.Row | None:
    r = con.execute("SELECT value FROM meta WHERE key='current_project'").fetchone()
    if not r:
        return None
    p = con.execute("SELECT * FROM projects WHERE id=? AND status IN ('active','paused')", (r[0],)).fetchone()
    return p


def set_current_project(con, pid: str | None) -> None:
    if pid is None:
        con.execute("DELETE FROM meta WHERE key='current_project'")
    else:
        con.execute("INSERT OR REPLACE INTO meta(key,value) VALUES('current_project',?)", (pid,))


def route_request(text: str, attachments: list[str], current: dict | None = None) -> dict:
    """Decide what to do from what the owner actually supplied: attachments, words, current project."""
    text = (text or "").strip()
    low = text.lower()
    images = [p for p in attachments if Path(p).suffix.lower() in IMAGE_EXT]
    videos = [p for p in attachments if Path(p).suffix.lower() in VIDEO_EXT]
    other = [p for p in attachments if p not in images and p not in videos]
    if not text and not attachments:
        raise StudioError("No input to route. Ask the owner what they want made, or for the attachment. " + NO_DEFAULTS)

    named = next((n for n, (pat, _, _) in SPECIALISTS.items() if re.search(pat, low)), None)
    remainder = low
    if named:
        remainder = re.sub(SPECIALISTS[named][0], " ", remainder)
    subject_words = re.sub(r"[^a-z0-9 ]+", " ", re.sub(FILLER, " ", remainder)).split()
    has_subject = bool(subject_words) or bool(attachments) or bool(re.search(r"https?://", low))

    by_text = route(text) if text else None
    explicit = by_text["workflow"] if by_text and by_text["matched"] else None
    own_footage = bool(re.search(r"\b(my|our) (own )?(footage|clips?|rushes|takes)\b|\bi (shot|filmed)\b|\bedit (this|these|my)\b", low))

    res = {"action": "new_work", "workflow": None, "name": None, "rationale": None,
           "input_detected": {"text": text or None, "images": images, "videos": videos, "other_files": other},
           "named_specialist": named, "first_specialist": None, "pass_to_specialist": list(attachments),
           "current_project": ({k: current[k] for k in ("id", "title", "workflow", "stage", "status")} if current else None),
           "needs_clarification": None, "flags": [], "rule": NO_DEFAULTS}

    def clarify(msg: str, flag: str) -> dict:
        res.update(action="clarify", needs_clarification=msg)
        res["flags"].append(flag)
        return res

    # 1. A named specialist with no subject of its own: it works on the current project or not at all.
    if named and not has_subject:
        _, needs, fits = SPECIALISTS[named]
        if current and current["workflow"] in fits:
            res.update(action="continue_project", workflow=current["workflow"], name=WORKFLOWS[current["workflow"]][0],
                       first_specialist=named, pass_to_specialist=[current["id"]],
                       rationale=f"{named} named with no new subject; it fits the current project {current['id']}")
            return res
        if current:
            return clarify(
                f"{named} needs {needs}, and none was given. The current project {current['id']} "
                f"\"{current['title']}\" is workflow {current['workflow']} ({WORKFLOWS[current['workflow']][0]}), which "
                f"{named} does not fit. Tell the owner this and ask what subject they want, or whether to "
                f"continue {current['id']} with the specialist that does fit. Do not pick a subject.",
                "incompatible_specialist")
        return clarify(f"{named} needs {needs}, and none was given. Ask the owner for it. Do not pick a subject.",
                       "missing_subject")

    # 2. "Continue" with nothing new: stay on the current project.
    if not attachments and not named and re.search(CONTINUE, low) and not subject_words:
        if current:
            res.update(action="continue_project", workflow=current["workflow"], name=WORKFLOWS[current["workflow"]][0],
                       pass_to_specialist=[current["id"]],
                       rationale=f"a request to continue with no new subject: stay on {current['id']}")
            return res
        return clarify("The owner asked to continue but there is no current project. Ask which project or what "
                       "they want made. Do not pick a subject.", "missing_subject")

    # 3. New material: attachments first, then words.
    if videos and own_footage:
        wf, why = "A", "the owner's own footage: enter at the rough-cut stage"
    elif videos and explicit in ("D", "E"):
        wf, why = explicit, f"the words ask for workflow {explicit}; the attached video is its subject or reference"
    elif videos:
        wf, why = "C", "a video was attached with no instruction to edit it: treat it as a reference to analyse"
        res["needs_clarification"] = "Confirm this is a reference to study, not the owner's own footage to edit."
        res["flags"].append("ambiguous_video")
    elif images and explicit in ("D", "E"):
        wf, why = explicit, f"the words ask for workflow {explicit}; the attached image is its subject or reference"
    elif images:
        wf, why = "B", "an image was attached: treat it as a visual creative reference"
    elif other:
        wf, why = "B", "an attachment of unknown type: ask Agent 00 to identify it"
        res["needs_clarification"] = "Unrecognised file type; confirm what it is."
        res["flags"].append("unknown_attachment")
    else:
        wf, why = by_text["workflow"], (f"matched '{by_text['matched']}'" if by_text["matched"] else
                                         "no reference, footage or generation request: an original idea")
    if named:
        _, needs, fits = SPECIALISTS[named]
        if wf not in fits and not (named == "motion-director" and not attachments):
            return clarify(
                f"The owner named {named}, which needs {needs}, but what they supplied is workflow {wf} "
                f"({WORKFLOWS[wf][0]}). Say so and ask which they want. Do not change the subject to suit the specialist.",
                "incompatible_specialist")
        if named == "motion-director" and not attachments:
            wf, why = "E", "the owner named motion-director and gave a subject in words"
    res.update(workflow=wf, name=WORKFLOWS[wf][0], rationale=why, first_specialist=named or FIRST_SPECIALIST[wf])
    if current and not re.search(NEW_PROJECT, low):
        res["flags"].append("current_project_exists")
        res["project_note"] = (f"{current['id']} \"{current['title']}\" is the current project. If this input plainly "
                               "belongs to it, continue it; if it is plainly new, say you are opening a new project; "
                               "if unclear, ask. Never drop the current project silently.")
    return res


def studio_context(con, prompt: str = "") -> str:
    """Plain-text context injected on every owner message by .claude/hooks/context_hook.py."""
    cur = current_project(con)
    lines = ["[Studio context, generated by studio/studio.py. This is not a message from the owner.]"]
    if cur:
        pend = [f"{r['id']} ({r['gate']})" for r in con.execute(
            "SELECT id,gate FROM approvals WHERE project_id=? AND status='pending' ORDER BY rowid", (cur["id"],))]
        lines.append(f"Current project: {cur['id']} \"{cur['title']}\" (workflow {cur['workflow']}, stage {cur['stage']}, "
                     f"{cur['status']})." + (f" Waiting on the owner: {', '.join(pend)}." if pend else ""))
    else:
        lines.append("Current project: none.")
    others = [f"{r['id']} \"{r['title']}\"" for r in con.execute(
        "SELECT id,title FROM projects WHERE status IN ('active','paused') AND id<>? ORDER BY updated_at DESC LIMIT 5",
        (cur["id"] if cur else "",))]
    if others:
        lines.append("Other open projects: " + "; ".join(others) + ".")
    if prompt.strip():
        try:
            r = route_request(prompt, [], dict(cur) if cur else None)
            hint = f"Routing check on the owner's words alone: action={r['action']}"
            if r["named_specialist"]:
                hint += f", named specialist={r['named_specialist']}"
            if r["flags"]:
                hint += f", flags={','.join(r['flags'])}"
            lines.append(hint + ".")
            if r["needs_clarification"]:
                lines.append("STOP AND ASK: " + r["needs_clarification"])
        except StudioError:
            pass
    lines += [
        "Input rules (CLAUDE.md rule 10):",
        "1. The subject is the owner's words, attachments and current project. Attachments come first: "
        "rerun `python3 studio/studio.py route \"<words>\" --attachment <path>` for any uploaded file.",
        "2. Never substitute a sample, example or built-in topic, and never assume a domain, audience or platform.",
        "3. Stay on the current project unless the owner changes it. A named specialist does not change the subject.",
        "4. Give every specialist the owner's files and IDs. If input is missing or unclear, ask.",
    ]
    return "\n".join(lines)


def cmd_route(a):
    con = connect()
    cur = current_project(con)
    r = route_request(a.text, a.attachment or [], dict(cur) if cur else None)
    if r["workflow"]:
        r["stages"] = [{"stage": s, "requires_approval": g} for s, g in WORKFLOWS[r["workflow"]][1]]
    r["note"] = "Heuristic. The coordinator may override it; say why when it does."
    out(r)


def cmd_context(a):
    print(studio_context(connect(), a.prompt or ""))


def cmd_workflows(a):
    out({k: {"name": n, "stages": [{"stage": s, "requires_approval": g} for s, g in st]}
         for k, (n, st) in WORKFLOWS.items()})


# ---------------------------------------------------------------- projects
def cmd_project_new(a):
    con = connect()
    wf = a.workflow or route(a.title + " " + (a.brief or ""))["workflow"]
    pid = next_id(con, "PRJ")
    first = stage_names(wf)[0]
    budget = a.budget if a.budget is not None else config()["budget"]["per_project_usd"]
    t = now()
    con.execute("INSERT INTO projects(id,title,workflow,stage,brief,external_ref,budget_usd,created_at,updated_at) "
                "VALUES(?,?,?,?,?,?,?,?,?)", (pid, a.title, wf, first, a.brief, a.external_ref, budget, t, t))
    con.execute("INSERT INTO stage_history(project_id,from_stage,to_stage,note,at) VALUES(?,?,?,?,?)",
                (pid, None, first, "project created", t))
    for ins in a.inspiration or []:
        row(con, "inspirations", ins)
        con.execute("INSERT INTO project_inspirations VALUES(?,?)", (pid, ins))
    set_current_project(con, pid)
    con.commit()
    out({"ok": True, "project": as_dict(row(con, "projects", pid))})


def project_status(con, pid: str) -> dict:
    p = row(con, "projects", pid)
    stages = WORKFLOWS[p["workflow"]][1]
    names = [s for s, _ in stages]
    i = names.index(p["stage"])
    nxt = stages[i + 1] if i + 1 < len(stages) else None
    blocked = None
    if nxt and nxt[1]:
        ok, why = gate_open(con, pid, nxt[1])
        if not ok:
            blocked = {"gate": nxt[1], "reason": why}
    docs = [dict(r) for r in con.execute(
        "SELECT id,kind,variant,version,status,author,created_at FROM documents "
        "WHERE project_id=? ORDER BY rowid", (pid,))]
    return {
        "project": dict(p),
        "is_current_project": bool(current_project(con) and current_project(con)["id"] == pid),
        "workflow_name": WORKFLOWS[p["workflow"]][0],
        "completed_stages": names[:i],
        "current_stage": p["stage"],
        "next_stage": nxt[0] if nxt else None,
        "next_stage_blocked_by": blocked,
        "pending_approvals": [dict(r) for r in con.execute(
            "SELECT id,gate,subject_ref,summary,requested_at FROM approvals "
            "WHERE project_id=? AND status='pending' ORDER BY rowid", (pid,))],
        "documents": docs,
        "inspirations": [r[0] for r in con.execute(
            "SELECT inspiration_id FROM project_inspirations WHERE project_id=?", (pid,))],
        "last_runs": [dict(r) for r in con.execute(
            "SELECT id,agent,stage,status,summary,error FROM agent_runs WHERE project_id=? "
            "ORDER BY rowid DESC LIMIT 5", (pid,))],
        "budget": budget_for(con, pid),
    }


def cmd_project_show(a):
    out(project_status(connect(), a.project))


def cmd_project_list(a):
    con = connect()
    q = "SELECT id,title,workflow,stage,status,updated_at FROM projects"
    if not a.all:
        q += " WHERE status IN ('active','paused')"
    out([dict(r) for r in con.execute(q + " ORDER BY updated_at DESC")])


def cmd_project_advance(a):
    con = connect()
    p = row(con, "projects", a.project)
    if p["status"] != "active":
        raise StudioError(f"{a.project} is {p['status']}; resume it first")
    stages = WORKFLOWS[p["workflow"]][1]
    names = [s for s, _ in stages]
    i = names.index(p["stage"])
    if a.to:
        if a.to not in names:
            raise StudioError(f"'{a.to}' is not a stage of workflow {p['workflow']}: {names}")
        j = names.index(a.to)
        if j > i + 1:
            raise StudioError(f"cannot skip from '{p['stage']}' to '{a.to}'; advance one stage at a time")
    else:
        j = i + 1
    if j >= len(names):
        raise StudioError(f"{a.project} is already at the final stage")
    if j > i:
        gate = stages[j][1]
        if gate:
            ok, why = gate_open(con, a.project, gate)
            if not ok:
                raise StudioError(
                    f"Blocked: entering '{names[j]}' needs the user's '{gate}' approval ({why}).",
                    EXIT_BLOCKED, gate=gate, project=a.project, stage=p["stage"])
    t = now()
    status = "done" if names[j] == "done" else "active"
    con.execute("UPDATE projects SET stage=?, status=?, updated_at=? WHERE id=?",
                (names[j], status, t, a.project))
    con.execute("INSERT INTO stage_history(project_id,from_stage,to_stage,note,at) VALUES(?,?,?,?,?)",
                (a.project, p["stage"], names[j], a.note, t))
    con.commit()
    out({"ok": True, "project": a.project, "from": p["stage"], "to": names[j],
         "direction": "forward" if j > i else "rework"})


def _set_status(a, new, allowed_from):
    con = connect()
    p = row(con, "projects", a.project)
    if p["status"] not in allowed_from:
        raise StudioError(f"{a.project} is {p['status']}")
    t = now()
    con.execute("UPDATE projects SET status=?, updated_at=? WHERE id=?", (new, t, a.project))
    con.execute("INSERT INTO stage_history(project_id,from_stage,to_stage,note,at) VALUES(?,?,?,?,?)",
                (a.project, p["stage"], p["stage"], f"status -> {new}" + (f": {a.note}" if a.note else ""), t))
    if new == "active":
        set_current_project(con, a.project)
    con.commit()
    out({"ok": True, **project_status(con, a.project)})


def cmd_project_pause(a):
    _set_status(a, "paused", ("active",))


def cmd_project_resume(a):
    _set_status(a, "active", ("paused",))


def cmd_project_cancel(a):
    _set_status(a, "cancelled", ("active", "paused"))


def cmd_project_use(a):
    """Make a project the current one. Only on the owner's instruction."""
    con = connect()
    p = row(con, "projects", a.project)
    if p["status"] not in ("active", "paused"):
        raise StudioError(f"{a.project} is {p['status']} and cannot be the current project")
    set_current_project(con, a.project)
    con.commit()
    out({"ok": True, "current_project": a.project, "title": p["title"]})


def cmd_project_link(a):
    con = connect()
    row(con, "projects", a.project)
    row(con, "inspirations", a.inspiration)
    con.execute("INSERT OR IGNORE INTO project_inspirations VALUES(?,?)", (a.project, a.inspiration))
    con.commit()
    out({"ok": True})


# ---------------------------------------------------------------- approvals
def budget_for(con, pid: str) -> dict:
    p = row(con, "projects", pid)
    committed = con.execute(
        "SELECT COALESCE(SUM(max_cost_usd),0) FROM approvals WHERE project_id=? "
        "AND gate='paid_generation' AND status='approved'", (pid,)).fetchone()[0]
    actual = con.execute("SELECT COALESCE(SUM(cost_usd),0) FROM generations WHERE project_id=?",
                         (pid,)).fetchone()[0]
    return {"budget_usd": p["budget_usd"], "authorised_usd": round(committed, 2),
            "actual_usd": round(actual, 2), "remaining_usd": round(p["budget_usd"] - committed, 2)}


def month_authorised(con) -> float:
    month = now()[:7]
    return con.execute(
        "SELECT COALESCE(SUM(max_cost_usd),0) FROM approvals WHERE gate='paid_generation' "
        "AND status='approved' AND substr(decided_at,1,7)=?", (month,)).fetchone()[0]


def cmd_approval_request(a):
    con = connect()
    if a.gate != "manifest_update" or a.project:
        if not a.project:
            raise StudioError("--project is required for this gate")
        row(con, "projects", a.project)
    over = 0
    if a.gate == "style":
        ok, why = gate_open(con, a.project, "concept")
        if not ok:
            raise StudioError(
                f"Blocked: style selection cannot be requested before the concept is approved ({why}).",
                EXIT_BLOCKED, gate="concept", project=a.project)
    if a.gate == "paid_generation":
        if a.max_cost is None or a.uses is None:
            raise StudioError("paid_generation needs --max-cost (USD) and --uses (number of tool calls)")
        b = budget_for(con, a.project)
        cap = config()["budget"]["monthly_usd"]
        problems = []
        if a.max_cost > b["remaining_usd"] + 1e-9:
            problems.append(f"project budget: ${a.max_cost:.2f} requested, ${b['remaining_usd']:.2f} remaining of ${b['budget_usd']:.2f}")
        if month_authorised(con) + a.max_cost > cap + 1e-9:
            problems.append(f"monthly cap: ${month_authorised(con):.2f} already authorised of ${cap:.2f}")
        if problems and not a.over_budget:
            raise StudioError("Blocked by budget: " + "; ".join(problems) +
                              ". Re-request with --over-budget only if the user explicitly accepts the overrun.",
                              EXIT_BLOCKED, budget=b)
        over = 1 if problems else 0
    aid = next_id(con, "APR")
    con.execute("INSERT INTO approvals(id,project_id,gate,subject_ref,summary,max_cost_usd,uses_total,uses_left,over_budget,requested_at) "
                "VALUES(?,?,?,?,?,?,?,?,?,?)",
                (aid, a.project, a.gate, a.subject, a.summary, a.max_cost, a.uses, a.uses, over, now()))
    con.commit()
    out({"ok": True, "approval": as_dict(row(con, "approvals", aid)),
         "next": "STOP and ask the user. Record their answer with: approval decide "
                 f"{aid} --approve|--reject --user-quote \"<their words>\""})


def cmd_approval_decide(a):
    con = connect()
    ap = row(con, "approvals", a.approval)
    if ap["status"] != "pending":
        raise StudioError(f"{a.approval} is already {ap['status']}; request a new approval instead")
    quote = (a.user_quote or "").strip()
    if len(quote) < 2:
        raise StudioError("--user-quote is required: the user's own words. Agents must not self-approve.")
    status = "approved" if a.approve else "rejected"
    con.execute("UPDATE approvals SET status=?, user_quote=?, decided_at=? WHERE id=?",
                (status, quote, now(), a.approval))
    # --chosen names the one document the owner picked when several variants were offered
    subject = a.chosen or ap["subject_ref"] or ""
    if a.chosen and a.chosen not in (ap["subject_ref"] or "").split(","):
        raise StudioError(f"{a.chosen} is not one of the documents this approval covers ({ap['subject_ref']})")
    if re.fullmatch(r"DOC-\d+", subject) and ap["gate"] in ("concept", "style", "export"):
        _doc_set_status(con, subject, status)
        if a.chosen and status == "approved":
            for other in (ap["subject_ref"] or "").split(","):
                if other != a.chosen:
                    con.execute("UPDATE documents SET status='rejected' WHERE id=? AND status='draft'", (other,))
    con.commit()
    out({"ok": True, "approval": as_dict(row(con, "approvals", a.approval))})


def cmd_approval_list(a):
    con = connect()
    q, args = "SELECT * FROM approvals WHERE 1=1", []
    if a.project:
        q += " AND project_id=?"; args.append(a.project)
    if a.pending:
        q += " AND status='pending'"
    out([dict(r) for r in con.execute(q + " ORDER BY rowid", args)])


# ---------------------------------------------------------------- paid-generation gate
def paid_gate(tool: str) -> tuple[bool, str]:
    """Called by .claude/hooks/paid_gate.py before a paid tool runs. Consumes one use."""
    con = connect()
    ap = con.execute(
        "SELECT a.* FROM approvals a JOIN projects p ON p.id=a.project_id "
        "WHERE a.gate='paid_generation' AND a.status='approved' AND a.uses_left>0 "
        "AND p.status='active' ORDER BY a.rowid DESC LIMIT 1").fetchone()
    if not ap:
        reason = ("No approved paid-generation authorisation with uses left. Request one with "
                  "`studio.py approval request --gate paid_generation --project PRJ-… --max-cost … --uses …`, "
                  "ask the user, and record their decision.")
        con.execute("INSERT INTO gate_log(at,tool,decision,reason) VALUES(?,?,?,?)",
                    (now(), tool, "denied", "no approval"))
        con.commit()
        return False, reason
    con.execute("UPDATE approvals SET uses_left=uses_left-1 WHERE id=?", (ap["id"],))
    con.execute("INSERT INTO gate_log(at,tool,decision,approval_id,reason) VALUES(?,?,?,?,?)",
                (now(), tool, "allowed", ap["id"], f"{ap['uses_left'] - 1} uses left"))
    con.commit()
    return True, f"{ap['id']} ({ap['uses_left'] - 1} uses left, cap ${ap['max_cost_usd']:.2f})"


def cmd_gate_check(a):
    ok, msg = paid_gate(a.tool)
    out({"allowed": ok, "detail": msg})
    if not ok:
        sys.exit(EXIT_BLOCKED)


def cmd_gate_log(a):
    out([dict(r) for r in connect().execute("SELECT * FROM gate_log ORDER BY id DESC LIMIT 50")])


# ---------------------------------------------------------------- inspirations
def find_duplicate(con, urls: list[str], title: str, source_type: str) -> dict | None:
    for u in urls:
        r = con.execute("SELECT inspiration_id FROM inspiration_links WHERE url_norm=?",
                        (norm_url(u),)).fetchone()
        if r:
            return {"id": r[0], "matched_on": "link", "url": u}
    if not urls:
        r = con.execute("SELECT id FROM inspirations WHERE title_norm=? AND source_type=? AND id NOT IN "
                        "(SELECT inspiration_id FROM inspiration_links)",
                        (norm_text(title), source_type)).fetchone()
        if r:
            return {"id": r[0], "matched_on": "title"}
    return None


def add_inspiration(con, *, source_type, title, urls=(), creator=None, notes=None, meta=None) -> dict:
    urls = [u.strip() for u in urls if u and u.strip()]
    dup = find_duplicate(con, urls, title, source_type)
    if dup:
        return {"ok": True, "created": False, "duplicate_of": dup["id"], "matched_on": dup["matched_on"]}
    iid = next_id(con, "INS")
    con.execute("INSERT INTO inspirations(id,source_type,title,title_norm,creator,notes,source_meta_json,created_at) "
                "VALUES(?,?,?,?,?,?,?,?)",
                (iid, source_type, title.strip(), norm_text(title), creator, notes,
                 json.dumps(meta, ensure_ascii=False) if meta is not None else None, now()))
    seen = set()
    for u in urls:
        n = norm_url(u)
        if n in seen:
            continue
        seen.add(n)
        con.execute("INSERT INTO inspiration_links VALUES(?,?,?)", (iid, u, n))
    return {"ok": True, "created": True, "id": iid}


def cmd_ins_add(a):
    con = connect()
    r = add_inspiration(con, source_type=a.source, title=a.title, urls=a.url or [],
                        creator=a.creator, notes=a.notes)
    con.commit()
    out(r)


def cmd_ins_access(a):
    con = connect()
    row(con, "inspirations", a.inspiration)
    con.execute("UPDATE inspirations SET access_status=?, access_detail=? WHERE id=?",
                (a.status, a.detail, a.inspiration))
    con.commit()
    out({"ok": True, "inspiration": a.inspiration, "access_status": a.status})


REVIEWED = ("reviewed_video", "reviewed_images", "metadata_only")
CERTAINTY = ("observed", "inferred", "suggested", "unverified")


def record_analysis(con, iid, origin, access_status, analysis_text, basis, ref_id=None) -> bool:
    """Append to the analysis history. Returns False when this exact analysis is already stored."""
    h = hashlib.sha256(analysis_text.encode()).hexdigest()
    cur = con.execute(
        "INSERT OR IGNORE INTO inspiration_analyses(inspiration_id,origin,ref_id,access_status,basis,"
        "analysis_json,content_hash,recorded_at) VALUES(?,?,?,?,?,?,?,?)",
        (iid, origin, ref_id, access_status, basis, analysis_text, h, now()))
    return cur.rowcount == 1


def cmd_ins_analysis(a):
    con = connect()
    r = row(con, "inspirations", a.inspiration)
    if r["access_status"] not in REVIEWED:
        raise StudioError(
            f"Refused: {a.inspiration} is '{r['access_status']}'. Analysis may only be recorded for content "
            "that was actually inspected. Record what was inspected with `ins access` or ask the user "
            "for an upload or screenshot.", EXIT_BLOCKED)
    if not (a.basis or "").strip():
        raise StudioError("--basis is required: state exactly what was inspected (file, frames, page text)")
    data = json.loads(read_arg(a.json))
    status = "partial" if r["access_status"] == "metadata_only" else a.status
    text = json.dumps(data, ensure_ascii=False, sort_keys=True)
    new = record_analysis(con, a.inspiration, "studio", r["access_status"], text, a.basis)
    con.execute("UPDATE inspirations SET analysis_json=?, analysis_basis=?, analysis_status=? WHERE id=?",
                (text, a.basis, status, a.inspiration))
    con.commit()
    out({"ok": True, "inspiration": a.inspiration, "analysis_status": status, "new_history_entry": new,
         "note": "metadata only: recorded as partial, not a media review" if status != a.status else None})


def cmd_ins_show(a):
    con = connect()
    r = dict(row(con, "inspirations", a.inspiration))
    r["links"] = [x[0] for x in con.execute(
        "SELECT url FROM inspiration_links WHERE inspiration_id=?", (a.inspiration,))]
    r["genres"] = [x[0] for x in con.execute(
        "SELECT g.name FROM genres g JOIN inspiration_genres ig ON ig.genre_id=g.id "
        "WHERE ig.inspiration_id=?", (a.inspiration,))]
    r["agent00_refs"] = [dict(x) for x in con.execute(
        "SELECT ref_id,url,is_duplicate FROM agent00_refs WHERE inspiration_id=? ORDER BY ref_id", (a.inspiration,))]
    r["analysis_history"] = [dict(x) for x in con.execute(
        "SELECT id,origin,ref_id,access_status,basis,recorded_at FROM inspiration_analyses "
        "WHERE inspiration_id=? ORDER BY id", (a.inspiration,))]
    r["reference_shots"] = [x[0] for x in con.execute(
        "SELECT id FROM reference_shots WHERE inspiration_id=? ORDER BY id", (a.inspiration,))]
    out(r)


def cmd_ins_list(a):
    con = connect()
    q, args = "SELECT id,source_type,title,creator,access_status,analysis_status FROM inspirations WHERE 1=1", []
    if a.search:
        q += " AND (title_norm LIKE ? OR lower(COALESCE(notes,'')) LIKE ? OR lower(COALESCE(analysis_json,'')) LIKE ?)"
        s = f"%{a.search.lower()}%"
        args += [f"%{norm_text(a.search)}%", s, s]
    out([dict(r) for r in con.execute(q + " ORDER BY rowid", args)])


# ---------------------------------------------------------------- Agent 00 mirror
AGENT00_DB = ROOT / "data" / "inspirations.sqlite3"
PLATFORM_TO_SOURCE = {"instagram": "instagram", "pinterest": "pinterest", "youtube": "youtube", "other": "web",
                      "local": "upload"}


def upsert_genre(con, name: str, origin: str = "discovered") -> tuple[str, bool]:
    n = norm_text(name)
    ex = con.execute("SELECT id FROM genres WHERE name_norm=?", (n,)).fetchone()
    if ex:
        return ex["id"], False
    gid, t = next_id(con, "GEN"), now()
    con.execute("INSERT INTO genres(id,name,name_norm,origin,status,created_at,updated_at) VALUES(?,?,?,?,?,?,?)",
                (gid, name.strip(), n, origin, "approved" if origin == "user" else "proposed", t, t))
    return gid, True


def sync_agent00(con, src: Path) -> dict:
    """One-way mirror of Agent 00's catalog into the studio database. Never writes to `src`.
    Safe to run repeatedly: unchanged records are skipped, analyses are stored once each."""
    if not src.is_file():
        raise StudioError(f"Agent 00 catalog not found at {src}. It is created by tools/inspiration.py on first use.")
    acon = sqlite3.connect(f"file:{src}?mode=ro", uri=True)
    acon.row_factory = sqlite3.Row
    res = {"created": [], "linked_to_existing": [], "duplicates": [], "updated": [], "unchanged": 0,
           "analyses_added": 0, "genres_added": [], "warnings": []}
    for r in acon.execute("SELECT * FROM refs ORDER BY id"):
        ref = f"REF-{r['id']:06d}"
        m = con.execute("SELECT * FROM agent00_refs WHERE ref_id=?", (ref,)).fetchone()
        t = now()
        if m:
            iid, dup = m["inspiration_id"], bool(m["is_duplicate"])
            if m["source_updated_at"] == r["updated_at"]:
                res["unchanged"] += 1
                continue
            res["updated"].append(ref)
        else:
            # a local file is identified by its content hash, a link by its normalised form
            key = r["url_key"] if r["platform"] == "local" else norm_url(r["url"])
            ex = con.execute("SELECT inspiration_id FROM inspiration_links WHERE url_norm=?", (key,)).fetchone()
            if ex:
                iid = ex["inspiration_id"]
                dup = bool(con.execute("SELECT 1 FROM agent00_refs WHERE inspiration_id=? AND is_duplicate=0",
                                       (iid,)).fetchone())
                if dup:
                    res["duplicates"].append({"ref": ref, "same_post_as": iid, "url": r["url"]})
                else:
                    res["linked_to_existing"].append({"ref": ref, "inspiration": iid})
            else:
                iid, dup = next_id(con, "INS"), False
                title = (r["title"] or "").strip() or r["url"]
                con.execute("INSERT INTO inspirations(id,source_type,title,title_norm,created_at) VALUES(?,?,?,?,?)",
                            (iid, PLATFORM_TO_SOURCE.get(r["platform"], "web"), title, norm_text(title), t))
                con.execute("INSERT INTO inspiration_links VALUES(?,?,?)", (iid, r["url"], key))
                res["created"].append({"ref": ref, "inspiration": iid})
            con.execute("INSERT INTO agent00_refs(ref_id,inspiration_id,url,is_duplicate,first_synced_at,last_synced_at) "
                        "VALUES(?,?,?,?,?,?)", (ref, iid, r["url"], int(dup), t, t))
        analysis = (r["analysis_json"] or "").strip()
        has_analysis = analysis not in ("", "{}")
        if not dup:        # the first REF for a post is authoritative for its descriptive fields
            meta = {k: r[k] for k in ("platform", "collection_name", "created_at", "updated_at")}
            title = (r["title"] or "").strip() or r["url"]
            detail = (r["access_detail"] if "access_detail" in r.keys() else "") or None
            con.execute("UPDATE inspirations SET title=?, title_norm=?, creator=?, notes=?, collection=?, "
                        "access_status=?, access_detail=?, source_meta_json=? WHERE id=?",
                        (title, norm_text(title), r["creator"] or None, r["notes"] or None,
                         r["collection_name"] or None, r["access_status"], detail,
                         json.dumps({"agent00": meta}, ensure_ascii=False), iid))
        if has_analysis:
            if record_analysis(con, iid, "agent00", r["access_status"], analysis,
                               f"Agent 00 analysis of {ref} (access_status={r['access_status']})", ref):
                res["analyses_added"] += 1
            obj = json.loads(analysis)
            claims = [x.get("name", "?") for x in obj.get("techniques", []) if x.get("certainty") == "observed"]
            if r["access_status"] in ("blocked", "unreviewed") and claims:
                res["warnings"].append(f"{ref}: marked '{r['access_status']}' but lists observed techniques "
                                       f"{claims}. Nothing can be observed in a source that was not opened; review it.")
            if not dup:
                status = {"reviewed_video": "complete", "reviewed_images": "complete",
                          "metadata_only": "partial"}.get(r["access_status"], "none")
                con.execute("UPDATE inspirations SET analysis_json=?, analysis_basis=?, analysis_status=? WHERE id=?",
                            (analysis, f"Agent 00, {ref}, access_status={r['access_status']}", status, iid))
            for g in json.loads(r["genre_json"] or "[]"):
                if isinstance(g, str) and g.strip():
                    gid, made = upsert_genre(con, g)
                    if made:
                        res["genres_added"].append(g.strip())
                    con.execute("INSERT OR IGNORE INTO inspiration_genres VALUES(?,?)", (iid, gid))
        con.execute("UPDATE agent00_refs SET source_updated_at=?, last_synced_at=? WHERE ref_id=?",
                    (r["updated_at"], t, ref))
    acon.close()
    res["mirrored_total"] = con.execute("SELECT COUNT(*) FROM agent00_refs").fetchone()[0]
    return res


def cmd_ins_sync(a):
    con = connect()
    res = sync_agent00(con, Path(a.db) if a.db else AGENT00_DB)
    con.commit()
    out({"ok": True, **res})


# ---------------------------------------------------------------- reference shots (15-column manifest)
MANIFEST_FIELDS = ("shot_id start_time end_time shot_size body_crop camera_angle camera_height composition "
                   "model_movement camera_movement focal_length recording_settings actual_frame sketch "
                   "confidence").split()


def cmd_refshot_import(a):
    """Import rows in the owner's 15-column format. Every row arrives PENDING_REVIEW."""
    con = connect()
    path = Path(a.file)
    with path.open(newline="", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        missing = [c for c in MANIFEST_FIELDS if c not in (reader.fieldnames or [])]
        if missing:
            raise StudioError(f"{path.name} is not in the shot manifest format; missing columns: {missing}")
        rows = list(reader)
    for table, val in (("inspirations", a.inspiration), ("assets", a.asset), ("projects", a.project)):
        if val:
            row(con, table, val)
    added, skipped, unresolved = [], 0, []
    for r in rows:
        ref = (r.get("reference_id") or "").strip() or None
        iid = a.inspiration
        if ref and not iid:
            m = con.execute("SELECT inspiration_id FROM agent00_refs WHERE ref_id=?", (ref,)).fetchone()
            if m:
                iid = m["inspiration_id"]
            else:
                unresolved.append(ref)
        label = (r.get("candidate_label") or "").strip() or None
        vals = [(r.get(c) or "").strip() for c in MANIFEST_FIELDS]
        source_key = ref or a.inspiration or a.asset or path.name
        # Agent 00 renumbers PROPOSED- ids on every export, so they are not part of the identity
        ident = [source_key, label or ""] + (vals[1:] if vals[0].startswith("PROPOSED-") else vals)
        h = hashlib.sha256(json.dumps(ident, ensure_ascii=False).encode()).hexdigest()
        if con.execute("SELECT 1 FROM reference_shots WHERE row_hash=?", (h,)).fetchone():
            skipped += 1
            continue
        rid = next_id(con, "RSH")
        con.execute(
            "INSERT INTO reference_shots(id,inspiration_id,ref_id,asset_id,project_id,source_label,candidate_label,"
            + ",".join(MANIFEST_FIELDS) + ",row_hash,created_at) VALUES(" + ",".join("?" * (9 + len(MANIFEST_FIELDS))) + ")",
            (rid, iid, ref, a.asset, a.project, path.name, label, *vals, h, now()))
        added.append(rid)
    con.commit()
    out({"ok": True, "file": path.name, "rows": len(rows), "added": added, "already_present": skipped,
         "unresolved_reference_ids": sorted(set(unresolved)),
         "status": "PENDING_REVIEW — nothing joins the approved manifest until `refshot decide`"})


def cmd_refshot_decide(a):
    con = connect()
    quote = (a.user_quote or "").strip()
    if len(quote) < 2:
        raise StudioError("--user-quote is required: the user's own words. Agents must not self-approve.")
    shots = [row(con, "reference_shots", i) for i in a.shots]
    for sh in shots:
        if sh["approval_status"] != "PENDING_REVIEW":
            raise StudioError(f"{sh['id']} is already {sh['approval_status']}; approved records are not changed")
    t, status = now(), "approved" if a.approve else "rejected"
    aid = next_id(con, "APR")
    con.execute("INSERT INTO approvals(id,project_id,gate,subject_ref,summary,status,user_quote,requested_at,decided_at) "
                "VALUES(?,?,?,?,?,?,?,?,?)",
                (aid, None, "manifest_update", ",".join(a.shots), f"{len(shots)} reference shot(s)", status, quote, t, t))
    for sh in shots:
        con.execute("UPDATE reference_shots SET approval_status=?, approval_id=?, decided_at=? WHERE id=?",
                    (status.upper(), aid, t, sh["id"]))
    con.commit()
    out({"ok": True, "shots": a.shots, "status": status.upper(), "approval": aid})


def cmd_refshot_list(a):
    con = connect()
    q, args = ("SELECT id,inspiration_id,ref_id,candidate_label,shot_id,start_time,end_time,shot_size,"
               "camera_movement,confidence,approval_status FROM reference_shots WHERE 1=1"), []
    if a.status:
        q += " AND approval_status=?"; args.append(a.status)
    if a.inspiration:
        q += " AND inspiration_id=?"; args.append(a.inspiration)
    out([dict(r) for r in con.execute(q + " ORDER BY id", args)])


def cmd_refshot_export(a):
    """Write approved shots as a CSV with exactly the template's 15 columns. Never overwrites."""
    con = connect()
    dest = Path(a.file)
    if dest.exists():
        raise StudioError(f"{dest} already exists; choose a new filename (nothing is overwritten)")
    rows = con.execute(f"SELECT {','.join(MANIFEST_FIELDS)} FROM reference_shots WHERE approval_status=? ORDER BY id",
                       (a.status,)).fetchall()
    dest.parent.mkdir(parents=True, exist_ok=True)
    with dest.open("w", newline="", encoding="utf-8") as f:
        w = csv.writer(f, lineterminator="\n")
        w.writerow(MANIFEST_FIELDS)
        w.writerows([list(r) for r in rows])
    out({"ok": True, "file": str(dest), "rows": len(rows), "status": a.status})


def cmd_manifest_link(a):
    con = connect()
    row(con, "shot_manifest", a.technique)
    row(con, "reference_shots", a.shot)
    cur = con.execute("INSERT OR IGNORE INTO technique_shots VALUES(?,?,?)", (a.technique, a.shot, a.note))
    con.commit()
    out({"ok": True, "linked": cur.rowcount == 1, "technique": a.technique, "reference_shot": a.shot})


def cmd_manifest_show(a):
    con = connect()
    t = dict(row(con, "shot_manifest", a.technique))
    t["reference_shots"] = [dict(r) for r in con.execute(
        "SELECT r.id,r.inspiration_id,r.ref_id,r.shot_id,r.start_time,r.end_time,r.approval_status,ts.note "
        "FROM technique_shots ts JOIN reference_shots r ON r.id=ts.reference_shot_id "
        "WHERE ts.technique_id=? ORDER BY r.id", (a.technique,))]
    out(t)


# ---------------------------------------------------------------- genres
def cmd_genre_add(a):
    con = connect()
    n = norm_text(a.name)
    ex = con.execute("SELECT id,status FROM genres WHERE name_norm=?", (n,)).fetchone()
    if ex:
        gid, created = ex["id"], False
    else:
        gid, created = next_id(con, "GEN"), True
        t = now()
        con.execute("INSERT INTO genres(id,name,name_norm,description,knowledge_json,origin,status,created_at,updated_at) "
                    "VALUES(?,?,?,?,?,?,?,?,?)",
                    (gid, a.name.strip(), n, a.description,
                     read_arg(a.knowledge) if a.knowledge else None, a.origin,
                     "approved" if a.origin == "user" else "proposed", t, t))
    for ins in a.inspiration or []:
        row(con, "inspirations", ins)
        con.execute("INSERT OR IGNORE INTO inspiration_genres VALUES(?,?)", (ins, gid))
    con.commit()
    out({"ok": True, "created": created, "genre": as_dict(row(con, "genres", gid))})


def cmd_genre_list(a):
    con = connect()
    out([dict(r) for r in con.execute(
        "SELECT g.id,g.name,g.origin,g.status,g.version,"
        "(SELECT COUNT(*) FROM inspiration_genres ig WHERE ig.genre_id=g.id) AS inspirations "
        "FROM genres g ORDER BY g.name")])


# ---------------------------------------------------------------- shot manifest
def similar_manifest(con, name: str) -> tuple[str | None, float]:
    n = norm_text(name)
    best, score = None, 0.0
    for r in con.execute("SELECT id,name_norm FROM shot_manifest"):
        s = difflib.SequenceMatcher(None, n, r["name_norm"]).ratio()
        if s > score:
            best, score = r["id"], s
    return best, score


def cmd_manifest_propose(a):
    con = connect()
    n = norm_text(a.name)
    ex = con.execute("SELECT id FROM shot_manifest WHERE name_norm=?", (n,)).fetchone()
    if ex:
        out({"ok": True, "created": False, "duplicate_of": ex["id"],
             "note": "Already in the manifest; no proposal created."})
        return
    pend = con.execute("SELECT id FROM manifest_proposals WHERE name_norm=? AND status='proposed'", (n,)).fetchone()
    if pend:
        out({"ok": True, "created": False, "duplicate_of": pend["id"],
             "note": "An open proposal with this name already exists."})
        return
    spec = json.loads(read_arg(a.spec))
    sim, score = similar_manifest(con, a.name)
    mid = next_id(con, "MPR")
    con.execute("INSERT INTO manifest_proposals(id,name,name_norm,category,spec_json,source_ref,similar_to,created_at) "
                "VALUES(?,?,?,?,?,?,?,?)",
                (mid, a.name.strip(), n, a.category, json.dumps(spec, ensure_ascii=False),
                 a.source, sim if score >= 0.75 else None, now()))
    con.commit()
    out({"ok": True, "created": True, "proposal": mid,
         "similar_to": sim if score >= 0.75 else None, "similarity": round(score, 2),
         "next": "Proposals never enter the manifest until the user decides: manifest decide "
                 f"{mid} --approve|--reject --user-quote \"…\""})


def cmd_manifest_decide(a):
    con = connect()
    pr = row(con, "manifest_proposals", a.proposal)
    if pr["status"] != "proposed":
        raise StudioError(f"{a.proposal} is already {pr['status']}")
    quote = (a.user_quote or "").strip()
    if len(quote) < 2:
        raise StudioError("--user-quote is required: the user's own words. Agents must not self-approve.")
    t = now()
    aid = next_id(con, "APR")
    status = "approved" if a.approve else "rejected"
    con.execute("INSERT INTO approvals(id,project_id,gate,subject_ref,summary,status,user_quote,requested_at,decided_at) "
                "VALUES(?,?,?,?,?,?,?,?,?)",
                (aid, None, "manifest_update", a.proposal, f"Manifest entry: {pr['name']}", status, quote, t, t))
    sid = None
    if a.approve:
        if con.execute("SELECT 1 FROM shot_manifest WHERE name_norm=?", (pr["name_norm"],)).fetchone():
            raise StudioError(f"'{pr['name']}' is already in the manifest")
        sid = next_id(con, "SHT")
        con.execute("INSERT INTO shot_manifest(id,name,name_norm,category,spec_json,source_ref,approval_id,created_at) "
                    "VALUES(?,?,?,?,?,?,?,?)",
                    (sid, pr["name"], pr["name_norm"], pr["category"], pr["spec_json"], pr["source_ref"], aid, t))
        if (pr["source_ref"] or "").startswith("RSH-") and con.execute(
                "SELECT 1 FROM reference_shots WHERE id=?", (pr["source_ref"],)).fetchone():
            con.execute("INSERT OR IGNORE INTO technique_shots VALUES(?,?,?)", (sid, pr["source_ref"], "source of the technique"))
    con.execute("UPDATE manifest_proposals SET status=?, manifest_id=?, decided_at=? WHERE id=?",
                (status, sid, t, a.proposal))
    con.commit()
    out({"ok": True, "proposal": a.proposal, "status": status, "manifest_id": sid, "approval": aid})


def cmd_manifest_list(a):
    con = connect()
    if a.proposals:
        out([dict(r) for r in con.execute(
            "SELECT id,name,category,source_ref,similar_to,status FROM manifest_proposals ORDER BY rowid")])
    else:
        out([dict(r) for r in con.execute(
            "SELECT id,name,category,version,source_ref FROM shot_manifest ORDER BY name")])


# ---------------------------------------------------------------- documents and shots
def _doc_set_status(con, doc_id: str, status: str) -> None:
    d = row(con, "documents", doc_id)
    if status == "approved":
        con.execute("UPDATE documents SET status='superseded' WHERE project_id=? AND kind=? AND variant=? "
                    "AND status='approved'", (d["project_id"], d["kind"], d["variant"]))
    con.execute("UPDATE documents SET status=? WHERE id=?", (status, doc_id))


def cmd_doc_add(a):
    """Always inserts a new version. Existing versions are never edited."""
    con = connect()
    row(con, "projects", a.project)
    content = read_arg(a.content)
    v = con.execute("SELECT COALESCE(MAX(version),0)+1 FROM documents WHERE project_id=? AND kind=? AND variant=?",
                    (a.project, a.kind, a.variant)).fetchone()[0]
    did = next_id(con, "DOC")
    con.execute("INSERT INTO documents(id,project_id,kind,variant,version,content,author,created_at) "
                "VALUES(?,?,?,?,?,?,?,?)", (did, a.project, a.kind, a.variant, v, content, a.author, now()))
    shots = 0
    if a.kind == "shot_list":
        try:
            data = json.loads(content)
        except json.JSONDecodeError:
            raise StudioError("a shot_list document must be JSON: {\"shots\": [{\"description\": …, …}]}")
        for i, s in enumerate(data.get("shots", []), 1):
            if not s.get("description"):
                raise StudioError(f"shot {i} has no description")
            mref = s.get("manifest_id")
            if mref:
                row(con, "shot_manifest", mref)
            con.execute("INSERT INTO shots(id,project_id,document_id,seq,manifest_id,description,spec_json) "
                        "VALUES(?,?,?,?,?,?,?)",
                        (next_id(con, "SHO"), a.project, did, i, mref, s["description"],
                         json.dumps({k: v2 for k, v2 in s.items() if k not in ("description", "manifest_id")},
                                    ensure_ascii=False)))
            shots += 1
    con.commit()
    out({"ok": True, "document": did, "kind": a.kind, "variant": a.variant, "version": v, "shots": shots})


def cmd_doc_show(a):
    con = connect()
    d = dict(row(con, "documents", a.document))
    d["shots"] = [dict(r) for r in con.execute(
        "SELECT id,seq,manifest_id,description,spec_json FROM shots WHERE document_id=? ORDER BY seq",
        (a.document,))]
    out(d)


def cmd_doc_list(a):
    con = connect()
    out([dict(r) for r in con.execute(
        "SELECT id,kind,variant,version,status,author,created_at FROM documents WHERE project_id=? ORDER BY rowid",
        (a.project,))])


# ---------------------------------------------------------------- prompts / generations / assets
def cmd_prompt_add(a):
    con = connect()
    row(con, "projects", a.project)
    pid = next_id(con, "PRM")
    con.execute("INSERT INTO prompts(id,project_id,shot_id,provider,model,kind,prompt,params_json,parent_id,created_at) "
                "VALUES(?,?,?,?,?,?,?,?,?,?)",
                (pid, a.project, a.shot, a.provider, a.model, a.kind, read_arg(a.prompt),
                 read_arg(a.params) if a.params else None, a.parent, now()))
    con.commit()
    out({"ok": True, "prompt": pid})


def cmd_gen_record(a):
    con = connect()
    row(con, "projects", a.project)
    gid = next_id(con, "GNR")
    con.execute("INSERT INTO generations(id,project_id,prompt_id,approval_id,provider,tool,status,external_task_id,cost_usd,credits,asset_id,review_notes,created_at) "
                "VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?)",
                (gid, a.project, a.prompt, a.approval, a.provider, a.tool, a.status, a.task_id,
                 a.cost, a.credits, a.asset, a.notes, now()))
    con.commit()
    out({"ok": True, "generation": gid, "budget": budget_for(con, a.project)})


def cmd_asset_add(a):
    con = connect()
    p = Path(a.path)
    h = size = None
    if p.is_file():
        sha = hashlib.sha256()
        with p.open("rb") as f:
            for chunk in iter(lambda: f.read(1 << 20), b""):
                sha.update(chunk)
        h, size = sha.hexdigest(), p.stat().st_size
        ex = con.execute("SELECT id FROM assets WHERE content_hash=?", (h,)).fetchone()
        if ex:
            out({"ok": True, "created": False, "duplicate_of": ex["id"], "matched_on": "content hash"})
            return
    try:
        rel = str(p.resolve().relative_to(ROOT))
    except ValueError:
        rel = a.path
    aid = next_id(con, "AST")
    con.execute("INSERT INTO assets(id,project_id,kind,rel_path,content_hash,bytes,meta_json,created_at) "
                "VALUES(?,?,?,?,?,?,?,?)",
                (aid, a.project, a.kind, rel, h, size, read_arg(a.meta) if a.meta else None, now()))
    con.commit()
    out({"ok": True, "created": True, "asset": aid, "hashed": h is not None})


# ---------------------------------------------------------------- agent runs
def cmd_run_start(a):
    con = connect()
    rid = next_id(con, "RUN")
    con.execute("INSERT INTO agent_runs(id,project_id,agent,model,stage,status,summary,started_at) "
                "VALUES(?,?,?,?,?,?,?,?)", (rid, a.project, a.agent, a.model, a.stage, "started", a.summary, now()))
    con.commit()
    out({"ok": True, "run": rid})


def cmd_run_finish(a):
    con = connect()
    row(con, "agent_runs", a.run)
    con.execute("UPDATE agent_runs SET status=?, summary=COALESCE(?,summary), output_ref=?, tokens_in=?, "
                "tokens_out=?, error=?, finished_at=? WHERE id=?",
                ("failed" if a.error else "succeeded", a.summary, a.output, a.tokens_in, a.tokens_out,
                 a.error, now(), a.run))
    con.commit()
    out({"ok": True, "run": as_dict(row(con, "agent_runs", a.run))})


# ---------------------------------------------------------------- publishing
def cmd_pub_draft(a):
    con = connect()
    row(con, "projects", a.project)
    pid = next_id(con, "PUB")
    con.execute("INSERT INTO publications(id,project_id,platform,caption,asset_id,created_at) VALUES(?,?,?,?,?,?)",
                (pid, a.project, a.platform, read_arg(a.caption) if a.caption else None, a.asset, now()))
    con.commit()
    out({"ok": True, "publication": pid, "status": "draft"})


def cmd_pub_set(a):
    """Record scheduling or publication. Refused without the user's 'publish' approval."""
    con = connect()
    pub = row(con, "publications", a.publication)
    ok, why = gate_open(con, pub["project_id"], "publish")
    if not ok:
        raise StudioError(f"Blocked: scheduling or publishing needs the user's 'publish' approval ({why}).",
                          EXIT_BLOCKED, gate="publish", project=pub["project_id"])
    if a.status == "scheduled":
        con.execute("UPDATE publications SET status='scheduled', scheduled_at=?, approval_id=? WHERE id=?",
                    (a.at, why, a.publication))
    else:
        con.execute("UPDATE publications SET status='published', published_at=?, url=?, approval_id=? WHERE id=?",
                    (a.at or now(), a.url, why, a.publication))
    con.commit()
    out({"ok": True, "publication": as_dict(row(con, "publications", a.publication))})


def cmd_metrics_add(a):
    con = connect()
    row(con, "publications", a.publication)
    data = json.loads(read_arg(a.json))
    con.execute("INSERT INTO metrics(publication_id,captured_at,source,data_json) VALUES(?,?,?,?)",
                (a.publication, now(), a.source, json.dumps(data, ensure_ascii=False)))
    con.commit()
    out({"ok": True})


def cmd_budget(a):
    con = connect()
    cfg = config()["budget"]
    res = {"monthly_cap_usd": cfg["monthly_usd"], "month": now()[:7],
           "month_authorised_usd": round(month_authorised(con), 2)}
    if a.project:
        res["project"] = budget_for(con, a.project)
    out(res)


# ---------------------------------------------------------------- CLI
def build_parser() -> argparse.ArgumentParser:
    ap = argparse.ArgumentParser(prog="studio.py", description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)

    def add(parent, name, fn, help_):
        p = parent.add_parser(name, help=help_)
        p.set_defaults(fn=fn)
        return p

    def group(name, help_):
        g = sub.add_parser(name, help=help_)
        return g.add_subparsers(dest="sub", required=True)

    add(sub, "init", cmd_init, "create or upgrade the database (safe to repeat)")
    add(sub, "snapshot", cmd_snapshot, "write data/studio.sql for committing to git")
    add(sub, "workflows", cmd_workflows, "list workflows A–E with stages and gates")
    p = add(sub, "route", cmd_route, "choose a workflow from the owner's words and attachments")
    p.add_argument("text", nargs="?", default="")
    p.add_argument("--attachment", action="append", help="path of an uploaded file (repeatable)")
    p = add(sub, "context", cmd_context, "current project and input rules (used by the prompt hook)")
    p.add_argument("--prompt")
    p = add(sub, "budget", cmd_budget, "budget position")
    p.add_argument("--project")

    g = group("project", "creative projects")
    p = add(g, "new", cmd_project_new, "create a project")
    p.add_argument("--title", required=True); p.add_argument("--brief")
    p.add_argument("--workflow", choices=list(WORKFLOWS)); p.add_argument("--budget", type=float)
    p.add_argument("--external-ref"); p.add_argument("--inspiration", action="append")
    p = add(g, "show", cmd_project_show, "full status — use this to resume"); p.add_argument("project")
    p = add(g, "list", cmd_project_list, "list projects"); p.add_argument("--all", action="store_true")
    p = add(g, "advance", cmd_project_advance, "move to the next stage (or back with --to)")
    p.add_argument("project"); p.add_argument("--to"); p.add_argument("--note")
    for name, fn in (("pause", cmd_project_pause), ("resume", cmd_project_resume), ("cancel", cmd_project_cancel)):
        p = add(g, name, fn, f"{name} a project"); p.add_argument("project"); p.add_argument("--note")
    p = add(g, "link", cmd_project_link, "link an inspiration"); p.add_argument("project"); p.add_argument("inspiration")
    p = add(g, "use", cmd_project_use, "make this the current project (on the owner's instruction)"); p.add_argument("project")

    g = group("approval", "approval checkpoints")
    p = add(g, "request", cmd_approval_request, "open an approval; then stop and ask the user")
    p.add_argument("--gate", required=True, choices=GATES); p.add_argument("--project")
    p.add_argument("--summary", required=True); p.add_argument("--subject")
    p.add_argument("--max-cost", type=float); p.add_argument("--uses", type=int)
    p.add_argument("--over-budget", action="store_true")
    p = add(g, "decide", cmd_approval_decide, "record the user's decision")
    p.add_argument("approval"); m = p.add_mutually_exclusive_group(required=True)
    m.add_argument("--approve", action="store_true"); m.add_argument("--reject", action="store_true")
    p.add_argument("--user-quote", required=True)
    p.add_argument("--chosen", help="the document the owner picked, when the approval offered several variants")
    p = add(g, "list", cmd_approval_list, "list approvals")
    p.add_argument("--project"); p.add_argument("--pending", action="store_true")

    g = group("gate", "paid-tool gate (used by the hook)")
    p = add(g, "check", cmd_gate_check, "consume one authorised paid call"); p.add_argument("tool")
    add(g, "log", cmd_gate_log, "recent gate decisions")

    g = group("ins", "inspiration library")
    p = add(g, "add", cmd_ins_add, "add a reference (duplicates are detected, not created)")
    p.add_argument("--source", required=True, choices=["instagram", "pinterest", "youtube", "web", "upload", "idea", "sheet"])
    p.add_argument("--title", required=True); p.add_argument("--url", action="append")
    p.add_argument("--creator"); p.add_argument("--notes")
    p = add(g, "access", cmd_ins_access, "record whether the source could be opened")
    p.add_argument("inspiration"); p.add_argument("--detail")
    p.add_argument("--status", required=True,
                   choices=["unreviewed", "blocked", "metadata_only", "reviewed_images", "reviewed_video"])
    p = add(g, "analysis", cmd_ins_analysis, "store analysis (refused unless the source was inspected)")
    p.add_argument("inspiration"); p.add_argument("--json", required=True); p.add_argument("--basis", required=True)
    p.add_argument("--status", default="complete", choices=["partial", "complete"])
    p = add(g, "show", cmd_ins_show, "show one"); p.add_argument("inspiration")
    p = add(g, "list", cmd_ins_list, "list / search"); p.add_argument("--search")
    p = add(g, "sync-agent00", cmd_ins_sync, "mirror Agent 00's catalog into the studio database (one-way, repeatable)")
    p.add_argument("--db", help="path to Agent 00's catalog (default data/inspirations.sqlite3)")

    g = group("refshot", "reference shots in the 15-column manifest format")
    p = add(g, "import", cmd_refshot_import, "import a manifest-format CSV as PENDING_REVIEW (repeatable)")
    p.add_argument("file"); p.add_argument("--inspiration"); p.add_argument("--asset"); p.add_argument("--project")
    p = add(g, "decide", cmd_refshot_decide, "record the user's decision on pending shots")
    p.add_argument("shots", nargs="+"); m = p.add_mutually_exclusive_group(required=True)
    m.add_argument("--approve", action="store_true"); m.add_argument("--reject", action="store_true")
    p.add_argument("--user-quote", required=True)
    p = add(g, "list", cmd_refshot_list, "list reference shots")
    p.add_argument("--status", choices=["PENDING_REVIEW", "APPROVED", "REJECTED"]); p.add_argument("--inspiration")
    p = add(g, "export", cmd_refshot_export, "write approved shots as a 15-column CSV (never overwrites)")
    p.add_argument("file"); p.add_argument("--status", default="APPROVED", choices=["PENDING_REVIEW", "APPROVED", "REJECTED"])

    g = group("genre", "genre knowledge")
    p = add(g, "add", cmd_genre_add, "add a genre or tag inspirations with it")
    p.add_argument("--name", required=True); p.add_argument("--description"); p.add_argument("--knowledge")
    p.add_argument("--origin", default="discovered", choices=["user", "discovered", "research"])
    p.add_argument("--inspiration", action="append")
    add(g, "list", cmd_genre_list, "list genres")

    g = group("manifest", "Master Shot Manifest")
    p = add(g, "propose", cmd_manifest_propose, "propose a new technique (never writes the manifest)")
    p.add_argument("--name", required=True); p.add_argument("--category")
    p.add_argument("--spec", required=True); p.add_argument("--source")
    p = add(g, "decide", cmd_manifest_decide, "record the user's decision on a proposal")
    p.add_argument("proposal"); m = p.add_mutually_exclusive_group(required=True)
    m.add_argument("--approve", action="store_true"); m.add_argument("--reject", action="store_true")
    p.add_argument("--user-quote", required=True)
    p = add(g, "list", cmd_manifest_list, "list entries"); p.add_argument("--proposals", action="store_true")
    p = add(g, "link", cmd_manifest_link, "link a technique to a reference shot that shows it")
    p.add_argument("technique"); p.add_argument("shot"); p.add_argument("--note")
    p = add(g, "show", cmd_manifest_show, "a technique with its linked reference shots"); p.add_argument("technique")

    g = group("doc", "versioned concepts, storyboards, shot lists, specs")
    p = add(g, "add", cmd_doc_add, "add a new version (never edits an old one)")
    p.add_argument("--project", required=True); p.add_argument("--kind", required=True)
    p.add_argument("--variant", default="main"); p.add_argument("--content", required=True)
    p.add_argument("--author")
    p = add(g, "show", cmd_doc_show, "show a document"); p.add_argument("document")
    p = add(g, "list", cmd_doc_list, "list a project's documents"); p.add_argument("project")

    g = group("prompt", "prompt history")
    p = add(g, "add", cmd_prompt_add, "record a prompt")
    p.add_argument("--project", required=True); p.add_argument("--shot"); p.add_argument("--provider", required=True)
    p.add_argument("--model"); p.add_argument("--kind", required=True, choices=["image", "video", "audio"])
    p.add_argument("--prompt", required=True); p.add_argument("--params"); p.add_argument("--parent")

    g = group("gen", "generation history")
    p = add(g, "record", cmd_gen_record, "record a generation result and its cost")
    p.add_argument("--project", required=True); p.add_argument("--prompt"); p.add_argument("--approval")
    p.add_argument("--provider", required=True); p.add_argument("--tool")
    p.add_argument("--status", required=True, choices=["submitted", "succeeded", "failed", "rejected", "accepted"])
    p.add_argument("--task-id"); p.add_argument("--cost", type=float); p.add_argument("--credits", type=float)
    p.add_argument("--asset"); p.add_argument("--notes")

    g = group("asset", "asset registry")
    p = add(g, "add", cmd_asset_add, "register a file (deduplicated by content hash)")
    p.add_argument("--path", required=True); p.add_argument("--project"); p.add_argument("--meta")
    p.add_argument("--kind", required=True,
                   choices=["footage", "photo", "reference", "generated", "audio", "lut", "export", "other"])

    g = group("run", "agent execution history")
    p = add(g, "start", cmd_run_start, "log the start of an agent task")
    p.add_argument("--agent", required=True); p.add_argument("--project"); p.add_argument("--model")
    p.add_argument("--stage"); p.add_argument("--summary")
    p = add(g, "finish", cmd_run_finish, "log the result")
    p.add_argument("run"); p.add_argument("--summary"); p.add_argument("--output"); p.add_argument("--error")
    p.add_argument("--tokens-in", type=int); p.add_argument("--tokens-out", type=int)

    g = group("pub", "publishing records")
    p = add(g, "draft", cmd_pub_draft, "create a draft publication record")
    p.add_argument("--project", required=True); p.add_argument("--platform", required=True)
    p.add_argument("--caption"); p.add_argument("--asset")
    p = add(g, "set", cmd_pub_set, "mark scheduled or published (needs 'publish' approval)")
    p.add_argument("publication"); p.add_argument("--status", required=True, choices=["scheduled", "published"])
    p.add_argument("--at"); p.add_argument("--url")
    p = add(g, "metrics", cmd_metrics_add, "store performance numbers")
    p.add_argument("publication"); p.add_argument("--json", required=True); p.add_argument("--source", required=True)
    return ap


def main(argv=None) -> int:
    args = build_parser().parse_args(argv)
    try:
        args.fn(args)
        return 0
    except StudioError as e:
        print(json.dumps({"ok": False, "error": str(e), **e.extra}, indent=2), file=sys.stderr)
        return e.code
    except (sqlite3.Error, json.JSONDecodeError, OSError, csv.Error) as e:
        print(json.dumps({"ok": False, "error": f"{type(e).__name__}: {e}"}, indent=2), file=sys.stderr)
        return EXIT_ERROR


if __name__ == "__main__":
    sys.exit(main())
