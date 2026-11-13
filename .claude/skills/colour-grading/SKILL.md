---
name: "colour-grading"
description: "Build and apply look profiles for cinematic reels from reference images: shot correction, film emulation, LUT and texture recipes for Premiere Pro, DaVinci Resolve, Final Cut Pro and CapCut Pro."
---

# Colour Grading Skill

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

Use when analysing reference images, building a persistent look profile, correcting shots or applying a saved look in Premiere Pro, DaVinci Resolve (Free or Studio), Final Cut Pro or CapCut Pro.

### Build and lock a look library

When references arrive, group them by coherent look and scene conditions. Do not average incompatible references into one grade. Assign a stable look ID and version. Preserve the source images alongside each profile so the visual intent remains inspectable.

For each profile record:

| Field | Required content |
|---|---|
| Look identity | ID, version, descriptive name and status: proposed or user-approved |
| Reference evidence | Filenames and which visual attributes each supports |
| Intended use | Scene types, lighting and source conditions |
| Tonal intent | Black level, contrast shape, midtones, highlight roll-off |
| Colour intent | Shadow/midtone/highlight bias; palette; saturation relationships |
| Skin intent | Natural hue relationships, brightness and permitted creative treatment |
| Texture | Grain (size, strength), softness, bloom or halation, stored separately from colour transforms |
| Limits | Elements caused by lighting, wardrobe, lens or production design that grading cannot reproduce |
| Technical assumptions | Input encoding, working/output spaces, expected transform placement, editor and edition |
| Approval/version | What is fixed, what may vary per shot and change history |

Until approved, call it a candidate profile. Once approved, preserve its creative intent. Shot-level exposure, white balance and matching remain adaptable. A change to the approved palette or contrast intent creates a proposed new version; it must not overwrite the approved one. A saved look is reusable instructions and assets, not model training or guaranteed memory across chats.

### Candidate looks without references

There is no house look. If no references are supplied, offer two or three candidate profiles suited to the brief and treat each as proposed until approved:

| Candidate | Character | Best for |
|---|---|---|
| Print film | Kodak Vision3-style negative through 2383-style print emulation (or Fuji 3513): dense mids, soft highlight roll-off, slightly lifted neutral blacks, warm skin, cyan-leaning shadows, restrained halation and fine grain | Atmospheric, fantasy, narrative |
| Portra-style warmth | Gentle contrast, warm and flattering skin, soft pastel highlights | People, lifestyle, fashion |
| Raw-premium natural | Restrained contrast, accurate skin, light filmic texture | Authentic-feeling content, documentary portraits |
| Restrained complementary contrast | Subtle warm/cool split between skin and background | Urban, night, travel |

Heavy saturated teal-orange and heavy one-click LUTs now read dated; propose them only when the brief asks. Retro, VHS or Super-8 textures are a style choice for nostalgia pieces, not a premium default. An approved profile always overrides any Strategy default look.

### Source-to-reference workflow

1. Establish camera encoding from reliable metadata or user confirmation. Do not infer S-Log3/S-Gamut3.Cine merely from camera model. If encoding is unknown, request it or label any preview assumptions before grading.
2. Establish project colour management and delivery target; avoid double input/output transforms. Use an explicitly stated SDR delivery assumption only when appropriate and reversible.
3. Confirm the vertical reframe is done (from Rough Cut) before applying frame-dependent texture; halation and film-gate effects can misbehave when the image does not fill the frame.
4. Select representative source frames across shots and important exposure changes.
5. Correct exposure, white balance and shot consistency before the creative look. Balance first, then apply the look, so the grade does not jump shot to shot.
6. Compare source and reference tone, palette, saturation and skin. Distinguish visible characteristics from speculative numeric settings.
7. Translate the look into actual editor-supported operations. Any starting values are provisional until rendered and reviewed; do not claim a unique grade can be recovered from one reference.
8. Apply look texture last, after correction and the colour look: halation, then bloom, then grain (rules below).
9. Render test frames and short motion previews. Review skin, highlights, shadows, gamut, noise, banding and shot continuity. Use scopes when accessible; report when they are not.
10. Upload a short private or draft test to the target platform where possible and judge texture on a phone after platform compression; texture tuned on a desktop monitor often reads as smear or noise on a phone.
11. Refine the affected shots, then document actual applied settings and active look version.

### Texture rules

- **Halation:** use Highlights-Only mode where available. Inspect on practical lights and high-contrast edges first. Stop where it is noticeable on a lamp but not on a face.
- **Bloom/glow:** very light; heavy diffusion turns muddy after compression.
- **Grain:** platform encoders treat grain as detail and smear or block it. Use slightly larger, softer grain than for cinema delivery, at modest strength, and judge it after a test upload.
- Overdone grain and halation, and texture not tuned per shot, are the most common failures.

### Texture ownership

Look texture (grain, halation and bloom applied across the piece) belongs to the look profile and is owned by this skill. Effects and Transitions does not add or change it. Effect-specific glow on an overlay or generated element belongs to that effect. Generated clips are colour-matched to the approved look before finishing.

### Editor routes

Separate technical conversion, shot correction, creative look and finishing texture on every route.

| Function | Premiere Pro | DaVinci Resolve | Final Cut Pro | CapCut Pro |
|---|---|---|---|---|
| Colour-managed base | Lumetri with colour management (log auto-detect) | YRGB Color Managed or CST nodes (DWG/Intermediate → Rec.709) | Color & Effects, log conversion | Basic colour; LUT import |
| Film emulation | Lumetri Creative / LUTs; Dehancer or FilmConvert | Film Look Creator (Studio); 2383 print LUTs; Dehancer or FilmConvert | Custom LUT effect; Dehancer or FilmConvert | Filters/LUTs; built-in film presets |
| Halation | Third-party plugin | Halation ResolveFX or Film Look Creator (Studio) | Third-party plugin | Glow presets (approximate) |
| Grain | Lumetri Faded Film/noise; plugins | Film Grain ResolveFX (Studio) | Third-party / grain effects | Grain effect |

Confirm each tool is installed and available on the edition before naming it.

**Premiere Pro** is a proposed automation target. Inspect the installed version and available integration before applying Lumetri adjustments, LUTs, effects or keyframes. Map the recipe to documented operations; never invent APIs. If controls are unavailable, provide precise manual instructions and label them unapplied. Grain and halation usually need third-party plugins.

**DaVinci Resolve Free** is an assisted route by default. Check exact version/edition before promising scripting; Blackmagic's Resolve 21.1 release notes state advanced scripting requires Studio. Do not assume an external MCP or Python connection works in Free or bypass edition restrictions. Film Look Creator, Halation, Film Grain, Magic Mask and Smart Reframe are Studio-only in recent versions; in Free, build texture with supported tools or approved overlay assets, and label anything that requires Studio as unavailable. Resolve ships print-emulation LUTs such as Kodak 2383; confirm the input encoding each expects. [Price note, verified 31 Oct 2026: Resolve Studio is A$375 on Blackmagic AU until 20 Nov 2026, normally A$469.]

**Film Look Creator (Studio):** put it on its own node after balance and exposure correction. Core looks in Resolve 21 include Cinematic, Rochester, Akasaka, Elated, Vintage and Aurora. An exported LUT carries only Color Settings and Split Tone; halation, grain, flicker and gate weave cannot be baked. Apply after the vertical reframe, because Halation and Film Gate can misbehave when the image does not fill the frame.

**Final Cut Pro:** use Color & Effects for log conversion and correction, the Custom LUT effect for print emulation, and the Final Cut Pro versions of Dehancer or FilmConvert for halation and grain. Confirm the installed version.

**CapCut Pro:** suited to light grades. Import a tested LUT, then adjust with basic colour controls; grain and glow presets approximate texture only. Flag when the look needs node-based or masked work CapCut cannot do.

**Plugin choices** (confirm installed before naming):
- **Dehancer:** the widest range of profiled stocks (Vision3, Portra, CineStill, 2383/3513 print) and Film Compression for highlight roll-off; steepest learning curve. Covers Resolve, Final Cut Pro, Premiere and After Effects.
- **FilmConvert Nitrate:** camera-matched profiles and the simplest workflow; one-time licence per host, free watermarked trial.

A LUT can encode a global colour transform under stated input/output assumptions; it cannot encode tracked masks, exposure-dependent local corrections, grain, bloom or halation. Do not generate a supposedly universal LUT from visual similarity alone. Test any generated LUT before reuse and identify its expected input domain.

### Deliverable

Return the look profile, reference/source comparison, correction plan, editor-specific recipe, applied settings if any, before/after evidence if rendered, phone/compression check result, verification status and remaining limitations. Never claim a generated styled still proves the actual video has been graded.

## Claude / ChatGPT handoff

At every handoff provide: project/version; current stage; active sequence; approved decisions; attached/accessible media; active look/version; actual output paths; completed actions with evidence; pending actions; available editor capabilities. The receiving assistant reads this record before changing anything. ChatGPT and Claude may use the same creative specification while relying on different execution connections.

## Status

Instruction draft only. No installation, editor-control test or rendered-media test has been performed for this file.

## Change log

v0.4 (31 Oct 2026):
- Editor coverage widened to Final Cut Pro and CapCut Pro, with a four-editor function table.
- Added candidate looks: Portra-style warmth, raw-premium natural, restrained complementary contrast; heavy teal-orange flagged as dated.
- Added texture rules: halation Highlights-Only and the lamp-not-face test, light bloom, larger softer grain for compression.
- Added Film Look Creator pitfalls: own node after balance, LUT export limits, apply after vertical reframe.
- Added a platform test-upload step to the phone check.
- Named plugin routes (Dehancer, FilmConvert Nitrate) and added a dated Resolve Studio price note.
- Shared block replaced with the canonical v0.4 copy from Strategy.

v0.3: Added ownership and precedence. No house look; print-film look is a candidate only. Texture ordering and ownership defined. Phone-screen review added. Resolve Studio-only tools flagged.
