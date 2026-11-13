---
name: cinematic-reel-storyboard
description: Analyse a reference video and deliver a repeatable shoot plan with BOTH real extracted video frames AND hand-drawn-style storyboard sketches for every shot, precise framing, model and camera blocking, Sony A7 IV recreation settings, printable PDF, contact sheets, and downloadable image library. Designed for about 10 reels per month.
---
# Cinematic Reel Storyboard Skill v2.0

## Trigger
When a reference video is uploaded with a request for cinematic shot breakdown, camera/model moves, framing, storyboard, or shoot preparation. Shortcut: **Use my Cinematic Reel Storyboard skill on this video.**

## Saved defaults
- **Visual mode: DUAL REFERENCES, mandatory.** Each shot must have (A) an actual extracted frame from the user's video and (B) an original hand-drawn-style sketch depicting the framing and movement. Never quietly omit one type.
- **Workload: approximately 10 reels per month.** Optimise for efficient, repeatable production, not expensive per-shot AI calls.
- Camera: Sony A7 IV; Australian PAL-friendly settings (25/50/100 fps) unless otherwise requested.
- Deliver a shot-by-shot director/cinematographer plan, printable storyboard PDF, individual images, contact sheets, ZIP and reusable checklist.
- Visual style for sketches: clean monochrome pencil/ink storyboard, 16:9 or reference aspect ratio, clear silhouette, horizon, thirds grid when useful, arrows and concise labels. These sketches are *interpretive production diagrams*, not claims about the original filming method.

## Inputs
Required: uploaded reference video. Optional: desired aspect ratio, reel duration, available lenses, shooting location, preferred mood, production crew, stabilisation gear, and whether to reproduce or reinterpret. Assume reasonable defaults when missing and identify assumptions.

## Mandatory process
1. Verify file path; inspect full video, metadata (length, fps, resolution, audio). Identify cuts and sample frames near every shot's middle plus start/end where motion is important. Never infer the entire movement solely from a contact sheet.
2. Number all identifiable shots and timecode ranges. Distinguish observed action from inferred camera motion. Mark uncertain cuts and directions as approximate.
3. For **EVERY** shot capture these fields:
   - Shot number, timestamp, story function and suggested duration.
   - Shot size: EWS / WS / MWS / MS / MCU / CU / ECU; **exact body crop** (e.g. knees-up).
   - Angle: frontal, profile, rear, three-quarter, over-shoulder; camera height (ground/waist/chest/eye/above) and tilt.
   - Composition: subject screen position, headroom, horizon, negative space, leading lines, foreground/background layers, lens perspective.
   - Model: start pose, gaze, hands, feet, walking/turning direction, fabric/hair cues, end pose and take variations.
   - Camera: starting placement, move direction, distance, speed, path (push/pull/track/orbit/locked), end framing, stabilisation.
   - Sony A7 IV recommended focal length, resolution, fps, shutter, aperture, AF/stabilisation/ND; flag crop implications.
   - Transition to next shot, continuity, environmental and safety considerations; confidence/assumption flag.
4. Extract **one genuine source frame per shot** at minimum; name `shot_XX_actual_frame.jpg`. Add start/end source frames for complex actions.
5. Create **one hand-drawn-style storyboard sketch per shot**, named `shot_XX_storyboard_sketch.png`. Sketch should match the actual shot's subject position and crop and show a clear arrow for model motion and a differently styled arrow for camera motion, with a small legend. For locked camera, mark LOCKED. For unclear motion, label `SUGGESTED` or `INFERRED`. Sketches can be produced locally as original line-art diagrams (Pillow/SVG) at no external generation cost. If AI image generation is explicitly requested, explain potential billing before using separately metered services.
6. Pair the real frame and sketch **side by side** for each shot, with all mandatory shot details. The PDF must never contain an image-only shot without its camera and model instructions.
7. Produce a shoot-day preparation section: equipment checklist, A7 IV setup, weather/wind/light and tide notes if relevant, recommended filming order, model briefing, blocking and take counts, shot completion checkboxes.
8. Deliver files:
   - `<project>_Storyboard_and_Shoot_Plan.pdf` (cover, legend, overview, paired visuals for every shot, timeline, shooting plan, checklist)
   - `<project>_Dual_Contact_Sheet.jpg` (frame + sketch per shot)
   - `<project>_Actual_Frames.zip`
   - `<project>_Storyboard_Sketches.zip`
   - `<project>_Complete_Image_Library.zip` (both visual types, contact sheet and shot manifest)
   - `<project>_Shot_List.csv` (sortable production table)
   - Optional `README.txt` with image legend and filenames.
9. Validate: actual extracted frame count >= shot count; sketch count >= shot count; PDF pages and image placements; open and verify ZIPs; links only after files are confirmed present. If a ZIP download fails, provide direct contact-sheet JPG and PDF links.
10. Distinguish recreation recommendations from verified source-camera metadata. Sony A7 IV 4K 50/60p has Super 35 crop; 100/120p is Full HD. Normal shutter ~1/(2*fps); outdoors use ND where appropriate.

## Sketch specification
- White/off-white paper, graphite or ink outlines, uncluttered.
- Use consistent framing box and crop; show camera-facing perspective, subject silhouette, horizon and scene geometry.
- Solid arrow = model direction; dashed arrow = camera movement; circular arrow = orbit; `LOCKED` = stationary camera.
- For camera movement too complex to show within one image, include small top-down blocking inset or start/end mini-panels.
- Include shot ID and framing label in sketch. Never present a generated drawing as an actual extracted frame.

## Cost-aware monthly operating plan (10 reels)
- Default to local frame extraction, local diagram sketches, local PDF/ZIP creation: **no separately metered API calls required**.
- ChatGPT subscription usage/limits may apply; do not promise unlimited video processing or a guaranteed zero effective cost.
- For planning, expect about 10 times the per-reel shot count (e.g. 14 shots/reel = 140 source frames and 140 sketches/month), plus 10 PDFs and 10 library ZIPs. This is a workload example, not a quota or charge estimate.
- If optional external image/video AI is chosen, request model and pricing before forecasting charges; never invent token/credit costs.

## Quality gates (all must pass)
- EVERY shot has both a genuine frame and an original sketch, clearly labelled.
- EVERY shot specifies exact framing, composition, model direction, camera direction, and practical settings.
- All shot counts agree across PDF, CSV, sketches, real frames, and ZIP manifests.
- Timing and movement uncertainty is visible.
- PDF is readable on phone and print; direct downloadable files are verified.
- Do not claim the skill was installed account-wide unless installation is actually confirmed.
