# Claude Cinematic Content Studio — Recovery Pack

## Purpose
Recovered source artifacts from prior ChatGPT work for Claude Code audit and migration. **This is not a completed or installed ecosystem.** No changes have been made to your Claude Code repository.

## Originals (unaltered copies)
- `01_RESTORED_ORIGINALS/SKILL(1).md`: Motion Director skill design. Includes IDEA approval before STYLE approval, 3 static previews, 20-style approach. Check actual repository copy and version before migration.
- `01_RESTORED_ORIGINALS/Cinematic_Storyboard_SKILL_v2.md`: storyboard/reference-video-to-shots workflow.
- `01_RESTORED_ORIGINALS/SHOT_MANIFEST_TEMPLATE.csv`: **empty schema/template**, not a populated master database. Preserve an existing production manifest if located.
- `01_RESTORED_ORIGINALS/01_Rough_Cut_Skill_Draft.md`: rough-cut instructions **draft**, not validated deployed automation.
- `01_RESTORED_ORIGINALS/02_Color_Grading_Skill_Draft.md`: colour grading instructions **draft**.
- `01_RESTORED_ORIGINALS/03_Assembly_Skill_Draft.md`: assembly instructions **draft**.
- `01_RESTORED_ORIGINALS/04_Effects_and_Transitions_Skill_Draft.md`: VFX/transitions instructions **draft**.
- `01_RESTORED_ORIGINALS/Cinematic_Editing_Skills_Draft_v0.1.md`: shared handoff contract/design **draft**.

## Agent 00
- `02_AGENT_00_PACKAGE/cinematic-content-studio-agent00.zip`: previously generated Agent 00 package.
- `02_AGENT_00_PACKAGE/EXTRACTED_FOR_REVIEW/`: convenience extracted copy including `inspiration-intelligence` skill, subagent definition, SQLite-friendly local Python tool, schema, sample CSV, and `CLAUDE.md`.
- That inner `CLAUDE.md` is a **proposal**, not an authorized replacement for the existing project `CLAUDE.md`.
- Private Instagram/Pinterest saved collection ingestion and actual streamed video inspection are **not yet verified integrations**. Never claim access from a saved URL alone.

## Missing / not validated from this recovery pack
- No verified original standalone **Creative Director** skill file was recovered. Existing repository content must be audited before authoring one.
- No verified **populated Master Shot Manifest** was recovered. CSV above contains only headers.
- Exact status/relationship of `frameplan-reference-analyser` to Agent 00 is unknown; inspect code to decide whether to integrate, wrap or leave separate.
- Frameplan application's source directory/repository location is unknown.
- The original Motion Director may have additional deployed assets or a newer version in Claude. This pack does not prove version supremacy.
- Existing project branch, installed subagents and the three newly approved agents must be inspected in the actual Claude repository.

## Suggested Claude Code migration sequence
1. Inspect the existing repository and all branches. Report exact paths and differences; do not modify anything yet.
2. Compare existing `motion-director`, `frameplan-reference-analyser`, CLAUDE.md, shot manifest, rough cut and editing skills with these originals.
3. Present a source-of-truth table (keep current / restore recovered / merge carefully / defer), with conflict details.
4. Ask for explicit approval before modifications. Do not overwrite files, create competing agent names, or deploy/charge external APIs.
5. Once approved, copy files into Claude-compatible locations only after preserving existing versions and checking skill frontmatter and subagent contracts.
6. Test every agent with a fixed sample and a logged pass/fail report.

## Important guards
- User approval order: idea/story FIRST, then three static style previews and style approval, then any paid generation or irreversible publishing only after distinct execution approval.
- Preserve source URLs, creators/attribution, access limitations and analysis confidence.
- Reuse existing shots; propose novel shots for review instead of silently updating an approved master record.
- Keep original footage unchanged; track project, version, approvals and media lineage.
- Prioritize free/local tools; optional paid generation requires a quote and authorization, target under US$10/finished reel.
