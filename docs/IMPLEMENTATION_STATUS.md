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
| Workflow routing A–E and stage gating | Working | `route` reads attachments first, then words; an image with no prompt goes to Agent 00; no input is refused, never replaced by a sample. Fixed 14 Nov 2026 after a routing failure |
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

Byte-identical to the originals in `archive/recovery-pack-2026-11-13/` (a test checks this),
except Agent 00's catalog tool, skill text and analysis schema, which carry approved additions
(tests check that nothing original was removed from the skill or the schema).

| Component | Path | State |
|---|---|---|
| Motion Director | `.claude/skills/motion-director/SKILL.md` | **No valid test yet.** Run 1 (14 Nov 2026) failed: the coordinator ran it on the skill's built-in example instead of the owner's material (`docs/tests/ROUTING_FAILURE_2026-11-14.md`). The skill itself is unchanged. Rendering needs Remotion or HyperFrames, neither verified |
| Cinematic Reel Storyboard v2.0 | `.claude/skills/cinematic-reel-storyboard/SKILL.md` | Installed; **never run**. Sketch, PDF and zip steps not built |
| Agent 00 subagent | `.claude/agents/inspiration-intelligence.md` | Installed, unchanged, no model pinned. Not yet registered when tested; see below |
| Agent 00 skill | `.claude/skills/inspiration-intelligence/SKILL.md` | **Additions 13 Nov 2026 (approved):** local-file intake, `blocked_reason`, shot timecodes. Every original line kept |
| Agent 00 catalog tool | `tools/inspiration.py` | **Modified 13 Nov 2026 (approved):** `add` and `import` accept a local media file, stored as `file:<path>` and deduplicated by content hash; bad input gives a clean error. Link handling unchanged. A `blocked` analysis must give a reason from a fixed list; `export-shots` carries timecodes, frame names, focal length and settings from the analysis and says when there is nothing to export. Catalogs made by the original tool upgrade in place. Tested |
| Analysis schema, sample import | `references/` | Schema gained optional fields (approved); sample import unchanged |

**Agent 00 test status: tested for still images and for honest failure; not yet for video or links.**

| Test | Log | Result |
|---|---|---|
| Blocked Instagram link; synthetic local video (general-purpose agent following the definition) | `docs/tests/AGENT00_TEST_2026-11-13.md` | Passed, exposed four gaps, all since fixed |
| Two real still photographs, run as the registered subagent on the real catalog | `docs/tests/AGENT00_TEST_2026-11-13_real_references.md` | Passed on every check |

Still untested: real video (timecoded shots, camera movement, editing), any link that opens, and
saved-collection import. The catalog now holds `REF-000001` and `REF-000002`, mirrored as
`INS-0001` and `INS-0002`, with two reference shots pending the owner's decision.

Older editing drafts (v0.1/v0.2) stay in the archive only; see `docs/EDITING_DRAFTS_GAP_REVIEW.md`.

## Drafts awaiting review

| Document | Purpose |
|---|---|
| `docs/drafts/CREATIVE_DIRECTOR_SPEC.md` | Creative Director specification v1.0, **signed off by the owner on 14 Nov 2026**. Not installed, not active. Implementation is deferred until the dependent specialists pass their tests |

## Still missing

| Component | What is needed |
|---|---|
| Creative Director | The owner's review of the draft |
| Populated Master Shot Manifest | The real file if one exists; otherwise it fills through approved proposals |
| `frameplan-reference-analyser` | The skill file. Not assumed to be Agent 00 |
| Frameplan app | Source location (`projects.external_ref` is ready to hold its IDs). Not to be modified |
| A real reference video for Agent 00 | An uploaded clip, to test timecoded analysis |

## Planned (approved scope, in order)

One specialist at a time; each needs the owner's go-ahead and a logged test before the next.

1. Agent 00: test on a real reference video; import the 16 rows from the "Shoot Planner & Inspiration" sheet.
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
- A local file's catalog entry points at its path; if the file is
  moved or the session's container is discarded, the entry remains but the media is gone.
- Agent 00's duplicate rule is looser than the studio's; the mirror folds duplicates into one
  record and reports them, but Agent 00's own catalog keeps both.
