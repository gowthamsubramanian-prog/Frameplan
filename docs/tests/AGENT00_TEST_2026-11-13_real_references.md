# Agent 00 — second test: real references, registered subagent

13 November 2026. Run as the registered `inspiration-intelligence` subagent, in the real
project, writing to the real catalog (`data/inspirations.sqlite3`).

## Inputs

Two still photographs uploaded by the owner as inspiration for a candle-themed portrait shoot,
with no source links: `media/incoming/1000162216.jpg` and `media/incoming/1000162212.jpg`.
The images are not committed: `media/` is outside git, the repository is public, and they are
other people's work.

## Results

| Check | Result |
|---|---|
| Ran as the registered subagent with its own six tools | **Pass** |
| Both local files catalogued without an invented URL | **Pass** — `REF-000001`, `REF-000002`, stored as `file:media/incoming/…`, platform `local` |
| Access status | **Pass** — `reviewed_images` for both |
| Attribution only from evidence | **Pass** — REF-000001 credited "Cap2red Studio (per on-image watermark; handle and origin link unknown)"; REF-000002 left as unknown. The watermark reading was checked against the image by the main session and is correct |
| Observations match the images | **Pass** — lighting, pose, framing, colour and styling for both were compared with the images by the main session; no invented detail found |
| Certainty labels | **Pass** — 12 techniques on REF-000001 and 10 on REF-000002, each labelled; things not visible in a still (hidden key light, lens, whether the wax piece is a pre-made wearable) are `inferred`, and safety alternatives are `suggested` |
| Flags doubtful sources | **Pass** — judged REF-000002 probably AI-generated or a heavy composite, labelled `inferred`, with its evidence listed and "none of that is conclusive" |
| Practical recreation plan for the owner's kit | **Pass** — Sony A7 IV, 85mm, portable LED, Lightroom grade; includes fire-safety alternatives |
| Genre discovery | **Pass** — tagged three starting genres and proposed a new one, "candlelit conceptual portrait" |
| Shot proposals exported in the 15-column format | **Pass** — 2 rows, `PENDING_REVIEW`; timecodes correctly empty for stills |
| Did not touch the studio database, the manifest or the image files | **Pass** — file hashes identical to the uploads |
| Did not self-approve | **Pass** — asked the owner whether to approve the two proposals |

Mirror, run by the main session afterwards: `ins sync-agent00` created `INS-0001` and `INS-0002`
with the `REF-` IDs, file references, creator text, access status and full analyses; a second
run changed nothing. `refshot import` added `RSH-0001` and `RSH-0002` as PENDING_REVIEW, each
linked to its reference. The new genre arrived as a proposal linked to both references.

## Limits of this test

- Stills only. **No real video has been analysed**, so timecoded shot breakdown, camera movement
  and editing analysis on real footage remain untested.
- No link of any kind has been opened; this environment's network blocks outside hosts.
- Saved-collection import (Instagram Saved, Pinterest boards) is untested.
- Whether the lighting inferences are right cannot be checked from the image alone; they are
  labelled as inferences.

## What the agent reported did not fit

1. The analysis schema is video-shaped: timecodes on every technique and shot, and no field for
   aspect ratio or pixel size of a still.
2. Certainty is validated on techniques but not on shot candidates; one `confidence` value covers a whole shot row.
3. `actual_frame` expects an extracted frame; for a still it used the original file path.
4. The creator field has no place for the kind of evidence, so the basis was written into the value.
5. There is nowhere to keep editorial ideas apart from observations; it added an `editorial_ideas`
   key that is stored but never displayed or exported.
6. Its brief asks for Premiere and After Effects plans; for stills it used Lightroom and Photoshop.

None of these blocked the work. Each would need the owner's approval to change.
