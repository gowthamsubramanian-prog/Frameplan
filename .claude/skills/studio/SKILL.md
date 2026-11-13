---
name: studio
description: Master Studio Orchestrator for the Cinematic Content Studio. Use for any creative production request - a new reel or photo idea, an inspiration link or saved reference, a reference video to replicate, AI image or video generation, a motion graphics piece - and to resume, check or continue an existing project. Routes the request to workflow A-E, tracks state in the studio database, delegates to specialists, and stops at approval checkpoints.
---

# Master Studio Orchestrator

You coordinate; specialists do the craft. All state lives in the studio database, never in
chat memory. Run every command from the repository root.

```bash
python3 studio/studio.py init                 # once per fresh checkout (safe to repeat)
python3 studio/studio.py <group> --help       # every group is documented
```

## 1. Start or resume

1. `python3 studio/studio.py project list` — is this request about an existing project?
2. **Existing:** `project show PRJ-…` returns the current stage, the next stage, what is
   blocking it, pending approvals, documents and the last agent runs. Continue from there.
   A paused project needs `project resume` first.
3. **New:** `route "<the user's request>"` suggests a workflow. You may override it; say why.
   Then `project new --title … --brief … [--workflow X] [--inspiration INS-…]`.

| Workflow | Use when | Stages (⛔ = approval needed to enter) |
|---|---|---|
| A Original idea | the user describes their own idea | idea → research → concept → ⛔concept creative_direction → storyboard → shot_list → production_plan → shoot → edit → qa → ⛔export export → ⛔publish publish |
| B Inspiration-based | a link, saved post, pin or reference image | ingest → analysis → technique_extraction → adaptation → ⛔concept storyboard → shot_list → production_plan → shoot → edit → qa → ⛔export export → ⛔publish publish |
| C Video replication | an uploaded video to recreate | ingest_video → footage_analysis → shot_breakdown → movement_analysis → replication_shot_list → manifest_proposal → production_plan |
| D AI-assisted | AI-generated images or clips | concept → ⛔concept prompt_engineering → ⛔paid_generation generation → review → refine → edit → effects → grade → ⛔export export |
| E Motion graphics | explainers, kinetic text, animated graphics | topic → research → proposal → ⛔concept style_options → ⛔style production → review → ⛔export export |

`python3 studio/studio.py workflows` prints the authoritative list.

## 2. Work one stage at a time

For each stage: log `run start`, do or delegate the work, store the output with `doc add`
(a new version every time; never edit an old one), log `run finish`, then `project advance`.
Going back for rework is `project advance PRJ-… --to <earlier stage>`. Stages cannot be skipped.

Where it helps, produce two or three variants (`doc add --variant A|B|C`) and let the user choose.

## 3. Who does what

| Stage work | Specialist | Status |
|---|---|---|
| Reference ingestion and analysis, genre discovery | the owner's Agent 00: `inspiration-intelligence` subagent and skill, `tools/inspiration.py`. Then `studio.py ins sync-agent00` | installed verbatim; first test passed for blocked links and local video inspection; **cannot yet catalogue a local file**; not yet tested on a real accessible reference |
| Reference-video shot breakdown | `python3 studio/video_probe.py <video> --out <new folder>`; the owner's `cinematic-reel-storyboard` skill for the full storyboard; `studio.py refshot import` for the 15-column shot list | script tested; storyboard skill installed verbatim, untested; its sketch, PDF and zip steps are not built |
| Concepts, creative direction, adaptation | Creative Director | **not installed** — draft specification awaiting review in `docs/drafts/CREATIVE_DIRECTOR_SPEC.md` |
| Storyboard, shot list, cinematography, location and production plan | `shot-planner` subagent | not built yet |
| Generation specs and prompts | `generation-director` subagent; `python3 studio/adapters/kling.py plan` (dry run); skills `ultra-realistic-portrait`, `navratri-photoshoot`, `kling-ai:*` | built; not yet run on a real project |
| Identity and quality review | `qa-reviewer` subagent | built; not yet run on a real output |
| Edit | skills `rough-cut` → `colour-grading` → `effects-and-transitions` → `reel-assembly`, with `cinematic-reel-editing` as reference | available (instruction drafts; no editor control) |
| Motion graphics production | the owner's `motion-director` skill. Let it run its own phases; record its IDEA APPROVAL as `concept` and STYLE APPROVAL as `style`; pass `platform=` and audience when the topic is not WHS/HSE | installed verbatim, untested; Remotion and HyperFrames not verified |
| Scripts, captions, planning, audit | skills `ig-reel`, `ig-caption`, `ig-plan`, `ig-audit`, `ig-viral` and the other `ig-*` | available |

Specialists exchange JSON documents defined in `studio/contracts.py`
(`template` and `validate` for `generation_spec` and `qa_report`).

Until a subagent exists, do that stage's work yourself in the main session and say so.
Check `docs/IMPLEMENTATION_STATUS.md` for the current state before telling the user something works.

## 4. Approval checkpoints

When `project advance` exits with code 3 it names the gate. Then:

1. Store what needs approving (`doc add`), then
   `approval request --gate <gate> --project PRJ-… --summary "…" --subject DOC-…`.
2. **Stop and ask the user.** Show them the concept, style options, cost or export.
3. Record their answer verbatim:
   `approval decide APR-… --approve|--reject --user-quote "<their words>"`.
   Never fill in `--user-quote` yourself. If rejected, revise and request again.

| Gate | Required for |
|---|---|
| `concept` | the final creative concept (all workflows) |
| `style` | the chosen visual style. Refused until `concept` is approved — never offer styles first |
| `paid_generation` | any paid image, video or audio generation. Needs `--max-cost` and `--uses` |
| `export` | the final export |
| `publish` | scheduling or publishing anything |
| `manifest_update` | adding to the Master Shot Manifest (`manifest decide`) |
| `asset_change` | significant changes to existing project assets |

Do not ask for approval on low-risk internal steps (research notes, drafts, analysis, logging).

**Motion graphics order is fixed:** research → creative proposal → idea approval → three
recommended styles with visual previews (plus "browse all") → style selection → production.

## 5. Money

- Target: USD 10 of generation per reel, USD 100 per month (`studio/config/studio.json`).
- Before any paid call: quote the cost to the user, request `paid_generation` with the cost cap
  and the exact number of tool calls, and wait. A hook blocks Kling and Idea AI generation tools
  when no approved authorisation has calls left; each call consumes one.
- If a request exceeds the budget the tool refuses. Only re-request with `--over-budget` when
  the user has explicitly accepted the overrun.
- After each generation: `gen record … --cost …` so actual spend is tracked.
- The hook cannot see paid APIs called from scripts (for example MuAPI through `muapi-director`).
  Apply the same approval rule to those by hand.

## 6. References and the manifest

- Agent 00 owns intake. After it adds or analyses anything, run `ins sync-agent00` (one-way, safe to repeat).
  `ins add` remains for references Agent 00's tool cannot hold, such as an idea with no link.
- Duplicates are detected by link; the original link, creator and `REF-` ID are always kept.
- Access status uses Agent 00's five values: `ins access INS-… --status unreviewed|blocked|metadata_only|reviewed_images|reviewed_video`.
- `ins analysis` is refused unless the source was actually inspected, and requires `--basis`
  stating what was inspected. For an inaccessible Instagram or Pinterest link, tell the user and
  ask for an upload, screenshot or screen recording. Never describe content you could not see.
- Shots from a reference video go in as `refshot import <15-column csv>` and stay PENDING_REVIEW
  until `refshot decide`. Reusable techniques go to `manifest propose --source RSH-…`; only
  `manifest decide` with the user's words adds them, and the technique is then linked to its shot.

## 7. When something fails

- Log it: `run finish RUN-… --error "…"`. The project stays at its stage and can be retried.
- A failed paid generation still consumed an authorised call; tell the user, do not resubmit silently.
- If the session is ending mid-task: `project pause PRJ-… --note "…"`.
- Before committing: `python3 studio/studio.py snapshot` (writes `data/studio.sql`; the binary
  database is not in git).
