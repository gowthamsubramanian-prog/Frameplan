# Implementation status

Last updated: 13 November 2026. Update this file whenever a component changes state.

Legend: **Working** = implemented and covered by a passing test. **Draft** = instructions only,
not exercised against real tools. **Blocked** = waiting on the owner. **Planned** = approved, not started.

## Built

| Component | State | Notes |
|---|---|---|
| Studio database (`studio/schema.sql`, schema version 2, 25 tables) | Working | All ten libraries from the brief are present. `init` upgrades a version 1 database in place |
| One-way mirror of Agent 00's catalog (`ins sync-agent00`) | Working | Keeps `REF-` IDs, original URLs, creator, access status, certainty labels and every analysis version; repeatable; never writes to Agent 00's catalog |
| Reference-shot manifest in the owner's 15-column format (`refshot …`) | Working | Imports arrive PENDING_REVIEW; only approved shots export; approved rows are frozen |
| Technique library linked to reference shots (`manifest …`) | Working | Proposal-only until approved; links back to the shots that show each technique |
| Genre library | Working | Seeded with the eight starting genres as owner-defined; grows through proposals and the mirror |
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

## Installed verbatim from the recovery pack

Byte-identical to the originals in `archive/recovery-pack-2026-11-13/` (a test checks this).

| Component | Path | State |
|---|---|---|
| Motion Director | `.claude/skills/motion-director/SKILL.md` | Installed; **never run**. Rendering needs Remotion or HyperFrames, neither verified |
| Cinematic Reel Storyboard v2.0 | `.claude/skills/cinematic-reel-storyboard/SKILL.md` | Installed; **never run**. Sketch, PDF and zip steps not built |
| Agent 00 subagent | `.claude/agents/inspiration-intelligence.md` | Installed, unchanged, no model pinned. Not yet registered when tested; see below |
| Agent 00 skill | `.claude/skills/inspiration-intelligence/SKILL.md` | Installed |
| Agent 00 catalog tool | `tools/inspiration.py` | Installed; add, import, analyse, search, list and export-shots exercised by tests |
| Analysis schema, sample import | `references/` | Installed |

**Agent 00 test status:** one independent run on 13 November 2026
(`docs/tests/AGENT00_TEST_2026-11-13.md`). Passed for a blocked link and for whole-file
inspection of a local video. **Not yet tested on a real accessible reference**, and the run used
a general-purpose agent following Agent 00's definition because the new agent type was not
registered in that session. Known gap: its tool cannot catalogue a local file.

Older editing drafts (v0.1/v0.2) stay in the archive only; see `docs/EDITING_DRAFTS_GAP_REVIEW.md`.

## Drafts awaiting review

| Document | Purpose |
|---|---|
| `docs/drafts/CREATIVE_DIRECTOR_SPEC.md` | Creative Director specification. Not installed, not active |

## Still missing

| Component | What is needed |
|---|---|
| Creative Director | The owner's review of the draft |
| Populated Master Shot Manifest | The real file if one exists; otherwise it fills through approved proposals |
| `frameplan-reference-analyser` | The skill file. Not assumed to be Agent 00 |
| Frameplan app | Source location (`projects.external_ref` is ready to hold its IDs). Not to be modified |
| A real accessible reference for Agent 00 | An uploaded photo or clip, or outside hosts allowed in the environment |

## Planned (approved scope, in order)

One specialist at a time; each needs the owner's go-ahead and a logged test before the next.

1. Agent 00: real-world test with an accessible reference; decide how local files are catalogued;
   import the 16 rows from the "Shoot Planner & Inspiration" sheet.
2. Storyboard: first run on a real reference video; build the local sketch, PDF and zip steps.
3. Motion Director: first run to IDEA APPROVAL and three style previews.
4. Creative Director (after spec review), then `shot-planner`.
5. First live runs of `generation-director` and `qa-reviewer`.
6. Remaining adapters: Higgsfield, OpenAI, Sheets, Resolve — each labelled real or mock.
7. Master Creative Studio end to end; the twelve validation scenarios on real components.
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
- This cloud environment's network refuses every outside host tested (Instagram, Pinterest,
  YouTube, Wikimedia, Pexels, archive.org). No link can be reviewed from here until hosts are allowed.
- Agent 00's tool cannot catalogue a local file, cannot distinguish a network block from a login
  wall, and its shot export never fills timecodes or frame names.
- Agent 00's duplicate rule is looser than the studio's; the mirror folds duplicates into one
  record and reports them, but Agent 00's own catalog keeps both.
