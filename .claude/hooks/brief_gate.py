#!/usr/bin/env python3
"""PreToolUse hook: a studio specialist may not be started without the owner's input in its brief.

- A studio subagent (Agent/Task tool) must be given at least one concrete reference to the
  owner's material: a project, reference, asset or document ID, a file path, or a link.
- A subject-driven skill (Skill tool) must be given arguments; it must not fall back on an example.

Exit 2 blocks the call and shows the message to the coordinator. Anything this hook does not
recognise is allowed. It cannot tell whether a subject truly came from the owner; that remains
the coordinator's responsibility (CLAUDE.md rule 10).
"""
import json
import re
import sys

STUDIO_AGENTS = {"inspiration-intelligence", "generation-director", "qa-reviewer", "shot-planner"}
SUBJECT_SKILLS = {"motion-director": "the owner's title or subject",
                  "cinematic-reel-storyboard": "the owner's reference video (path)"}
HAS_OWNER_INPUT = re.compile(
    r"\b(PRJ|REF|INS|AST|DOC|GNR|RSH|SHT)-\d+\b|https?://\S+|"
    r"[\w./~-]+\.(jpe?g|png|webp|heic|heif|tiff?|gif|arw|dng|mp4|mov|m4v|mkv|avi|webm|csv|json|pdf)\b", re.I)


def main() -> int:
    try:
        payload = json.load(sys.stdin)
        tool, args = payload.get("tool_name", ""), payload.get("tool_input", {}) or {}
    except Exception:  # noqa: BLE001
        return 0
    if tool in ("Agent", "Task"):
        agent = args.get("subagent_type", "")
        if agent in STUDIO_AGENTS and not HAS_OWNER_INPUT.search(args.get("prompt", "") or ""):
            print(f"BLOCKED by the studio brief gate: the brief for {agent} names no project, reference, asset, "
                  "file or link. Every specialist must receive the owner's attachments and context. Add the IDs "
                  "or file paths; if there is no input to give, ask the owner. Do not invent a subject.",
                  file=sys.stderr)
            return 2
    elif tool == "Skill":
        skill = (args.get("skill", "") or "").split(":")[-1]
        if skill in SUBJECT_SKILLS and not (args.get("args", "") or "").strip():
            print(f"BLOCKED by the studio brief gate: {skill} was started without {SUBJECT_SKILLS[skill]}. "
                  "Pass what the owner supplied. If they supplied nothing, ask them. Never use an example or "
                  "a subject of your own choosing.", file=sys.stderr)
            return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
