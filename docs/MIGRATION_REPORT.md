# Migration and integration report — Recovery Pack

Prepared 13 November 2026. Status: **proposal, awaiting the owner's decisions in section 7.**
Nothing from the pack has been installed. The pack is stored unaltered in
`archive/recovery-pack-2026-11-13/`, where nothing is loaded by Claude Code.

## 1. What was received

`Claude_Cinematic_Studio_Skills_Recovery_Pack.zip`: 19 files, all text, one nested zip.
All eight checksums in `03_HANDOFF/SOURCE_CHECKSUMS.txt` match the files. The nested Agent 00 zip
is identical to its `EXTRACTED_FOR_REVIEW` copy. The pack's own readme describes the contents
as recovered from earlier ChatGPT work and "not a completed or installed ecosystem".

## 2. Inventory and source of truth

| # | Recovered file | What it is | In the repository today | Decision proposed |
|---|---|---|---|---|
| 1 | `01_RESTORED_ORIGINALS/SKILL(1).md` | **Motion Director** skill (`name: motion-director`), complete | Absent | **Migrate verbatim** to `.claude/skills/motion-director/SKILL.md` |
| 2 | `Cinematic_Storyboard_SKILL_v2.md` | **Cinematic Reel Storyboard** skill v2.0 (`name: cinematic-reel-storyboard`), complete | Absent | **Migrate verbatim** to `.claude/skills/cinematic-reel-storyboard/SKILL.md` |
| 3 | `SHOT_MANIFEST_TEMPLATE.csv` | Header row only: 15 columns. **Not a populated manifest** | Tables exist with a different shape (section 4.3) | **Adopt its columns** as the manifest schema; needs a decision |
| 4 | `02_AGENT_00_PACKAGE/…/.claude/agents/inspiration-intelligence.md` | **Agent 00** subagent definition | Absent | **Migrate verbatim** to `.claude/agents/` |
| 5 | `…/.claude/skills/inspiration-intelligence/SKILL.md` | Agent 00 skill (commands and review rules) | Absent | **Migrate verbatim** to `.claude/skills/inspiration-intelligence/` |
| 6 | `…/tools/inspiration.py` | Agent 00 catalog tool (SQLite, stdlib only) | Overlaps `studio.py ins …` (section 4.1) | **Migrate verbatim** to `tools/`; needs a decision on the two catalogs |
| 7 | `…/references/analysis-schema.json`, `import-example.csv` | Analysis contract and sample import | Absent | **Migrate verbatim** to `references/` |
| 8 | `…/CLAUDE.md` | A proposed project instruction file | Repository has its own `CLAUDE.md` | **Do not replace.** Merge four items (section 4.4) |
| 9 | `…/SETUP.md` | Agent 00 setup and first test | Absent | Keep in archive; fold its test steps into the Agent 00 test plan |
| 10 | `01_Rough_Cut_Skill_Draft.md` | Rough Cut draft **v0.2**, 24 Oct | `rough-cut` **v0.4**, 31 Oct | **Keep current.** Archive only |
| 11 | `02_Color_Grading_Skill_Draft.md` | Colour Grading draft v0.2 | `colour-grading` v0.4 | **Keep current.** Archive only |
| 12 | `03_Assembly_Skill_Draft.md` | Assembly draft v0.2 | `reel-assembly` v0.4 | **Keep current.** Archive only |
| 13 | `04_Effects_and_Transitions_Skill_Draft.md` | Effects draft v0.2 | `effects-and-transitions` v0.4 | **Keep current.** Archive only |
| 14 | `Cinematic_Editing_Skills_Draft_v0.1.md` | The single-file v0.1 ancestor of the four editing skills | Superseded by the five v0.4 skills | **Keep current.** Archive only |
| 15 | `README_START_HERE.md`, `PROMPT_FOR_CLAUDE.txt`, `SOURCE_CHECKSUMS.txt` | Handoff notes | — | Archive only |

On the editing drafts: the repository copies are newer (v0.4 against v0.2/v0.1) and two to three
times longer. A sentence-level comparison found 7 to 12 sentences per v0.2 draft that do not
appear word for word in v0.4. I have not reviewed those sentence by sentence, so I cannot say
whether each was reworded or dropped. Restoring the older files would lose the v0.4 additions
(loop seams, loudness, safe areas, evidence tiers), so the current versions stay and the drafts
remain in the archive for reference.

## 3. Still missing after this pack

| Component | Finding | What is needed |
|---|---|---|
| **Creative Director** | No standalone file was recovered; the pack's readme says so. The only trace is one line in Agent 00's proposed `CLAUDE.md`: "Act as the Creative Director", a role for the main session | Either the original file, or approval to author one from that proposal and the approval rules |
| **Populated Master Shot Manifest** | Only the empty template was recovered | The real manifest if one exists; otherwise it starts empty and fills through approved proposals |
| **`frameplan-reference-analyser`** | Named in the Drive request `FP-TEST-001`. Not in the pack, the repository or the installed skills | The skill file. Until it is seen, its relationship to Agent 00 cannot be judged. From the request, it analyses references per assigned purpose for a Frameplan shoot, while Agent 00 catalogues and analyses a saved collection: related, not identical |
| **Frameplan application** | Source location unknown; not accessible from this session | Repository or folder location |
| **Motion Director assets** | The skill needs no asset files. Its 20 styles are a table in the skill, and previews are generated per project | Nothing, unless a newer version exists in a Claude project |

## 4. Conflicts and overlaps

### 4.1 Two inspiration catalogs

| | Agent 00 (`tools/inspiration.py`) | Studio (`studio/studio.py ins`) |
|---|---|---|
| Store | `data/inspirations.sqlite3`, table `refs` | `data/studio.db`, `inspirations` and `inspiration_links` |
| IDs | `REF-000001` | `INS-0001` |
| Access states | `reviewed_video`, `reviewed_images`, `metadata_only`, `blocked`, `unreviewed` | `not_attempted`, `accessible`, `inaccessible` |
| Per-observation certainty | `observed`, `inferred`, `suggested`, `unverified`, validated | Free-form JSON plus a required "basis" |
| Links per reference | One | Several (the Google Sheet rows hold up to three) |
| Instagram duplicates | Strips tracking parameters only; `…/user/p/CODE/?img_index=4` and `…/p/CODE` count as two | Recognised as one |
| Batch import | CSV and JSON | Not built |
| Shot proposals | `export-shots` writes a review CSV in manifest columns | `manifest propose` / `manifest decide` with approval record |
| Links to projects, approvals, genres | None | Yes |

They do the same job in different ways. Agent 00's subagent and skill call `tools/inspiration.py`
by name, so it must exist for them to work as designed.

**Recommended:** install Agent 00 exactly as written and let it own reference intake and
analysis. Add a one-way sync command to `studio.py` that reads Agent 00's catalog and mirrors
each `REF-` record into the studio database (keeping the `REF-` ID, access state and certainty
labels), so projects, genres and approvals can link to it. Agent 00's files are not edited.
`studio.py ins` stays for references that carry several links. The studio's access-state list is
widened to Agent 00's five values so nothing is lost in the mirror.

The stricter Instagram duplicate rule then applies at the mirror step, which will report
duplicates Agent 00's tool let through.

### 4.2 Planned agent names

The architecture planned a `reference-analyst` subagent. Agent 00 (`inspiration-intelligence`)
already is that specialist, so `reference-analyst` is **dropped** and the config now names
`inspiration-intelligence`. No competing agent will be created.

The Storyboard skill covers reference-video breakdown, storyboard sketches and the shoot plan.
The planned `shot-planner` subagent is therefore narrowed to what the skill does not cover:
storyboards and shot lists for **original** ideas with no reference video, and location and
production planning. It will use the Storyboard skill's field list and Sony A7 IV rules so both
paths produce the same shot-list shape.

### 4.3 Shot manifest shape

The template describes **one shot in one reference video** (`start_time`, `end_time`,
`actual_frame`, `sketch`). The studio's `shot_manifest` table was built as a library of reusable
**techniques** (`name`, `category`, free-form spec). The template is the owner's design, so it wins.

**Recommended:** add the template's 15 columns to `shot_manifest` and `manifest_proposals` as
real columns, keep `name` as the label (Agent 00's `candidate_label`), and add `import` and
`export` commands that read and write the template's CSV exactly. Both tables are empty, so no
data is affected. `studio/video_probe.py` already writes its shot list in these columns.

### 4.4 Agent 00's proposed `CLAUDE.md`

It must not replace the repository's file, and the pack's readme says the same. Four things in
it are not yet in the repository's `CLAUDE.md` and are worth merging:

1. The eight creative genres: cinematic fashion; fantasy/surrealism; Indian cultural aesthetics;
   emotional romance; dark experimental; creative VFX; motion graphics/typography; editing
   education/BTS. These would also seed the genre library as owner-defined genres.
2. The four observation labels (`observed`, `inferred`, `suggested`, `unverified`).
3. "Never bypass authentication, DRM, platform restrictions, or access controls."
4. Gear detail: After Effects **Beta**, DaVinci Resolve **Free**, portrait lenses, portable lighting.

One line conflicts: it makes the main session "the Creative Director", while the approved
architecture makes the main session the orchestrator and Creative Director a specialist. That
line would be left out pending the Creative Director decision.

### 4.5 Motion Director against the brief

| Point | Motion Director (recovered) | Phase 4 brief, Workflow E | Proposed handling |
|---|---|---|---|
| Style choice | "Do not offer 'Browse all 20' … unless the user separately requests it" | "Style Selection or Browse All" | Follow the skill: three previews, and the full list only when asked. Both allow browsing on request |
| Defaults | Audience and tone are written for WHS/HSE content on LinkedIn, 25–40 s | Cinematic reels for Instagram | Leave the skill untouched; the orchestrator passes `platform=` and audience when the topic is not HSE. Flagged because the default will otherwise steer a cinematic topic toward a LinkedIn explainer |
| Gate names | IDEA APPROVAL, STYLE APPROVAL | Studio gates `concept`, `style` | Same order and meaning. The orchestrator records IDEA as `concept` and STYLE as `style`; the studio already refuses `style` before `concept` |
| Render engines | Remotion or HyperFrames | — | Neither is installed in this cloud environment and neither has been tested. An earlier session of yours asked for `/hyperframes` and the skill was not installed. Rendering stays unverified until tried on your Mac |
| Paid previews | Asks consent before paid image generation | Paid gate | Compatible; the hook enforces it for Kling and Idea AI |

### 4.6 Storyboard skill details

- It is written for ChatGPT ("ChatGPT subscription usage/limits may apply"). It still reads
  correctly in Claude Code; no edit proposed.
- It requires hand-drawn-style sketches made locally with Pillow or SVG. Pillow 12.3 is installed
  here. No sketch generator exists yet; that is new work inside this skill's scope.
- It requires a PDF, contact sheets and zip bundles. Not built yet.
- `studio/video_probe.py` now covers its steps 1, 2 and 4 (metadata, shot numbering with
  timecodes, one genuine frame per shot named `shot_XX_actual_frame.jpg`) and writes the shot
  list CSV in the template's columns.

### 4.7 Agent 00 details

- The subagent file has no `model:` line, so it would run on the session's model. Proposed: add
  `model: sonnet`, the only edit to any recovered file, and only with approval.
- Its tool list includes WebFetch and WebSearch. Instagram and Pinterest pages are normally
  behind a login from this environment; the agent's own instructions already say to report that
  and ask for the media.
- `tools/inspiration.py` creates its database on first use and overwrites nothing.

## 5. Proposed repository layout after migration

```
.claude/
  agents/
    inspiration-intelligence.md      ← Agent 00, verbatim (+ model line if approved)
    generation-director.md           built this session
    qa-reviewer.md                   built this session
    creative-director.md             pending decision
    shot-planner.md                  planned
  skills/
    motion-director/SKILL.md         ← verbatim
    cinematic-reel-storyboard/SKILL.md   ← verbatim
    inspiration-intelligence/SKILL.md    ← verbatim
    studio/ …existing…               orchestrator, table updated
tools/inspiration.py                 ← verbatim
references/analysis-schema.json, import-example.csv   ← verbatim
archive/recovery-pack-2026-11-13/    unaltered originals (already committed)
```

No existing file is overwritten by any of these paths; every target is new.

## 6. Order of work — one specialist at a time

Each step ends with a fixed sample and a logged pass/fail before the next begins.

| Step | Specialist | Work | Test sample |
|---|---|---|---|
| 1 | **Agent 00** | Install verbatim; run `SETUP.md` steps; build the one-way sync | The pack's `import-example.csv`; one uploaded image or clip from you; one Instagram link expected to be blocked |
| 2 | **Shot manifest** | Adopt the 15 columns; CSV import and export | Round-trip the template; approve one proposal from step 1 |
| 3 | **Storyboard** | Install verbatim; wire `video_probe.py`; build the local sketch, PDF and zip steps | One short reference video from you |
| 4 | **Motion Director** | Install verbatim; map its gates to studio approvals | One title, run to IDEA APPROVAL and then to three style previews; rendering only on your Mac |
| 5 | **Creative Director** | Author or install, per your decision | One idea and one Agent 00 reference |
| 6 | **Shot planner** | Build for original ideas | The concept approved in step 5 |
| 7 | **Generation Director** | Already built; first live run | The shot list from step 6 with one reference photo; dry run only |
| 8 | **QA Reviewer** | Already built; first live run | One generated or edited clip, and one deliberately flawed one |
| 9 | **Master orchestrator** | End-to-end runs of workflows A to E | The twelve validation scenarios |

## 7. Decisions needed

1. **Install the recovered files verbatim** at the paths in section 5 (items 1, 2, 4, 5, 6, 7)?
2. **Two catalogs:** accept the recommendation in 4.1 (Agent 00 owns intake; one-way mirror into the studio database)?
3. **Manifest:** adopt the template's 15 columns as in 4.3?
4. **`CLAUDE.md`:** merge the four items in 4.4?
5. **Agent 00 model:** add `model: sonnet` to its file, or leave it exactly as recovered?
6. **Creative Director:** will you supply a file, or should one be authored for your review?
7. **Still needed from you:** the `frameplan-reference-analyser` skill and the Frameplan app location.

## 8. Risks

- **Version uncertainty.** The pack's readme says a newer Motion Director may exist in a Claude
  project. Installing this copy would not delete anything, but it could become the stale one.
- **Catalog drift.** Until the mirror exists, references added through one tool are invisible to the other.
- **Untested behaviour.** The recovered skills and agent are instructions. None has been run in
  Claude Code. Each needs its test in section 6 before the orchestrator relies on it.
- **Rendering.** Motion Director's production phase depends on Remotion or HyperFrames, neither verified.
- **Private collections.** Instagram Saved and Pinterest boards need a signed-in browser on your
  own machine. Nothing here can read them from the cloud.
