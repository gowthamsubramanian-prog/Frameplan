# Routing, built-in topics and Creative Director status — audit of 14 November 2026

Prompted by the routing failure logged in `docs/tests/ROUTING_FAILURE_2026-11-14.md`.
The candle project and all creative tests are paused until the owner has reviewed this.

## 1. Global routing coverage

**How work enters this system.** There is no single door. Claude Code gives four ways in, and
only some pass through code:

| Way in | Passes through `route`? | What governs it |
|---|---|---|
| A plain message to the main session, with or without attachments | Only if the coordinator runs it | `CLAUDE.md` rule 10 (always loaded) + the context hook |
| A skill typed as a slash command (`/motion-director …`, `/studio`, an editing or `ig-*` skill) | No. The skill's text is loaded directly | The skill's own text + the context hook |
| A skill or subagent started by the coordinator | No | The brief gate hook + the coordinator's brief |
| A tool run directly (`studio.py`, `tools/inspiration.py`) | n/a | The tool's own validation |

So fixing `route` alone could not fix the system. Three layers now cover it:

1. **`route`** (code) — reads attachments, words and the current project; returns `new_work`,
   `continue_project` or `clarify`.
2. **Context hook** (code, every owner message) — prints the current project, pending approvals,
   a routing check on the owner's words and the input rules, whatever the entry point.
3. **Brief gate** (code, before a specialist starts) — blocks a studio subagent whose brief names
   no project, reference, asset, file or link, and blocks Motion Director or the Storyboard skill
   started with no subject.

### Coverage matrix

"Code" = enforced or computed by a script and covered by an automated test.
"Instruction" = depends on the coordinator following written rules.

| # | Entry point | Expected behaviour | Enforced by | Tested |
|---|---|---|---|---|
| 1 | Direct request in words | Owner's words are the subject | `route` (code) | Yes |
| 2 | Uploaded image, no words | Reference → Agent 00; files listed to pass on | `route` (code) | Yes |
| 3 | Uploaded video, no words | Reference analysis, and ask whether it is own footage | `route` (code) | Yes |
| 4 | Own footage ("edit this, I shot it") | Enter at the edit | `route` (code) | Yes |
| 5 | Link | Reference → Agent 00 | `route` (code) | Yes |
| 6 | "Continue / proceed / next" | Stay on the current project | `route` + context hook (code) | Yes |
| 7 | "Continue" with no current project | Ask; no subject invented | `route` (code) | Yes |
| 8 | Resumed or switched project | Becomes current; a cancelled project never lingers | `studio.py` (code) | Yes |
| 9 | New input while a project is current | Current project stays in view; ask if unclear | `route` flags it (code); the decision is **instruction** | Flag: yes. Decision: no |
| 10 | Named specialist, no subject, does not fit the current project (the 14 Nov failure) | Flag the mismatch and ask | `route` + context hook (code) | Yes |
| 11 | Named specialist, no subject, no project | Ask | `route` (code) | Yes |
| 12 | Named specialist that fits the current project | Continue that project with it | `route` (code) | Yes |
| 13 | Named specialist with the owner's own subject | Allowed, on that subject | `route` (code) | Yes |
| 14 | Named specialist that does not fit the attachment | Flag; do not change the subject | `route` (code) | Yes |
| 15 | No words and no attachment | Refused; ask | `route` (code) | Yes |
| 16 | Subagent started with no owner input in its brief | Blocked | Brief gate (code) | Script: yes. Live: no |
| 17 | Motion Director or Storyboard started by the coordinator with no subject | Blocked | Brief gate (code) | Script: yes. Live: no |
| 18 | `/motion-director` typed by the owner with no title | Skill asks for a title | Skill text (**instruction**) | No |
| 19 | Every owner message shows current project and rules | Context printed | Context hook (code) | Script: yes. Live: no |
| 20 | Coordinator actually runs `route` with the attachment paths | Attachments reach `route` | **Instruction only.** The hook cannot see attachments | No |
| 21 | The brief contains the *right* files, not just *a* file | Relevant attachments passed | **Instruction only.** The gate checks presence, not relevance | No |
| 22 | The subject passed to a skill really came from the owner | No invented subject | **Instruction only.** No script can tell who thought of a title | No |
| 23 | Editing, portrait and `ig-*` skills invoked directly | Work on the owner's material | Skill text (**instruction**) | No |
| 24 | Tools run directly | Validate their own input | Code | Yes |

### Paths that bypass `route` or rest on instructions alone

- **Rows 20–22 are the real residual risk.** A script can check that input exists and that a
  specialist fits; it cannot check that the coordinator chose the owner's subject rather than its
  own. The 14 November failure was exactly that kind of judgement. It is now caught at three
  earlier points (rows 10, 17, 19), but the last step is still a rule, not a lock.
- **Slash-invoked skills** (rows 18, 23) never touch `route`.
- **Hook firing:** the context hook was observed firing live on the owner's next message
  (14 November). The brief gate and the paid-generation hook have been tested as scripts but
  not yet observed live.
- **Decisions recorded 14 November:** the owner accepted the specification amendment and chose
  to keep every item in the "found and deliberately kept" table.

## 2. Built-in topics: inventory and changes

Scope: every skill, agent, hook, tool, template and instruction file. A test now scans all
production files for sample subjects and fails if one returns.

### Removed or neutralised

| File | Found | Change |
|---|---|---|
| `motion-director` skill | Example title "Why forklift and pedestrian segregation matters" | Removed. Empty input now means "ask for a title and stop" |
| | Default audience: WHS/HSE, Australian safety leaders | Removed. Audience is inferred from the owner's title, or asked |
| | Default distribution: "LinkedIn first" | Removed. No default platform. The technical default (1080×1920, 30 fps, 25–40 s) is kept |
| | Description: "HSE/WHS education, LinkedIn videos" | Reworded: "on any subject the user supplies" |
| | `platform=linkedin` in the shorthand | Now `platform=<name>` |
| | Research step naming Australian WHS sources | Generalised to "the subject's own field and jurisdiction"; the method is kept |
| | "compliance clichés" | Now "clichés" |
| | Three style-fit descriptions naming warehouse, LOTO and HSE | Reworded without domain examples; all 20 styles kept |
| `inspiration-intelligence` skill | Command examples: "Saved Reels", "Pinterest Ideas", "portal silhouette slow push-in" | Replaced with placeholders |
| `references/analysis-schema.json` | A filled-in sample analysis (portal reveal, fantasy) | Replaced with placeholders and a "never copy a placeholder" note; same fields |
| `references/import-example.csv` | Sample rows | Moved to `tests/fixtures/agent00-import-sample.csv` |
| `ultra-realistic-portrait` skill | Worked example: a saree set | Kept, relabelled "illustration of the method only; never use it as a live subject" |
| `studio` skill, `CLAUDE.md`, `route` | My own rules named WHS and LinkedIn as things not to assume | Reworded so no domain is named |

Motion Director's phases, both approval gates, the three-preview rule, the production brief and
the style library are unchanged; a test compares it with the recovered original and allows
exactly the ten edited lines. Originals remain in `archive/`.

### Found and deliberately kept — for the owner's decision

| File | What it assumes | Why kept |
|---|---|---|
| Five editing skills (v0.4) | Scope line: "cinematic portrait, fashion, atmospheric and fantasy reels on Instagram Reels, TikTok and YouTube Shorts" | It describes what the skills are for, not a subject they would pick. They are the owner's approved text |
| `ultra-realistic-portrait` | Uses "she/her" and "ethnic-wear catalogue" throughout, including the identity lock marked "copy verbatim" | A subject assumption, but inside the owner's approved wording |
| `navratri-photoshoot` | The whole skill is one theme | A topic skill by design; runs only when Navratri is requested |
| `ig-*` pack (13 skills) | Instagram-only; `hooks.json` has 26 filled example hooks | Instagram tools by purpose, run only when the owner asks for Instagram content. The examples illustrate formulas |
| `cinematic-reel-storyboard` | Sony A7 IV, PAL frame rates, "10 reels per month" | Equipment and workload, not subject |
| Agent 00 definition | "Sony A7 IV and Premiere/After Effects" | Equipment |
| `CLAUDE.md` | Eight starting genres | Owner-approved, stated as a starting library, not a default subject |
| `archive/`, test logs, the cancelled project `PRJ-0002` | The forklift text survives as history | Not loaded, not routable; records are not rewritten |

## 3. Test results and gaps

`python3 -m unittest discover -s tests`: **140 tests, 140 passed** (111 before this audit).
Added: 17 entry-point tests, 4 context-hook tests, 5 brief-gate tests, 4 topic-scan tests,
1 Motion Director integrity test; 4 older tests updated for the approved removals.

Gaps: rows 18 and 20–23 of the matrix; no live observation of any hook; Motion Director still
has no valid test.

## 4. Creative Director: status and prerequisites

**Why it is still "not installed".** Two of the owner's own conditions: "Do not install or
activate it yet" (13 and 14 November) and "Keep the Creative Director specification separate
from implementation until dependent specialists have passed their individual tests". Neither
has been lifted, and most dependencies are untested.

**Under Option A there is no Creative Director file to install.** It is the main session's
role. "Installing" it means three edits: rewriting the `studio` skill's text from the
specification, adding four features to `studio.py`, and naming the role in `CLAUDE.md`.

**What is active today**

| Piece | File | Role |
|---|---|---|
| Project rules | `CLAUDE.md` | Always loaded; rule 10 governs input |
| Orchestrator skill | `.claude/skills/studio/SKILL.md` | The coordinator's manual; section 0 is input handling |
| State and routing | `studio/studio.py` | Projects, gates, budget, `route`, `context` |
| Hooks | `.claude/hooks/context_hook.py`, `brief_gate.py`, `paid_gate.py` | Context, briefs, paid calls |
| Coordinator | The main session | Already does the Creative Director's job informally, without the specification's rules |

**The specification:** `docs/drafts/CREATIVE_DIRECTOR_SPEC.md`, v1.0, signed off 14 November 2026.
Nothing in `.claude/` refers to it.

**Dependencies**

| Dependency | Independent test |
|---|---|
| Agent 00 | **Passed** for still images and blocked links. Not tested on video or an opening link |
| `ig-*` scripts | **Passed** (scripts run) |
| Studio tool, gates, routing | **Passed** (automated) |
| Motion Director | **Not passed.** One run, failed on input |
| Cinematic Reel Storyboard | Never run |
| Generation Director | Never run |
| QA Reviewer | Never run |
| Shot planner | Not built |
| Editing skills ×4 | Instruction drafts; never run against an editor |

**Remaining before activation**

1. Individual tests for Motion Director, Storyboard, Generation Director and QA Reviewer; Agent 00 on video; build and test the shot planner.
2. Four studio-tool changes from the specification: the `rough_cut` gate; late entry with recorded skipped gates; a `style_treatments` document type; a deliverables summary.
3. Rewrite the `studio` skill text from the specification, keeping every command.
4. Name the role in `CLAUDE.md`.
5. One end-to-end run per workflow, including a late entry with existing footage.
6. The owner's approval to activate.

**Will the routing rules carry forward?** Yes. They live in `CLAUDE.md`, `studio.py` and the
hooks, none of which the Creative Director replaces. Section 0 of the `studio` skill is the one
part that would be rewritten; an amendment to the specification now requires it to be kept.
