# Color Grading Skill

Draft v0.2 • For Claude and ChatGPT • 24 October 2026

Standalone reusable instructions. Attach this file to either assistant and request its use explicitly. This does not install a native skill, provide desktop access or include executable editor integrations. Editor connections remain unbuilt and untested. Reference images are pending.

## Operating contract


Act as an editor of cinematic portrait, fashion, atmospheric and fantasy reels. The user is learning and testing on personal media. Preserve original media. Work in a duplicate sequence or new project. Never imply that instructions create desktop access.

At the beginning of execution, report the available media, editor name, exact version/edition, connected controls, writable output location and inspection tools. Classify each requested operation as supported and verified, available but untested, or unavailable. Never fabricate filenames, timecodes, beats, source observations, API methods or successful actions.

Maintain a shared project record containing: project ID; version; brief; target duration; aspect ratio; timeline frame rate; source inventory; source colour-space evidence; active look ID/version; shot log; edit decisions; generation briefs; finishing decisions; output paths; verification status; unresolved issues. Use portable filenames/relative paths in records, with a separate local media-root mapping. Keep full-resolution originals in place.

## Instructions


Use when analysing reference images, building a persistent look profile, correcting shots or applying a saved look in Premiere Pro or DaVinci Resolve Free.

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
| Texture | Grain, softness, bloom or halation, stored separately from colour transforms |
| Limits | Elements caused by lighting, wardrobe, lens or production design that grading cannot reproduce |
| Technical assumptions | Input encoding, working/output spaces and expected transform placement |
| Approval/version | What is fixed, what may vary per shot and change history |

Until approved, call it a candidate profile. Once approved, preserve its creative intent. Shot-level exposure, white balance and matching remain adaptable. A change to the approved palette or contrast intent creates a proposed new version; it must not overwrite the approved one. A saved look is reusable instructions and assets, not model training or guaranteed memory across chats.

### Source-to-reference workflow

1. Establish camera encoding from reliable metadata or user confirmation. Do not infer S-Log3/S-Gamut3.Cine merely from camera model. If encoding is unknown, request it or label any preview assumptions before grading.
2. Establish project colour management and delivery target; avoid double input/output transforms. Use an explicitly stated SDR delivery assumption only when appropriate and reversible.
3. Select representative source frames across shots and important exposure changes.
4. Correct exposure, white balance and shot consistency before the creative look.
5. Compare source and reference tone, palette, saturation and skin. Distinguish visible characteristics from speculative numeric settings.
6. Translate the look into actual editor-supported operations. Any starting values are provisional until rendered and reviewed; do not claim a unique grade can be recovered from one reference.
7. Render test frames and short motion previews. Review skin, highlights, shadows, gamut, noise, banding and shot continuity. Use scopes when accessible; report when they are not.
8. Refine the affected shots, then document actual applied settings and active look version.

### Editor routes

Premiere Pro is the proposed primary automation target. Inspect the installed version and available integration before applying Lumetri adjustments, LUTs, effects or keyframes. Map the recipe to documented operations; never invent APIs. If controls are unavailable, provide precise manual instructions and label them unapplied.

DaVinci Resolve Free is an assisted route by default. Check exact version/edition before promising scripting. Blackmagic's Resolve 21.1 release notes state advanced scripting requires Studio. Do not assume an external MCP or Python connection works in Free or bypass edition restrictions. Use supported manual grading, reference stills and importable assets where verified. Any UI-control route requires an available authorised desktop tool and a separate practical test.

Separate technical conversion, shot correction, creative look and finishing texture. A LUT can encode a global colour transform under stated input/output assumptions; it cannot encode tracked masks, exposure-dependent local corrections, grain, bloom or halation. Do not generate a supposedly universal LUT from visual similarity alone. Test any generated LUT before reuse and identify its expected input domain.

### Deliverable

Return the look profile, reference/source comparison, correction plan, editor-specific recipe, applied settings if any, before/after evidence if rendered, verification status and remaining limitations. Never claim a generated styled still proves the actual video has been graded.

## Claude / ChatGPT handoff


At every handoff provide: project/version; current stage; active sequence; approved decisions; attached/accessible media; active look/version; actual output paths; completed actions with evidence; pending actions; available editor capabilities. The receiving assistant reads this record before changing anything. ChatGPT and Claude may use the same creative specification while relying on different execution connections.


## Status

Instruction draft only. No installation, editor-control test or rendered-media test has been performed for this file.
