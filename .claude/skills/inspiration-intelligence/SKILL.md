---
name: inspiration-intelligence
description: Collect and analyse saved Instagram Reels, Pinterest pins/boards, YouTube videos, images and pasted creative reference links. Use when the user shares an inspiration, asks to import saved collections, recreate a video, search reference techniques, or update the shot manifest with new shot types.
---

# Inspiration Intelligence — Agent 00

Operate from the Cinematic Content Studio project root.

## Ingest
- `python3 tools/inspiration.py add 'https://...' --collection 'Saved Reels'`
- `python3 tools/inspiration.py import references.csv --collection 'Pinterest Ideas'`
- `python3 tools/inspiration.py list`
- `python3 tools/inspiration.py search 'portal silhouette slow push-in'`

Accepted CSV headers: `url,creator,title,notes,collection` (only `url` required). JSON imports may be an array of URLs or objects using those keys. Existing records are deduplicated by normalized source URL; URLs are stored intact separately from the comparison key. Do not erase user notes.

## Review
1. Fetch accessible public page information, using an authenticated browser session only with user permission. If the collection requires authentication and browser access is unavailable, request a user-supplied link list/export or downloaded video. Do not automate scraping behind access controls.
2. Preserve origin URL, creator handle and post title when verified. Mark missing creator as unknown.
3. For media, inspect multiple moments, timecodes and transitions; extract genuine frames when local media is supplied and ffmpeg is available. Respect creators' rights; do not redistribute their video.
4. Write JSON matching `references/analysis-schema.json` with provenance per observation. `access_status` is `reviewed_video`, `reviewed_images`, `metadata_only`, `blocked`, or `unreviewed`.
5. Save with `python3 tools/inspiration.py analyse analysis.json`; never pretend metadata-only review is a full video review.
6. Generate original, feasible creative adaptations; search the catalog before suggesting new themes.

## Shot manifest integration
- Generate a **separate** proposal CSV: `python3 tools/inspiration.py export-shots shot_proposals.csv`.
- Fields follow the existing manifest: `index,shot_id,start_time,end_time,shot_size,body_crop,camera_angle,camera_height,composition,model_movement,camera_movement,focal_length,recording_settings,actual_frame,sketch,confidence`; extra columns provide reference provenance and approval status.
- Match existing shot concepts semantically, not just by title. Only after the user explicitly approves, merge reviewed unique rows into a copy of the master manifest using the established storyboard workflow; do not overwrite originals.

## Creative Director handoff
For each recommendation send source IDs, links, exact observed evidence, genre, usable technique, practical recreation path, risks and uncertainty. IDEA APPROVAL happens before STYLE APPROVAL; never leak style recommendations into the idea stage.
