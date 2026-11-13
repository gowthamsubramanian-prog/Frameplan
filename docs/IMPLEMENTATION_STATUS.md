# Implementation status

Last updated: 13 November 2026. Update this file whenever a component changes state.

Legend: **Working** = implemented and covered by a passing test. **Draft** = instructions only,
not exercised against real tools. **Blocked** = waiting on the owner. **Planned** = approved, not started.

## Built

| Component | State | Notes |
|---|---|---|
| Studio database (`studio/schema.sql`, 21 tables) | Working | All ten libraries from the brief are present |
| `studio/studio.py` (projects, approvals, inspirations, genres, manifest, documents, shots, prompts, generations, assets, runs, publishing, budget, snapshot) | Working | 38 tests |
| Workflow routing A–E and stage gating | Working | `route` is a keyword heuristic; the orchestrator may override |
| Approval checkpoints (concept, style, paid generation, export, publish, manifest, asset change) | Working | Style is refused before concept approval |
| Paid-generation hook (`.claude/hooks/paid_gate.py`) | Working when invoked directly | Tested by piping hook payloads to the script. **Not yet observed firing inside a live Claude Code session**; confirm on the next session by attempting a Kling call without approval |
| Budget limits (USD 10 per project, USD 100 per month) | Working | Based on the cost cap entered at approval; real Kling prices are not yet known |
| Resume from the database | Working | `project show` / `project resume` |
| Duplicate detection (links, titles, asset content, manifest names) | Working | |
| Master Studio Orchestrator skill (`.claude/skills/studio/`) | Draft | Written; not yet run end to end on a real project |
| `ig-*` skill pack (13 skills, 6 scripts) | Working (scripts) | Merged from `claude/instagram-agent-skill-setup-cqq7jk`; state moved to `data/instagram/` |
| Editing skills ×5, portrait skills ×2 | Draft | Byte-for-byte copies of the owner's account skills. Each declares itself an instruction draft with no editor test |

## Blocked on the owner

| Component | What is needed |
|---|---|
| Motion Director | The skill folder or `SKILL.md`, with its style-preview assets |
| Agent 00 (Inspiration Intelligence) | Its specification, or the `frameplan-reference-analyser` skill if that is the same thing |
| Creative Director | Its instructions |
| Master Shot Manifest | The existing file, any format. The tables exist and are empty |
| Frameplan app | Source, or confirmation it lives elsewhere, so project IDs can link (`projects.external_ref`) |

None of these was found in the repository, its branches, the account skills, Google Drive or
recent sessions. They must not be rebuilt without the owner's approval.

## Planned (approved scope, in order)

1. `reference-analyst` subagent, ingestion script, import of the 16 rows from the
   "Shoot Planner & Inspiration" sheet (blocked in part on Agent 00).
2. `creative-director` and `shot-planner` subagents; Master Shot Manifest import (blocked in part).
3. Reference-video replication with ffmpeg (`video_probe.py`).
4. `generation-director` subagent, Kling adapter in dry-run, `qa-reviewer` subagent.
5. Motion graphics workflow skill (blocked on Motion Director).
6. Integration adapters: Kling, Higgsfield, OpenAI, Sheets, Resolve — each labelled real or mock.
7. The twelve validation scenarios, run against real components.
8. Remaining handover documents: ARCHITECTURE, AGENT_REGISTRY, WORKFLOWS, INTEGRATIONS,
   DATABASE_SCHEMA, MODEL_AND_COST_STRATEGY, NEXT_STEPS.

## Known limitations

- The hook only sees MCP tool calls. Paid APIs called from scripts (for example MuAPI) are
  governed by instruction, not enforcement.
- `approval decide` requires the owner's words but cannot prove the owner typed them. It is an
  audit trail, not a lock.
- The five editing skills share an "operating contract" block; the copy in
  `cinematic-reel-editing` differs from the other four although its header says they must match.
  Left as found.
- Kling has 0 credits and its per-clip prices are not exposed by the connector, so no cost
  figures have been verified.
- No Instagram, Pinterest or OpenAI connector is available. Instagram publishing is manual.
