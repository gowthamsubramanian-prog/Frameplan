BEGIN TRANSACTION;
CREATE TABLE agent00_refs (
  ref_id         TEXT PRIMARY KEY,             -- REF-000001, stable
  inspiration_id TEXT NOT NULL REFERENCES inspirations(id),
  url            TEXT NOT NULL,                -- original URL exactly as Agent 00 stored it
  is_duplicate   INTEGER NOT NULL DEFAULT 0,   -- 1 = same post as an earlier REF
  source_updated_at TEXT,                      -- Agent 00's updated_at at last sync
  first_synced_at TEXT NOT NULL,
  last_synced_at  TEXT NOT NULL
);
INSERT INTO "agent00_refs" VALUES('REF-000001','INS-0001','file:media/incoming/1000162216.jpg',0,'2026-11-13T20:51:25.524430+00:00','2026-11-13T20:52:13Z','2026-11-13T20:52:13Z');
INSERT INTO "agent00_refs" VALUES('REF-000002','INS-0002','file:media/incoming/1000162212.jpg',0,'2026-11-13T20:51:25.588660+00:00','2026-11-13T20:52:13Z','2026-11-13T20:52:13Z');
CREATE TABLE agent_runs (
  id         TEXT PRIMARY KEY,                 -- RUN-0001
  project_id TEXT REFERENCES projects(id),
  agent      TEXT NOT NULL,
  model      TEXT,
  stage      TEXT,
  status     TEXT NOT NULL CHECK (status IN ('started','succeeded','failed')),
  summary    TEXT,
  output_ref TEXT,
  tokens_in  INTEGER,
  tokens_out INTEGER,
  error      TEXT,
  started_at TEXT NOT NULL,
  finished_at TEXT
);
CREATE TABLE approvals (
  id          TEXT PRIMARY KEY,                -- APR-0001
  project_id  TEXT REFERENCES projects(id),
  gate        TEXT NOT NULL CHECK (gate IN
                ('concept','style','asset_change','paid_generation','export','publish','manifest_update')),
  subject_ref TEXT,                            -- DOC-/MPR-/PUB- id being approved
  summary     TEXT NOT NULL,
  status      TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','approved','rejected')),
  max_cost_usd REAL,                           -- paid_generation only
  uses_total  INTEGER,                         -- paid_generation only: tool calls authorised
  uses_left   INTEGER,
  over_budget INTEGER NOT NULL DEFAULT 0,
  user_quote  TEXT,                            -- the user's own words when deciding
  requested_at TEXT NOT NULL,
  decided_at  TEXT
);
INSERT INTO "approvals" VALUES('APR-0001',NULL,'manifest_update','RSH-0001,RSH-0002','2 reference shot(s)','approved',NULL,NULL,NULL,0,'1. Approve','2026-11-13T20:57:42Z','2026-11-13T20:57:42Z');
INSERT INTO "approvals" VALUES('APR-0002','PRJ-0002','concept','DOC-0002','IDEA APPROVAL: The line that never stopped a forklift (30 s, three beats)','rejected',NULL,NULL,NULL,0,'STOP. Do not approve or continue the forklift safety concept. The test has failed its input relevance requirement.','2026-11-13T21:05:55Z','2026-11-13T21:10:33Z');
INSERT INTO "approvals" VALUES('APR-0003','PRJ-0001','concept','DOC-0003,DOC-0004,DOC-0005','Choose one of three candle-portrait concepts: A Vigil, B The Candle-Bearer, C Offering','approved',NULL,NULL,NULL,0,'I accept the amendment, keep the items, approve concept A','2026-11-13T21:11:33Z','2026-11-13T21:35:44Z');
INSERT INTO "approvals" VALUES('APR-0004','PRJ-0001','style','DOC-0006','Choose a style treatment for Vigil: 1 Ember, 2 Cold Hours, 3 Until Dawn','approved',NULL,NULL,NULL,0,'Approve 1 and blend 2 in. I do prefer some AI generated images','2026-11-13T21:35:44Z','2026-11-13T21:41:18Z');
INSERT INTO "approvals" VALUES('APR-0005','PRJ-0001','paid_generation','PRM-0001,PRM-0002,PRM-0003','3 AI preview stills for Vigil on idea.ai, Seedream 4.5, 690 coins each = 2,070 coins. USD equivalent not known (connector gives no dollar price); max-cost recorded as 0 because the owner gave no USD cap, so the USD budget does not reflect this spend.','approved',0.0,3,0,0,'Approve 3 preview images','2026-11-14T08:45:37Z','2026-11-14T08:45:37Z');
CREATE TABLE assets (
  id           TEXT PRIMARY KEY,               -- AST-0001
  project_id   TEXT REFERENCES projects(id),
  kind         TEXT NOT NULL CHECK (kind IN
                 ('footage','photo','reference','generated','audio','lut','export','other')),
  rel_path     TEXT NOT NULL,                  -- portable path; media root mapped separately
  content_hash TEXT UNIQUE,                    -- sha256 when the file was readable
  bytes        INTEGER,
  meta_json    TEXT,
  created_at   TEXT NOT NULL
);
INSERT INTO "assets" VALUES('AST-0001','PRJ-0001','generated','https:/modality-cdn.idea.ai/mcp/textToImage/27709881/3M5ggkekRxaoIeCW9ZJKpFkW0hl.jpeg',NULL,NULL,'{"generation_id":"3M5ggfJQWbf1GGRcNYLGMVFnWWB","provider":"idea_ai","model":"seedream_4_5","size":"1728x2304","aspect":"3:4, crop to 4:5","purpose":"style preview, beat 1","note":"hosted by idea.ai; not downloaded because this session''s network blocks the host"}','2026-11-14T08:47:02Z');
INSERT INTO "assets" VALUES('AST-0002','PRJ-0001','generated','https:/modality-cdn.idea.ai/mcp/textToImage/27709881/3M5gheAUCHzs19giTqcoitOSrRU.jpeg',NULL,NULL,'{"generation_id":"3M5ghbotVktwenGcfkOaicZYAgz","provider":"idea_ai","model":"seedream_4_5","size":"1728x2304","aspect":"3:4, crop to 4:5","purpose":"style preview, beat 2","note":"hosted by idea.ai; not downloaded because this session''s network blocks the host"}','2026-11-14T08:47:02Z');
INSERT INTO "assets" VALUES('AST-0003','PRJ-0001','generated','https:/modality-cdn.idea.ai/mcp/textToImage/27709881/3M5gi9XVN12oQjR9mcxlP5vFaka.jpeg',NULL,NULL,'{"generation_id":"3M5gi8wjbhewcsLbpn3E5CIV7Bb","provider":"idea_ai","model":"seedream_4_5","size":"1728x2304","aspect":"3:4, crop to 4:5","purpose":"style preview, beat 3","note":"hosted by idea.ai; not downloaded because this session''s network blocks the host"}','2026-11-14T08:47:03Z');
CREATE TABLE documents (
  id         TEXT PRIMARY KEY,                 -- DOC-0001
  project_id TEXT NOT NULL REFERENCES projects(id),
  kind       TEXT NOT NULL CHECK (kind IN
               ('research','concept','creative_direction','storyboard','shot_list',
                'production_plan','replication_breakdown','generation_spec','edit_plan',
                'motion_proposal','style_options','qa_report','caption','other')),
  variant    TEXT NOT NULL DEFAULT 'main',     -- allows multiple creative versions side by side
  version    INTEGER NOT NULL,
  status     TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','approved','superseded','rejected')),
  content    TEXT NOT NULL,                    -- JSON or markdown; never edited after insert
  author     TEXT,                             -- agent or 'user'
  created_at TEXT NOT NULL,
  UNIQUE (project_id, kind, variant, version)
);
INSERT INTO "documents" VALUES('DOC-0001','PRJ-0002','research','main',1,'draft','# Research ledger — "Why forklift and pedestrian segregation matters"

Researched 14 November 2026 by web search. **Limitation:** this session''s network blocks outside
hosts, so no source document was opened. Every entry below rests on search-result excerpts, not
on a reading of the document. Each must be checked against the source before anything is rendered.

| # | Claim | Source | Confidence | On screen as |
|---|---|---|---|---|
| 1 | The best way to make sure people are not hit by a forklift is to keep them away from forklifts using physical barriers such as guardrails or overhead walkways | SafeWork NSW, Forklift safety guide for employers (SW08196) https://www.safework.nsw.gov.au/__data/assets/pdf_file/0017/602018/Forklift-safety-guide-employers_SW08196_0519.pdf | Medium: regulator source, excerpt only, document dated 2019 by filename | Paraphrase, credited to SafeWork NSW |
| 2 | The most effective way of ensuring people and vehicles move safely is to provide separate pedestrian and vehicle routes | SafeWork NSW, traffic management risk assessment page https://www.safework.nsw.gov.au/resource-library/transport-postal-and-warehousing/work-health-and-safety-in-the-road-freight-transport-industry/risk-assessment-traffic-management | Medium: excerpt only | Paraphrase |
| 3 | Exclusion zones: forklift-only areas in loading bays, pedestrian-only areas around tearooms, amenities and entrances | Safe Work Australia, Workplace traffic management information sheet https://www.safeworkaustralia.gov.au/sites/default/files/2021-04/Traffic-Management-Information-Sheet.PDF | Medium: excerpt only | Short list |
| 4 | The person operating the forklift should control the exclusion zone | Same information sheet | Medium: excerpt only | Paraphrase |
| 5 | Around loading, erect sturdy barriers such as fences or gates; the operator should not start until everyone is clear | SafeWork NSW, loading/unloading risk assessment page https://www.safework.nsw.gov.au/resource-library/transport-postal-and-warehousing/work-health-and-safety-in-the-road-freight-transport-industry/risk-assessment-loadingunloading-procedures | Medium: excerpt only | Paraphrase |
| 6 | Eliminating forklift and pedestrian interaction is the most effective control | WorkSafe Queensland incident alert, 2026 https://www.worksafe.qld.gov.au/news-and-events/alerts/incident-alerts/2026/workers-struck-by-forklifts-in-separate-incidents | Medium: excerpt only | Supports beat 2; not quoted |
| 7 | SafeWork SA: 81 serious injury notifications and 14 fatalities involving powered mobile plant over 2020-21 to 2024-25 | SafeWork SA incident alert, 6 Aug 2025 https://safework.sa.gov.au/news-and-alerts/safety-alerts/incident-alerts/2025/mobile-plant-and-pedestrians-dont-mix | **Low for this video:** excerpt only; covers all powered mobile plant in one state, not forklifts or pedestrians specifically | **Not used on screen** |

## Classification
- **Verified facts:** none yet. Claims 1 to 6 are regulator guidance known from excerpts; treat as "to verify".
- **Interpretation / opinion:** "a painted line does not stop a forklift"; "separation works when it does not depend on anyone paying attention". These are editorial framing, not legal requirements.
- **Creative simplification:** treating "barriers first, exclusion zones where barriers cannot be permanent" as a two-step rule.
- **Not found:** a national count of pedestrians struck by forklifts. No statistic is used.
- **Jurisdiction:** guidance cited is NSW and national model guidance; duties vary by state and are not stated as law in the video.
','motion-director','2026-11-13T21:05:54Z');
INSERT INTO "documents" VALUES('DOC-0002','PRJ-0002','motion_proposal','main',1,'rejected','# Idea proposal v1 — "Why forklift and pedestrian segregation matters"

**Thesis:** Separation works when it does not depend on anyone paying attention: a barrier protects a distracted person, a painted line does not.

**Working title:** The line that never stopped a forklift
**Hook (0-3 s):** "A painted line has never stopped a forklift."
**Audience:** Australian safety leaders, supervisors and frontline warehouse workers. Platform: LinkedIn, 9:16.
**Key message:** Put something physical between people and forklifts wherever you can; where you cannot, make the zone someone''s job to control.

**Beats and draft wording**
1. The shared floor — "Forklifts and people on the same floor rely on both noticing each other, every time."
2. What works best — "Regulators put physical separation first: guardrails, overhead walkways, separate routes."
3. Where a barrier cannot be permanent — "At the loading dock, set an exclusion zone. The operator controls it, and nothing moves until everyone is clear."

**Takeaway / CTA:** "Walk your site today. Where does safety depend on someone looking up?"

**Factual basis:** claims 1-5 of the research ledger (SafeWork NSW and Safe Work Australia guidance). No statistics. Known from search excerpts only; to be verified against the documents before rendering. The hook and thesis are editorial framing, not legal requirements.

**Suggested duration:** 30 seconds.
','motion-director','2026-11-13T21:05:55Z');
INSERT INTO "documents" VALUES('DOC-0003','PRJ-0001','concept','A',1,'approved','# Concept A — "Vigil"

**Premise:** A woman keeps a night-long vigil. The candles she carries burn down as she waits, and the wax records the hours.
**Story (stills series, or a 15–20 s reel):**
1. Hook — a single flame is lit in darkness, close on hands.
2. Reveal — the wax-laden shoulder with its lit candles; we see she is carrying the light herself.
3. Hero — head back, eyes closed, fingertips at her lips: the stillest moment of the wait.
4. Breath — eyes open, she looks down the shoulder at the flames; the candles are visibly shorter.
5. Ending — she blows the last flame out; a thread of smoke, then dark. Works as a loop back to the lighting.
**Drawn from the references (observed):** wax-dripped shoulder piece with two lit candles, chin-up eyes-closed pose with fingertips at the lips, over-the-shoulder three-quarter profile, blurred pillar candles behind (REF-000001); downcast gaze towards the shoulder flames (REF-000002).
**Original to this concept (suggested):** the passage of time shown by candle height; the lighting and blowing-out bookends.
**Deliverables:** 5–7 stills and one short reel from a single set.
**Real-flame demands:** two or three sets of candles pre-cut to different heights so "time passing" is staged, not waited for; rigid shoulder base; hair tied back.
**Difficulty:** medium.
','main session (Creative Director role not installed)','2026-11-13T21:11:33Z');
INSERT INTO "documents" VALUES('DOC-0004','PRJ-0001','concept','B',1,'rejected','# Concept B — "The Candle-Bearer"

**Premise:** She is the candelabra. A figure who has stood holding the light for so long that the wax has grown over her like a garment; then, for a moment, she wakes.
**Story (stills series, or a 12–15 s reel):**
1. Hook — extreme detail of wax and flame that reads as an object, not a person.
2. Reveal — the frame widens: the "object" is a shoulder, a neck, a face held statue-still.
3. Hero — perfect stillness in profile, eyes closed, as if carved; only the flames move.
4. Breath — a finger lifts and touches the wax.
5. Ending — her eyes open and meet the lens. Cut.
**Drawn from the references (observed):** the mass of dripped wax worn on the shoulder like a garment (REF-000001); candles standing directly on the shoulder with wax running down the arm (REF-000002); hand entering frame towards the shoulder (REF-000001).
**Original to this concept (suggested):** the object-to-person reveal; statue stillness broken by one small movement; a larger wax build extending to the collarbone and upper arm.
**Deliverables:** 4–6 stills and one short reel.
**Real-flame demands:** the most prop work of the three: a bigger pre-built wax piece on a rigid base; long held poses near flame mean short takes, a seated or supported model and an assistant within reach.
**Difficulty:** medium-hard.
','main session (Creative Director role not installed)','2026-11-13T21:11:33Z');
INSERT INTO "documents" VALUES('DOC-0005','PRJ-0001','concept','C',1,'rejected','# Concept C — "Offering"

**Premise:** Light is passed, not kept. She lights one candle from another until the dark room is full of small flames, and the last one she lights is the one she wears.
**Story (stills series, or a 15–20 s reel):**
1. Hook — one flame touching an unlit wick; the second catches.
2. Reveal — her face in the new light, eyes lowered to her hands.
3. Hero — she lifts a lit taper to the candles on her own shoulder and lights them.
4. Breath — hands lowered, eyes closed, the room now ringed with flames.
5. Ending — a wide frame: one small figure among many lights.
**Drawn from the references (observed):** hands as a leading element, and pillar candles as depth behind the subject (REF-000001); eyes lowered towards the flames, and a hand clasping the arm (REF-000002).
**Original to this concept (suggested):** the act of lighting as the story; many candles rather than two; a closing wide frame, which neither reference has. It can be styled plainly or with cultural wardrobe of your choosing; that is your decision and nothing is assumed.
**Deliverables:** 5–7 stills and one short reel.
**Real-flame demands:** the most open flame of the three: many candles on stable holders with clear floor around them, a taper for lighting, a fire blanket and extinguisher on set, hair tied back for the shoulder-lighting shot.
**Difficulty:** medium.
','main session (Creative Director role not installed)','2026-11-13T21:11:33Z');
INSERT INTO "documents" VALUES('DOC-0006','PRJ-0001','style_options','main',1,'approved','# Style treatments for Concept A "Vigil" (approved, DOC-0003)

Reference boards are internal working material and are never published or included in final output.
The catalog holds two references, so only treatments 1 and 2 have a reference behind them; treatment 3 has none.

## 1 — Ember (reference: REF-000001, credited Cap2red Studio per watermark)
- Mood: intimate, hushed, devotional.
- Lighting: warm and low-key; a soft dimmed key motivated by the candles, with real flames as visible practicals.
- Palette: amber skin against olive-black shadow; lifted matte blacks; cream wax; fine grain.
- Composition: tight over-the-shoulder three-quarter profile, 4:5, shallow depth of field, blurred pillar candles behind.
- Camera movement: very slow push-ins; otherwise still.
- Editing: long holds joined by slow dissolves, each dissolve landing on shorter candles.
- Trades away: distinctiveness (closest to the reference); an all-warm frame gives the candle shortening less contrast to read against.

## 2 — Cold Hours (reference: REF-000002, creator unknown, probably AI-generated)
- Mood: solitary, wakeful; the flame is the only warmth in a cold night.
- Lighting: cool soft key with a small orange accent on the cheek and jaw nearest the flames.
- Palette: teal-black background, true deep blacks, neutral-cool skin with one saturated orange area.
- Composition: more negative space; face and flames on a diagonal; square-safe framing inside 4:5.
- Camera movement: locked off, like a time-lapse position that never changes.
- Editing: hard cuts between identical frames as time jumps; only the candles and her posture change.
- Trades away: softness and warmth; needs a second, coloured light flagged tightly; a real photograph will look less neon than the reference.

## 3 — Until Dawn (no reference in the catalog; a suggestion)
- Mood: endurance giving way to release.
- Lighting: begins candle-only and warm; cool pre-dawn light slowly enters from one side until daylight overtakes the flame.
- Palette: amber and near-black at the start, moving to grey-blue with a small pale flame at the end.
- Composition: starts close, ends wider with the edge of a window or room visible.
- Camera movement: one slow pull-back across the piece.
- Editing: fewest cuts; match dissolves on the same pose as the light changes.
- Trades away: ease. Lighting continuity is the hardest of the three and needs a dimmable daylight source; no reference board can be shown for it.

Recommended: 3, Until Dawn, because it is the only treatment where the look itself tells the vigil''s story (the light changes as the night passes). If its difficulty is not wanted, 1 is the safest to execute.
','main session (Creative Director role not installed)','2026-11-13T21:35:44Z');
INSERT INTO "documents" VALUES('DOC-0007','PRJ-0001','creative_direction','main',1,'draft','# Approved look for "Vigil": Ember, with Cold Hours blended in

Owner''s decision, 14 Nov 2026: "Approve 1 and blend 2 in." What is taken from each is Claude''s
interpretation of the blend and is open to correction.

**From Ember (base, REF-000001):**
- Warm, low-key light on the face, neck and hands; real candle flames as visible practicals.
- Amber skin, cream wax, lifted matte blacks, fine grain.
- Tight over-the-shoulder three-quarter profile, 4:5, shallow depth of field, blurred pillar candles behind.
- Very slow push-ins; long holds joined by slow dissolves, each landing on shorter candles.

**Blended in from Cold Hours (REF-000002):**
- Background and shadow side pushed cool: teal-black instead of olive-black, so the warm flame-lit side stands out.
- A faint cool fill on the far side of the face, giving a warm–cool split.
- One locked-off repeated frame used as a time-jump device at the midpoint, where only the candle height and her posture change.

**Not taken from Cold Hours:** the saturated neon-orange cheek patch, and true clipped blacks. Ember''s matte finish is kept.

**Reference boards are internal only and never published.**
','main session (Creative Director role not installed)','2026-11-13T21:41:18Z');
INSERT INTO "documents" VALUES('DOC-0008','PRJ-0001','storyboard','main',1,'draft','# Storyboard — "Vigil" (PRJ-0001)

Built on the approved concept (DOC-0003, APR-0003) and the approved look, Ember with Cold Hours
blended in (DOC-0007, APR-0004). Real candles, as the owner decided. Written by the main session:
the shot-planner specialist is not built, and the Cinematic Reel Storyboard skill is for reference
videos, so neither was used.

**Deliverables:** one vertical reel of about 18 seconds and a stills set of 7 frames, from one set.
**Frame:** vertical 4:5 for stills; 9:16 for the reel (protect a 4:5 centre so frames can be shared).
**Structure:** hook, reveal, hero, breath, ending (the rough-cut skill''s structure).
**Time device:** three pre-cut candle sets (tall, half, stub) swapped between scenes. Nothing is
burned down for real; the story time is staged.

## Beats

| Beat | Reel time | What we see | Candles | Feeling |
|---|---|---|---|---|
| 1 Hook | 0:00–0:03 | Darkness. A match flares; hands bring it to the first wick on the shoulder | Tall, unlit to lit | Anticipation |
| 2 Reveal | 0:03–0:07 | Slow push-in over her shoulder: the wax piece, two flames, her lowered eyes | Tall | Discovery: she is carrying the light |
| 3 Hero | 0:07–0:12 | Head back, eyes closed, fingertips at her lips; flames flicker, she breathes | Half | Stillness, devotion |
| 4 Breath | 0:12–0:15 | Locked-off frame repeats: the candles are shorter, her posture has sunk; she opens her eyes and looks down at them | Half, then stub | Time passing |
| 5 Ending | 0:15–0:18 | She blows one candle out; smoke rises; then the last; black | Stub | Release |

**Loop option:** the final black cuts back to the match strike in beat 1. Owner''s choice at rough cut;
the default is a subtle close.

## Look, per the approved direction
- Warm amber on face, neck and hands from the flames and a dimmed warm key.
- A cool fill on the far side of the face. The AI previews suggest a "faint" fill will not read;
  plan for a clearly visible but low cool fill, and judge on the monitor.
- Teal-black background with two out-of-focus pillar candles 1–1.5 m behind.
- Lifted matte blacks and fine grain in the grade; do not crush blacks on set.
- Slow push-ins; long holds; slow dissolves, except the hard cut of the locked-off time jump.

## Lighting plan
| Light | Source | Position | Setting | Purpose |
|---|---|---|---|---|
| Practicals | Two candles on the shoulder piece; two pillar candles behind | — | Real flame | Motivation and sparkle |
| Key | Portable LED in a small softbox or through diffusion | 45° camera left, slightly above eye line, ~1 m | 2700–3200 K, a few percent output | Makes the candlelight readable on the face |
| Cool fill | Small LED panel or RGB tube | Camera right, far side of the face, low | ~6500 K or teal, very low; flag with black card | The Cold Hours split |
| Background | RGB tube or gelled LED aimed at the backdrop, not the subject | Behind subject, low | Teal | Teal-black separation |

Judgement on flicker: Australia''s mains are 50 Hz, so use shutter speeds of 1/50 or 1/100 with LED
sources, and check for banding on a test frame.

## Camera (Sony A7 IV)
- **Video:** 4K 25p full-width, shutter 1/50, S-Cinetone or S-Log3 (S-Log3 needs at least ISO 800;
  in this light expect ISO 1600–4000). The smoke shot at 4K 50p (Super 35 crop, about 1.5×; use
  the 50mm to keep the framing) or FHD 100p, shutter 1/100.
- **Stills:** RAW, 85mm at f/1.8–2.8, 1/125 or 1/160, ISO 1600–3200. Mechanical shutter if any
  LED bands with the electronic shutter.
- **White balance:** fixed, about 3800–4500 K, so the flames stay warm and the fill stays cool.
  Never auto.
- **Focus:** eyes closed in the hero shots will defeat Eye AF; use a small flexible spot on the
  lashes, or manual focus with peaking.
- **Support:** tripod for locked-off shots (essential for beat 4); slider or gimbal for push-ins.

## Real-flame safety (non-negotiable on set)
- The wax shoulder piece is pre-built on a rigid shoulder pad or foam cap and strapped on. **No
  hot wax touches skin.** The drips are part of the prop.
- Candles are fixed into the rigid base. Use short, wide candles and keep flames well clear of the
  face, ear and hair.
- Hair tied back on the candle side, with **no hairspray**. No loose fabric near the flames.
- Model seated or supported. Takes kept short; extinguish between set-ups.
- An assistant within reach throughout, with a fire blanket and extinguisher on set. Snuffer ready.
- Agree a stop word with the model. Stop at once if wax pools near skin or a flame leans in.

This is production guidance, not a substitute for the venue''s own fire rules.
','main session (shot-planner not built)','2026-11-14T09:04:01Z');
INSERT INTO "documents" VALUES('DOC-0009','PRJ-0001','shot_list','main',1,'draft','{
 "project": "PRJ-0001",
 "based_on": [
  "DOC-0003",
  "DOC-0007"
 ],
 "shooting_order": "by candle set: tall (shots 1-4), half (5-7, 14), stub (8-12); detail (13) at any point",
 "shots": [
  {
   "description": "HOOK, video. Darkness; a match flares and is brought to the first wick on the shoulder piece; the flame catches.",
   "beat": "hook",
   "type": "video",
   "duration_s": 3,
   "shot_size": "ECU",
   "body_crop": "hands, match and the two wicks; face out of frame",
   "camera_angle": "three-quarter from front-left",
   "camera_height": "shoulder",
   "composition": "flame centre-right in the 9:16 frame; hands enter from frame left; black around",
   "camera_movement": "locked",
   "model_movement": "hand brings the match in, holds, withdraws",
   "lens": "85mm (minimum focus 0.85 m) or a macro if available",
   "settings": "4K 25p, 1/50, f/2.8, ISO 1600\u20133200",
   "candles": "tall; first unlit, then lit",
   "lighting": "match and flame only at first; key fades up from zero (or set low throughout)",
   "notes": "Shoot three takes; strike the match out of frame to avoid flare in the lens",
   "camera": "Sony A7 IV"
  },
  {
   "description": "HOOK, still. Close detail of the wick catching, hands soft behind.",
   "beat": "hook",
   "type": "still",
   "shot_size": "ECU",
   "body_crop": "flame, wick and fingertips",
   "camera_angle": "side",
   "camera_height": "shoulder",
   "composition": "flame on a third; fingertips soft",
   "camera_movement": "n/a",
   "model_movement": "held",
   "lens": "85mm",
   "settings": "RAW, f/2, 1/160, ISO 1600",
   "candles": "tall",
   "lighting": "flame, low warm key",
   "notes": "Stills set frame 1",
   "camera": "Sony A7 IV"
  },
  {
   "description": "REVEAL, video. Slow push-in over her shoulder: the wax piece and two flames come into frame, then her lowered eyes.",
   "beat": "reveal",
   "type": "video",
   "duration_s": 4,
   "shot_size": "MCU to CU",
   "body_crop": "top of head to upper chest, ending at chin to shoulder",
   "camera_angle": "over-the-shoulder three-quarter profile from behind the candle shoulder",
   "camera_height": "shoulder",
   "composition": "subject weighted right; pillar candles soft at left",
   "camera_movement": "slow push-in, about 30 cm over 4 s, slider or gimbal",
   "model_movement": "eyes lowered to the flames, a slow breath",
   "lens": "85mm",
   "settings": "4K 25p, 1/50, f/2, ISO 2000\u20133200",
   "candles": "tall",
   "lighting": "full plan: key, cool fill, teal background, pillars",
   "notes": "The approved look''s signature frame",
   "camera": "Sony A7 IV"
  },
  {
   "description": "REVEAL, still. Over-the-shoulder three-quarter profile, eyes lowered to the flames.",
   "beat": "reveal",
   "type": "still",
   "shot_size": "MCU",
   "body_crop": "head to upper chest",
   "camera_angle": "over-the-shoulder three-quarter profile",
   "camera_height": "shoulder",
   "composition": "4:5; subject right two thirds; pillars left third",
   "camera_movement": "n/a",
   "model_movement": "held",
   "lens": "85mm",
   "settings": "RAW, f/2, 1/160, ISO 2000",
   "candles": "tall",
   "lighting": "full plan",
   "notes": "Stills set frame 2",
   "camera": "Sony A7 IV"
  },
  {
   "description": "HERO, still. Head back, eyes closed, fingertips resting at her lips; the main image of the set.",
   "beat": "hero",
   "type": "still",
   "shot_size": "CU",
   "body_crop": "top of head to shoulder; hand in frame",
   "camera_angle": "three-quarter profile from the candle side",
   "camera_height": "chin",
   "composition": "4:5; face upper right; flames lower centre; fingertips leading to the lips",
   "camera_movement": "n/a",
   "model_movement": "head back, eyes closed, lips parted, fingertips at lower lip",
   "lens": "85mm",
   "settings": "RAW, f/1.8\u20132.2, 1/125, ISO 2500",
   "candles": "half",
   "lighting": "full plan; check the cool fill reads on the far cheek",
   "notes": "Stills set frame 3 (hero). Its pose is close to REF-000001: change the hand and head angle so it is not a copy",
   "camera": "Sony A7 IV"
  },
  {
   "description": "HERO, video. The same pose held; very slow push-in; flames flicker; one breath.",
   "beat": "hero",
   "type": "video",
   "duration_s": 5,
   "shot_size": "CU",
   "body_crop": "top of head to shoulder",
   "camera_angle": "three-quarter profile from the candle side",
   "camera_height": "chin",
   "composition": "as the hero still, 9:16",
   "camera_movement": "very slow push-in, about 10 cm over 5 s",
   "model_movement": "stillness; one slow breath; slight head settle",
   "lens": "85mm",
   "settings": "4K 25p, 1/50, f/2, ISO 2500",
   "candles": "half",
   "lighting": "full plan",
   "notes": "Hold 8\u201310 s per take for editing room",
   "camera": "Sony A7 IV"
  },
  {
   "description": "BREATH, video, part 1. Locked-off medium shot; she sits upright, eyes closed, half candles.",
   "beat": "breath",
   "type": "video",
   "duration_s": 1.5,
   "shot_size": "MS",
   "body_crop": "head to waist",
   "camera_angle": "three-quarter front",
   "camera_height": "chest",
   "composition": "locked frame with headroom; candles clearly readable",
   "camera_movement": "locked \u2014 do not touch the tripod between parts 1 and 2",
   "model_movement": "upright, still",
   "lens": "50mm",
   "settings": "4K 25p, 1/50, f/2.8, ISO 3200",
   "candles": "half",
   "lighting": "full plan, unchanged between parts",
   "notes": "Mark the model''s position with tape",
   "camera": "Sony A7 IV"
  },
  {
   "description": "BREATH, video, part 2. The identical locked frame; candles now stubs; her posture has sunk; she opens her eyes and looks down at the flames.",
   "beat": "breath",
   "type": "video",
   "duration_s": 2,
   "shot_size": "MS",
   "body_crop": "head to waist",
   "camera_angle": "three-quarter front",
   "camera_height": "chest",
   "composition": "identical to part 1",
   "camera_movement": "locked",
   "model_movement": "shoulders lowered, head tilted, eyes open to the flames",
   "lens": "50mm",
   "settings": "as part 1",
   "candles": "stub (swap the candle set; keep the wax piece in place)",
   "lighting": "as part 1",
   "notes": "The hard cut between parts 1 and 2 is the time jump",
   "camera": "Sony A7 IV"
  },
  {
   "description": "BREATH, still. Eyes open, looking down the shoulder at the stub candles.",
   "beat": "breath",
   "type": "still",
   "shot_size": "CU",
   "body_crop": "face to shoulder",
   "camera_angle": "three-quarter front",
   "camera_height": "eye",
   "composition": "4:5; eyes to flames on a diagonal",
   "camera_movement": "n/a",
   "model_movement": "eyes lowered to the flames",
   "lens": "85mm",
   "settings": "RAW, f/2, 1/160, ISO 2500",
   "candles": "stub",
   "lighting": "full plan",
   "notes": "Stills set frame 4",
   "camera": "Sony A7 IV"
  },
  {
   "description": "ENDING, video, slow motion. She blows out one candle; a thread of smoke rises from that wick; the last flame still burns.",
   "beat": "ending",
   "type": "video",
   "duration_s": 3,
   "shot_size": "CU",
   "body_crop": "lips to shoulder",
   "camera_angle": "side",
   "camera_height": "shoulder",
   "composition": "the blown-out wick centre frame; smoke rising into black",
   "camera_movement": "locked",
   "model_movement": "a single gentle breath out at the nearer candle",
   "lens": "50mm at 4K 50p (crop), or 85mm at FHD 100p",
   "settings": "4K 50p or FHD 100p, 1/100, f/2.8, ISO 3200",
   "candles": "stub",
   "lighting": "key low; backlight the smoke with a small hard source from behind if available",
   "notes": "The AI preview put the smoke on the wrong candle; check the source on playback",
   "camera": "Sony A7 IV"
  },
  {
   "description": "ENDING, still. The smoke thread with the last flame still lit.",
   "beat": "ending",
   "type": "still",
   "shot_size": "CU",
   "body_crop": "lips, shoulder and both candles",
   "camera_angle": "side",
   "camera_height": "shoulder",
   "composition": "4:5; smoke on the upper third",
   "camera_movement": "n/a",
   "model_movement": "just after the breath",
   "lens": "85mm",
   "settings": "RAW, f/2.8, 1/200, ISO 3200, burst",
   "candles": "stub",
   "lighting": "key low, smoke backlight",
   "notes": "Stills set frame 5",
   "camera": "Sony A7 IV"
  },
  {
   "description": "ENDING, video. The last flame is blown out; the frame falls to black.",
   "beat": "ending",
   "type": "video",
   "duration_s": 2,
   "shot_size": "CU",
   "body_crop": "face and shoulder",
   "camera_angle": "three-quarter profile",
   "camera_height": "shoulder",
   "composition": "face lit only by the last flame",
   "camera_movement": "locked",
   "model_movement": "blows the last candle out",
   "lens": "85mm",
   "settings": "4K 25p, 1/50, f/2, ISO 3200",
   "candles": "stub, last one lit",
   "lighting": "key and fill off for this take; flame only, then black",
   "notes": "Possible loop seam back to the match strike; decided at rough cut",
   "camera": "Sony A7 IV"
  },
  {
   "description": "DETAIL, still. Hands and wax only: fingers resting on the drips, flames soft above.",
   "beat": "detail",
   "type": "still",
   "shot_size": "ECU",
   "body_crop": "hand and wax piece",
   "camera_angle": "top-side",
   "camera_height": "above shoulder",
   "composition": "4:5; drips leading lines down the frame",
   "camera_movement": "n/a",
   "model_movement": "fingers resting lightly on the wax",
   "lens": "85mm",
   "settings": "RAW, f/2.8, 1/160, ISO 1600",
   "candles": "any set",
   "lighting": "key raking across the wax",
   "notes": "Stills set frame 6",
   "camera": "Sony A7 IV"
  },
  {
   "description": "WIDE, still. One wider frame of the figure among the pillar candles, for the set''s closing image.",
   "beat": "detail",
   "type": "still",
   "shot_size": "MWS",
   "body_crop": "head to hips",
   "camera_angle": "three-quarter front",
   "camera_height": "chest",
   "composition": "4:5; figure right; pillars left; more of the teal-black space",
   "camera_movement": "n/a",
   "model_movement": "seated, eyes closed",
   "lens": "50mm",
   "settings": "RAW, f/2.8, 1/125, ISO 3200",
   "candles": "half",
   "lighting": "full plan; open the background light slightly",
   "notes": "Stills set frame 7",
   "camera": "Sony A7 IV"
  }
 ]
}','main session (shot-planner not built)','2026-11-14T09:04:02Z');
INSERT INTO "documents" VALUES('DOC-0010','PRJ-0001','shot_list','main',2,'draft','{
 "project": "PRJ-0001",
 "based_on": [
  "DOC-0003",
  "DOC-0007",
  "DOC-0009"
 ],
 "shooting_order": "by candle set: tall (shots 1-4), half (5-7, 14), stub (8-12); detail (13) at any point",
 "shots": [
  {
   "description": "HOOK, video. Darkness; a match flares and is brought to the first wick on the shoulder piece; the flame catches.",
   "beat": "hook",
   "type": "video",
   "duration_s": 3,
   "shot_size": "ECU",
   "body_crop": "hands, match and the two wicks; face out of frame",
   "camera_angle": "three-quarter from front-left",
   "camera_height": "shoulder",
   "composition": "flame centre-right in the 9:16 frame; hands enter from frame left; black around",
   "camera_movement": "locked",
   "model_movement": "hand brings the match in, holds, withdraws",
   "lens": "70mm (or 50mm if the 70 cannot focus this close)",
   "settings": "4K 25p, 1/50, f/2.8, ISO 1600\u20133200",
   "candles": "tall; first unlit, then lit",
   "lighting": "match and flame only at first; key fades up from zero (or set low throughout)",
   "notes": "Shoot three takes; strike the match out of frame to avoid flare in the lens; shoot with the camera mounted vertically (native 2160x3840)",
   "camera": "Sony A7 IV"
  },
  {
   "description": "HOOK, still. Close detail of the wick catching, hands soft behind.",
   "beat": "hook",
   "type": "still",
   "shot_size": "ECU",
   "body_crop": "flame, wick and fingertips",
   "camera_angle": "side",
   "camera_height": "shoulder",
   "composition": "flame on a third; fingertips soft",
   "camera_movement": "n/a",
   "model_movement": "held",
   "lens": "70mm",
   "settings": "RAW, f/2, 1/160, ISO 1600",
   "candles": "tall",
   "lighting": "flame, low warm key",
   "notes": "Stills set frame 1",
   "camera": "Sony A7 IV"
  },
  {
   "description": "REVEAL, video. Slow push-in over her shoulder: the wax piece and two flames come into frame, then her lowered eyes.",
   "beat": "reveal",
   "type": "video",
   "duration_s": 4,
   "shot_size": "MCU to CU",
   "body_crop": "top of head to upper chest, ending at chin to shoulder",
   "camera_angle": "over-the-shoulder three-quarter profile from behind the candle shoulder",
   "camera_height": "shoulder",
   "composition": "subject weighted right; pillar candles soft at left",
   "camera_movement": "locked on the tripod, camera mounted vertically; slow push-in added in the edit (about 15%)",
   "model_movement": "eyes lowered to the flames, a slow breath",
   "lens": "70mm",
   "settings": "4K 25p, 1/50, f/2, ISO 2000\u20133200",
   "candles": "tall",
   "lighting": "full plan: key, cool fill, teal background, pillars",
   "notes": "The approved look''s signature frame",
   "camera": "Sony A7 IV"
  },
  {
   "description": "REVEAL, still. Over-the-shoulder three-quarter profile, eyes lowered to the flames.",
   "beat": "reveal",
   "type": "still",
   "shot_size": "MCU",
   "body_crop": "head to upper chest",
   "camera_angle": "over-the-shoulder three-quarter profile",
   "camera_height": "shoulder",
   "composition": "4:5; subject right two thirds; pillars left third",
   "camera_movement": "n/a",
   "model_movement": "held",
   "lens": "70mm",
   "settings": "RAW, f/2, 1/160, ISO 2000",
   "candles": "tall",
   "lighting": "full plan",
   "notes": "Stills set frame 2",
   "camera": "Sony A7 IV"
  },
  {
   "description": "HERO, still. Head back, eyes closed, fingertips resting at her lips; the main image of the set.",
   "beat": "hero",
   "type": "still",
   "shot_size": "CU",
   "body_crop": "top of head to shoulder; hand in frame",
   "camera_angle": "three-quarter profile from the candle side",
   "camera_height": "chin",
   "composition": "4:5; face upper right; flames lower centre; fingertips leading to the lips",
   "camera_movement": "n/a",
   "model_movement": "head back, eyes closed, lips parted, fingertips at lower lip",
   "lens": "70mm",
   "settings": "RAW, f/1.8\u20132.2, 1/125, ISO 2500",
   "candles": "half",
   "lighting": "full plan; check the cool fill reads on the far cheek",
   "notes": "Stills set frame 3 (hero). Its pose is close to REF-000001: change the hand and head angle so it is not a copy",
   "camera": "Sony A7 IV"
  },
  {
   "description": "HERO, video. The same pose held; very slow push-in; flames flicker; one breath.",
   "beat": "hero",
   "type": "video",
   "duration_s": 5,
   "shot_size": "CU",
   "body_crop": "top of head to shoulder",
   "camera_angle": "three-quarter profile from the candle side",
   "camera_height": "chin",
   "composition": "as the hero still, 9:16",
   "camera_movement": "locked, vertical; very slow digital push-in in the edit (about 8%)",
   "model_movement": "stillness; one slow breath; slight head settle",
   "lens": "70mm",
   "settings": "4K 25p, 1/50, f/2, ISO 2500",
   "candles": "half",
   "lighting": "full plan",
   "notes": "Hold 8\u201310 s per take for editing room",
   "camera": "Sony A7 IV"
  },
  {
   "description": "BREATH, video, part 1. Locked-off medium shot; she sits upright, eyes closed, half candles.",
   "beat": "breath",
   "type": "video",
   "duration_s": 1.5,
   "shot_size": "MS",
   "body_crop": "head to waist",
   "camera_angle": "three-quarter front",
   "camera_height": "chest",
   "composition": "locked frame with headroom; candles clearly readable",
   "camera_movement": "locked \u2014 do not touch the tripod between parts 1 and 2",
   "model_movement": "upright, still",
   "lens": "50mm",
   "settings": "4K 25p, 1/50, f/2.8, ISO 3200",
   "candles": "half",
   "lighting": "full plan, unchanged between parts",
   "notes": "Mark the model''s position with tape; shoot with the camera mounted vertically (native 2160x3840)",
   "camera": "Sony A7 IV"
  },
  {
   "description": "BREATH, video, part 2. The identical locked frame; candles now stubs; her posture has sunk; she opens her eyes and looks down at the flames.",
   "beat": "breath",
   "type": "video",
   "duration_s": 2,
   "shot_size": "MS",
   "body_crop": "head to waist",
   "camera_angle": "three-quarter front",
   "camera_height": "chest",
   "composition": "identical to part 1",
   "camera_movement": "locked",
   "model_movement": "shoulders lowered, head tilted, eyes open to the flames",
   "lens": "50mm",
   "settings": "as part 1",
   "candles": "stub (swap the candle set; keep the wax piece in place)",
   "lighting": "as part 1",
   "notes": "The hard cut between parts 1 and 2 is the time jump; shoot with the camera mounted vertically (native 2160x3840)",
   "camera": "Sony A7 IV"
  },
  {
   "description": "BREATH, still. Eyes open, looking down the shoulder at the stub candles.",
   "beat": "breath",
   "type": "still",
   "shot_size": "CU",
   "body_crop": "face to shoulder",
   "camera_angle": "three-quarter front",
   "camera_height": "eye",
   "composition": "4:5; eyes to flames on a diagonal",
   "camera_movement": "n/a",
   "model_movement": "eyes lowered to the flames",
   "lens": "70mm",
   "settings": "RAW, f/2, 1/160, ISO 2500",
   "candles": "stub",
   "lighting": "full plan",
   "notes": "Stills set frame 4",
   "camera": "Sony A7 IV"
  },
  {
   "description": "ENDING, video, slow motion. She blows out one candle; a thread of smoke rises from that wick; the last flame still burns.",
   "beat": "ending",
   "type": "video",
   "duration_s": 3,
   "shot_size": "CU",
   "body_crop": "lips to shoulder",
   "camera_angle": "side",
   "camera_height": "shoulder",
   "composition": "the blown-out wick centre frame; smoke rising into black",
   "camera_movement": "locked",
   "model_movement": "a single gentle breath out at the nearer candle",
   "lens": "50mm at 4K 50p (Super 35 crop, about 75mm equivalent), or 70mm at FHD 100p",
   "settings": "4K 50p or FHD 100p, 1/100, f/2.8, ISO 3200",
   "candles": "stub",
   "lighting": "key low; backlight the smoke with a small hard source from behind if available",
   "notes": "The AI preview put the smoke on the wrong candle; check the source on playback; shoot with the camera mounted vertically (native 2160x3840)",
   "camera": "Sony A7 IV"
  },
  {
   "description": "ENDING, still. The smoke thread with the last flame still lit.",
   "beat": "ending",
   "type": "still",
   "shot_size": "CU",
   "body_crop": "lips, shoulder and both candles",
   "camera_angle": "side",
   "camera_height": "shoulder",
   "composition": "4:5; smoke on the upper third",
   "camera_movement": "n/a",
   "model_movement": "just after the breath",
   "lens": "70mm",
   "settings": "RAW, f/2.8, 1/200, ISO 3200, burst",
   "candles": "stub",
   "lighting": "key low, smoke backlight",
   "notes": "Stills set frame 5",
   "camera": "Sony A7 IV"
  },
  {
   "description": "ENDING, video. The last flame is blown out; the frame falls to black.",
   "beat": "ending",
   "type": "video",
   "duration_s": 2,
   "shot_size": "CU",
   "body_crop": "face and shoulder",
   "camera_angle": "three-quarter profile",
   "camera_height": "shoulder",
   "composition": "face lit only by the last flame",
   "camera_movement": "locked",
   "model_movement": "blows the last candle out",
   "lens": "70mm",
   "settings": "4K 25p, 1/50, f/2, ISO 3200",
   "candles": "stub, last one lit",
   "lighting": "key and fill off for this take; flame only, then black",
   "notes": "Possible loop seam back to the match strike; decided at rough cut; shoot with the camera mounted vertically (native 2160x3840)",
   "camera": "Sony A7 IV"
  },
  {
   "description": "DETAIL, still. Hands and wax only: fingers resting on the drips, flames soft above.",
   "beat": "detail",
   "type": "still",
   "shot_size": "ECU",
   "body_crop": "hand and wax piece",
   "camera_angle": "top-side",
   "camera_height": "above shoulder",
   "composition": "4:5; drips leading lines down the frame",
   "camera_movement": "n/a",
   "model_movement": "fingers resting lightly on the wax",
   "lens": "70mm",
   "settings": "RAW, f/2.8, 1/160, ISO 1600",
   "candles": "any set",
   "lighting": "key raking across the wax",
   "notes": "Stills set frame 6",
   "camera": "Sony A7 IV"
  },
  {
   "description": "WIDE, still. One wider frame of the figure among the pillar candles, for the set''s closing image.",
   "beat": "detail",
   "type": "still",
   "shot_size": "MWS",
   "body_crop": "head to hips",
   "camera_angle": "three-quarter front",
   "camera_height": "chest",
   "composition": "4:5; figure right; pillars left; more of the teal-black space",
   "camera_movement": "n/a",
   "model_movement": "seated, eyes closed",
   "lens": "50mm",
   "settings": "RAW, f/2.8, 1/125, ISO 3200",
   "candles": "half",
   "lighting": "full plan; open the background light slightly",
   "notes": "Stills set frame 7",
   "camera": "Sony A7 IV"
  }
 ],
 "kit_note": "v2: lenses and support changed to the owner''s kit (no 85mm, no slider). 70mm assumed to be a prime; confirm."
}','main session (shot-planner not built)','2026-11-14T09:12:33Z');
INSERT INTO "documents" VALUES('DOC-0011','PRJ-0001','production_plan','main',1,'draft','# Production plan — "Vigil" (PRJ-0001)

Shoot: tomorrow, owner''s home studio. Crew: the owner (photographer) and the model only.
Built on the storyboard (DOC-0008) and shot list v2 (owner''s kit). The model''s name is kept out
of this public repository.

## Kit mapping (owner''s kit; two items need confirming)

| Role | Owner''s kit | Setting |
|---|---|---|
| Camera | Sony A7 IV, on tripod, **mounted vertically for video** | As shot list |
| Main lens | 70mm (assumed prime) | Hero, reveal, close-ups |
| Second lens | 50mm | Locked-off time jump, smoke in 4K 50p crop |
| Wide | 28–75mm | Wide still, backup push-in |
| Not used | 35mm APS-C | Forces APS-C crop on the A7 IV; not needed |
| Key (video and stills) | YRGB 500W, assumed a 500 W RGB COB, in a softbox | 2700–3200 K at its lowest output; **if it will not dim low enough, add diffusion and move it back, or bounce it** |
| Key, stills alternative | AD300Pro flash with a CTO gel in the softbox | Low power; cleaner, sharper stills at ISO 400–800 with the flames still visible (shutter 1/30–1/60) |
| Cool fill | Cinepeer RGB | ~6500 K or teal, very low, camera right, flagged with black card |
| Background teal | Z1PRO, **if it is an RGB or coloured light** | Teal on the backdrop, not the model |
| Practicals | Candles on the shoulder piece; two pillar candles 1–1.5 m behind | Real flame |

No slider or gimbal is listed, so every push-in is done in the edit from vertical 4K
(native 2160×3840, plenty of room for a 1080×1920 reel).

## Tonight: prepare

1. **Build the wax shoulder piece tonight.** Pour or layer wax (or hot glue) on a rigid shoulder pad
   or foam cap, build the drips, set the two candle sockets, and let it cure fully. Add a strap under
   the arm with a **quick-release buckle** so it comes off in one movement.
2. Cut three candle sets for the sockets: **tall, half, stub**. Short, wide, dripless candles burn
   cooler and steadier; the drips are part of the prop.
3. Check stock: matches, a long lighter, a snuffer, two pillar candles with stable holders, black
   card flags, clamps, tape for floor marks, a spare set of candles.
4. **Safety stock (needed before any flame is lit):** a fire blanket, a small extinguisher, and a damp
   towel, all placed beside the tripod.
5. Charge camera batteries and the lights; format cards.

## Tomorrow: schedule (from the start time)

| Time | Block | Detail |
|---|---|---|
| 0:00 | Set up | Backdrop, key, fill, background light, pillar candles, tripod, floor marks |
| 0:40 | Tests | White balance (fixed ~3800–4500 K), flicker test at 1/50 and 1/100, exposure with the flames lit |
| 0:55 | Model ready | Hair tied back on the candle side, **no hairspray**; makeup; fit the prop |
| 1:10 | **Tall set** — shots 1–4 | Hook match strike, reveal |
| 1:35 | Swap to **half set** — shots 5–7, 14 | Hero still and video, time jump part 1, wide still |
| 2:05 | Swap to **stub set** — shots 8–12 | Time jump part 2 (do not move the tripod), stubs, smoke slow motion, final blow-out |
| 2:35 | Detail — shot 13 | Hands and wax |
| 2:45 | Review and wrap | Check focus, smoke source, the cool fill on playback |

## Real flames with no assistant — read before tomorrow

The storyboard assumed an assistant on fire watch. There is none, so the photographer is the fire
watch, and the plan changes to suit:

- The camera stays on the tripod and fires by remote (the Sony Creators'' App on your phone, or a
  remote) so you can stand close to the model, not behind the viewfinder, while flames are lit.
- **Flames are lit only for the take**, at most about a minute, and snuffed between takes and before
  every adjustment, candle swap and pose change.
- Fire blanket, extinguisher and damp towel stay **within one step of where you stand**.
- The model can release the strap herself; agree a stop word before the first light.
- Never leave the room, or turn your back on the model, while a flame is lit.
- If anything leans, pools near skin or catches hair: snuff, release the strap, blanket.

**Recommendation:** a second person for the forty or so minutes of lit shots would make this
markedly safer, even someone with no photography role. This is production guidance, not a
substitute for your own judgement or any building fire rules.
','main session (shot-planner not built)','2026-11-14T09:12:34Z');
CREATE TABLE gate_log (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  at         TEXT NOT NULL,
  tool       TEXT NOT NULL,
  decision   TEXT NOT NULL CHECK (decision IN ('allowed','denied')),
  approval_id TEXT,
  reason     TEXT
);
INSERT INTO "gate_log" VALUES(1,'2026-11-14T08:45:44Z','mcp__Idea_AI__create_image','allowed','APR-0005','2 uses left');
INSERT INTO "gate_log" VALUES(2,'2026-11-14T08:45:58Z','mcp__Idea_AI__create_image','allowed','APR-0005','1 uses left');
INSERT INTO "gate_log" VALUES(3,'2026-11-14T08:46:03Z','mcp__Idea_AI__create_image','allowed','APR-0005','0 uses left');
CREATE TABLE generations (
  id           TEXT PRIMARY KEY,               -- GNR-0001
  project_id   TEXT NOT NULL REFERENCES projects(id),
  prompt_id    TEXT REFERENCES prompts(id),
  approval_id  TEXT REFERENCES approvals(id),
  provider     TEXT NOT NULL,
  tool         TEXT,
  status       TEXT NOT NULL CHECK (status IN ('submitted','succeeded','failed','rejected','accepted')),
  external_task_id TEXT,
  cost_usd     REAL,                           -- actual, when known
  credits      REAL,
  asset_id     TEXT REFERENCES assets(id),
  review_notes TEXT,
  created_at   TEXT NOT NULL
);
INSERT INTO "generations" VALUES('GNR-0001','PRJ-0001','PRM-0001','APR-0005','idea_ai','mcp__Idea_AI__create_image','succeeded','3M5ggfJQWbf1GGRcNYLGMVFnWWB',NULL,690.0,'AST-0001','Usable for mood. Warm amber on hands, cool fill and teal background read clearly; hands correct. Not as prompted: both candles already lit, so it shows a relight rather than the first lighting; face cropped at the frame edge; cool fill is stronger than the faint fill asked for; blacks deep, not matte.','2026-11-14T08:47:02Z');
INSERT INTO "generations" VALUES('GNR-0002','PRJ-0001','PRM-0002','APR-0005','idea_ai','mcp__Idea_AI__create_image','succeeded','3M5ghbotVktwenGcfkOaicZYAgz',NULL,690.0,'AST-0002','Strongest of the three. Pose, wax piece, half-burned candles and the warm-cool split all read. Artefact: an unexplained orange glow patch on the side of the neck. Pose and framing sit very close to REF-000001; treat as direction, not a shot to copy.','2026-11-14T08:47:02Z');
INSERT INTO "generations" VALUES('GNR-0003','PRJ-0001','PRM-0003','APR-0005','idea_ai','mcp__Idea_AI__create_image','succeeded','3M5gi8wjbhewcsLbpn3E5CIV7Bb',NULL,690.0,'AST-0003','Weakest. Candles are mid-height, not stubs; the extinguished wick looks charred; the smoke trail rises from beside the lit flame rather than the blown-out one; both hands grip the one shoulder awkwardly. Overall too teal: Cold Hours dominates the Ember base.','2026-11-14T08:47:03Z');
CREATE TABLE genres (
  id          TEXT PRIMARY KEY,                -- GEN-0001
  name        TEXT NOT NULL,
  name_norm   TEXT NOT NULL UNIQUE,
  description TEXT,
  knowledge_json TEXT,                         -- conventions, lighting, pacing, etc.
  origin      TEXT NOT NULL DEFAULT 'discovered' CHECK (origin IN ('user','discovered','research')),
  status      TEXT NOT NULL DEFAULT 'proposed' CHECK (status IN ('proposed','approved','retired')),
  version     INTEGER NOT NULL DEFAULT 1,
  created_at  TEXT NOT NULL,
  updated_at  TEXT NOT NULL
);
INSERT INTO "genres" VALUES('GEN-0001','Cinematic fashion','cinematic fashion',NULL,NULL,'user','approved',1,'2026-11-13T06:46:42Z','2026-11-13T06:46:42Z');
INSERT INTO "genres" VALUES('GEN-0002','Fantasy / surrealism','fantasy surrealism',NULL,NULL,'user','approved',1,'2026-11-13T06:46:42Z','2026-11-13T06:46:42Z');
INSERT INTO "genres" VALUES('GEN-0003','Indian cultural aesthetics','indian cultural aesthetics',NULL,NULL,'user','approved',1,'2026-11-13T06:46:42Z','2026-11-13T06:46:42Z');
INSERT INTO "genres" VALUES('GEN-0004','Emotional romance','emotional romance',NULL,NULL,'user','approved',1,'2026-11-13T06:46:42Z','2026-11-13T06:46:42Z');
INSERT INTO "genres" VALUES('GEN-0005','Dark experimental','dark experimental',NULL,NULL,'user','approved',1,'2026-11-13T06:46:42Z','2026-11-13T06:46:42Z');
INSERT INTO "genres" VALUES('GEN-0006','Creative VFX','creative vfx',NULL,NULL,'user','approved',1,'2026-11-13T06:46:42Z','2026-11-13T06:46:42Z');
INSERT INTO "genres" VALUES('GEN-0007','Motion graphics / typography','motion graphics typography',NULL,NULL,'user','approved',1,'2026-11-13T06:46:42Z','2026-11-13T06:46:42Z');
INSERT INTO "genres" VALUES('GEN-0008','Editing education / BTS','editing education bts',NULL,NULL,'user','approved',1,'2026-11-13T06:46:42Z','2026-11-13T06:46:42Z');
INSERT INTO "genres" VALUES('GEN-0009','candlelit conceptual portrait','candlelit conceptual portrait',NULL,NULL,'discovered','proposed',1,'2026-11-13T20:52:13Z','2026-11-13T20:52:13Z');
CREATE TABLE id_counters (
  prefix TEXT PRIMARY KEY,
  next   INTEGER NOT NULL
);
INSERT INTO "id_counters" VALUES('GEN',10);
INSERT INTO "id_counters" VALUES('INS',3);
INSERT INTO "id_counters" VALUES('RSH',3);
INSERT INTO "id_counters" VALUES('APR',6);
INSERT INTO "id_counters" VALUES('PRJ',3);
INSERT INTO "id_counters" VALUES('DOC',12);
INSERT INTO "id_counters" VALUES('PRM',4);
INSERT INTO "id_counters" VALUES('AST',4);
INSERT INTO "id_counters" VALUES('GNR',4);
INSERT INTO "id_counters" VALUES('SHO',29);
CREATE TABLE inspiration_analyses (
  id             INTEGER PRIMARY KEY AUTOINCREMENT,
  inspiration_id TEXT NOT NULL REFERENCES inspirations(id),
  origin         TEXT NOT NULL CHECK (origin IN ('agent00','studio')),
  ref_id         TEXT,                         -- Agent 00 REF- id the analysis was written against
  access_status  TEXT NOT NULL,
  basis          TEXT,
  analysis_json  TEXT NOT NULL,
  content_hash   TEXT NOT NULL,
  recorded_at    TEXT NOT NULL,
  UNIQUE (inspiration_id, content_hash)
);
INSERT INTO "inspiration_analyses" VALUES(1,'INS-0001','agent00','REF-000001','reviewed_images','Agent 00 analysis of REF-000001 (access_status=reviewed_images)','{"reference_id": "REF-000001", "access_status": "reviewed_images", "blocked_reason": "", "creator": "Cap2red Studio (per on-image watermark; handle and origin link unknown)", "title": "Candle portrait reference: wax shoulder piece, eyes closed (1000162216.jpg)", "genre": ["dark experimental", "cinematic fashion", "fantasy/surrealism", "candlelit conceptual portrait"], "story_summary": "Single still photograph (media/incoming/1000162216.jpg, 736x920, 4:5 vertical), reviewed in full plus enlarged crops. A blonde woman is seen in three-quarter profile from slightly behind her right shoulder, head tilted back and turned towards frame left, eyes closed, lips parted. The fingertips of one hand rest on her chin and lower lip; a second hand reaches in from the lower-left corner towards the shoulder. On the near shoulder sits a mass of white dripped wax with two small lit candles on top, the drips running down like a fringe. Two large lit pillar candles stand out of focus in a dark green-black background at frame left. Everything is warm amber against dark olive shadow with a matte, faded finish. No narrative beyond a single quiet, sensual, ritual-like moment; it is one frame, so no sequence or motion is known.", "techniques": [{"name": "wax-dripped shoulder piece with two small lit candles", "timecode": "", "evidence": "Whole frame and enlarged crop of the lower half: two short lit candles stand on top of a thick white drip mass that covers the near shoulder and falls in long parallel runs; bare skin of the shoulder and back is visible to the right of it.", "certainty": "observed", "recreation": "Build the piece in advance on a base (fabric shoulder pad, craft foam or a moulded shoulder cap) by pouring candle wax or hot glue in layers and letting it set fully before it goes on the model. Do not drip hot wax on the model or burn candles directly on skin."}, {"name": "wax piece is a pre-made wearable, not wax poured on skin", "timecode": "", "evidence": "Drips are long, even and fringe-like and stand proud of the body; a lace-like or fabric edge shows under the wax at the lower-left of the piece. Not confirmable from one frame.", "certainty": "inferred", "recreation": "Treat as a costume build: one evening of prop work. Test weight and how it is fixed (straps under the arm, or a garment it is sewn to) before the shoot."}, {"name": "candle practicals as out-of-focus background depth", "timecode": "", "evidence": "Two large lit pillar candles at frame left (one upper-centre-left, one cut by the lower-left edge) on dark holders, strongly blurred; background otherwise near-black.", "certainty": "observed", "recreation": "Place 2-3 pillar candles 1-1.5 m behind the model at staggered heights (stands, stacked boxes under black cloth) against a dark backdrop a further metre back. Shoot wide open so they turn into soft shapes."}, {"name": "warm low-key lighting on face, neck and hands", "timecode": "", "evidence": "Brightest skin is the jaw, neck and underside of the chin nearest the shoulder candles (sampled about RGB 217,117,44) with the forehead and top of the hair also lit; far side of the back falls to near black. Shadows are soft-edged.", "certainty": "observed", "recreation": "Keep the key low in power and warm; expose for the skin highlight on the jaw and let the back and background fall away."}, {"name": "hidden soft warm key supplementing the candles", "timecode": "", "evidence": "The forehead, eyelids and upper hair are evenly and softly lit from above and frame left, which two small flames at shoulder height would not do; the flames keep their shape rather than blowing out, suggesting a short exposure with added light. The light itself is not visible in frame.", "certainty": "inferred", "recreation": "Portable LED with softbox or shoot-through diffusion, set to 2700-3200K (or daylight with full CTO), dimmed to a few percent, about 45 degrees to camera left and slightly above head height, feathered so it grazes the face and misses the background. Optional second tiny warm source low near the shoulder to strengthen the under-jaw glow the candles motivate."}, {"name": "over-the-shoulder three-quarter profile close-up, 4:5 vertical, subject weighted right", "timecode": "", "evidence": "Camera looks past the near shoulder at roughly shoulder-to-chin height; face in three-quarter profile turned to frame left; head and hair fill the right two thirds and touch the top and right edges; left third is left to dark background and blurred candles. File is 736x920.", "certainty": "observed", "recreation": "Sit the model side-on to camera, shoulder towards lens, then have her turn the chin back over that shoulder and tilt up. Frame vertical with space on the side she faces."}, {"name": "chin-up, eyes-closed pose with fingertips at the lips and a second hand entering frame", "timecode": "", "evidence": "Eyes closed, lips parted, head tilted back; four fingertips of one hand touch chin and lower lip; another hand with a ring enters from lower left with fingers spread towards the wax piece. Pale/white nail polish on both hands.", "certainty": "observed", "recreation": "Direct light touch only (no pressing into the face), relaxed fingers with gaps between them, wrists soft. Shoot bursts while she breathes out slowly."}, {"name": "second hand belongs to the model", "timecode": "", "evidence": "Both hands share the same nail colour and skin tone, but the lower arm leaves frame before it can be traced to her body. It could be an assistant''s or second model''s hand.", "certainty": "inferred", "recreation": "Either works. Using the model''s own two hands is simplest."}, {"name": "shallow depth of field on a short telephoto", "timecode": "", "evidence": "Eyelashes and shoulder candles are sharp; the lower hand in the foreground and the background pillar candles are soft; facial perspective is flat with no wide-angle distortion. No lens or exposure data is in the file (EXIF holds only resolution and a colour-profile note).", "certainty": "inferred", "recreation": "Sony A7 IV with an 85mm at f/2-f/2.8 (f/1.8 if the face and shoulder candles can be kept in one plane). Around 1/125 s, ISO 800-3200, RAW."}, {"name": "amber-and-olive grade with lifted matte blacks and fine grain", "timecode": "", "evidence": "Sampled background shadows are green-leaning (about RGB 21,34,14 and 16,26,10) rather than neutral; darkest 1 percent of luminance sits at 18/255, not 0; skin sits at hue about 25 degrees orange; whites of the candles are cream, not pure white; visible grain or texture in the dark areas.", "certainty": "observed", "recreation": "Lightroom: raise the black point on the tone curve, colour-grade shadows towards green-olive and highlights towards amber, pull orange saturation back a little so skin does not go neon, warm the whites, add grain. Save as a preset for the set."}, {"name": "styling: glitter copper lip, pale nails, hair pulled back off the face, bare shoulders", "timecode": "", "evidence": "Enlarged crop shows a sparkling copper-bronze lip; white or very pale nails; blonde hair swept back from the forehead and falling behind the ear to about jaw length; no visible clothing other than the wax piece; a ring on the lower hand.", "certainty": "observed", "recreation": "Metallic or glitter lip as the one strong make-up accent, matte skin with a little highlight on the cheekbone, hair secured back and kept well away from any real flame."}, {"name": "safer flame options for the shoulder candles", "timecode": "", "evidence": "Recommendation only; not a claim about how the source was made.", "certainty": "suggested", "recreation": "Preferred: warm LED taper or tea-light inserts set into the wax piece, with the flame replaced or enhanced in Photoshop from a separately photographed real flame at the same angle. If real flames are used: short candles fixed into the rigid base, hair tied back and free of hairspray, an assistant within arm''s reach with a damp cloth, short takes, model seated."}], "shot_candidates": [{"label": "candle-shoulder over-the-shoulder profile close-up", "shot_size": "CU", "body_crop": "top of head to upper chest and near shoulder; both hands in frame", "camera_angle": "three-quarter profile from behind the near shoulder (over-the-shoulder)", "camera_height": "chin to shoulder height, level", "composition": "4:5 vertical; subject fills right two thirds; blurred pillar-candle practicals in the dark left third; shoulder candles lower centre", "model_movement": "still pose: chin lifted, eyes closed, fingertips at lips", "camera_movement": "none (still photograph)", "focal_length": "not recorded in file; short telephoto inferred, 85mm suggested", "recording_settings": "not recorded in file; suggested f/2-2.8, 1/125 s, ISO 800-3200, RAW", "actual_frame": "media/incoming/1000162216.jpg", "confidence": "observed"}], "difficulty": "medium", "editorial_ideas": ["suggested: shoot a three-frame series from one setup - eyes closed chin up (this frame), eyes open looking down the shoulder at the flames, and a detail of hands and wax only.", "suggested: add a short 4K clip of the same pose (A7 IV, 25p, 1/50 s) for a slow push-in with flame flicker, graded in Premiere with the same matte amber-olive look; searched the catalog first and nothing similar exists yet (catalog was empty)."], "notes": "Local file with no origin link; stored as file:media/incoming/1000162216.jpg (SHA-256 a6ab9b33532665cc74bf199aedad626e75fb1fa6ba9da3f187c6afafc995b742). Access: whole image viewed plus enlarged crops made in a scratch folder; the original file was not modified. Attribution: a script watermark at the bottom right reads ''Cap'', a camera icon containing the numeral 2, ''red'', with ''Studio'' beneath - recorded here as ''Cap2red Studio''. Whether it is meant to be read ''Captured Studio'' is a guess, and no handle, URL or post could be checked, so the watermark is the only evidence of authorship. Image is 736 px wide, a size commonly served by Pinterest (inferred, not proof of origin). EXIF carries only resolution fields and ''ProfileCopyright: Google Inc. 2016'' (an ICC colour-profile note, not an author credit); no camera, lens, exposure or date. Not known: the lighting equipment actually used, whether the flames are real or retouched, whether the wax is on fabric or skin, focal length and aperture. No engagement figures exist for this record. Stills have no timecodes, so every ''timecode'' field is intentionally empty."}','9554111efb634dbb30e2a05c3c3fbd27c67d54297e12b86f7472b2af4a18a110','2026-11-13T20:52:13Z');
INSERT INTO "inspiration_analyses" VALUES(2,'INS-0002','agent00','REF-000002','reviewed_images','Agent 00 analysis of REF-000002 (access_status=reviewed_images)','{"reference_id": "REF-000002", "access_status": "reviewed_images", "blocked_reason": "", "creator": "", "title": "Candle portrait reference: candles on bare shoulder, orange cheek glow (1000162212.jpg)", "genre": ["dark experimental", "fantasy/surrealism", "candlelit conceptual portrait"], "story_summary": "Single still image (media/incoming/1000162212.jpg, 736x736, square), reviewed in full plus enlarged crops. A woman with long, loose, wavy dark-blonde hair is seen from the front-left, head tilted down and turned towards her own near shoulder, eyes lowered, lips slightly parted. Two short lit candles stand directly on her bare shoulder, with white wax running down the upper arm and back; her hand clasps the upper arm at the bottom edge. The face is lit cool and soft on the forehead and nose, with a strongly saturated orange patch on the cheek and jaw nearest the flames, against a blue-teal near-black background. The image shows signs of being AI-generated or heavily composited (see techniques), so it is a mood and colour reference rather than proof of a physical setup.", "techniques": [{"name": "two lit candles standing on a bare shoulder with wax running down the arm", "timecode": "", "evidence": "Whole frame and enlarged crop of the lower right: two short candles with flames on the top of the shoulder; white wax pooled at their bases and running in thin streams down the upper arm and behind it; one separate wax droplet on the skin.", "certainty": "observed", "recreation": "Do not attempt literally. Build a thin skin-toned or clear shoulder cap (or a strip of fabric tape base) carrying the candle stubs and pre-set drips, fix it with body-safe adhesive or a hidden strap, and paint a few extra cooled drips of body-safe material beyond its edge so it reads as wax on skin. Blend the edge in Photoshop."}, {"name": "image is probably AI-generated or a heavy composite", "timecode": "", "evidence": "Wax streams continue into and merge with strands of hair behind the arm; the candles sit on skin with no contact shadow or support; the cheek glow is a deep saturated orange (sampled about RGB 210,68,6) while the flames are pale yellow-white and sit below and behind the cheek; skin and hair have a uniform painted smoothness; pure black and pure white are both clipped; the file has no EXIF at all and no watermark. None of this is conclusive.", "certainty": "inferred", "recreation": "Treat the picture as a target mood. Expect a real photograph to look less saturated in the orange and to need a hidden light to create the cheek glow."}, {"name": "cool-and-warm two-colour lighting: neutral-cool soft key with a saturated orange accent on one cheek", "timecode": "", "evidence": "Forehead and bare shoulder sample almost neutral grey (about RGB 99,103,102 and 82,81,77); cheek and jaw nearest the candles sample saturated orange (hue about 18 degrees, saturation above 0.8); background samples blue-teal (hue about 200 degrees). A small specular highlight sits on the tip of the nose.", "certainty": "observed", "recreation": "Light 1: portable LED in a small softbox at camera left, slightly above eye level, daylight-balanced and dimmed low. Light 2: a small RGB tube or pocket LED set to orange (or tungsten with full CTO plus a little red), hidden low at camera right near the shoulder, flagged with black card so it only touches cheek, jaw and neck. Camera white balance fixed around 4300-4800K so the key reads slightly cool and the accent stays orange."}, {"name": "the orange accent is meant to read as candle glow", "timecode": "", "evidence": "The orange patch is on the side of the face nearest the two flames and fades with distance from them; no other warm source is visible.", "certainty": "inferred", "recreation": "Keep the accent light on the same line as the candles from the face so the glow looks motivated, and add slight flicker only if shooting video."}, {"name": "downcast gaze towards the shoulder, head tilted, hand clasping the upper arm", "timecode": "", "evidence": "Eyes open but lowered towards frame right and down; head tilted down and towards the near shoulder; lips slightly parted; fingers of one hand wrap the upper arm at the bottom edge with natural pale-pink nails.", "certainty": "observed", "recreation": "Model seated, near shoulder rolled slightly forward, chin dropped towards it; ask her to look at the flames rather than at the lens. The self-holding hand keeps the arm steady, which also helps the prop."}, {"name": "square close-up, face upper centre-left, candles lower centre-right, hair filling the left side", "timecode": "", "evidence": "736x736 frame; face occupies the upper middle; the two flames sit just right of centre in the lower half; long hair fills the left third and frames the right; top of the head is cropped; background is a featureless dark blue-teal blur.", "certainty": "observed", "recreation": "Frame slightly loose on a vertical 4:5 and crop to square later, keeping the eye-to-flame diagonal."}, {"name": "shallow depth of field at portrait focal length", "timecode": "", "evidence": "Face, candles and shoulder all appear sharp while the background is completely smooth; perspective on the face is flat. With a possibly synthetic image there is no real lens to identify, and the file carries no EXIF.", "certainty": "inferred", "recreation": "Sony A7 IV with 85mm at f/2.8-f/4 (the face and the shoulder candles are at different distances, so stop down further than for REF-000001), 1/125 s, ISO 400-1600, RAW; background at least 2 m behind."}, {"name": "teal-black background with deep, clipped blacks and high colour contrast", "timecode": "", "evidence": "Background samples about RGB 17,27,31, 9,19,25 and 14,31,40; darkest 1 percent of luminance is 0 (true black, unlike the matte look of REF-000001); image median is very dark (25/255).", "certainty": "observed", "recreation": "Dark grey or black backdrop left unlit, then in Lightroom push shadows towards teal with colour grading, keep blacks deep, and raise orange saturation and lower orange luminance selectively on the cheek with a masked adjustment."}, {"name": "styling: long loose waves, smoky bronze eye, mauve-pink lip, bare shoulders", "timecode": "", "evidence": "Enlarged face crop shows defined dark brows, bronze-brown smoky eyeshadow, a satin mauve-pink lip and smooth matte skin; hair is long, loose and wavy over both shoulders; no clothing visible.", "certainty": "observed", "recreation": "Achievable make-up. Loose hair this close to flame is a fire risk: pin the hair behind the candle-side shoulder or use LED candles and add the flames in post."}, {"name": "LED candles plus composited flames", "timecode": "", "evidence": "Recommendation only; not a claim about how the source was made.", "certainty": "suggested", "recreation": "Photograph a real candle flame separately against black at the same focal length and angle, then screen-blend it over LED candle stubs in Photoshop. This allows loose hair and long posing time."}], "shot_candidates": [{"label": "candles on bare shoulder with orange cheek glow, downcast gaze", "shot_size": "CU", "body_crop": "forehead (top of head cropped) to upper arm; one hand at bottom edge", "camera_angle": "front three-quarter, model''s head turned towards her near shoulder", "camera_height": "eye level or slightly above, level", "composition": "1:1 square; face upper centre-left, twin flames lower centre-right forming an eye-to-flame diagonal; hair fills left third; plain teal-black background", "model_movement": "still pose: head tilted down, eyes lowered to the flames, hand holding upper arm", "camera_movement": "none (still image)", "focal_length": "not recorded in file and image may be synthetic; 85mm suggested", "recording_settings": "not recorded in file; suggested f/2.8-4, 1/125 s, ISO 400-1600, RAW", "actual_frame": "media/incoming/1000162212.jpg", "confidence": "observed"}], "difficulty": "medium-hard", "editorial_ideas": ["suggested: use the cool-key and orange-accent lighting from this reference as a second look in the same session as REF-000001''s all-warm setup, changing only the key colour temperature, accent light and grade.", "suggested: an original combination - REF-000001''s wearable wax shoulder piece and over-the-shoulder angle, lit with this reference''s cool key and orange cheek accent."], "notes": "Local file with no origin link; stored as file:media/incoming/1000162212.jpg (SHA-256 699d64a6b2213f9e4d2eadcb3e8e1d0a41b8e575ce4f374fb3b0b02b358585e8). Access: whole image viewed plus enlarged crops and a brightened copy made in a scratch folder; the original file was not modified. Attribution: no watermark, signature, caption or embedded metadata was found (corners and dark areas checked on a brightened copy; EXIF is empty), so the creator is unknown and none is recorded. Image is 736 px wide, a size commonly served by Pinterest (inferred, not proof of origin). The AI-generated judgement is an inference from visual artefacts and has not been confirmed by any tool or source. Not known: who made it, with what, and whether any physical shoot lies behind it. No engagement figures exist for this record. Stills have no timecodes, so every ''timecode'' field is intentionally empty. Difficulty is higher than REF-000001 because the prop has to pass as wax on bare skin and the two-colour light needs tight flagging."}','fe19a91123f05c059bbfd5dbebb36a1f369788201db9d9b72470f7b2cea35552','2026-11-13T20:52:13Z');
CREATE TABLE inspiration_genres (
  inspiration_id TEXT NOT NULL REFERENCES inspirations(id),
  genre_id       TEXT NOT NULL REFERENCES genres(id),
  PRIMARY KEY (inspiration_id, genre_id)
);
INSERT INTO "inspiration_genres" VALUES('INS-0001','GEN-0005');
INSERT INTO "inspiration_genres" VALUES('INS-0001','GEN-0001');
INSERT INTO "inspiration_genres" VALUES('INS-0001','GEN-0002');
INSERT INTO "inspiration_genres" VALUES('INS-0001','GEN-0009');
INSERT INTO "inspiration_genres" VALUES('INS-0002','GEN-0005');
INSERT INTO "inspiration_genres" VALUES('INS-0002','GEN-0002');
INSERT INTO "inspiration_genres" VALUES('INS-0002','GEN-0009');
CREATE TABLE inspiration_links (
  inspiration_id TEXT NOT NULL REFERENCES inspirations(id),
  url            TEXT NOT NULL,                -- original link, unmodified
  url_norm       TEXT NOT NULL UNIQUE,         -- duplicate detection key
  PRIMARY KEY (inspiration_id, url)
);
INSERT INTO "inspiration_links" VALUES('INS-0001','file:media/incoming/1000162216.jpg','sha256:a6ab9b33532665cc74bf199aedad626e75fb1fa6ba9da3f187c6afafc995b742');
INSERT INTO "inspiration_links" VALUES('INS-0002','file:media/incoming/1000162212.jpg','sha256:699d64a6b2213f9e4d2eadcb3e8e1d0a41b8e575ce4f374fb3b0b02b358585e8');
CREATE TABLE "inspirations" (
  id              TEXT PRIMARY KEY,            -- INS-0001
  source_type     TEXT NOT NULL CHECK (source_type IN
                    ('instagram','pinterest','youtube','web','upload','idea','sheet')),
  title           TEXT NOT NULL,
  title_norm      TEXT NOT NULL,
  creator         TEXT,                        -- attribution, as given by the source
  notes           TEXT,                        -- the user's own words about why it was saved
  collection      TEXT,                        -- saved-collection name, if any
  -- Agent 00's five access states (references/analysis-schema.json)
  access_status   TEXT NOT NULL DEFAULT 'unreviewed' CHECK (access_status IN
                    ('unreviewed','blocked','metadata_only','reviewed_images','reviewed_video')),
  access_detail   TEXT,                        -- e.g. "login wall", "network policy", "HTTP 404"
  analysis_status TEXT NOT NULL DEFAULT 'none' CHECK (analysis_status IN
                    ('none','partial','complete')),
  analysis_json   TEXT,                        -- latest analysis; full history in inspiration_analyses
  analysis_basis  TEXT,                        -- what was actually inspected
  source_meta_json TEXT,                       -- original row/metadata, preserved verbatim
  created_at      TEXT NOT NULL
);
INSERT INTO "inspirations" VALUES('INS-0001','upload','Candle portrait reference: wax shoulder piece, eyes closed (1000162216.jpg)','candle portrait reference wax shoulder piece eyes closed 1000162216 jpg','Cap2red Studio (per on-image watermark; handle and origin link unknown)','Uploaded by owner as a local file for a candle-themed portrait shoot; origin link not known.','Candle portrait shoot','reviewed_images',NULL,'complete','{"reference_id": "REF-000001", "access_status": "reviewed_images", "blocked_reason": "", "creator": "Cap2red Studio (per on-image watermark; handle and origin link unknown)", "title": "Candle portrait reference: wax shoulder piece, eyes closed (1000162216.jpg)", "genre": ["dark experimental", "cinematic fashion", "fantasy/surrealism", "candlelit conceptual portrait"], "story_summary": "Single still photograph (media/incoming/1000162216.jpg, 736x920, 4:5 vertical), reviewed in full plus enlarged crops. A blonde woman is seen in three-quarter profile from slightly behind her right shoulder, head tilted back and turned towards frame left, eyes closed, lips parted. The fingertips of one hand rest on her chin and lower lip; a second hand reaches in from the lower-left corner towards the shoulder. On the near shoulder sits a mass of white dripped wax with two small lit candles on top, the drips running down like a fringe. Two large lit pillar candles stand out of focus in a dark green-black background at frame left. Everything is warm amber against dark olive shadow with a matte, faded finish. No narrative beyond a single quiet, sensual, ritual-like moment; it is one frame, so no sequence or motion is known.", "techniques": [{"name": "wax-dripped shoulder piece with two small lit candles", "timecode": "", "evidence": "Whole frame and enlarged crop of the lower half: two short lit candles stand on top of a thick white drip mass that covers the near shoulder and falls in long parallel runs; bare skin of the shoulder and back is visible to the right of it.", "certainty": "observed", "recreation": "Build the piece in advance on a base (fabric shoulder pad, craft foam or a moulded shoulder cap) by pouring candle wax or hot glue in layers and letting it set fully before it goes on the model. Do not drip hot wax on the model or burn candles directly on skin."}, {"name": "wax piece is a pre-made wearable, not wax poured on skin", "timecode": "", "evidence": "Drips are long, even and fringe-like and stand proud of the body; a lace-like or fabric edge shows under the wax at the lower-left of the piece. Not confirmable from one frame.", "certainty": "inferred", "recreation": "Treat as a costume build: one evening of prop work. Test weight and how it is fixed (straps under the arm, or a garment it is sewn to) before the shoot."}, {"name": "candle practicals as out-of-focus background depth", "timecode": "", "evidence": "Two large lit pillar candles at frame left (one upper-centre-left, one cut by the lower-left edge) on dark holders, strongly blurred; background otherwise near-black.", "certainty": "observed", "recreation": "Place 2-3 pillar candles 1-1.5 m behind the model at staggered heights (stands, stacked boxes under black cloth) against a dark backdrop a further metre back. Shoot wide open so they turn into soft shapes."}, {"name": "warm low-key lighting on face, neck and hands", "timecode": "", "evidence": "Brightest skin is the jaw, neck and underside of the chin nearest the shoulder candles (sampled about RGB 217,117,44) with the forehead and top of the hair also lit; far side of the back falls to near black. Shadows are soft-edged.", "certainty": "observed", "recreation": "Keep the key low in power and warm; expose for the skin highlight on the jaw and let the back and background fall away."}, {"name": "hidden soft warm key supplementing the candles", "timecode": "", "evidence": "The forehead, eyelids and upper hair are evenly and softly lit from above and frame left, which two small flames at shoulder height would not do; the flames keep their shape rather than blowing out, suggesting a short exposure with added light. The light itself is not visible in frame.", "certainty": "inferred", "recreation": "Portable LED with softbox or shoot-through diffusion, set to 2700-3200K (or daylight with full CTO), dimmed to a few percent, about 45 degrees to camera left and slightly above head height, feathered so it grazes the face and misses the background. Optional second tiny warm source low near the shoulder to strengthen the under-jaw glow the candles motivate."}, {"name": "over-the-shoulder three-quarter profile close-up, 4:5 vertical, subject weighted right", "timecode": "", "evidence": "Camera looks past the near shoulder at roughly shoulder-to-chin height; face in three-quarter profile turned to frame left; head and hair fill the right two thirds and touch the top and right edges; left third is left to dark background and blurred candles. File is 736x920.", "certainty": "observed", "recreation": "Sit the model side-on to camera, shoulder towards lens, then have her turn the chin back over that shoulder and tilt up. Frame vertical with space on the side she faces."}, {"name": "chin-up, eyes-closed pose with fingertips at the lips and a second hand entering frame", "timecode": "", "evidence": "Eyes closed, lips parted, head tilted back; four fingertips of one hand touch chin and lower lip; another hand with a ring enters from lower left with fingers spread towards the wax piece. Pale/white nail polish on both hands.", "certainty": "observed", "recreation": "Direct light touch only (no pressing into the face), relaxed fingers with gaps between them, wrists soft. Shoot bursts while she breathes out slowly."}, {"name": "second hand belongs to the model", "timecode": "", "evidence": "Both hands share the same nail colour and skin tone, but the lower arm leaves frame before it can be traced to her body. It could be an assistant''s or second model''s hand.", "certainty": "inferred", "recreation": "Either works. Using the model''s own two hands is simplest."}, {"name": "shallow depth of field on a short telephoto", "timecode": "", "evidence": "Eyelashes and shoulder candles are sharp; the lower hand in the foreground and the background pillar candles are soft; facial perspective is flat with no wide-angle distortion. No lens or exposure data is in the file (EXIF holds only resolution and a colour-profile note).", "certainty": "inferred", "recreation": "Sony A7 IV with an 85mm at f/2-f/2.8 (f/1.8 if the face and shoulder candles can be kept in one plane). Around 1/125 s, ISO 800-3200, RAW."}, {"name": "amber-and-olive grade with lifted matte blacks and fine grain", "timecode": "", "evidence": "Sampled background shadows are green-leaning (about RGB 21,34,14 and 16,26,10) rather than neutral; darkest 1 percent of luminance sits at 18/255, not 0; skin sits at hue about 25 degrees orange; whites of the candles are cream, not pure white; visible grain or texture in the dark areas.", "certainty": "observed", "recreation": "Lightroom: raise the black point on the tone curve, colour-grade shadows towards green-olive and highlights towards amber, pull orange saturation back a little so skin does not go neon, warm the whites, add grain. Save as a preset for the set."}, {"name": "styling: glitter copper lip, pale nails, hair pulled back off the face, bare shoulders", "timecode": "", "evidence": "Enlarged crop shows a sparkling copper-bronze lip; white or very pale nails; blonde hair swept back from the forehead and falling behind the ear to about jaw length; no visible clothing other than the wax piece; a ring on the lower hand.", "certainty": "observed", "recreation": "Metallic or glitter lip as the one strong make-up accent, matte skin with a little highlight on the cheekbone, hair secured back and kept well away from any real flame."}, {"name": "safer flame options for the shoulder candles", "timecode": "", "evidence": "Recommendation only; not a claim about how the source was made.", "certainty": "suggested", "recreation": "Preferred: warm LED taper or tea-light inserts set into the wax piece, with the flame replaced or enhanced in Photoshop from a separately photographed real flame at the same angle. If real flames are used: short candles fixed into the rigid base, hair tied back and free of hairspray, an assistant within arm''s reach with a damp cloth, short takes, model seated."}], "shot_candidates": [{"label": "candle-shoulder over-the-shoulder profile close-up", "shot_size": "CU", "body_crop": "top of head to upper chest and near shoulder; both hands in frame", "camera_angle": "three-quarter profile from behind the near shoulder (over-the-shoulder)", "camera_height": "chin to shoulder height, level", "composition": "4:5 vertical; subject fills right two thirds; blurred pillar-candle practicals in the dark left third; shoulder candles lower centre", "model_movement": "still pose: chin lifted, eyes closed, fingertips at lips", "camera_movement": "none (still photograph)", "focal_length": "not recorded in file; short telephoto inferred, 85mm suggested", "recording_settings": "not recorded in file; suggested f/2-2.8, 1/125 s, ISO 800-3200, RAW", "actual_frame": "media/incoming/1000162216.jpg", "confidence": "observed"}], "difficulty": "medium", "editorial_ideas": ["suggested: shoot a three-frame series from one setup - eyes closed chin up (this frame), eyes open looking down the shoulder at the flames, and a detail of hands and wax only.", "suggested: add a short 4K clip of the same pose (A7 IV, 25p, 1/50 s) for a slow push-in with flame flicker, graded in Premiere with the same matte amber-olive look; searched the catalog first and nothing similar exists yet (catalog was empty)."], "notes": "Local file with no origin link; stored as file:media/incoming/1000162216.jpg (SHA-256 a6ab9b33532665cc74bf199aedad626e75fb1fa6ba9da3f187c6afafc995b742). Access: whole image viewed plus enlarged crops made in a scratch folder; the original file was not modified. Attribution: a script watermark at the bottom right reads ''Cap'', a camera icon containing the numeral 2, ''red'', with ''Studio'' beneath - recorded here as ''Cap2red Studio''. Whether it is meant to be read ''Captured Studio'' is a guess, and no handle, URL or post could be checked, so the watermark is the only evidence of authorship. Image is 736 px wide, a size commonly served by Pinterest (inferred, not proof of origin). EXIF carries only resolution fields and ''ProfileCopyright: Google Inc. 2016'' (an ICC colour-profile note, not an author credit); no camera, lens, exposure or date. Not known: the lighting equipment actually used, whether the flames are real or retouched, whether the wax is on fabric or skin, focal length and aperture. No engagement figures exist for this record. Stills have no timecodes, so every ''timecode'' field is intentionally empty."}','Agent 00, REF-000001, access_status=reviewed_images','{"agent00": {"platform": "local", "collection_name": "Candle portrait shoot", "created_at": "2026-11-13T20:49:54.425742+00:00", "updated_at": "2026-11-13T20:51:25.524430+00:00"}}','2026-11-13T20:52:13Z');
INSERT INTO "inspirations" VALUES('INS-0002','upload','Candle portrait reference: candles on bare shoulder, orange cheek glow (1000162212.jpg)','candle portrait reference candles on bare shoulder orange cheek glow 1000162212 jpg',NULL,'Uploaded by owner as a local file for a candle-themed portrait shoot; origin link not known.','Candle portrait shoot','reviewed_images',NULL,'complete','{"reference_id": "REF-000002", "access_status": "reviewed_images", "blocked_reason": "", "creator": "", "title": "Candle portrait reference: candles on bare shoulder, orange cheek glow (1000162212.jpg)", "genre": ["dark experimental", "fantasy/surrealism", "candlelit conceptual portrait"], "story_summary": "Single still image (media/incoming/1000162212.jpg, 736x736, square), reviewed in full plus enlarged crops. A woman with long, loose, wavy dark-blonde hair is seen from the front-left, head tilted down and turned towards her own near shoulder, eyes lowered, lips slightly parted. Two short lit candles stand directly on her bare shoulder, with white wax running down the upper arm and back; her hand clasps the upper arm at the bottom edge. The face is lit cool and soft on the forehead and nose, with a strongly saturated orange patch on the cheek and jaw nearest the flames, against a blue-teal near-black background. The image shows signs of being AI-generated or heavily composited (see techniques), so it is a mood and colour reference rather than proof of a physical setup.", "techniques": [{"name": "two lit candles standing on a bare shoulder with wax running down the arm", "timecode": "", "evidence": "Whole frame and enlarged crop of the lower right: two short candles with flames on the top of the shoulder; white wax pooled at their bases and running in thin streams down the upper arm and behind it; one separate wax droplet on the skin.", "certainty": "observed", "recreation": "Do not attempt literally. Build a thin skin-toned or clear shoulder cap (or a strip of fabric tape base) carrying the candle stubs and pre-set drips, fix it with body-safe adhesive or a hidden strap, and paint a few extra cooled drips of body-safe material beyond its edge so it reads as wax on skin. Blend the edge in Photoshop."}, {"name": "image is probably AI-generated or a heavy composite", "timecode": "", "evidence": "Wax streams continue into and merge with strands of hair behind the arm; the candles sit on skin with no contact shadow or support; the cheek glow is a deep saturated orange (sampled about RGB 210,68,6) while the flames are pale yellow-white and sit below and behind the cheek; skin and hair have a uniform painted smoothness; pure black and pure white are both clipped; the file has no EXIF at all and no watermark. None of this is conclusive.", "certainty": "inferred", "recreation": "Treat the picture as a target mood. Expect a real photograph to look less saturated in the orange and to need a hidden light to create the cheek glow."}, {"name": "cool-and-warm two-colour lighting: neutral-cool soft key with a saturated orange accent on one cheek", "timecode": "", "evidence": "Forehead and bare shoulder sample almost neutral grey (about RGB 99,103,102 and 82,81,77); cheek and jaw nearest the candles sample saturated orange (hue about 18 degrees, saturation above 0.8); background samples blue-teal (hue about 200 degrees). A small specular highlight sits on the tip of the nose.", "certainty": "observed", "recreation": "Light 1: portable LED in a small softbox at camera left, slightly above eye level, daylight-balanced and dimmed low. Light 2: a small RGB tube or pocket LED set to orange (or tungsten with full CTO plus a little red), hidden low at camera right near the shoulder, flagged with black card so it only touches cheek, jaw and neck. Camera white balance fixed around 4300-4800K so the key reads slightly cool and the accent stays orange."}, {"name": "the orange accent is meant to read as candle glow", "timecode": "", "evidence": "The orange patch is on the side of the face nearest the two flames and fades with distance from them; no other warm source is visible.", "certainty": "inferred", "recreation": "Keep the accent light on the same line as the candles from the face so the glow looks motivated, and add slight flicker only if shooting video."}, {"name": "downcast gaze towards the shoulder, head tilted, hand clasping the upper arm", "timecode": "", "evidence": "Eyes open but lowered towards frame right and down; head tilted down and towards the near shoulder; lips slightly parted; fingers of one hand wrap the upper arm at the bottom edge with natural pale-pink nails.", "certainty": "observed", "recreation": "Model seated, near shoulder rolled slightly forward, chin dropped towards it; ask her to look at the flames rather than at the lens. The self-holding hand keeps the arm steady, which also helps the prop."}, {"name": "square close-up, face upper centre-left, candles lower centre-right, hair filling the left side", "timecode": "", "evidence": "736x736 frame; face occupies the upper middle; the two flames sit just right of centre in the lower half; long hair fills the left third and frames the right; top of the head is cropped; background is a featureless dark blue-teal blur.", "certainty": "observed", "recreation": "Frame slightly loose on a vertical 4:5 and crop to square later, keeping the eye-to-flame diagonal."}, {"name": "shallow depth of field at portrait focal length", "timecode": "", "evidence": "Face, candles and shoulder all appear sharp while the background is completely smooth; perspective on the face is flat. With a possibly synthetic image there is no real lens to identify, and the file carries no EXIF.", "certainty": "inferred", "recreation": "Sony A7 IV with 85mm at f/2.8-f/4 (the face and the shoulder candles are at different distances, so stop down further than for REF-000001), 1/125 s, ISO 400-1600, RAW; background at least 2 m behind."}, {"name": "teal-black background with deep, clipped blacks and high colour contrast", "timecode": "", "evidence": "Background samples about RGB 17,27,31, 9,19,25 and 14,31,40; darkest 1 percent of luminance is 0 (true black, unlike the matte look of REF-000001); image median is very dark (25/255).", "certainty": "observed", "recreation": "Dark grey or black backdrop left unlit, then in Lightroom push shadows towards teal with colour grading, keep blacks deep, and raise orange saturation and lower orange luminance selectively on the cheek with a masked adjustment."}, {"name": "styling: long loose waves, smoky bronze eye, mauve-pink lip, bare shoulders", "timecode": "", "evidence": "Enlarged face crop shows defined dark brows, bronze-brown smoky eyeshadow, a satin mauve-pink lip and smooth matte skin; hair is long, loose and wavy over both shoulders; no clothing visible.", "certainty": "observed", "recreation": "Achievable make-up. Loose hair this close to flame is a fire risk: pin the hair behind the candle-side shoulder or use LED candles and add the flames in post."}, {"name": "LED candles plus composited flames", "timecode": "", "evidence": "Recommendation only; not a claim about how the source was made.", "certainty": "suggested", "recreation": "Photograph a real candle flame separately against black at the same focal length and angle, then screen-blend it over LED candle stubs in Photoshop. This allows loose hair and long posing time."}], "shot_candidates": [{"label": "candles on bare shoulder with orange cheek glow, downcast gaze", "shot_size": "CU", "body_crop": "forehead (top of head cropped) to upper arm; one hand at bottom edge", "camera_angle": "front three-quarter, model''s head turned towards her near shoulder", "camera_height": "eye level or slightly above, level", "composition": "1:1 square; face upper centre-left, twin flames lower centre-right forming an eye-to-flame diagonal; hair fills left third; plain teal-black background", "model_movement": "still pose: head tilted down, eyes lowered to the flames, hand holding upper arm", "camera_movement": "none (still image)", "focal_length": "not recorded in file and image may be synthetic; 85mm suggested", "recording_settings": "not recorded in file; suggested f/2.8-4, 1/125 s, ISO 400-1600, RAW", "actual_frame": "media/incoming/1000162212.jpg", "confidence": "observed"}], "difficulty": "medium-hard", "editorial_ideas": ["suggested: use the cool-key and orange-accent lighting from this reference as a second look in the same session as REF-000001''s all-warm setup, changing only the key colour temperature, accent light and grade.", "suggested: an original combination - REF-000001''s wearable wax shoulder piece and over-the-shoulder angle, lit with this reference''s cool key and orange cheek accent."], "notes": "Local file with no origin link; stored as file:media/incoming/1000162212.jpg (SHA-256 699d64a6b2213f9e4d2eadcb3e8e1d0a41b8e575ce4f374fb3b0b02b358585e8). Access: whole image viewed plus enlarged crops and a brightened copy made in a scratch folder; the original file was not modified. Attribution: no watermark, signature, caption or embedded metadata was found (corners and dark areas checked on a brightened copy; EXIF is empty), so the creator is unknown and none is recorded. Image is 736 px wide, a size commonly served by Pinterest (inferred, not proof of origin). The AI-generated judgement is an inference from visual artefacts and has not been confirmed by any tool or source. Not known: who made it, with what, and whether any physical shoot lies behind it. No engagement figures exist for this record. Stills have no timecodes, so every ''timecode'' field is intentionally empty. Difficulty is higher than REF-000001 because the prop has to pass as wax on bare skin and the two-colour light needs tight flagging."}','Agent 00, REF-000002, access_status=reviewed_images','{"agent00": {"platform": "local", "collection_name": "Candle portrait shoot", "created_at": "2026-11-13T20:49:54.477871+00:00", "updated_at": "2026-11-13T20:51:25.588660+00:00"}}','2026-11-13T20:52:13Z');
CREATE TABLE manifest_proposals (
  id          TEXT PRIMARY KEY,                -- MPR-0001
  name        TEXT NOT NULL,
  name_norm   TEXT NOT NULL,
  category    TEXT,
  spec_json   TEXT NOT NULL,
  source_ref  TEXT,
  similar_to  TEXT,                            -- SHT- id of a near match, if any
  status      TEXT NOT NULL DEFAULT 'proposed' CHECK (status IN ('proposed','approved','rejected')),
  manifest_id TEXT REFERENCES shot_manifest(id),
  created_at  TEXT NOT NULL,
  decided_at  TEXT
);
CREATE TABLE meta (
  key   TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
INSERT INTO "meta" VALUES('created_at','2026-11-13T04:47:52Z');
INSERT INTO "meta" VALUES('schema_version','2');
INSERT INTO "meta" VALUES('current_project','PRJ-0001');
CREATE TABLE metrics (
  id             INTEGER PRIMARY KEY AUTOINCREMENT,
  publication_id TEXT NOT NULL REFERENCES publications(id),
  captured_at    TEXT NOT NULL,
  source         TEXT NOT NULL,                -- where the numbers came from (e.g. "pasted Insights")
  data_json      TEXT NOT NULL
);
CREATE TABLE project_inspirations (
  project_id     TEXT NOT NULL REFERENCES projects(id),
  inspiration_id TEXT NOT NULL REFERENCES inspirations(id),
  PRIMARY KEY (project_id, inspiration_id)
);
INSERT INTO "project_inspirations" VALUES('PRJ-0001','INS-0001');
INSERT INTO "project_inspirations" VALUES('PRJ-0001','INS-0002');
CREATE TABLE projects (
  id           TEXT PRIMARY KEY,               -- PRJ-0001
  title        TEXT NOT NULL,
  workflow     TEXT NOT NULL CHECK (workflow IN ('A','B','C','D','E')),
  stage        TEXT NOT NULL,
  status       TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','paused','done','cancelled')),
  brief        TEXT,
  external_ref TEXT,                           -- e.g. a Frameplan shoot ID
  budget_usd   REAL NOT NULL,
  created_at   TEXT NOT NULL,
  updated_at   TEXT NOT NULL
);
INSERT INTO "projects" VALUES('PRJ-0001','Candle portrait shoot','B','production_plan','active','Candle-themed portrait shoot from two saved references (REF-000001, REF-000002). Owner decision 13 Nov 2026: use REAL candles, not LED with composited flames. Plan the prop, hair styling and safety measures around live flame. No source links or creators beyond the Cap2red Studio watermark on REF-000001.',NULL,10.0,'2026-11-13T20:57:42Z','2026-11-14T09:12:33Z');
INSERT INTO "projects" VALUES('PRJ-0002','Why forklift and pedestrian segregation matters','E','proposal','cancelled','Motion Director test run 1 (skill default path: WHS/HSE, LinkedIn, 9:16). Title chosen by Claude from the skill''s own example; owner may substitute.',NULL,10.0,'2026-11-13T21:05:54Z','2026-11-13T21:10:33Z');
CREATE TABLE prompts (
  id         TEXT PRIMARY KEY,                 -- PRM-0001
  project_id TEXT NOT NULL REFERENCES projects(id),
  shot_id    TEXT REFERENCES shots(id),
  provider   TEXT NOT NULL,
  model      TEXT,
  kind       TEXT NOT NULL CHECK (kind IN ('image','video','audio')),
  prompt     TEXT NOT NULL,
  params_json TEXT,
  parent_id  TEXT REFERENCES prompts(id),      -- refinement chain
  created_at TEXT NOT NULL
);
INSERT INTO "prompts" VALUES('PRM-0001','PRJ-0001',NULL,'idea_ai','seedream_4_5','image','Cinematic still photograph at night. Close-up of an adult woman''s hands striking a long match and lighting the first of two tall white candles set in a sculpted mass of white dripped wax on her bare shoulder; her face is only partly lit, eyes lowered to the flame. Warm amber candlelight on hands, jaw and neck; a faint cool fill on the far side of her face; teal-black background with two out-of-focus lit pillar candles. Lifted matte blacks, fine film grain, shallow depth of field, 85mm portrait look, vertical 4:5. Real photography, natural skin texture, accurate hands with five fingers, no text, no watermark, single image, not a collage.','{"purpose":"style preview for the approved Ember+Cold Hours look","beat":1,"aspect_ratio":"4:5","quote_coins":690}',NULL,'2026-11-14T01:42:05Z');
INSERT INTO "prompts" VALUES('PRM-0002','PRJ-0001',NULL,'idea_ai','seedream_4_5','image','Cinematic still photograph at night. Over-the-shoulder three-quarter profile of an adult woman, head tilted back, eyes closed, fingertips resting at her lips. A sculpted mass of white dripped candle wax sits on her bare near shoulder with two lit candles, now burned halfway down. Warm amber candlelight on her jaw, neck and hand; a faint cool fill on the far side of her face; teal-black background with two out-of-focus lit pillar candles. Lifted matte blacks, fine film grain, shallow depth of field, 85mm portrait look, vertical 4:5. Real photography, natural skin texture, accurate hands with five fingers, no text, no watermark, single image, not a collage.','{"purpose":"style preview for the approved Ember+Cold Hours look","beat":2,"aspect_ratio":"4:5","quote_coins":690}',NULL,'2026-11-14T01:42:05Z');
INSERT INTO "prompts" VALUES('PRM-0003','PRJ-0001',NULL,'idea_ai','seedream_4_5','image','Cinematic still photograph at night. Three-quarter profile of an adult woman looking down at her bare shoulder, where a sculpted mass of white dripped wax holds two candles burned almost to stubs; she has just blown one out and a thin thread of smoke rises while the last small flame still burns. Dim warm amber light on her face from the remaining flame; cool teal-black shadows; two out-of-focus pillar candles behind, one extinguished. Lifted matte blacks, fine film grain, shallow depth of field, 85mm portrait look, vertical 4:5. Real photography, natural skin texture, accurate hands with five fingers, no text, no watermark, single image, not a collage.','{"purpose":"style preview for the approved Ember+Cold Hours look","beat":3,"aspect_ratio":"4:5","quote_coins":690}',NULL,'2026-11-14T01:42:05Z');
CREATE TABLE publications (
  id          TEXT PRIMARY KEY,                -- PUB-0001
  project_id  TEXT NOT NULL REFERENCES projects(id),
  platform    TEXT NOT NULL,
  status      TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','scheduled','published')),
  caption     TEXT,
  asset_id    TEXT REFERENCES assets(id),
  approval_id TEXT REFERENCES approvals(id),
  scheduled_at TEXT,
  published_at TEXT,
  url         TEXT,
  created_at  TEXT NOT NULL
);
CREATE TABLE reference_shots (
  id              TEXT PRIMARY KEY,            -- RSH-0001
  inspiration_id  TEXT REFERENCES inspirations(id),
  ref_id          TEXT,                        -- Agent 00 REF- id, when the row came from Agent 00
  asset_id        TEXT REFERENCES assets(id),
  project_id      TEXT REFERENCES projects(id),
  source_label    TEXT,                        -- file the row was imported from
  candidate_label TEXT,
  -- the 15 columns of SHOT_MANIFEST_TEMPLATE.csv, in order
  shot_id TEXT, start_time TEXT, end_time TEXT, shot_size TEXT, body_crop TEXT,
  camera_angle TEXT, camera_height TEXT, composition TEXT, model_movement TEXT,
  camera_movement TEXT, focal_length TEXT, recording_settings TEXT, actual_frame TEXT,
  sketch TEXT, confidence TEXT,
  approval_status TEXT NOT NULL DEFAULT 'PENDING_REVIEW' CHECK (approval_status IN
                    ('PENDING_REVIEW','APPROVED','REJECTED')),
  approval_id     TEXT REFERENCES approvals(id),
  row_hash        TEXT NOT NULL UNIQUE,        -- makes imports idempotent
  created_at      TEXT NOT NULL,
  decided_at      TEXT
);
INSERT INTO "reference_shots" VALUES('RSH-0001','INS-0001','REF-000001',NULL,NULL,'shot_proposals.csv','candle-shoulder over-the-shoulder profile close-up','PROPOSED-0001','','','CU','top of head to upper chest and near shoulder; both hands in frame','three-quarter profile from behind the near shoulder (over-the-shoulder)','chin to shoulder height, level','4:5 vertical; subject fills right two thirds; blurred pillar-candle practicals in the dark left third; shoulder candles lower centre','still pose: chin lifted, eyes closed, fingertips at lips','none (still photograph)','not recorded in file; short telephoto inferred, 85mm suggested','not recorded in file; suggested f/2-2.8, 1/125 s, ISO 800-3200, RAW','media/incoming/1000162216.jpg','','observed','APPROVED','APR-0001','ce92c7832365b435742a8a769cd142bd28baab1d19f971ce434b6f4cc21a4bee','2026-11-13T20:52:13Z','2026-11-13T20:57:42Z');
INSERT INTO "reference_shots" VALUES('RSH-0002','INS-0002','REF-000002',NULL,NULL,'shot_proposals.csv','candles on bare shoulder with orange cheek glow, downcast gaze','PROPOSED-0002','','','CU','forehead (top of head cropped) to upper arm; one hand at bottom edge','front three-quarter, model''s head turned towards her near shoulder','eye level or slightly above, level','1:1 square; face upper centre-left, twin flames lower centre-right forming an eye-to-flame diagonal; hair fills left third; plain teal-black background','still pose: head tilted down, eyes lowered to the flames, hand holding upper arm','none (still image)','not recorded in file and image may be synthetic; 85mm suggested','not recorded in file; suggested f/2.8-4, 1/125 s, ISO 400-1600, RAW','media/incoming/1000162212.jpg','','observed','APPROVED','APR-0001','fd095da24ab5252bcbe1b647a1c33f09c0c0557a84888b046a06d6b6042fb129','2026-11-13T20:52:13Z','2026-11-13T20:57:42Z');
CREATE TABLE shot_manifest (
  id          TEXT PRIMARY KEY,                -- SHT-0001
  name        TEXT NOT NULL,
  name_norm   TEXT NOT NULL UNIQUE,
  category    TEXT,
  spec_json   TEXT NOT NULL,                   -- framing, movement, lens, lighting, how-to
  version     INTEGER NOT NULL DEFAULT 1,
  source_ref  TEXT,                            -- INS-/AST-/PRJ- id it came from
  approval_id TEXT REFERENCES approvals(id),
  created_at  TEXT NOT NULL
);
CREATE TABLE shots (
  id          TEXT PRIMARY KEY,                -- SHO-0001
  project_id  TEXT NOT NULL REFERENCES projects(id),
  document_id TEXT NOT NULL REFERENCES documents(id),
  seq         INTEGER NOT NULL,
  manifest_id TEXT REFERENCES shot_manifest(id),
  description TEXT NOT NULL,
  spec_json   TEXT,                            -- framing, lens, settings, movement, lighting, duration
  UNIQUE (document_id, seq)
);
INSERT INTO "shots" VALUES('SHO-0001','PRJ-0001','DOC-0009',1,NULL,'HOOK, video. Darkness; a match flares and is brought to the first wick on the shoulder piece; the flame catches.','{"beat": "hook", "type": "video", "duration_s": 3, "shot_size": "ECU", "body_crop": "hands, match and the two wicks; face out of frame", "camera_angle": "three-quarter from front-left", "camera_height": "shoulder", "composition": "flame centre-right in the 9:16 frame; hands enter from frame left; black around", "camera_movement": "locked", "model_movement": "hand brings the match in, holds, withdraws", "lens": "85mm (minimum focus 0.85 m) or a macro if available", "settings": "4K 25p, 1/50, f/2.8, ISO 1600–3200", "candles": "tall; first unlit, then lit", "lighting": "match and flame only at first; key fades up from zero (or set low throughout)", "notes": "Shoot three takes; strike the match out of frame to avoid flare in the lens", "camera": "Sony A7 IV"}');
INSERT INTO "shots" VALUES('SHO-0002','PRJ-0001','DOC-0009',2,NULL,'HOOK, still. Close detail of the wick catching, hands soft behind.','{"beat": "hook", "type": "still", "shot_size": "ECU", "body_crop": "flame, wick and fingertips", "camera_angle": "side", "camera_height": "shoulder", "composition": "flame on a third; fingertips soft", "camera_movement": "n/a", "model_movement": "held", "lens": "85mm", "settings": "RAW, f/2, 1/160, ISO 1600", "candles": "tall", "lighting": "flame, low warm key", "notes": "Stills set frame 1", "camera": "Sony A7 IV"}');
INSERT INTO "shots" VALUES('SHO-0003','PRJ-0001','DOC-0009',3,NULL,'REVEAL, video. Slow push-in over her shoulder: the wax piece and two flames come into frame, then her lowered eyes.','{"beat": "reveal", "type": "video", "duration_s": 4, "shot_size": "MCU to CU", "body_crop": "top of head to upper chest, ending at chin to shoulder", "camera_angle": "over-the-shoulder three-quarter profile from behind the candle shoulder", "camera_height": "shoulder", "composition": "subject weighted right; pillar candles soft at left", "camera_movement": "slow push-in, about 30 cm over 4 s, slider or gimbal", "model_movement": "eyes lowered to the flames, a slow breath", "lens": "85mm", "settings": "4K 25p, 1/50, f/2, ISO 2000–3200", "candles": "tall", "lighting": "full plan: key, cool fill, teal background, pillars", "notes": "The approved look''s signature frame", "camera": "Sony A7 IV"}');
INSERT INTO "shots" VALUES('SHO-0004','PRJ-0001','DOC-0009',4,NULL,'REVEAL, still. Over-the-shoulder three-quarter profile, eyes lowered to the flames.','{"beat": "reveal", "type": "still", "shot_size": "MCU", "body_crop": "head to upper chest", "camera_angle": "over-the-shoulder three-quarter profile", "camera_height": "shoulder", "composition": "4:5; subject right two thirds; pillars left third", "camera_movement": "n/a", "model_movement": "held", "lens": "85mm", "settings": "RAW, f/2, 1/160, ISO 2000", "candles": "tall", "lighting": "full plan", "notes": "Stills set frame 2", "camera": "Sony A7 IV"}');
INSERT INTO "shots" VALUES('SHO-0005','PRJ-0001','DOC-0009',5,NULL,'HERO, still. Head back, eyes closed, fingertips resting at her lips; the main image of the set.','{"beat": "hero", "type": "still", "shot_size": "CU", "body_crop": "top of head to shoulder; hand in frame", "camera_angle": "three-quarter profile from the candle side", "camera_height": "chin", "composition": "4:5; face upper right; flames lower centre; fingertips leading to the lips", "camera_movement": "n/a", "model_movement": "head back, eyes closed, lips parted, fingertips at lower lip", "lens": "85mm", "settings": "RAW, f/1.8–2.2, 1/125, ISO 2500", "candles": "half", "lighting": "full plan; check the cool fill reads on the far cheek", "notes": "Stills set frame 3 (hero). Its pose is close to REF-000001: change the hand and head angle so it is not a copy", "camera": "Sony A7 IV"}');
INSERT INTO "shots" VALUES('SHO-0006','PRJ-0001','DOC-0009',6,NULL,'HERO, video. The same pose held; very slow push-in; flames flicker; one breath.','{"beat": "hero", "type": "video", "duration_s": 5, "shot_size": "CU", "body_crop": "top of head to shoulder", "camera_angle": "three-quarter profile from the candle side", "camera_height": "chin", "composition": "as the hero still, 9:16", "camera_movement": "very slow push-in, about 10 cm over 5 s", "model_movement": "stillness; one slow breath; slight head settle", "lens": "85mm", "settings": "4K 25p, 1/50, f/2, ISO 2500", "candles": "half", "lighting": "full plan", "notes": "Hold 8–10 s per take for editing room", "camera": "Sony A7 IV"}');
INSERT INTO "shots" VALUES('SHO-0007','PRJ-0001','DOC-0009',7,NULL,'BREATH, video, part 1. Locked-off medium shot; she sits upright, eyes closed, half candles.','{"beat": "breath", "type": "video", "duration_s": 1.5, "shot_size": "MS", "body_crop": "head to waist", "camera_angle": "three-quarter front", "camera_height": "chest", "composition": "locked frame with headroom; candles clearly readable", "camera_movement": "locked — do not touch the tripod between parts 1 and 2", "model_movement": "upright, still", "lens": "50mm", "settings": "4K 25p, 1/50, f/2.8, ISO 3200", "candles": "half", "lighting": "full plan, unchanged between parts", "notes": "Mark the model''s position with tape", "camera": "Sony A7 IV"}');
INSERT INTO "shots" VALUES('SHO-0008','PRJ-0001','DOC-0009',8,NULL,'BREATH, video, part 2. The identical locked frame; candles now stubs; her posture has sunk; she opens her eyes and looks down at the flames.','{"beat": "breath", "type": "video", "duration_s": 2, "shot_size": "MS", "body_crop": "head to waist", "camera_angle": "three-quarter front", "camera_height": "chest", "composition": "identical to part 1", "camera_movement": "locked", "model_movement": "shoulders lowered, head tilted, eyes open to the flames", "lens": "50mm", "settings": "as part 1", "candles": "stub (swap the candle set; keep the wax piece in place)", "lighting": "as part 1", "notes": "The hard cut between parts 1 and 2 is the time jump", "camera": "Sony A7 IV"}');
INSERT INTO "shots" VALUES('SHO-0009','PRJ-0001','DOC-0009',9,NULL,'BREATH, still. Eyes open, looking down the shoulder at the stub candles.','{"beat": "breath", "type": "still", "shot_size": "CU", "body_crop": "face to shoulder", "camera_angle": "three-quarter front", "camera_height": "eye", "composition": "4:5; eyes to flames on a diagonal", "camera_movement": "n/a", "model_movement": "eyes lowered to the flames", "lens": "85mm", "settings": "RAW, f/2, 1/160, ISO 2500", "candles": "stub", "lighting": "full plan", "notes": "Stills set frame 4", "camera": "Sony A7 IV"}');
INSERT INTO "shots" VALUES('SHO-0010','PRJ-0001','DOC-0009',10,NULL,'ENDING, video, slow motion. She blows out one candle; a thread of smoke rises from that wick; the last flame still burns.','{"beat": "ending", "type": "video", "duration_s": 3, "shot_size": "CU", "body_crop": "lips to shoulder", "camera_angle": "side", "camera_height": "shoulder", "composition": "the blown-out wick centre frame; smoke rising into black", "camera_movement": "locked", "model_movement": "a single gentle breath out at the nearer candle", "lens": "50mm at 4K 50p (crop), or 85mm at FHD 100p", "settings": "4K 50p or FHD 100p, 1/100, f/2.8, ISO 3200", "candles": "stub", "lighting": "key low; backlight the smoke with a small hard source from behind if available", "notes": "The AI preview put the smoke on the wrong candle; check the source on playback", "camera": "Sony A7 IV"}');
INSERT INTO "shots" VALUES('SHO-0011','PRJ-0001','DOC-0009',11,NULL,'ENDING, still. The smoke thread with the last flame still lit.','{"beat": "ending", "type": "still", "shot_size": "CU", "body_crop": "lips, shoulder and both candles", "camera_angle": "side", "camera_height": "shoulder", "composition": "4:5; smoke on the upper third", "camera_movement": "n/a", "model_movement": "just after the breath", "lens": "85mm", "settings": "RAW, f/2.8, 1/200, ISO 3200, burst", "candles": "stub", "lighting": "key low, smoke backlight", "notes": "Stills set frame 5", "camera": "Sony A7 IV"}');
INSERT INTO "shots" VALUES('SHO-0012','PRJ-0001','DOC-0009',12,NULL,'ENDING, video. The last flame is blown out; the frame falls to black.','{"beat": "ending", "type": "video", "duration_s": 2, "shot_size": "CU", "body_crop": "face and shoulder", "camera_angle": "three-quarter profile", "camera_height": "shoulder", "composition": "face lit only by the last flame", "camera_movement": "locked", "model_movement": "blows the last candle out", "lens": "85mm", "settings": "4K 25p, 1/50, f/2, ISO 3200", "candles": "stub, last one lit", "lighting": "key and fill off for this take; flame only, then black", "notes": "Possible loop seam back to the match strike; decided at rough cut", "camera": "Sony A7 IV"}');
INSERT INTO "shots" VALUES('SHO-0013','PRJ-0001','DOC-0009',13,NULL,'DETAIL, still. Hands and wax only: fingers resting on the drips, flames soft above.','{"beat": "detail", "type": "still", "shot_size": "ECU", "body_crop": "hand and wax piece", "camera_angle": "top-side", "camera_height": "above shoulder", "composition": "4:5; drips leading lines down the frame", "camera_movement": "n/a", "model_movement": "fingers resting lightly on the wax", "lens": "85mm", "settings": "RAW, f/2.8, 1/160, ISO 1600", "candles": "any set", "lighting": "key raking across the wax", "notes": "Stills set frame 6", "camera": "Sony A7 IV"}');
INSERT INTO "shots" VALUES('SHO-0014','PRJ-0001','DOC-0009',14,NULL,'WIDE, still. One wider frame of the figure among the pillar candles, for the set''s closing image.','{"beat": "detail", "type": "still", "shot_size": "MWS", "body_crop": "head to hips", "camera_angle": "three-quarter front", "camera_height": "chest", "composition": "4:5; figure right; pillars left; more of the teal-black space", "camera_movement": "n/a", "model_movement": "seated, eyes closed", "lens": "50mm", "settings": "RAW, f/2.8, 1/125, ISO 3200", "candles": "half", "lighting": "full plan; open the background light slightly", "notes": "Stills set frame 7", "camera": "Sony A7 IV"}');
INSERT INTO "shots" VALUES('SHO-0015','PRJ-0001','DOC-0010',1,NULL,'HOOK, video. Darkness; a match flares and is brought to the first wick on the shoulder piece; the flame catches.','{"beat": "hook", "type": "video", "duration_s": 3, "shot_size": "ECU", "body_crop": "hands, match and the two wicks; face out of frame", "camera_angle": "three-quarter from front-left", "camera_height": "shoulder", "composition": "flame centre-right in the 9:16 frame; hands enter from frame left; black around", "camera_movement": "locked", "model_movement": "hand brings the match in, holds, withdraws", "lens": "70mm (or 50mm if the 70 cannot focus this close)", "settings": "4K 25p, 1/50, f/2.8, ISO 1600–3200", "candles": "tall; first unlit, then lit", "lighting": "match and flame only at first; key fades up from zero (or set low throughout)", "notes": "Shoot three takes; strike the match out of frame to avoid flare in the lens; shoot with the camera mounted vertically (native 2160x3840)", "camera": "Sony A7 IV"}');
INSERT INTO "shots" VALUES('SHO-0016','PRJ-0001','DOC-0010',2,NULL,'HOOK, still. Close detail of the wick catching, hands soft behind.','{"beat": "hook", "type": "still", "shot_size": "ECU", "body_crop": "flame, wick and fingertips", "camera_angle": "side", "camera_height": "shoulder", "composition": "flame on a third; fingertips soft", "camera_movement": "n/a", "model_movement": "held", "lens": "70mm", "settings": "RAW, f/2, 1/160, ISO 1600", "candles": "tall", "lighting": "flame, low warm key", "notes": "Stills set frame 1", "camera": "Sony A7 IV"}');
INSERT INTO "shots" VALUES('SHO-0017','PRJ-0001','DOC-0010',3,NULL,'REVEAL, video. Slow push-in over her shoulder: the wax piece and two flames come into frame, then her lowered eyes.','{"beat": "reveal", "type": "video", "duration_s": 4, "shot_size": "MCU to CU", "body_crop": "top of head to upper chest, ending at chin to shoulder", "camera_angle": "over-the-shoulder three-quarter profile from behind the candle shoulder", "camera_height": "shoulder", "composition": "subject weighted right; pillar candles soft at left", "camera_movement": "locked on the tripod, camera mounted vertically; slow push-in added in the edit (about 15%)", "model_movement": "eyes lowered to the flames, a slow breath", "lens": "70mm", "settings": "4K 25p, 1/50, f/2, ISO 2000–3200", "candles": "tall", "lighting": "full plan: key, cool fill, teal background, pillars", "notes": "The approved look''s signature frame", "camera": "Sony A7 IV"}');
INSERT INTO "shots" VALUES('SHO-0018','PRJ-0001','DOC-0010',4,NULL,'REVEAL, still. Over-the-shoulder three-quarter profile, eyes lowered to the flames.','{"beat": "reveal", "type": "still", "shot_size": "MCU", "body_crop": "head to upper chest", "camera_angle": "over-the-shoulder three-quarter profile", "camera_height": "shoulder", "composition": "4:5; subject right two thirds; pillars left third", "camera_movement": "n/a", "model_movement": "held", "lens": "70mm", "settings": "RAW, f/2, 1/160, ISO 2000", "candles": "tall", "lighting": "full plan", "notes": "Stills set frame 2", "camera": "Sony A7 IV"}');
INSERT INTO "shots" VALUES('SHO-0019','PRJ-0001','DOC-0010',5,NULL,'HERO, still. Head back, eyes closed, fingertips resting at her lips; the main image of the set.','{"beat": "hero", "type": "still", "shot_size": "CU", "body_crop": "top of head to shoulder; hand in frame", "camera_angle": "three-quarter profile from the candle side", "camera_height": "chin", "composition": "4:5; face upper right; flames lower centre; fingertips leading to the lips", "camera_movement": "n/a", "model_movement": "head back, eyes closed, lips parted, fingertips at lower lip", "lens": "70mm", "settings": "RAW, f/1.8–2.2, 1/125, ISO 2500", "candles": "half", "lighting": "full plan; check the cool fill reads on the far cheek", "notes": "Stills set frame 3 (hero). Its pose is close to REF-000001: change the hand and head angle so it is not a copy", "camera": "Sony A7 IV"}');
INSERT INTO "shots" VALUES('SHO-0020','PRJ-0001','DOC-0010',6,NULL,'HERO, video. The same pose held; very slow push-in; flames flicker; one breath.','{"beat": "hero", "type": "video", "duration_s": 5, "shot_size": "CU", "body_crop": "top of head to shoulder", "camera_angle": "three-quarter profile from the candle side", "camera_height": "chin", "composition": "as the hero still, 9:16", "camera_movement": "locked, vertical; very slow digital push-in in the edit (about 8%)", "model_movement": "stillness; one slow breath; slight head settle", "lens": "70mm", "settings": "4K 25p, 1/50, f/2, ISO 2500", "candles": "half", "lighting": "full plan", "notes": "Hold 8–10 s per take for editing room", "camera": "Sony A7 IV"}');
INSERT INTO "shots" VALUES('SHO-0021','PRJ-0001','DOC-0010',7,NULL,'BREATH, video, part 1. Locked-off medium shot; she sits upright, eyes closed, half candles.','{"beat": "breath", "type": "video", "duration_s": 1.5, "shot_size": "MS", "body_crop": "head to waist", "camera_angle": "three-quarter front", "camera_height": "chest", "composition": "locked frame with headroom; candles clearly readable", "camera_movement": "locked — do not touch the tripod between parts 1 and 2", "model_movement": "upright, still", "lens": "50mm", "settings": "4K 25p, 1/50, f/2.8, ISO 3200", "candles": "half", "lighting": "full plan, unchanged between parts", "notes": "Mark the model''s position with tape; shoot with the camera mounted vertically (native 2160x3840)", "camera": "Sony A7 IV"}');
INSERT INTO "shots" VALUES('SHO-0022','PRJ-0001','DOC-0010',8,NULL,'BREATH, video, part 2. The identical locked frame; candles now stubs; her posture has sunk; she opens her eyes and looks down at the flames.','{"beat": "breath", "type": "video", "duration_s": 2, "shot_size": "MS", "body_crop": "head to waist", "camera_angle": "three-quarter front", "camera_height": "chest", "composition": "identical to part 1", "camera_movement": "locked", "model_movement": "shoulders lowered, head tilted, eyes open to the flames", "lens": "50mm", "settings": "as part 1", "candles": "stub (swap the candle set; keep the wax piece in place)", "lighting": "as part 1", "notes": "The hard cut between parts 1 and 2 is the time jump; shoot with the camera mounted vertically (native 2160x3840)", "camera": "Sony A7 IV"}');
INSERT INTO "shots" VALUES('SHO-0023','PRJ-0001','DOC-0010',9,NULL,'BREATH, still. Eyes open, looking down the shoulder at the stub candles.','{"beat": "breath", "type": "still", "shot_size": "CU", "body_crop": "face to shoulder", "camera_angle": "three-quarter front", "camera_height": "eye", "composition": "4:5; eyes to flames on a diagonal", "camera_movement": "n/a", "model_movement": "eyes lowered to the flames", "lens": "70mm", "settings": "RAW, f/2, 1/160, ISO 2500", "candles": "stub", "lighting": "full plan", "notes": "Stills set frame 4", "camera": "Sony A7 IV"}');
INSERT INTO "shots" VALUES('SHO-0024','PRJ-0001','DOC-0010',10,NULL,'ENDING, video, slow motion. She blows out one candle; a thread of smoke rises from that wick; the last flame still burns.','{"beat": "ending", "type": "video", "duration_s": 3, "shot_size": "CU", "body_crop": "lips to shoulder", "camera_angle": "side", "camera_height": "shoulder", "composition": "the blown-out wick centre frame; smoke rising into black", "camera_movement": "locked", "model_movement": "a single gentle breath out at the nearer candle", "lens": "50mm at 4K 50p (Super 35 crop, about 75mm equivalent), or 70mm at FHD 100p", "settings": "4K 50p or FHD 100p, 1/100, f/2.8, ISO 3200", "candles": "stub", "lighting": "key low; backlight the smoke with a small hard source from behind if available", "notes": "The AI preview put the smoke on the wrong candle; check the source on playback; shoot with the camera mounted vertically (native 2160x3840)", "camera": "Sony A7 IV"}');
INSERT INTO "shots" VALUES('SHO-0025','PRJ-0001','DOC-0010',11,NULL,'ENDING, still. The smoke thread with the last flame still lit.','{"beat": "ending", "type": "still", "shot_size": "CU", "body_crop": "lips, shoulder and both candles", "camera_angle": "side", "camera_height": "shoulder", "composition": "4:5; smoke on the upper third", "camera_movement": "n/a", "model_movement": "just after the breath", "lens": "70mm", "settings": "RAW, f/2.8, 1/200, ISO 3200, burst", "candles": "stub", "lighting": "key low, smoke backlight", "notes": "Stills set frame 5", "camera": "Sony A7 IV"}');
INSERT INTO "shots" VALUES('SHO-0026','PRJ-0001','DOC-0010',12,NULL,'ENDING, video. The last flame is blown out; the frame falls to black.','{"beat": "ending", "type": "video", "duration_s": 2, "shot_size": "CU", "body_crop": "face and shoulder", "camera_angle": "three-quarter profile", "camera_height": "shoulder", "composition": "face lit only by the last flame", "camera_movement": "locked", "model_movement": "blows the last candle out", "lens": "70mm", "settings": "4K 25p, 1/50, f/2, ISO 3200", "candles": "stub, last one lit", "lighting": "key and fill off for this take; flame only, then black", "notes": "Possible loop seam back to the match strike; decided at rough cut; shoot with the camera mounted vertically (native 2160x3840)", "camera": "Sony A7 IV"}');
INSERT INTO "shots" VALUES('SHO-0027','PRJ-0001','DOC-0010',13,NULL,'DETAIL, still. Hands and wax only: fingers resting on the drips, flames soft above.','{"beat": "detail", "type": "still", "shot_size": "ECU", "body_crop": "hand and wax piece", "camera_angle": "top-side", "camera_height": "above shoulder", "composition": "4:5; drips leading lines down the frame", "camera_movement": "n/a", "model_movement": "fingers resting lightly on the wax", "lens": "70mm", "settings": "RAW, f/2.8, 1/160, ISO 1600", "candles": "any set", "lighting": "key raking across the wax", "notes": "Stills set frame 6", "camera": "Sony A7 IV"}');
INSERT INTO "shots" VALUES('SHO-0028','PRJ-0001','DOC-0010',14,NULL,'WIDE, still. One wider frame of the figure among the pillar candles, for the set''s closing image.','{"beat": "detail", "type": "still", "shot_size": "MWS", "body_crop": "head to hips", "camera_angle": "three-quarter front", "camera_height": "chest", "composition": "4:5; figure right; pillars left; more of the teal-black space", "camera_movement": "n/a", "model_movement": "seated, eyes closed", "lens": "50mm", "settings": "RAW, f/2.8, 1/125, ISO 3200", "candles": "half", "lighting": "full plan; open the background light slightly", "notes": "Stills set frame 7", "camera": "Sony A7 IV"}');
CREATE TABLE stage_history (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  project_id TEXT NOT NULL REFERENCES projects(id),
  from_stage TEXT,
  to_stage   TEXT NOT NULL,
  note       TEXT,
  at         TEXT NOT NULL
);
INSERT INTO "stage_history" VALUES(1,'PRJ-0001',NULL,'ingest','project created','2026-11-13T20:57:42Z');
INSERT INTO "stage_history" VALUES(2,'PRJ-0002',NULL,'topic','project created','2026-11-13T21:05:54Z');
INSERT INTO "stage_history" VALUES(3,'PRJ-0002','topic','research',NULL,'2026-11-13T21:05:54Z');
INSERT INTO "stage_history" VALUES(4,'PRJ-0002','research','proposal',NULL,'2026-11-13T21:05:55Z');
INSERT INTO "stage_history" VALUES(5,'PRJ-0002','proposal','proposal','status -> cancelled: Wrong input: coordinator substituted the skill''s built-in example title for the owner''s candle-portrait references. See docs/tests/MOTION_DIRECTOR_TEST_2026-11-14.md','2026-11-13T21:10:33Z');
INSERT INTO "stage_history" VALUES(6,'PRJ-0001','ingest','analysis',NULL,'2026-11-13T21:11:33Z');
INSERT INTO "stage_history" VALUES(7,'PRJ-0001','analysis','technique_extraction',NULL,'2026-11-13T21:11:33Z');
INSERT INTO "stage_history" VALUES(8,'PRJ-0001','technique_extraction','adaptation',NULL,'2026-11-13T21:11:33Z');
INSERT INTO "stage_history" VALUES(9,'PRJ-0001','adaptation','storyboard','concept A approved (APR-0003); style 1 blended with 2 approved (APR-0004)','2026-11-13T21:41:18Z');
INSERT INTO "stage_history" VALUES(10,'PRJ-0001','storyboard','shot_list','storyboard v1 drafted','2026-11-14T09:04:02Z');
INSERT INTO "stage_history" VALUES(11,'PRJ-0001','shot_list','production_plan','shot list v2 fitted to the owner''s kit','2026-11-14T09:12:33Z');
CREATE TABLE technique_shots (
  technique_id      TEXT NOT NULL REFERENCES shot_manifest(id),
  reference_shot_id TEXT NOT NULL REFERENCES reference_shots(id),
  note              TEXT,
  PRIMARY KEY (technique_id, reference_shot_id)
);
CREATE INDEX idx_docs_project ON documents(project_id, kind);
CREATE INDEX idx_approvals_project ON approvals(project_id, gate);
CREATE INDEX idx_insp_title ON inspirations(title_norm);
CREATE INDEX idx_refshots_insp ON reference_shots(inspiration_id);
COMMIT;
