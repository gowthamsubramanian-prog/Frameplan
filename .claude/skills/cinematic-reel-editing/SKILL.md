---
name: "cinematic-reel-editing"
description: "Platform specs, hook and retention heuristics, critique and post-publish review for cinematic short-form video (Reels, TikTok, Shorts). Reference layer for the Rough Cut, Colour Grading, Effects and Assembly skills."
---

# Cinematic Reel Strategy Skill

Draft v0.4 • For Claude and ChatGPT • 31 October 2026

Standalone reusable instructions. Attach this file to either assistant and request its use explicitly. This does not install a native skill, provide desktop access or include executable editor integrations. Editor connections remain unbuilt and untested.

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

## Use when

- No stage skill is attached and the user wants general planning, critique or advice.
- A stage skill needs a default the brief does not set (duration, frame rate, loudness, safe area).
- Reviewing a finished cut or its post-publish metrics.

## Evidence tiers

Label every factual claim with one tier and never promote a claim above its tier.

| Tier | Meaning | Example |
|---|---|---|
| Platform-confirmed | Stated by Meta/Instagram, TikTok or YouTube, or on record by Adam Mosseri | Instagram's top signals are watch time, likes and sends |
| Data study | Published analysis with a stated method | That Random Agency's t-tested audio comparison (March 2025) |
| Vendor data | A tool company analysing its own users; no independent check | OpusClip: 50–60% of drop-off happens in the first 3 s (Jan–Mar 2026 clips, skewed to talking-head content) |
| Practitioner | Editors' craft consensus, tutorials, software documentation | Ramp curves, sound stacks, film recipes |
| Weak | Widely repeated, no traceable method | Trending audio +29%/+42%; fixed skip or swipe benchmarks |

## Platform signals

Platform facts last verified 31 October 2026. Re-check official creator documentation before relying on them after 31 January 2027, or sooner when a platform announces ranking changes.

Platforms rank on attention, not polish, and none favours a format:
- **Instagram** [Platform-confirmed]: watch time, likes per reach, sends per reach (sends weigh slightly more for non-follower reach). Reels ranking also predicts watch-to-end, reshares and audio-page opens. **Skip rate** is an Insights diagnostic for drop-off in the first seconds; claims that it is a named ranking signal are unconfirmed and have been debunked. [Secondary, unverified: April 2026 Insights additions (share and skip rate, Views Over Time); the September 2026 ranking-principles series.]
- **TikTok** [Platform-confirmed]: watch duration, whether the video was finished, interactions (likes, shares, comments, follows), and diversity rules that avoid repetitive content and repeated sounds in a row. Follower count and past hits are not direct factors.
- **YouTube Shorts** [Platform-confirmed]: ranks on % of viewers who chose to view (viewed vs swiped away), average view duration and average % viewed, then likes and post-watch surveys. **Engaged views** are the monetisation measure, not a ranking signal; they exclude replays.
- **YouTube view counting** [Platform-confirmed]: since 31 March 2025 a public Shorts view counts every start or replay; since 24 August 2026 first-frame counting covers all YouTube formats. Compare performance across dates with engaged views. Average % viewed above 100% means people are replaying.

Instagram visibility reducers [Platform-confirmed]: low resolution, another app's watermark, borders, muted audio, mostly-text Reels, and content already posted on Instagram. Reels over 3 minutes are not recommended to non-followers.

Instagram originality [Platform-confirmed, April 2024]: accounts that repeatedly repost others' content without material change lose recommendations, and originals replace identical reposts. [Secondary, unverified, 30 October 2026]: content edited in other apps is not demoted unless a watermark is visible.

## Default retention structure (maps onto Rough Cut's story contract)

| Rough Cut block | Heuristic |
|---|---|
| Hook (3–5 s) | Theme and promise readable within 3 s. First frame carries motion, a striking image or a sound event. A brief payoff flash (10–15 frames of the strongest shot) is one option. Avoid static title, logo or establishing-only openers; a buildup is fine if it starts in motion. |
| Reveal (3–5 s) | Fulfil the hook's promise quickly with new information. Steady early retention followed by a sharp mid-video drop points to pacing, not the hook. |
| Hero | A pattern change every 2–4 s (angle, scale, speed or sound texture) while one visual thread runs through. Hold the payoff long enough to register (often 1.5–3 s). |
| Breath | A beat of near-silence or slow motion immediately before the drop or climax. |
| Ending | Subtle close by default. A seamless loop is an option the user approves, best for short visual pieces. No call-to-action tail; put CTAs in the caption or pinned comment. |

Length defaults when the brief is silent: 15–30 s for a cinematic montage; 7–15 s for a pure visual loop; 45–60 s only when the material keeps escalating; under 3 min on Instagram. Ranking depends on percentage watched, not length.

Trim test: check whether removing the opening frames sharpens the hook; keep lead-in that carries intent.

Send-worthiness: design at least one moment a viewer would want to DM to someone (astonishing, or useful such as "how this shot was done" or "save this location"). Consider a behind-the-scenes or breakdown companion post.

## Hook techniques

1. Payoff-first cold open.
2. Motion on frame one (push-in, subject crossing, ramp already decelerating).
3. Scale or contrast shock (macro → wide, silhouette → practical light).
4. Sound-first hook: hard transient, whispered line or natural sound. [Practitioner/unverified: speech in the first 3 s helps early retention while music-only openings help replays; source not confirmed in the October 2026 research.]
5. Text as a promise, not a title; one short line inside the safe area. Mostly-text Reels are recommended less.
6. Vertical-native hero shots.
7. Open loop: an unexplained image resolved at the end; doubles as a loop mechanism.

## Craft defaults (stage skills may override)

**Capture and frame rate.**
- Timeline 24 fps, or 25 fps in 50 Hz regions (including Australia, UK, Europe); 30 for sports or gaming.
- Shoot slow-motion sources at 2–5× the timeline rate: 50/60 for 2×, 100/120 for 4–5×.
- Keep shutter near 180° (1/50 at 25p, 1/100 at 50p) on real-time sections.
- **Flicker:** under LED or fluorescent light on 50 Hz mains, shoot 25/50/100 fps with a 1/50 or 1/100 shutter. 24/30/60 fps often bands indoors.
- **Instagram conflict:** Instagram's Help Center lists 30 fps as the Reel minimum. 24/25p uploads normally play; if playback stutters after upload, deliver 25p or conform properly to 30p.
- Never mix 24p and 30p sources without a proper retime.
- Clean speed = timeline fps ÷ source fps × 100 (60→24 = 40%, 120→24 = 20%, 100→25 = 25%, 120→30 = 25%).

**Speed ramps** (Effects designs them; use only when motivated): eased S-curve with deceleration starting 4–8 frames before the action peak, a hold at 20–40% through the peak, then a quicker ease-out. Put the slowest point on an audio accent or the silence before a drop. Prefer native high-frame-rate frames → frame blending → optical flow or AI interpolation.

| Editor | Ramp control | Interpolation | Audio on ramps |
|---|---|---|---|
| Resolve | Retime Controls → Retime Curve with Bezier keyframes | Retime & Scaling → Optical Flow (Speed Warp is Studio) | Muted on variable-speed clips; design separately |
| Premiere Pro | Time Remapping → Speed, split keyframes, Bezier (handles ~30–45°) | Time Interpolation → Frame Sampling / Frame Blending / Optical Flow | Detach and design separately |
| Final Cut Pro | Retime → Speed Ramp / Custom; Blade Speed | Video Quality → Frame Blending / Optical Flow / Machine Learning | Preserve Pitch on by default; detach for ramps |
| CapCut Pro | Speed → Curve (presets or custom) | Smooth slow-mo | Detach and re-sync |

Verify control names on the installed version.

**Pacing.** Variable cadence: tighter cuts in the hook, breathing holds on hero shots, re-accelerate into the climax. Align cuts to musical accents only after analysing the actual audio; never cut on every beat by default.

**Transitions.** Prefer transitions motivated by the footage: directional match cuts (matching motion vector, speed, scale), shape, colour or position matches, in-camera occlusion wipes, and blur-seam ramps. Treatments that now read as templated: generic glitch or RGB-split packs, transition packs, chained stock whip-pans on unmotivated cuts, zoom-punches on every beat, light leaks on every transition, long branded intros, fully one-click AI edits. Flares, particles, light leaks and bokeh remain valid when motivated by scene light, story or a fantasy world and used with restraint.

**Vertical framing.** Deliver 1080×1920 unless the brief says otherwise. Design for three crops: full 9:16, the centre 4:5 feed preview and the 3:4 profile grid (cover keeps faces and text inside the centred 1080×1440). Meta's safe area in proportions: keep the top ~14%, bottom 20–35% and ~6% each side clear. Do not use black letterbox bars: Instagram names borders as a visibility reducer. Get a scope feel through composition (negative space, layered depth, low angles), or use a full-bleed blurred background for a brief title beat.

**Look.** There is no house look. Candidate profiles for Colour Grading to propose: print-film (Kodak Vision3 negative through 2383-style print emulation), Portra-style warmth, raw-premium natural, and restrained complementary contrast. Heavy teal-orange and heavy one-click LUTs read dated. An approved look profile always wins. Several Resolve tools are Studio-only in recent versions, including Film Look Creator, Halation, Film Grain, Magic Mask, Speed Warp and Smart Reframe. Confirm the edition before recommending them.

**Sound.** A five-layer stack for hero moments: ambience bed, movement (whoosh), build (riser), impact (3–5 complementary samples), tail. Lead picture cuts with ambience crossfades 4–10 frames early. Drop audio for 4–12 frames before key impacts. Pan movement with on-screen direction in moderation; keep low end and voice centred and check mono. Phones reproduce little below ~150–250 Hz, so pair sub impacts with a 150–400 Hz layer. Default loudness ~−14 LUFS integrated, −1 dBTP (common mastering practice, not a published platform spec).

**Music choice (decision rule).**
- The widely shared "+29% reach / +42% engagement" trending-audio figure is Weak. The one transparent test (That Random Agency, March 2025) found no significant reach or engagement difference between original audio and named music.
- Default: hybrid. A licensed or trending track as the spine where it fits the mood, with original sound design layered on top.
- Reach experiments: lead with trending or in-app audio (Instagram predicts audio-page opens). Expect a diversity cost on TikTok when a sound is saturated.
- Brand and portfolio pieces: lead with original score or soundscape; it cannot be muted or pulled by licensing changes.
- Business accounts are often limited to commercial libraries (TikTok Commercial Music Library, Meta Sound Collection).

**Cross-posting.** Edit one master project. Export a clean, watermark-free version per platform, adjusting on-screen text and safe areas for each. Never upload a file carrying another app's watermark.

## Critique checklist

1. Static or slow opener that would raise skip rate or swipe-away.
2. Slow motion conformed from 24/30 fps source relying on optical flow (warping on edges, hands, hair, water).
3. Mixed frame rates or 50 Hz flicker.
4. LUT applied to uncorrected footage; look not matching the approved profile.
5. Grain or halation tuned on desktop that smears on phone.
6. Mix that disappears on phone speakers, collapses in mono, or clips.
7. Text or faces in UI dead zones; key subject lost in the 4:5 or 3:4 crop.
8. Instagram visibility reducers: another app's watermark, borders or letterbox bars, muted audio, mostly text, low resolution, a repost.
9. Instagram Reels over 3 minutes.
10. Templated transitions with no story motivation.
11. Call-to-action tail or outro that breaks a loop.
12. No moment worth sending.

Frame critique as proposals routed to the owning stage skill.

## Measurement loop

- Instagram: average watch time → sends per reach → likes per reach; skip rate and retention chart as diagnostics; views over time. Days 1–3 carry most views; reply to comments early.
- YouTube: viewed vs swiped away → average view duration → average % viewed. Use engaged views to compare across dates.
- TikTok: average watch time, % watched full video, For You traffic share.
- Change one variable per post (hook frame, opening sound, trending vs original audio, length, loop vs close, grade intensity) as matched pairs, and compare to the creator's own median of the last 10–20 similar posts. Platforms publish no official "good" skip or swipe thresholds.

## Evidence honesty

Use the evidence tiers above. Do not quote untraceable stats: trending audio +29%/+42% or +47%, "original audio 22% lower visibility", "original content gets 40–60% more distribution", "completion is 40%+ of TikTok's ranking weight", "60%+ completion = viral", jump cuts +32%, "sends = 3–5× likes", fixed skip or swipe benchmarks. TikTok's sound statistics (88% say sound is vital; 73% stop for sound) are 2020–2021 advertiser studies commissioned by TikTok. Platforms change often; re-check official creator documentation when currency matters.

## Resources appendix (prices for Sydney, verified 31 October 2026; re-check before buying)

| Tool | Price (AUD) | Notes |
|---|---|---|
| DaVinci Resolve Studio | A$375 one-time on Blackmagic AU (sale to 20 Nov 2026; normally A$469); confirm GST at checkout | Unlocks Film Look Creator, Halation, Film Grain, Magic Mask, Speed Warp, Smart Reframe, advanced scripting |
| Final Cut Pro (Mac) | A$499.99 one-time | Machine Learning interpolation, Smart Conform |
| Apple Creator Studio | A$19.99/mo or A$199/yr | FCP Mac + iPad, Logic Pro, Motion, Compressor |
| Premiere Pro | About A$29.99–A$53.99/mo depending on plan | Verify on Adobe AU plans page |
| CapCut Pro | About A$29.99/mo (third-party report) | Export watermark-free for Instagram |
| Meta Edits | Free | Watermark-free exports, per-Reel Instagram stats |
| Dehancer Pro | US$348/yr (about A$490/yr), 3 seats | Lifetime price conflicts across sources; verify |
| FilmConvert Nitrate | From US$119 per host (about A$170), one-time | Free watermarked trial; Black Friday sale likely |
| Epidemic Sound Creator | US$9.99/mo billed yearly | Own channels only, not client work or ads |
| Youlean Loudness Meter | Free | Use with CapCut, which has no native meter |

Free music: Meta Sound Collection, TikTok Commercial Music Library, YouTube Audio Library. For SFX, prefer libraries with separate risers, impacts/sub drops, whooshes and ambiences.

## Claude / ChatGPT handoff

At every handoff provide: project/version; current stage; active sequence; approved decisions; attached/accessible media; active look/version; actual output paths; completed actions with evidence; pending actions; available editor capabilities. The receiving assistant reads this record before changing anything.

## Change log

v0.4 (31 Oct 2026):
- YouTube signals corrected: ranking uses chose-to-view, average view duration and average % viewed; engaged views moved to monetisation. Added the 24 Aug 2026 view-counting change and the >100% % viewed loop indicator.
- Instagram skip rate reclassified as a diagnostic metric, not a confirmed ranking signal.
- Added Instagram's full visibility-reducer list and originality rules; secondary-only 2026 items labelled unverified.
- Letterbox bars dropped; scope feel via composition or blurred background.
- Added the Instagram 30 fps minimum conflict and the 25p/30p fallback.
- Length default changed to 15–30 s for montage; 45–60 s only with escalating material.
- "~8.5 s drop-off" removed; Facebook speech-in-first-3 s finding labelled unverified.
- Added five evidence tiers, including vendor data.
- Added send-worthiness, the breath block, 2–4 s pattern changes, open-loop hook and no-CTA ending.
- Trending-audio note turned into a hybrid decision rule.
- Added 50 Hz flicker and shutter guidance, mixed-frame-rate rule, Final Cut Pro interpolation names and an audio-on-ramps column.
- Added cross-posting step, more candidate looks, and a dated AUD resources appendix.
- Shared block marked canonical; supported editors extended to Final Cut Pro and CapCut Pro; platform facts date-stamped with a re-check date.

v0.3: Reframed as a reference layer under the stage skills. Defaults now yield to briefs and approved decisions. Loop ending made optional. Beat-cutting requires audio analysis. Print-film look demoted to a candidate profile. Resolve Studio-only tools flagged. Flares and overlays allowed when motivated.
