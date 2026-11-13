#!/usr/bin/env python3
"""Agent communication contracts: the JSON shapes specialists hand to each other.

    python3 studio/contracts.py validate generation_spec spec.json
    python3 studio/contracts.py validate qa_report report.json
    python3 studio/contracts.py template generation_spec

Validation checks structure and honesty rules (evidence present, no cost invented).
It cannot check that the content is good.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

CERTAINTY = ("observed", "inferred", "suggested", "unverified")

TEMPLATES = {
    "generation_spec": {
        "project_id": "PRJ-0001",
        "concept_doc": "DOC-0001",
        "provider": "kling",
        "identity": {
            "reference_assets": ["AST-0001"],
            "invariants": ["face and facial features", "skin tone", "body type", "hair", "wardrobe as shot"],
        },
        "shots": [{
            "id": "G01",
            "story_role": "hook | reveal | hero | breath | ending | transition",
            "tool": "image_to_video",
            "model": "kling-video-v3_0_turbo",
            "duration_s": 5,
            "resolution": "720p",
            "aspect_ratio": None,
            "inputs": {"first_image": "AST-0002"},
            "prompt": "Camera move, subject action, environment, light. One clear action.",
            "unwanted": ["face change", "extra fingers", "warped fabric", "text or watermark"],
            "acceptance": ["identity matches the reference", "hands correct", "usable first and last frame"],
            "max_attempts": 2,
        }],
        "cost": {"estimate_usd": None, "source": "not quoted", "calls_requested": 2},
    },
    "qa_report": {
        "project_id": "PRJ-0001",
        "subject": "GNR-0001 or AST-0003",
        "inspected": [{"file": "media/work/…/shot_01_actual_frame.jpg", "how": "viewed frame"}],
        "reference_assets": ["AST-0001"],
        "checks": [{
            "criterion": "identity matches the reference",
            "result": "pass | fail | not_checked",
            "certainty": "observed",
            "evidence": "what was seen, in which file or at which timecode",
        }],
        "verdict": "accept | regenerate | refine | reject",
        "fixes": ["specific prompt or edit change, if not accepted"],
        "not_inspected": ["anything that could not be opened or checked, and why"],
    },
}


def _need(obj, key, typ, errors, where):
    if key not in obj or obj[key] in ("", None):
        errors.append(f"{where}: '{key}' is required")
        return None
    if not isinstance(obj[key], typ):
        errors.append(f"{where}: '{key}' has the wrong type")
        return None
    return obj[key]


def validate_generation_spec(d: dict) -> list[str]:
    e: list[str] = []
    _need(d, "project_id", str, e, "spec")
    _need(d, "provider", str, e, "spec")
    ident = _need(d, "identity", dict, e, "spec")
    if ident is not None:
        if "reference_assets" not in ident or not isinstance(ident["reference_assets"], list):
            e.append("identity: 'reference_assets' must be a list (empty only when no real person appears)")
        if not ident.get("invariants") and ident.get("reference_assets"):
            e.append("identity: 'invariants' is required when a reference person is used")
    shots = _need(d, "shots", list, e, "spec") or []
    seen = set()
    for i, s in enumerate(shots, 1):
        w = f"shot {i}"
        if not isinstance(s, dict):
            e.append(f"{w}: must be an object")
            continue
        sid = _need(s, "id", str, e, w)
        if sid in seen:
            e.append(f"{w}: duplicate id '{sid}'")
        seen.add(sid)
        for k in ("story_role", "tool", "prompt"):
            _need(s, k, str, e, w)
        if not isinstance(s.get("duration_s"), (int, float)) and s.get("tool", "").endswith("video"):
            e.append(f"{w}: 'duration_s' is required for video")
        if not s.get("acceptance"):
            e.append(f"{w}: 'acceptance' criteria are required so the result can be reviewed")
        if not isinstance(s.get("max_attempts", 1), int) or s.get("max_attempts", 1) < 1:
            e.append(f"{w}: 'max_attempts' must be a positive integer")
    cost = _need(d, "cost", dict, e, "spec")
    if cost is not None:
        if cost.get("estimate_usd") is not None and cost.get("source") in (None, "", "not quoted"):
            e.append("cost: an estimate needs a 'source' (a quote or a price the user gave); never invent one")
        calls = cost.get("calls_requested")
        need = sum(s.get("max_attempts", 1) for s in shots if isinstance(s, dict))
        if not isinstance(calls, int) or calls < 1:
            e.append("cost: 'calls_requested' must be a positive integer")
        elif calls > need:
            e.append(f"cost: 'calls_requested' ({calls}) exceeds the sum of max_attempts ({need})")
    return e


def validate_qa_report(d: dict) -> list[str]:
    e: list[str] = []
    _need(d, "project_id", str, e, "report")
    _need(d, "subject", str, e, "report")
    inspected = d.get("inspected")
    if not isinstance(inspected, list):
        e.append("report: 'inspected' must be a list of the files actually opened")
        inspected = []
    checks = _need(d, "checks", list, e, "report") or []
    for i, c in enumerate(checks, 1):
        w = f"check {i}"
        if not isinstance(c, dict):
            e.append(f"{w}: must be an object")
            continue
        _need(c, "criterion", str, e, w)
        if c.get("result") not in ("pass", "fail", "not_checked"):
            e.append(f"{w}: 'result' must be pass, fail or not_checked")
        if c.get("result") in ("pass", "fail"):
            if c.get("certainty") not in CERTAINTY:
                e.append(f"{w}: 'certainty' must be one of {CERTAINTY}")
            if not (c.get("evidence") or "").strip():
                e.append(f"{w}: a pass or fail needs 'evidence'")
            if not inspected:
                e.append(f"{w}: cannot pass or fail when nothing was inspected")
    verdict = d.get("verdict")
    if verdict not in ("accept", "regenerate", "refine", "reject"):
        e.append("report: 'verdict' must be accept, regenerate, refine or reject")
    if verdict == "accept":
        if not inspected:
            e.append("report: cannot accept without inspecting the output")
        if any(isinstance(c, dict) and c.get("result") != "pass" for c in checks):
            e.append("report: cannot accept while a check is failed or not checked")
    if verdict in ("regenerate", "refine") and not d.get("fixes"):
        e.append("report: 'fixes' are required when asking for another attempt")
    return e


VALIDATORS = {"generation_spec": validate_generation_spec, "qa_report": validate_qa_report}


def validate(kind: str, data) -> list[str]:
    if not isinstance(data, dict):
        return ["document must be a JSON object"]
    return VALIDATORS[kind](data)


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    v = sub.add_parser("validate"); v.add_argument("kind", choices=list(VALIDATORS)); v.add_argument("file")
    t = sub.add_parser("template"); t.add_argument("kind", choices=list(TEMPLATES))
    a = ap.parse_args(argv)
    if a.cmd == "template":
        print(json.dumps(TEMPLATES[a.kind], indent=2))
        return 0
    try:
        data = json.loads(Path(a.file).read_text())
    except (OSError, json.JSONDecodeError) as ex:
        print(json.dumps({"ok": False, "errors": [f"{type(ex).__name__}: {ex}"]}, indent=2))
        return 1
    errors = validate(a.kind, data)
    print(json.dumps({"ok": not errors, "kind": a.kind, "errors": errors}, indent=2))
    return 0 if not errors else 1


if __name__ == "__main__":
    sys.exit(main())
