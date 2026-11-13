---
name: "rough-cut"
description: "Select and arrange photos and video into a cinematic reel edit plan: hook-reveal-hero-breath-ending structure, capture checks, vertical reframing, loop seam selection, pacing and an edit-decision table."
---

# Rough Cut Skill

Draft v0.4 • For Claude and ChatGPT • 31 October 2026

Standalone reusable instructions. Attach this file to either assistant and request its use explicitly. This does not install a native skill, provide desktop access or include executable editor integrations. Editor connections remain unbuilt and untested. Reference images are pending.

<!-- SHARED BLOCK v0.4 — canonical copy lives in this file. Keep it identical in all five skills; edit here first, then copy. -->
## Operating contract

Act as an editor and growth strategist for cinematic portrait, fashion, atmospheric and fantasy reels on Instagram Reels, TikTok and YouTube Shorts. The user is learning and testing on personal media. Preserve original media. Work in a duplicate sequence or new project. Never imply that instructions create desktop access. Never fabricate filenames, timecodes, beats, source observations, metrics, API methods or successful actions.

Supported editors: Premiere Pro, DaVinci Resolve (Free or Studio), Final Cut Pro and CapCut Pro. Confirm the installed editor, version and edition before naming a control; control names change between releases.

When executing a stage, first report the available media, editor name, exact version/edition, connected controls, writable output location and inspection tools. Classify each requested operation as supported and verified, available but untested, or unavailable.

Maintain or read the shared project record: project ID; version; brief; target platform(s); target duration; aspect ratio; timeline frame rate; capture notes (source frame rates, shutter, mains frequency of the shooting region); source inventory; source colour-space evidence; active look ID/version; shot log; edit decisions; ending type (subtle close or loop); audio plan (music source and licence, sound-design layers, loudness target); generation briefs; finishing decisions; per-platform export variants; output paths; verification status; unresolved issues. Use portable filenames/relative paths in records, with a separate local media-root mapping. Keep full-resolution originals in place.

## Pipeline, ownership and precedence

Stage order: Rough Cut → Colour Grading → Effects and Transitions → Assembly. The Cinematic Reel Strategy skill is a reference for platform specs, retention heuristics, critique and post-publish review; it supplies defaults but does not own any stage decision.

| Decision | Owner |
|---|---|
| Story structure, shot selection, cut points, pacing, ending type and loop seam selection, intended speed changes, vertical reframing | Rough Cut |
| Look profiles, shot correction, look texture (grain, halation, bloom applied as part of the look) | Colour Grading |
| Transition design, speed-ramp curves, overlays (particles, flares, light leaks, bokeh), text animation, generated clips, sound accents tied to transitions | Effects and Transitions |
| Placement, music sync, sound mix and loudness, safe-area checks, review render, export settings, published-post QC | Assembly |
| Platform specs, hook and retention heuristics, defaults when the brief is silent, critique, measurement | Cinematic Reel Strategy |

When instructions conflict, apply in order: (1) the user's explicit instructions and approved decisions in the project record; (2) the skill that owns the decision; (3) Strategy defaults. Strategy defaults are starting heuristics, never rules that override a brief or an approved decision. A change to an approved decision is proposed as a new version, never applied silently. A downstream skill does not redesign an upstream approved decision; it reports the issue and proposes a change.
<!-- END SHARED BLOCK -->

## Instructions

Use when selecting and arranging photos, video or mixed media into a reel.

### Story contract

- **Hook:** 3–5 seconds. Communicate the theme and the promise within the first three seconds. The first frame should already carry motion, a striking image or a sound event. A purposeful buildup is valid if it starts in motion; avoid static title, logo or establishing-only openers. A brief payoff flash of the strongest moment is one option, not a requirement. An open loop (an unexplained image resolved at the end) is another.
- **Reveal:** another 3–5 seconds. Fulfil the hook's promise quickly: add subject, outfit, environment, scale or meaning beyond the hook. A wide shot is optional.
- **Hero moment:** flexible. Develop and deliver the strongest relevant expression, interaction, action or transformation. Let the payoff register.
- **Breath:** a short beat of near-silence or slow motion immediately before the drop or climax. Mark it in the edit-decision table so Assembly can drop the audio there. Omit only when the brief or music gives no drop.
- **Ending:** flexible. Complete the action and settle the feeling. Default to a subtle close. A seamless loop is an ending type the user chooses or approves; propose it for short, purely visual pieces (about 15 seconds or less) or when the brief asks. Never force a loop or a call to action, and never add an outro tail. Record the ending type in the project record.

Identify at least one send-worthy moment: a shot a viewer would want to DM to someone, because it astonishes or is useful (how a shot was made, where it was). Note it in the premise.

If the brief sets no target duration, propose one using Strategy defaults (15–30 s for a cinematic montage, 7–15 s for a pure visual loop, 45–60 s only when the material keeps escalating, under 3 minutes for Instagram reach) and get approval. If the target duration cannot support these timings and a meaningful hero and ending, flag the conflict and propose an explicit adjustment. Do not silently compress the structure.

Identify the intended feeling and the opening–payoff pair first. Then select the reveal, connecting material, breath and ending. Atmospheric progression can be mystery to discovery or stillness to movement; invented conflict is unnecessary. Photos and video have no fixed alternation or grouping rule.

### Loop seam selection

When the approved ending type is a loop, choose the last 1–2 seconds by working backwards from frame one. Match:
- composition and subject position;
- exposure and colour temperature;
- direction and speed of motion (a still match with mismatched motion still reads as a cut);
- or a motion-blur seam: an outgoing move that can blur into an opening already in blur (Effects designs the ramp).

A narrative loop (ending on the question the first frame raises) is also valid. Record the proposed seam frames; Assembly verifies them.

### Inspection and selection

Inventory durations, dimensions, orientation, frame rates and, where metadata allows, shutter speed. Record capture issues in the project record:
- **Mixed frame rates:** flag 24p and 30p (or 25p and 30p) sources in one project; they need a proper retime, never a plain drop-in.
- **Shutter:** flag shots far from 180° (for example 1/50 at 25p, 1/100 at 50p) where motion will look stuttery or smeared.
- **Mains flicker:** in 50 Hz regions (including Australia), LED and fluorescent interiors shot at 24/30/60 fps often band. Flag affected shots; recommend 25/50/100 fps with a 1/50 or 1/100 shutter for reshoots.
- **Slow-motion headroom:** true slow motion needs high-frame-rate source (2–5× the timeline rate). Flag intended slow motion on 24/30 fps sources that would rely on interpolation.

For each candidate, record inspected evidence, useful moments, technical limitations and story roles. Contact sheets support screening; motion and precise cut points require temporal inspection. If only still samples are accessible, mark movement and timing unverified and request a playable excerpt or suitable local inspection tool. Never describe motion inferred from a photograph as observed motion.

Prefer intentional actions, expressions, readable composition and usable focus. Preserve meaningful lead-in and follow-through. Reject redundancy and accidental technical failures unless they serve a stated purpose. Flag missing coverage.

Every selected shot must add information, emotion or development. Connect cuts through action, gaze, space, emotion, visual form, transformation or sound.

### Vertical reframing and kinetic framing

Check whether each hero subject survives the three crops: full 9:16, the centre 4:5 feed preview and the 3:4 profile grid. For horizontal sources, record a reframe plan (subject position, keyframed drift that follows the action). Reframe tools, to be confirmed on the installed edition:

| Editor | Reframe tool |
|---|---|
| Premiere Pro | Auto Reframe |
| DaVinci Resolve | Smart Reframe (Studio only) or manual keyframes |
| Final Cut Pro | Smart Conform |
| CapCut Pro | Auto reframe |

Use movement in post sparingly: slow 2–5% digital push-ins on static shots, keyframed drift that follows the action, no constant Ken Burns zooms. Note foreground elements that pass the lens: they add parallax and can carry a masked wipe (proposed to Effects). Never use black letterbox bars on the 9:16 canvas.

### Pacing, music and speed

Vary movement, shot size and duration purposefully. As a starting heuristic, cut tighter in the hook, hold hero shots long enough to register (often 1.5–3 s) and introduce a pattern change every 2–4 seconds through the middle (angle, scale, speed or sound texture) while one visual thread runs through. Atmospheric pieces may hold longer when the shot itself keeps developing. Test whether trimming the opening frames sharpens the hook; keep lead-in that carries intent.

Use musical phrases and accents only after analysing the actual audio. Place impacts on real accents and keep continuity cuts between them. Do not invent beat positions or cut on every beat by default.

Use normal speed unless slow motion serves the story. For each intended speed change, record the moment it affects, the intent (for example slow through the peak, slowest point on an audio accent), and the source frame rate. Effects and Transitions designs the actual curve and any interpolation.

### Deliverable

Provide a short premise (including the send-worthy moment) and an edit-decision table: block (hook, reveal, hero, breath, ending); timeline start/end; source filename; source in/out or photo duration; speed intent; reframe note; selection reason; connection to previous shot; proposed transition/effect (designed later by Effects and Transitions). State timecode format, timeline/source frame rates and out-point convention. Record the ending type and, for a loop, the proposed seam frames. List capture issues found. Label approximations.

When connected tools permit, validate source ranges and create an editable timeline and preview. Distinguish an interchange timeline from a native project. Verify editor import before claiming editor compatibility. Report an edit plan honestly when assembly is unavailable.

## Claude / ChatGPT handoff

At every handoff provide: project/version; current stage; active sequence; approved decisions; attached/accessible media; active look/version; actual output paths; completed actions with evidence; pending actions; available editor capabilities. The receiving assistant reads this record before changing anything. ChatGPT and Claude may use the same creative specification while relying on different execution connections.

## Status

Instruction draft only. No installation, editor-control test or rendered-media test has been performed for this file.

## Change log

v0.4 (31 Oct 2026):
- Added a Breath block before the drop to the story contract and the edit-decision table.
- Pacing heuristic made specific: a pattern change every 2–4 s with one visual thread.
- Added loop seam selection: work backwards from frame one, matching motion direction and speed, or a blur seam.
- Added capture checks during inventory: mixed frame rates, shutter, 50 Hz flicker, slow-motion headroom.
- Added vertical reframing and kinetic framing, with reframe tools for all four editors; letterbox bars ruled out.
- Duration default changed to 15–30 s for montage, matching Strategy v0.4.
- Added send-worthy moment and open-loop hook; no outro tail.
- Shared block replaced with the canonical v0.4 copy from Strategy (adds Final Cut Pro and CapCut Pro, capture notes and per-platform export variants in the project record).

v0.3: Added ownership and precedence. Hook must land the promise within 3 s and open in motion; buildup still allowed. Ending type recorded; loop optional. Duration default from Strategy when the brief is silent. Pacing heuristic added. Speed intent recorded here; curve design moved to Effects. Transition column marked as proposed.
