# Routing failure and correction — 14 November 2026

## What happened

1. 13 Nov: the owner uploaded two candle-themed portrait photographs with no prompt.
   They were handled correctly at that point: Agent 00 analysed both (`REF-000001`,
   `REF-000002`), the owner approved two reference shots, chose real candles, and project
   `PRJ-0001` "Candle portrait shoot" was opened.
2. 14 Nov: the owner wrote "proceed with Motion Director testing", naming no topic.
3. The main session ran Motion Director on **"Why forklift and pedestrian segregation
   matters"**, the example title printed in the skill's own text, and presented a WHS concept
   for LinkedIn. The owner stopped it: wrong subject, the uploaded reference was ignored.

## Findings

| Question | Finding |
|---|---|
| Was the uploaded image accessible to the session? | **Yes.** Both images were visible to the session and saved at `media/incoming/`; their hashes match the uploads, and both were already catalogued |
| Was it passed to the appropriate specialist? | **Yes on 13 Nov** (Agent 00), **no on 14 Nov.** Nothing about the candle references or `PRJ-0001` was passed into the Motion Director run |
| Why was the HSE example selected? | **The main session chose it.** Motion Director did not: a skill receives its title from whoever invokes it. With no topic given, the coordinator picked the skill's own example as a "fixed sample" instead of using the active project or asking. That was the error |
| Does the orchestrator prioritise defaults over user input? | **The code does not, but nothing prevented it.** `studio.py route` only read text and ignored attachments. The `studio` skill had no rule about attachments, active-project context or sample topics. So the decision fell to the coordinator's judgement, which failed. Separately, Motion Director's own defaults assume WHS and LinkedIn, which makes a wrong choice look natural |
| Was the wrong specialist selected? | **The owner named Motion Director, so it was the requested specialist, but it was applied to the wrong subject, and the mismatch was not raised.** Motion Director makes motion graphics; a candle fashion shoot is workflow B (reference → concepts → treatments). The coordinator should have said so before starting |

## Correction (coordinating layer only; Motion Director untouched)

- **`studio/studio.py route`** now takes `--attachment`. An image routes to workflow B with Agent 00
  as first specialist and the files listed to pass on; a video routes to analysis unless the
  owner says it is their own footage; with no words and no attachment it refuses and says to
  ask, never to substitute a sample. Its output names no domain.
- **`studio` skill:** new first section "Input handling" with eight rules: list the input; an image
  with no prompt is a reference for Agent 00; three concepts then stop at approval; never
  substitute a sample, even for a test; no domain defaults; carry attachments through; ask when
  an attachment cannot be opened; a named specialist does not change the subject.
- **`CLAUDE.md`:** rule 10, "The owner's input is the subject".
- **Approvals offering several variants** can now record which one was chosen (`--chosen`).
- **Tests:** 10 added (9 routing regressions, including one that fails if Motion Director's file
  ever differs from the recovered original; 1 for choosing among variants).

## Retest on the owner's candle photographs

| Step | Result |
|---|---|
| Input detected | Two images, no prompt: `media/incoming/1000162216.jpg`, `media/incoming/1000162212.jpg` |
| Route | `route --attachment … --attachment …` → workflow **B**, "an image was attached: treat it as a visual creative reference" |
| Specialist | Agent 00 (`inspiration-intelligence`) |
| Already catalogued? | Yes: `tools/inspiration.py add` answered "REF-000001 already exists" and "REF-000002 already exists" (matched by content hash) |
| Analysis | Agent 00's analyses of 13 Nov, read from the catalog. **Not re-run**: the same files, already reviewed as `reviewed_images` by the registered subagent |
| Concepts | Three, stored as `DOC-0003` (A, Vigil), `DOC-0004` (B, The Candle-Bearer), `DOC-0005` (C, Offering) in `PRJ-0001`. Written by the main session, because no Creative Director is installed |
| Gate | `APR-0003` pending; the project cannot enter storyboard until the owner decides |
| Style treatments | Not shown. They follow concept approval |

## Open

- Motion Director still has no valid test. It needs a subject the owner actually wants as a
  motion graphic.
- The rules above are instructions to the coordinator. Only the `route` behaviour is enforced by code.
