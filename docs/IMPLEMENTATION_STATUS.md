# Implementation status

Last updated: 13 November 2026. Update this file whenever a component changes state.

Legend: **Working** = implemented and covered by a passing test. **Draft** = instructions only,
not exercised against real tools. **Blocked** = waiting on the owner. **Planned** = approved, not started.

## Built

| Component | State | Notes |
|---|---|---|
| Studio database (`studio/schema.sql`, 21 tables) | Working | All ten libraries from the brief are present |
| `studio/studio.py` (projects, approvals, inspirations, genres, manifest, documents, shots, prompts, generations, assets, runs, publishing, budget, snapshot) | Working | Tested |
| Workflow routing A–E and stage gating | Working | `route` is a keyword heuristic; the orchestrator may override |
| Approval checkpoints (concept, style, paid generation, export, publish, manifest, asset change) | Working | Style is refused before concept approval |
| Paid-generation hook (`.claude/hooks/paid_gate.py`) | Working when invoked directly | Tested by piping hook payloads to the script. **Not yet observed firing inside a live Claude Code session**; confirm on the next session by attempting a Kling call without approval |
| Budget limits (USD 10 per project, USD 100 per month) | Working | Based on the cost cap entered at approval; real Kling prices are not known |
| Resume from the database | Working | `project show` / `project resume` |
| Duplicate detection (links, titles, asset content, manifest names) | Working | |
| Reference-video shot breakdown (`studio/video_probe.py`) | Working on a synthetic clip | Metadata, hard cuts, start/middle/end frames, contact sheet, shot list in the owner's manifest columns. **Not yet run on real footage.** Detects hard cuts only |
| Agent contracts (`studio/contracts.py`) | Working | `generation_spec` and `qa_report` templates and validators |
| Kling adapter (`studio/adapters/kling.py`) | **Dry run only** | Validates a spec against a capability snapshot and prints the calls that would be made. Sends nothing. Only `image_to_video` capabilities have been read from the connector |
| `generation-director` subagent | Draft | Definition written and structurally tested. **Never run as an agent** |
| `qa-reviewer` subagent | Draft | Definition written and structurally tested. **Never run as an agent** |
| Master Studio Orchestrator skill (`.claude/skills/studio/`) | Draft | Written; not yet run end to end on a real project |
| `ig-*` skill pack (13 skills, 6 scripts) | Working (scripts) | Merged from `claude/instagram-agent-skill-setup-cqq7jk`; state moved to `data/instagram/` |
| Editing skills ×5, portrait skills ×2 | Draft | Byte-for-byte copies of the owner's account skills (v0.4). Each declares itself an instruction draft with no editor test |

## Recovered, archived, not installed

Unaltered in `archive/recovery-pack-2026-11-13/`. See `docs/MIGRATION_REPORT.md`; migration
waits on the owner's decisions listed there.

| Component | Recovered as |
|---|---|
| Motion Director | Complete skill file |
| Agent 00 (Inspiration Intelligence) | Subagent, skill, catalog tool, analysis schema, sample import |
| Cinematic Reel Storyboard | Complete skill file (v2.0) |
| Shot manifest | Empty 15-column template only |
| Editing drafts v0.1/v0.2 | Older than the v0.4 skills in the repository; kept for reference only |

## Still missing

| Component | What is needed |
|---|---|
| Creative Director | The original file, or approval to author one |
| Populated Master Shot Manifest | The real file if one exists; otherwise it starts empty |
| `frameplan-reference-analyser` | The skill file, to judge its relationship to Agent 00 |
| Frameplan app | Source location, so project IDs can link (`projects.external_ref`) |

## Planned (approved scope, in order)

Specialists are developed and tested one at a time; the order and test samples are in
`docs/MIGRATION_REPORT.md` section 6.

1. Agent 00: install, test, one-way mirror into the studio database; import the 16 rows from the
   "Shoot Planner & Inspiration" sheet.
2. Shot manifest: adopt the template's columns; CSV import and export.
3. Storyboard: install; local sketch, PDF and zip steps.
4. Motion Director: install; map its gates to studio approvals.
5. Creative Director, then `shot-planner`.
6. First live runs of `generation-director` and `qa-reviewer`.
7. Remaining adapters: Higgsfield, OpenAI, Sheets, Resolve — each labelled real or mock.
8. Master orchestrator end to end; the twelve validation scenarios on real components.
9. Remaining handover documents: ARCHITECTURE, AGENT_REGISTRY, WORKFLOWS, INTEGRATIONS,
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
