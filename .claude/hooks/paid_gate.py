#!/usr/bin/env python3
"""PreToolUse hook: block paid generation tools unless the user has approved them.

Reads the hook payload (JSON) on stdin. Exit 0 lets the normal permission flow
continue; exit 2 blocks the tool call and shows stderr to the model.
Fails closed: any error blocks the call.
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "studio"))


def main() -> int:
    try:
        payload = json.load(sys.stdin)
        tool = payload.get("tool_name", "")
        import studio
        pattern = studio.config()["paid_tools"]["pattern"]
        if not re.search(pattern, tool):
            return 0
        ok, detail = studio.paid_gate(tool)
    except Exception as e:  # noqa: BLE001 - fail closed on anything
        print(f"Paid-generation gate could not verify approval ({type(e).__name__}: {e}). "
              "Blocked. Run `python3 studio/studio.py init` and request approval.", file=sys.stderr)
        return 2
    if ok:
        return 0
    print(f"BLOCKED by the studio approval gate: {tool} costs money. {detail} "
          "Do not retry or use another paid tool until the user has approved.", file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main())
