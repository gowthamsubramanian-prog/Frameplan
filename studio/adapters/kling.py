#!/usr/bin/env python3
"""Kling adapter — DRY RUN ONLY.

Turns a validated generation spec into the exact Kling connector calls that WOULD be made,
checked against the capability snapshot in kling_capabilities.json. It never contacts Kling
and cannot spend credits: the connector's tools can only be called by Claude in a session,
and those calls are gated by .claude/hooks/paid_gate.py.

    python3 studio/adapters/kling.py plan spec.json
    python3 studio/adapters/kling.py capabilities
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
import contracts  # noqa: E402

CAPS = HERE / "kling_capabilities.json"


def capabilities() -> dict:
    return json.loads(CAPS.read_text())


def _durations(model: dict) -> list[int]:
    d = model["durations"]
    if isinstance(d, str):
        lo, hi = d.split("-")
        return list(range(int(lo), int(hi) + 1))
    return d


def plan(spec: dict) -> dict:
    errors = contracts.validate("generation_spec", spec)
    if spec.get("provider") != "kling":
        errors.append(f"provider is '{spec.get('provider')}', not 'kling'")
    caps = capabilities()
    calls, warnings = [], []
    for s in spec.get("shots", []) if not errors else []:
        w = f"shot {s['id']}"
        tool = caps["tools"].get(s["tool"])
        if not tool:
            errors.append(f"{w}: unknown Kling tool '{s['tool']}'")
            continue
        if not tool["verified"]:
            errors.append(f"{w}: capabilities for '{s['tool']}' have not been read from the connector. "
                          "Call the free `who_am_i` tool for it and update kling_capabilities.json first.")
            continue
        name = s.get("model") or tool["default_model"]
        model = tool["models"].get(name)
        if not model:
            errors.append(f"{w}: model '{name}' is not available for {s['tool']}: {sorted(tool['models'])}")
            continue
        if int(s["duration_s"]) != s["duration_s"] or int(s["duration_s"]) not in _durations(model):
            errors.append(f"{w}: {name} does not support {s['duration_s']}s (allowed: {model['durations']})")
        res = s.get("resolution") or model["resolutions"][0]
        if res not in model["resolutions"]:
            errors.append(f"{w}: {name} on this account supports {model['resolutions']}, not {res}")
        aspect = s.get("aspect_ratio")
        if aspect and model["aspect_ratios"] is None:
            errors.append(f"{w}: {name} takes its aspect ratio from the first image; remove aspect_ratio")
        elif aspect and aspect not in model["aspect_ratios"]:
            errors.append(f"{w}: {name} does not support aspect ratio {aspect} ({model['aspect_ratios']})")
        inputs = s.get("inputs") or {}
        for k in inputs:
            if k not in model["inputs"]:
                errors.append(f"{w}: {name} has no input '{k}' (has: {model['inputs']})")
        for k in model["required_inputs"]:
            if k not in inputs:
                errors.append(f"{w}: {name} requires input '{k}'")
        if not inputs:
            errors.append(f"{w}: image_to_video needs at least one input image")
        if model.get("notes"):
            warnings.append(f"{w}: {model['notes']}")
        arguments = {"prompt": s["prompt"], "duration": str(int(s["duration_s"])), "resolution": res,
                     "imageCount": "1"}
        if aspect:
            arguments["aspect_ratio"] = aspect
        calls.append({
            "shot": s["id"], "mcp_tool": tool["mcp_tool"], "model": name, "arguments": arguments,
            "inputs": {k: f"<upload {v} with the free file_upload tool, then pass its URL>" for k, v in inputs.items()},
            "max_attempts": s.get("max_attempts", 1),
        })
    total_calls = sum(c["max_attempts"] for c in calls)
    return {
        "ok": not errors, "dry_run": True, "submitted": False,
        "errors": errors, "warnings": warnings,
        "calls": [] if errors else calls,
        "paid_calls_if_all_attempts_used": 0 if errors else total_calls,
        "cost": {"estimate_usd": None,
                 "note": "Kling prices are not exposed by the connector. Ask the user for the credit cost or "
                         "read it from their Kling account before requesting approval."},
        "account": caps["account"],
        "capabilities_source": caps["_source"],
        "next": "Request a paid_generation approval for exactly the number of calls above, with a cost cap the "
                "user states. Only then may Claude call the Kling tools; the hook counts each call.",
    }


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("plan"); p.add_argument("file")
    sub.add_parser("capabilities")
    a = ap.parse_args(argv)
    if a.cmd == "capabilities":
        print(json.dumps(capabilities(), indent=2))
        return 0
    try:
        spec = json.loads(Path(a.file).read_text())
    except (OSError, json.JSONDecodeError) as ex:
        print(json.dumps({"ok": False, "dry_run": True, "errors": [f"{type(ex).__name__}: {ex}"]}, indent=2))
        return 1
    result = plan(spec)
    print(json.dumps(result, indent=2, ensure_ascii=False))
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
