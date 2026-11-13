# Motion Director — test run 1

14 November 2026. Run in the main session through the installed skill, unchanged.
Project `PRJ-0002`; research ledger `DOC-0001`; idea proposal `DOC-0002`; approval `APR-0002`.

**Input:** `/motion-director Why forklift and pedestrian segregation matters` — the skill's own
example title, chosen by Claude because the owner asked for the test without naming a topic.
No `mode`, so the skill must stop at IDEA APPROVAL. This exercises the skill's default path
(WHS/HSE, LinkedIn, 9:16). A cinematic topic with `platform=` passed in is a separate test.

## Phase 1 — research

| Check | Result |
|---|---|
| Searched primary Australian sources (Safe Work Australia, state regulators) | **Pass** — three web searches |
| Disclosed browsing limits | **Pass, with a real limitation:** search works here but no page can be opened (network policy), so every claim rests on search excerpts. Stated in the ledger and in the proposal |
| Research ledger with claim, source, URL, confidence, on-screen treatment | **Pass** — 7 entries |
| Facts, interpretation and simplification separated | **Pass** — and "verified facts: none yet" recorded honestly |
| No invented statistics | **Pass** — no national pedestrian figure was found, so none is used; the one state figure found is excluded as too broad |
| Opinion not presented as law | **Pass** — hook and thesis labelled editorial framing; jurisdiction caveat recorded |

## Phase 2 — idea and IDEA APPROVAL gate

| Check | Result |
|---|---|
| Thesis, working title, hook, key message, beats, draft wording, CTA, factual basis, duration | **Pass** |
| Three or fewer beats; 25–40 s default | **Pass** — three beats, 30 s |
| No style, palette, font, engine, transition or music mentioned | **Pass** |
| Stopped at the gate with only the approval question | **Pass** |
| Studio bookkeeping: IDEA APPROVAL recorded as a pending `concept` approval | **Pass** |
| Style cannot be requested or the stage advanced while the idea is pending | **Pass** — both refused by the studio tool |

## Not yet run

- **Phase 3** — three styles with real static previews. Waits on the owner's idea approval.
  Open question for that phase: previews must be real image files; the free route is drawing
  still frames locally, the paid route needs a separate approval.
- **Phases 4–5** — master production prompt and rendering. Remotion and HyperFrames are not
  installed in this environment and have not been verified anywhere.
