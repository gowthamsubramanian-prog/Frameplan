"""Tests for the recovery-pack migration: verbatim installs, schema upgrade, the one-way
Agent 00 mirror, and the 15-column reference-shot manifest with its technique links.

Run from the repository root:  python3 -m unittest discover -s tests -v
"""
import csv
import hashlib
import json
import os
import shutil
import sqlite3
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
STUDIO = ROOT / "studio" / "studio.py"
PACK = ROOT / "archive" / "recovery-pack-2026-11-13"
ORIG = PACK / "01_RESTORED_ORIGINALS"
A00 = PACK / "02_AGENT_00_PACKAGE" / "EXTRACTED_FOR_REVIEW" / "cinematic-content-studio"
TEMPLATE = ORIG / "SHOT_MANIFEST_TEMPLATE.csv"

INSTALLED = {
    ".claude/skills/motion-director/SKILL.md": ORIG / "SKILL(1).md",
    ".claude/skills/cinematic-reel-storyboard/SKILL.md": ORIG / "Cinematic_Storyboard_SKILL_v2.md",
    ".claude/agents/inspiration-intelligence.md": A00 / ".claude/agents/inspiration-intelligence.md",
    ".claude/skills/inspiration-intelligence/SKILL.md": A00 / ".claude/skills/inspiration-intelligence/SKILL.md",
    "tools/inspiration.py": A00 / "tools/inspiration.py",
    "references/analysis-schema.json": A00 / "references/analysis-schema.json",
    "references/import-example.csv": A00 / "references/import-example.csv",
}


def sha(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest()


class TestVerbatimInstall(unittest.TestCase):
    def test_installed_files_are_byte_identical_to_the_recovered_originals(self):
        for rel, src in INSTALLED.items():
            self.assertEqual(sha(ROOT / rel), sha(src), rel)

    def test_archive_still_matches_the_packs_own_checksums(self):
        lines = [l.split() for l in (PACK / "03_HANDOFF" / "SOURCE_CHECKSUMS.txt").read_text().splitlines()
                 if l and not l.startswith("#")]
        self.assertEqual(len(lines), 8)
        for digest, name in lines:
            self.assertEqual(sha(ORIG / name), digest, name)

    def test_agent00_definition_is_unchanged_and_has_no_model_pinned(self):
        text = (ROOT / ".claude/agents/inspiration-intelligence.md").read_text()
        head = text.split("---\n")[1]
        self.assertIn("name: inspiration-intelligence", head)
        self.assertNotIn("model:", head)

    def test_recovered_skills_have_their_original_names(self):
        for folder in ("motion-director", "cinematic-reel-storyboard", "inspiration-intelligence"):
            head = (ROOT / ".claude/skills" / folder / "SKILL.md").read_text().split("---\n")[1]
            self.assertIn(f"name: {folder}", head)

    def test_motion_director_gate_order_is_intact(self):
        text = (ROOT / ".claude/skills/motion-director/SKILL.md").read_text()
        self.assertLess(text.index("IDEA APPROVAL gate"), text.index("STYLE APPROVAL gate"))
        self.assertIn("Never show, recommend, shortlist, or ask the user to select a visual style before idea approval", text)
        self.assertIn("three custom static preview images", text)

    def test_v04_editing_skills_were_not_replaced_by_the_older_drafts(self):
        for folder in ("rough-cut", "colour-grading", "effects-and-transitions", "reel-assembly", "cinematic-reel-editing"):
            self.assertIn("Draft v0.4", (ROOT / ".claude/skills" / folder / "SKILL.md").read_text(), folder)


class Base(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.dir = Path(self.tmp.name)
        self.env = {**os.environ, "STUDIO_DB": str(self.dir / "studio.db")}
        self.ok("init")
        # a private copy of Agent 00's tool so its catalog lands in the temp folder
        (self.dir / "a00" / "tools").mkdir(parents=True)
        shutil.copy(ROOT / "tools" / "inspiration.py", self.dir / "a00" / "tools" / "inspiration.py")
        self.a00_db = self.dir / "a00" / "data" / "inspirations.sqlite3"

    def tearDown(self):
        self.tmp.cleanup()

    def cli(self, *args):
        p = subprocess.run([sys.executable, str(STUDIO), *args], capture_output=True, text=True, env=self.env)
        text = p.stdout if p.returncode == 0 else p.stderr
        try:
            return p.returncode, json.loads(text)
        except json.JSONDecodeError:
            return p.returncode, {"raw": p.stdout + p.stderr}

    def ok(self, *args):
        code, data = self.cli(*args)
        self.assertEqual(code, 0, f"{args}: {data}")
        return data

    def a00(self, *args):
        p = subprocess.run([sys.executable, str(self.dir / "a00" / "tools" / "inspiration.py"), *args],
                           capture_output=True, text=True)
        self.assertEqual(p.returncode, 0, p.stderr)
        return p.stdout.strip()

    def analyse(self, ref, status, techniques=(), genre=(), shots=(), **extra):
        f = self.dir / f"{ref}.json"
        f.write_text(json.dumps({"reference_id": ref, "access_status": status, "genre": list(genre),
                                 "story_summary": extra.pop("summary", ""), "techniques": list(techniques),
                                 "shot_candidates": list(shots), **extra}))
        return self.a00("analyse", str(f))

    def sync(self):
        return self.ok("ins", "sync-agent00", "--db", str(self.a00_db))

    def a00_snapshot(self):
        con = sqlite3.connect(self.a00_db)
        rows = con.execute("SELECT * FROM refs ORDER BY id").fetchall()
        con.close()
        return rows


class TestSchemaUpgrade(Base):
    V1_INSPIRATIONS = """CREATE TABLE inspirations (id TEXT PRIMARY KEY,
        source_type TEXT NOT NULL CHECK (source_type IN ('instagram','pinterest','web','upload','idea','sheet')),
        title TEXT NOT NULL, title_norm TEXT NOT NULL, creator TEXT, notes TEXT,
        access_status TEXT NOT NULL DEFAULT 'not_attempted' CHECK (access_status IN ('not_attempted','accessible','inaccessible')),
        access_detail TEXT, analysis_status TEXT NOT NULL DEFAULT 'none', analysis_json TEXT, analysis_basis TEXT,
        source_meta_json TEXT, created_at TEXT NOT NULL)"""

    def make_v1(self):
        con = sqlite3.connect(self.env["STUDIO_DB"])
        con.execute("PRAGMA foreign_keys=OFF")
        con.execute("DROP TABLE inspirations")
        con.execute(self.V1_INSPIRATIONS)
        for i, st in enumerate(("not_attempted", "accessible", "inaccessible"), 1):
            con.execute("INSERT INTO inspirations(id,source_type,title,title_norm,creator,access_status,created_at) "
                        "VALUES(?,?,?,?,?,?,?)", (f"INS-000{i}", "instagram", f"Ref {i}", f"ref {i}", "@maker", st, "2026-11-13T00:00:00Z"))
        con.execute("INSERT INTO inspiration_links VALUES('INS-0001','https://www.instagram.com/p/AAA/','instagram.com/p/AAA')")
        con.execute("UPDATE meta SET value='1' WHERE key='schema_version'")
        con.commit(); con.close()

    def test_old_database_is_refused_until_upgraded(self):
        self.make_v1()
        code, data = self.cli("ins", "list")
        self.assertEqual(code, 1)
        self.assertIn("init", data["error"])

    def test_upgrade_keeps_every_row_and_maps_access_states(self):
        self.make_v1()
        r = self.ok("init")
        self.assertEqual(r["migrated"], {"from": "1", "to": "2", "inspirations_kept": 3})
        rows = {x["id"]: x["access_status"] for x in self.ok("ins", "list")}
        self.assertEqual(rows, {"INS-0001": "unreviewed", "INS-0002": "reviewed_images", "INS-0003": "blocked"})
        shown = self.ok("ins", "show", "INS-0001")
        self.assertEqual((shown["creator"], shown["links"]), ("@maker", ["https://www.instagram.com/p/AAA/"]))
        self.assertIsNone(self.ok("init")["migrated"])           # second run does nothing


class TestAgent00Mirror(Base):
    def test_mirror_preserves_ids_urls_creator_access_and_certainty(self):
        self.a00("add", "https://www.instagram.com/reel/ABC123/?igshid=xyz", "--creator", "@maker",
                 "--title", "Portal reveal", "--notes", "study the transition", "--collection", "Saved Reels")
        tech = [{"name": "slow push-in", "timecode": "00:02-00:05", "evidence": "subject grows across frames",
                 "certainty": "observed", "recreation": "slider"},
                {"name": "speed ramp", "certainty": "inferred"}]
        self.analyse("REF-000001", "reviewed_video", tech, genre=["Fantasy", "cinematic fashion"], summary="seen")
        r = self.sync()
        self.assertEqual(r["created"], [{"ref": "REF-000001", "inspiration": "INS-0001"}])
        s = self.ok("ins", "show", "INS-0001")
        self.assertEqual(s["links"], ["https://www.instagram.com/reel/ABC123/?igshid=xyz"])     # original, unmodified
        self.assertEqual((s["creator"], s["notes"], s["collection"]), ("@maker", "study the transition", "Saved Reels"))
        self.assertEqual((s["access_status"], s["analysis_status"], s["source_type"]), ("reviewed_video", "complete", "instagram"))
        self.assertEqual(s["agent00_refs"][0]["ref_id"], "REF-000001")
        stored = json.loads(s["analysis_json"])
        self.assertEqual([t["certainty"] for t in stored["techniques"]], ["observed", "inferred"])
        self.assertEqual(stored["techniques"][0]["timecode"], "00:02-00:05")
        self.assertEqual(sorted(s["genres"]), ["Fantasy", "cinematic fashion"])
        self.assertEqual(sorted(r["genres_added"]), ["Fantasy", "cinematic fashion"])

    def test_sync_is_idempotent(self):
        self.a00("import", str(ROOT / "references" / "import-example.csv"))
        first = self.sync()
        self.assertEqual(len(first["created"]), 2)
        again = self.sync()
        self.assertEqual((again["created"], again["updated"], again["unchanged"], again["analyses_added"]), ([], [], 2, 0))
        self.assertEqual(len(self.ok("ins", "list")), 2)
        self.a00("import", str(ROOT / "references" / "import-example.csv"))      # Agent 00 import is idempotent too
        self.assertEqual(self.sync()["mirrored_total"], 2)

    def test_sync_never_writes_to_agent00s_catalog(self):
        self.a00("add", "https://www.pinterest.com/pin/123456789/", "--title", "Editorial")
        before = self.a00_snapshot(), self.a00_db.stat().st_mtime_ns
        self.sync(); self.sync()
        self.assertEqual(before, (self.a00_snapshot(), self.a00_db.stat().st_mtime_ns))

    def test_analysis_history_is_kept_when_agent00_revises(self):
        self.a00("add", "https://www.instagram.com/reel/HIST1/")
        self.analyse("REF-000001", "metadata_only", summary="caption only")
        self.sync()
        self.assertEqual(self.ok("ins", "show", "INS-0001")["analysis_status"], "partial")
        self.analyse("REF-000001", "reviewed_video", [{"name": "orbit", "certainty": "observed"}], summary="full review")
        r = self.sync()
        self.assertEqual((r["updated"], r["analyses_added"]), (["REF-000001"], 1))
        s = self.ok("ins", "show", "INS-0001")
        self.assertEqual([h["access_status"] for h in s["analysis_history"]], ["metadata_only", "reviewed_video"])
        self.assertEqual((s["access_status"], s["analysis_status"]), ("reviewed_video", "complete"))
        self.assertEqual(json.loads(s["analysis_json"])["story_summary"], "full review")
        self.assertEqual(self.sync()["analyses_added"], 0)

    def test_same_post_under_two_links_becomes_one_record_with_both_ref_ids(self):
        self.a00("add", "https://www.instagram.com/thebianca.m/p/DcuzAuICCUV/?img_index=4", "--creator", "@thebianca.m")
        self.a00("add", "https://www.instagram.com/p/DcuzAuICCUV/")
        self.assertEqual(len(self.a00_snapshot()), 2)              # Agent 00's own rule lets both in
        r = self.sync()
        self.assertEqual(len(r["created"]), 1)
        self.assertEqual(r["duplicates"][0]["ref"], "REF-000002")
        self.assertEqual(len(self.ok("ins", "list")), 1)
        s = self.ok("ins", "show", "INS-0001")
        self.assertEqual([(x["ref_id"], x["is_duplicate"]) for x in s["agent00_refs"]],
                         [("REF-000001", 0), ("REF-000002", 1)])
        self.assertEqual(s["creator"], "@thebianca.m")             # the duplicate did not blank the credit
        self.assertEqual(len(self.sync()["duplicates"]), 0)        # reported once, not on every run

    def test_reference_already_in_the_studio_is_linked_not_duplicated(self):
        self.ok("ins", "add", "--source", "instagram", "--title", "From the sheet",
                "--url", "https://www.instagram.com/p/C9z9fZWO8qe/?img_index=7")
        self.a00("add", "https://www.instagram.com/p/C9z9fZWO8qe/")
        r = self.sync()
        self.assertEqual(r["linked_to_existing"], [{"ref": "REF-000001", "inspiration": "INS-0001"}])
        self.assertEqual(len(self.ok("ins", "list")), 1)

    def test_blocked_reference_is_mirrored_as_blocked_with_no_analysis_status(self):
        self.a00("add", "https://www.instagram.com/reel/PRIVATE1/")
        self.analyse("REF-000001", "blocked", notes="login wall; no media seen")
        r = self.sync()
        s = self.ok("ins", "show", "INS-0001")
        self.assertEqual((s["access_status"], s["analysis_status"]), ("blocked", "none"))
        self.assertEqual(r["warnings"], [])
        self.assertEqual(s["analysis_history"][0]["access_status"], "blocked")     # the failure itself is on record

    def test_observed_claims_on_a_blocked_reference_are_flagged(self):
        self.a00("add", "https://www.instagram.com/reel/PRIVATE2/")
        self.analyse("REF-000001", "blocked", [{"name": "whip pan", "certainty": "observed"}])
        w = self.sync()["warnings"]
        self.assertEqual(len(w), 1)
        self.assertIn("REF-000001", w[0]); self.assertIn("whip pan", w[0])
        self.assertEqual(self.ok("ins", "show", "INS-0001")["analysis_status"], "none")

    def test_missing_catalog_is_a_clear_error(self):
        code, data = self.cli("ins", "sync-agent00", "--db", str(self.dir / "nope.sqlite3"))
        self.assertEqual(code, 1)
        self.assertIn("not found", data["error"])


class TestReferenceShotManifest(Base):
    SHOT = {"label": "portal silhouette reveal", "shot_size": "WS", "body_crop": "full body", "camera_angle": "front",
            "camera_height": "eye", "composition": "centred portal", "model_movement": "step forward",
            "camera_movement": "locked", "confidence": "suggested"}

    def agent_export(self, n_refs=1):
        for i in range(1, n_refs + 1):
            self.a00("add", f"https://www.instagram.com/reel/SHOT{i}/", "--creator", "@maker")
            self.analyse(f"REF-{i:06d}", "reviewed_video", shots=[self.SHOT])
        self.sync()
        f = self.dir / f"proposals_{n_refs}.csv"
        self.a00("export-shots", str(f))
        return f

    def test_template_header_is_the_schema(self):
        self.ok("refshot", "import", str(TEMPLATE))                 # header only: valid, zero rows
        out = self.dir / "export.csv"
        self.ok("refshot", "export", str(out))
        self.assertEqual(out.read_text(), TEMPLATE.read_text().replace("\r\n", "\n"))

    def test_wrong_format_is_refused(self):
        bad = self.dir / "bad.csv"; bad.write_text("shot_id,start_time\nS01,00:00\n")
        code, data = self.cli("refshot", "import", str(bad))
        self.assertEqual(code, 1)
        self.assertIn("missing columns", data["error"])

    def test_agent00_proposals_import_pending_and_link_to_their_reference(self):
        r = self.ok("refshot", "import", str(self.agent_export()))
        self.assertEqual(r["added"], ["RSH-0001"])
        row = self.ok("refshot", "list")[0]
        self.assertEqual((row["approval_status"], row["ref_id"], row["inspiration_id"], row["candidate_label"]),
                         ("PENDING_REVIEW", "REF-000001", "INS-0001", "portal silhouette reveal"))
        self.assertEqual(self.ok("ins", "show", "INS-0001")["reference_shots"], ["RSH-0001"])

    def test_import_is_idempotent_even_when_agent00_renumbers_its_proposals(self):
        self.ok("refshot", "import", str(self.agent_export(1)))
        again = self.ok("refshot", "import", str(self.dir / "proposals_1.csv"))
        self.assertEqual((again["added"], again["already_present"]), ([], 1))
        self.a00("add", "https://www.instagram.com/reel/EARLIER/")
        self.analyse("REF-000002", "reviewed_video", shots=[dict(self.SHOT, label="hair flip in backlight")])
        self.sync()
        f2 = self.dir / "second.csv"; self.a00("export-shots", str(f2))
        r = self.ok("refshot", "import", str(f2))
        self.assertEqual((len(r["added"]), r["already_present"]), (1, 1))

    def test_only_approved_shots_reach_the_exported_manifest_and_are_then_frozen(self):
        self.ok("refshot", "import", str(self.agent_export()))
        e1 = self.dir / "e1.csv"; self.ok("refshot", "export", str(e1))
        self.assertEqual(len(list(csv.DictReader(e1.read_text().splitlines()))), 0)
        code, _ = self.cli("refshot", "decide", "RSH-0001", "--approve", "--user-quote", " ")
        self.assertEqual(code, 1)
        self.ok("refshot", "decide", "RSH-0001", "--approve", "--user-quote", "add this one")
        e2 = self.dir / "e2.csv"; self.ok("refshot", "export", str(e2))
        rows = list(csv.DictReader(e2.read_text().splitlines()))
        self.assertEqual((len(rows), rows[0]["shot_size"], rows[0]["camera_movement"]), (1, "WS", "locked"))
        self.assertEqual(list(rows[0].keys()), TEMPLATE.read_text().strip().split(","))
        code, _ = self.cli("refshot", "decide", "RSH-0001", "--reject", "--user-quote", "changed my mind")
        self.assertEqual(code, 1)
        code, _ = self.cli("refshot", "export", str(e2))             # never overwrites
        self.assertEqual(code, 1)

    def test_video_breakdown_csv_imports_against_an_asset(self):
        clip = self.dir / "clip.bin"; clip.write_bytes(b"stand-in for a video file")
        asset = self.ok("asset", "add", "--path", str(clip), "--kind", "reference")["asset"]
        f = self.dir / "clip_Shot_List.csv"
        with f.open("w", newline="") as fh:
            w = csv.writer(fh); w.writerow(TEMPLATE.read_text().strip().split(","))
            w.writerow(["S01", "00:00.000", "00:02.000"] + [""] * 9 + ["shot_01_actual_frame.jpg", "", ""])
            w.writerow(["S02", "00:02.000", "00:03.520"] + [""] * 9 + ["shot_02_actual_frame.jpg", "", ""])
        r = self.ok("refshot", "import", str(f), "--asset", asset)
        self.assertEqual(len(r["added"]), 2)
        self.assertEqual(self.ok("refshot", "import", str(f), "--asset", asset)["already_present"], 2)

    def test_technique_library_is_kept_and_links_back_to_reference_shots(self):
        self.ok("refshot", "import", str(self.agent_export()))
        spec = json.dumps({"camera": "locked", "model": "steps through a backlit frame"})
        p = self.ok("manifest", "propose", "--name", "Portal Silhouette Reveal", "--category", "reveal",
                    "--spec", spec, "--source", "RSH-0001")["proposal"]
        self.assertEqual(self.ok("manifest", "list"), [])             # still proposal-only until approved
        self.ok("manifest", "decide", p, "--approve", "--user-quote", "yes add it")
        t = self.ok("manifest", "show", "SHT-0001")
        self.assertEqual((t["name"], [s["id"] for s in t["reference_shots"]]), ("Portal Silhouette Reveal", ["RSH-0001"]))
        self.assertEqual(t["reference_shots"][0]["ref_id"], "REF-000001")
        self.assertFalse(self.ok("manifest", "link", "SHT-0001", "RSH-0001")["linked"])     # idempotent
        dup = self.ok("manifest", "propose", "--name", "portal silhouette reveal", "--spec", spec)
        self.assertEqual(dup["duplicate_of"], "SHT-0001")


if __name__ == "__main__":
    unittest.main()
