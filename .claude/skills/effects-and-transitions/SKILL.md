---
name: "effects-and-transitions"
description: "Design transitions, speed ramps, overlays, text animation, sound accents and AI-generated effect shots for cinematic reels in Premiere Pro, DaVinci Resolve, Final Cut Pro or CapCut Pro."
---

# Effects and Transitions Skill

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

### Generated effects

Use when preparing external text/image-to-video generation for selected moments. Keep the generator interchangeable: Seedance, Kling or another verified available model. Confirm the exact product/model intended by ambiguous names such as Astra.

For each effect record: story role; setup; transformation; consequence; source assets; identity/wardrobe invariants; environment; camera move; subject action; duration; aspect ratio; available first/last/reference-frame controls; prompt; unwanted changes; acceptance criteria; selected generation; cost/credit information when known.

Use only controls supported by the selected model. Prepare prompts and reference frames first. Submit paid generation only within the user's authorised scope. Review identity, anatomy, hands, fabric, water, camera motion, transition continuity and start/end usability. Colour-match generated clips to the approved look before finishing. Mark ungenerated shots as placeholders.

### Editorial transitions and composited effects

Use this skill also for match cuts, dissolves, motivated wipes, speed ramps, overlays, particles, light flares, bokeh, text animation and motion graphics. Start from the proposed transition/effect in the Rough Cut edit-decision table. Choose the simplest treatment that serves the story. An ordinary editorial transition does not require AI video generation.

Prefer transitions motivated by the footage:
- **Directional match cuts:** matching motion vector, speed and scale across the cut; keep screen direction consistent so the eye carries momentum.
- **Shape, colour, luminance or position matches.**
- **Occlusion and masked object wipes:** a foreground object (pole, person, doorframe) wipes the frame and the cut or mask hides behind it, finished with a short directional blur and a sound accent.
- **Blur-seam ramps:** ramp shot A up into motion blur, cut at peak blur, and ramp shot B down out of blur moving in the same direction. Also the main tool for loop seams.
- **Flash, flare and light transitions:** only when a real light source in frame motivates them.

Mask and tracking tools, to be confirmed on the installed edition:

| Editor | Masked wipe / object isolation |
|---|---|
| Premiere Pro | Effect masks with mask tracking; After Effects for complex roto |
| DaVinci Resolve | Magic Mask (Studio only), Power Windows with tracker, or Fusion |
| Final Cut Pro | Draw Mask and the object tracker |
| CapCut Pro | Mask with keyframes |

Avoid treatments that now read as templated: generic glitch or RGB-split packs, transition packs, chained stock whip-pans on unmotivated cuts, zoom-punches on every beat, light leaks on every transition, fully one-click AI edits. Flares, particles, light leaks and bokeh remain valid when motivated by scene light, the story or the fantasy world and used with restraint. A transition must never be more impressive than the shots on either side of it.

For each transition specify outgoing/incoming shots, story purpose, verified cut position, duration, required handles, movement direction, focal-point continuity and whether it changes total runtime. Do not move an approved cut point; if a transition needs one moved, propose the change to Rough Cut.

### Speed ramps

Implement the speed intent recorded in Rough Cut. For each speed change specify source frame rate, speed curve, interpolation method and audio handling; verify motion rather than promising smoothness.

Curve rules:
- Eased S-curve, never linear jumps: deceleration beginning 4–8 frames before the action peak, a hold at 20–40% through the peak, then a quicker ease back out.
- Put the slowest point on an audio accent, a hit, or the silence before a drop. Check alignment frame by frame with audio scrubbing; a few frames off reads as sloppy.
- Hide where the ramp starts inside motion blur or a camera move.
- In Premiere, split the speed keyframe and rotate the handles about 30–45° for a smooth S-curve.

| Editor | Ramp control | Interpolation options | Audio on ramps |
|---|---|---|---|
| DaVinci Resolve | Retime Controls (Ctrl/Cmd+R) → Retime Curve, Bezier | Frame Blend, Optical Flow; Speed Warp (Studio) | Muted on variable-speed clips |
| Premiere Pro | Time Remapping → Speed, split keyframes | Frame Sampling, Frame Blending, Optical Flow | Stretched or dropped; detach |
| Final Cut Pro | Retime → Speed Ramp / Custom; Blade Speed (Shift+B) | Frame Blending, Optical Flow, Machine Learning | Preserve Pitch on by default |
| CapCut Pro | Speed → Curve (presets or custom) | Smooth slow-mo | Detach and re-sync |

Interpolation order of preference: native high-frame-rate frames, then frame blending, then optical flow or machine-learning interpolation. After any optical-flow or AI retime, inspect edges, hands, hair, water, occlusions and spinning objects for warping; reject or shorten affected sections. Confirm options on the installed editor and edition.

Audio: for every ramp, detach or mute the clip's own audio and specify a designed replacement (whoosh into the ramp, impact or silence at the slowest point, tail out) in the sound-accent list.

### Overlays, text and texture boundaries

For overlays and graphics specify asset, timing, track/layer, opacity, blend mode, mask/tracking requirements, position/scale, keyframes, font/style and safe placement. Keep text and key elements inside the platform safe area (see Assembly). Keep on-screen text to one short line where possible; mostly-text Reels are recommended less on Instagram.

Look texture (grain, halation and bloom across the whole piece) belongs to the Colour Grading look profile; do not add or change it here. Effect-specific glow or bloom on an overlay or generated element is part of that effect. Review overlays across motion and skin, not just a still. Add camera-shake layers only on impacts.

### Sound accents

For each transition, ramp or effect that needs a sound accent, specify the layer type (whoosh, riser, impact, sub drop, tail, foley sweetener), sync point, intended length and panning direction relative to on-screen motion. Whoosh pitch and length match the speed of the motion. Risers end exactly on the cut or drop with the tail cut dead. Sub impacts need a paired 150–400 Hz layer to read on phone speakers. Mark silences (4–12 frames before a key impact). Assembly places and mixes these.

Prefer available native editor effects and reusable approved assets where suitable. Verify exact editor/version/edition support before naming controls or applying effects. If execution tools are available, create and test the treatment in a duplicate sequence; otherwise label it planned and provide precise implementation instructions.

### Handoff to Assembly

Provide an effects-and-transitions table with IDs, source/target shots, timeline positions, durations/handles, actual asset paths, approved parameters, interpolation method and verification, editability/baked status, sound accents and silences, and verification results. Include generated clips and graphics when actually produced. Assembly places the approved elements and verifies the combined sequence. Mark missing outputs as placeholders.

## Claude / ChatGPT handoff

At every handoff provide: project/version; current stage; active sequence; approved decisions; attached/accessible media; active look/version; actual output paths; completed actions with evidence; pending actions; available editor capabilities. The receiving assistant reads this record before changing anything. ChatGPT and Claude may use the same creative specification while relying on different execution connections.

## Status

Instruction draft only. No installation, editor-control test or rendered-media test has been performed for this file.

## Change log

v0.4 (31 Oct 2026):
- Added audio handling for every speed ramp (Resolve mutes variable-speed audio; Final Cut Pro preserves pitch by default).
- Added ramp timing rules: slowest point on an audio accent, ramp start hidden in blur or a camera move, Premiere handles 30–45°, frame-by-frame audio check.
- Added the blur-seam transition, including for loop seams.
- Added mask and object-wipe tools for all four editors.
- Updated Final Cut Pro interpolation names (Frame Blending, Optical Flow, Machine Learning) and added a per-editor ramp table.
- Added an interpolation check on edges, hands, hair and water.
- Flash and flare transitions allowed only when a real light source motivates them; transition packs and one-click AI edits added to the templated list.
- Sound-accent spec extended: sub-drop pairing, dead-cut riser tails, marked silences, foley sweeteners.
- Shared block replaced with the canonical v0.4 copy from Strategy.

v0.3: Added ownership and precedence. Transition restraint list added; motivated flares and particles still allowed. Speed-ramp curve design owned here, from Rough Cut's intent. Look texture handed to Colour Grading. Sound-accent spec added. Cut points stay with Rough Cut.
