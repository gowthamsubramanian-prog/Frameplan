# Frameplan — Cinematic Content Studio

A multi-agent production system that turns ideas, saved inspirations and reference footage
into cinematic photo and video content. The owner shoots on a Sony A7 IV with portrait lenses
and portable lighting, and edits in Premiere Pro, After Effects (Beta), DaVinci Resolve (Free),
CapCut, Lightroom and Photoshop.

**Read `docs/IMPLEMENTATION_STATUS.md` first.** It says what is built, what is a draft and what
is waiting on the owner. Do not describe anything as working unless that file or a test says so.

## How to work here

- Any creative production request goes through the `studio` skill (the Master Studio Orchestrator).
- State lives in the studio database. On a fresh checkout run `python3 studio/studio.py init`;
  it rebuilds from `data/studio.sql`. Write to it only through `studio/studio.py`.
- **Reference intake and analysis belong to Agent 00** (`inspiration-intelligence` subagent and
  skill, catalog tool `tools/inspiration.py`, catalog `data/inspirations.sqlite3`). The studio
  database holds a one-way mirror: run `python3 studio/studio.py ins sync-agent00` after Agent 00
  adds or analyses anything. Never write to Agent 00's catalog except through its own tool.
- **Shot manifest:** individual reference shots use the owner's 15-column format
  (`studio.py refshot …`); reusable techniques live in a separate library linked to those shots
  (`studio.py manifest …`). Both change only through approved proposals.
- Before committing, run `python3 studio/studio.py snapshot` and `python3 -m unittest discover -s tests`.

## Rules that do not bend

1. **Approvals.** Final concepts, chosen styles, paid generation, final exports, publishing or
   scheduling, Master Shot Manifest changes and significant changes to existing assets all need
   the owner's explicit approval, recorded with `approval decide … --user-quote "<their words>"`.
   Never write the quote yourself.
2. **No paid calls and no publishing without approval.** `.claude/hooks/paid_gate.py` blocks Kling
   and Idea AI generation tools unless an approved authorisation has calls left. Do not work
   around it. Paid APIs reached from scripts are not covered by the hook; hold them to the same rule.
3. **Never fabricate.** No analysis of a reference that could not be opened, no invented
   filenames, timecodes, metrics, test results or integration capabilities.
4. **Do not overwrite.** Documents are versioned; approved records are superseded, never edited.
   Original media is never modified. Keep original links and creator attribution.
5. **Do not redesign the owner's components.** Motion Director, Cinematic Reel Storyboard and
   Agent 00 (Inspiration Intelligence) are installed exactly as recovered; the originals are in
   `archive/recovery-pack-2026-11-13/` and a test checks the installed copies still match.
   On 14 Nov 2026, on the owner's instruction, built-in example subjects and default audience,
   domain and platform were removed from Motion Director and Agent 00's examples.
   Approved exceptions, all additions made on 13 Nov 2026 to Agent 00's catalog tool, skill text
   and analysis schema: local media files can be catalogued (`file:<path>`, deduplicated by
   content hash); a `blocked` analysis must give a `blocked_reason`; the shot export carries
   timecodes and frame names. The subagent definition itself is unchanged.
   Change them only with the owner's approval. No Creative Director is installed: a draft
   specification is in `docs/drafts/` awaiting review. `frameplan-reference-analyser` and the
   Frameplan app are separate things that have not been seen; do not assume either is Agent 00,
   and do not modify Frameplan.
6. **Motion graphics order:** research → proposal → idea approval → three styles with previews →
   style selection → production. Never show styles before the concept is approved.
7. **Never bypass access controls.** No working around authentication, DRM, platform
   restrictions or login walls, and never ask for passwords or session cookies. When a source
   cannot be opened, say so and ask for an upload, screenshot or screen recording.
8. **Do not integrate an untested specialist.** Each subagent is tested on its own, with a
   logged result, before the orchestrator relies on it. `docs/IMPLEMENTATION_STATUS.md` records which have been.
9. **Reference boards stay internal.** Boards built from saved references exist only to help the
   owner choose a style. Never publish one, and never include a board or any image from one in
   a final output, caption, carousel or deliverable.
10. **The owner's input is the subject.** Work on what the owner supplied — their words,
    attachments and active project. An uploaded image with no prompt is a creative reference for
    Agent 00. Never substitute a built-in example or sample topic, even for a test, and never
    assume a domain, audience or platform the owner did not name. Stay on the current project
    unless the owner changes it. A named specialist does not change the subject: if it does not
    fit the material, say so. If the input is missing, unclear or cannot be opened, ask for it.
    Run `python3 studio/studio.py route` on every request; two hooks back this up
    (`context_hook.py` on each message, `brief_gate.py` before a specialist starts). Sample
    subjects live only in `tests/fixtures/` and are never live inputs.

## Source discipline

Label every observation about a reference with one of four certainties, and record the access status:

| Label | Meaning |
|---|---|
| `observed` | Seen directly in the media that was opened (name the frame, timecode or file) |
| `inferred` | Reasoned from what was seen, such as a camera move judged from two frames |
| `suggested` | Your own recommendation, not a claim about the source |
| `unverified` | Reported by someone or something else and not checked |

Access status is one of `reviewed_video`, `reviewed_images`, `metadata_only`, `blocked`,
`unreviewed`. A `blocked` record says why: `network_policy` (this session could not reach the
host, so nothing is known about the post itself), `login_required`, `not_found`, `removed`,
`rate_limited` or `other`. Reading a link's page text or caption is `metadata_only`; it is never a video review.
Use references to learn techniques and build original combinations, not to copy wholesale.

## Creative context

Starting genres, seeded in the genre library as owner-defined:
cinematic fashion; fantasy/surrealism; Indian cultural aesthetics; emotional romance;
dark experimental; creative VFX; motion graphics/typography; editing education/BTS.

**These are a starting point, not a limit.** Research and discover further genres, techniques and
production knowledge from references, projects and current practice, and add them to the genre
library as proposals (`genre add`, or automatically through the Agent 00 mirror). Do not wait for
the owner to define a genre before recognising one.

## Layout

| Path | What |
|---|---|
| `.claude/skills/studio/` | Master Studio Orchestrator |
| `.claude/skills/{rough-cut,colour-grading,effects-and-transitions,reel-assembly,cinematic-reel-editing}/` | Editing pipeline skills (owner's v0.4 drafts) |
| `.claude/skills/{ultra-realistic-portrait,navratri-photoshoot}/` | Portrait prompt skills |
| `.claude/skills/ig-*/` | Instagram scripting, captions, planning, audit (third-party pack, MIT) |
| `.claude/hooks/paid_gate.py`, `.claude/settings.json` | Paid-generation approval gate |
| `.claude/hooks/context_hook.py`, `.claude/hooks/brief_gate.py` | Current-project context on every message; no specialist starts without the owner's input |
| `studio/studio.py`, `studio/schema.sql` | Database tool and schema |
| `studio/video_probe.py` | Reference-video shot breakdown (ffmpeg) |
| `studio/contracts.py` | JSON contracts between specialists |
| `studio/adapters/` | Service adapters; Kling is dry-run only |
| `.claude/agents/` | Subagents: `inspiration-intelligence` (Agent 00), `generation-director`, `qa-reviewer` |
| `.claude/skills/{motion-director,cinematic-reel-storyboard,inspiration-intelligence}/` | Owner's recovered skills, installed verbatim |
| `tools/inspiration.py`, `references/` | Agent 00's catalog tool and analysis schema (with the approved changes) |
| `tests/fixtures/` | Sample subjects for automated tests only; never live inputs |
| `archive/` | Unaltered recovered originals; nothing here is loaded |
| `studio/config/studio.json` | Budgets, agent model choices, paid-tool pattern |
| `data/` | `studio.sql` snapshot, Agent 00 catalog (`inspirations.sqlite3`), Instagram state (`data/instagram/`) |
| `tests/` | Automated tests |
| `docs/` | Status and handover documents |

## Skill copies

The seven editing and portrait skills also exist at account level (listed as
`anthropic-skills:<name>`). **The copies in this repository are authoritative.** Edit them here.

## Models

Subagents may use `opus`, `sonnet` or `haiku`. Do not depend on `fable`. Choices per agent are in
`studio/config/studio.json`: Opus for creative direction and quality review, Sonnet for analysis,
planning and prompt work.

## Environment notes

Cloud sessions are ephemeral and cannot reach the owner's footage or desktop editors. Local
files need Remote Control folder sharing or uploads. Instagram and Pinterest links are usually
behind a login wall from here.
