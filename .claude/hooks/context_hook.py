#!/usr/bin/env python3
"""UserPromptSubmit hook: put the studio's current project and input rules in front of the
coordinator on every owner message, whatever the entry point (new request, resumed project,
named specialist, "continue"). Output on stdout is added to the session context.

Never blocks and never fails the prompt: on any error it prints the bare rules and exits 0.
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "studio"))

FALLBACK = ("[Studio context unavailable: {err}. Run `python3 studio/studio.py init`.]\n"
            "Input rules: the subject is the owner's words, attachments and current project. Never substitute "
            "a sample or built-in topic, never assume a domain or platform, and ask when input is missing.")


def main() -> int:
    prompt = ""
    try:
        prompt = json.load(sys.stdin).get("prompt", "") or ""
    except Exception:  # noqa: BLE001
        pass
    try:
        import studio
        print(studio.studio_context(studio.connect(), prompt))
    except Exception as e:  # noqa: BLE001
        print(FALLBACK.format(err=f"{type(e).__name__}: {e}"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
