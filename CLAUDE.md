# Frameplan — Cinematic Content Studio

A multi-agent production system that turns ideas, saved inspirations and reference footage
into cinematic photo and video content. The owner shoots on a Sony A7 IV and edits in
Premiere Pro, After Effects, DaVinci Resolve, CapCut, Lightroom and Photoshop.

**Read `docs/IMPLEMENTATION_STATUS.md` first.** It says what is built, what is a draft and what
is waiting on the owner. Do not describe anything as working unless that file or a test says so.

## How to work here

- Any creative production request goes through the `studio` skill (the Master Studio Orchestrator).
- State lives in the studio database. On a fresh checkout run `python3 studio/studio.py init`;
  it rebuilds from `data/studio.sql`. Write to it only through `studio/studio.py`.
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
5. **Do not rebuild the owner's components.** Motion Director, Agent 00 (Inspiration
   Intelligence), Creative Director and the Master Shot Manifest were developed elsewhere and
   are not in this repository yet. Integrate them when supplied; do not improvise replacements
   without approval.
6. **Motion graphics order:** research → proposal → idea approval → three styles with previews →
   style selection → production. Never show styles before the concept is approved.

## Layout

| Path | What |
|---|---|
| `.claude/skills/studio/` | Master Studio Orchestrator |
| `.claude/skills/{rough-cut,colour-grading,effects-and-transitions,reel-assembly,cinematic-reel-editing}/` | Editing pipeline skills (owner's v0.4 drafts) |
| `.claude/skills/{ultra-realistic-portrait,navratri-photoshoot}/` | Portrait prompt skills |
| `.claude/skills/ig-*/` | Instagram scripting, captions, planning, audit (third-party pack, MIT) |
| `.claude/hooks/paid_gate.py`, `.claude/settings.json` | Paid-generation approval gate |
| `studio/studio.py`, `studio/schema.sql` | Database tool and schema |
| `studio/config/studio.json` | Budgets, agent model choices, paid-tool pattern |
| `data/` | `studio.sql` snapshot, Instagram state (`data/instagram/`) |
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
