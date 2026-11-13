# Editing drafts: what the older versions have that v0.4 does not

Reviewed 13 November 2026. The v0.4 skills in `.claude/skills/` stay as they are. The older
drafts (v0.1 master, v0.2 modules, 24 October) are kept unaltered in
`archive/recovery-pack-2026-11-13/01_RESTORED_ORIGINALS/`. Nothing here has been changed.

## Method

Every sentence in the five older files was compared against all five v0.4 skills together.
Forty-three sentences had no close match; each was read and checked against v0.4 by keyword.
This finds content that was dropped. It would not catch a rule that was kept in wording but
subtly weakened.

## Substantive content missing from v0.4

| # | In the older draft | In v0.4 | Recommendation |
|---|---|---|---|
| 1 | **"Validation cases for the later implementation"** (v0.1): eight concrete test situations, such as a six-second reel that cannot fit two 3–5 second opening blocks; a contact sheet that cannot establish a precise action; a warm sunset reference paired with a fluorescent indoor shot; unknown log encoding; Resolve Free with no external control; an approved look with one underexposed shot; a stale handoff; a timeline that imports with titles missing | No such list. Most of the underlying rules are present in the individual skills, but the cases themselves are gone | **Restore as a test plan**, not as skill text. These are exactly the fixed samples needed to test the editing skills one at a time |
| 2 | **"Underexposed shot under an approved look: correct that shot without silently changing the look version"** | The word "underexposed" does not appear. Shot correction and look versioning are both covered, but this specific interaction is not stated | Worth one sentence in `colour-grading` if you agree |
| 3 | **"A stale handoff: reconcile the active version before editing"** | The handoff section lists what to pass on; it does not say what to do when the record received is out of date | Worth one sentence in the shared handoff block |
| 4 | **Example invocation prompts** (v0.1): ready-to-paste requests for each module, including "Wait for profile approval before treating a look as locked" and "Do not claim timeline creation unless it was performed and checked" | The rules are present; the copy-and-paste prompts are not | Optional. Useful as a quick-start card |

## Carried into v0.4 (reworded, not lost)

- Hook within three seconds; reveal, hero and ending structure; flagging a duration that cannot fit the structure.
- Premiere Pro as the proposed primary assembly editor; other editors need verification.
- DaVinci Resolve Free as an assisted route, with the Resolve 21.1 scripting note.
- Keeping grain, bloom and halation separate from the global grade (now a full "texture ownership" section).
- Overlays and blend modes; protecting skin.
- Never overwriting an approved decision silently; saving revisions as new versions.
- Contact sheets for screening only; motion needs temporal inspection.

## Dropped deliberately or no longer relevant

- Setup notes for using one master document with two assistants, superseded when the master was split into separate skills.
- "A future Claude Code package can split the modules into skill folders": done.
- The v0.1 "next steps" line and its documentation links.

## Unrelated inconsistency found earlier

The shared "operating contract" block is identical in four of the v0.4 skills and different in
`cinematic-reel-editing`, although its header says all five must match. Left as found.
