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
CREATE TABLE gate_log (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  at         TEXT NOT NULL,
  tool       TEXT NOT NULL,
  decision   TEXT NOT NULL CHECK (decision IN ('allowed','denied')),
  approval_id TEXT,
  reason     TEXT
);
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
INSERT INTO "reference_shots" VALUES('RSH-0001','INS-0001','REF-000001',NULL,NULL,'shot_proposals.csv','candle-shoulder over-the-shoulder profile close-up','PROPOSED-0001','','','CU','top of head to upper chest and near shoulder; both hands in frame','three-quarter profile from behind the near shoulder (over-the-shoulder)','chin to shoulder height, level','4:5 vertical; subject fills right two thirds; blurred pillar-candle practicals in the dark left third; shoulder candles lower centre','still pose: chin lifted, eyes closed, fingertips at lips','none (still photograph)','not recorded in file; short telephoto inferred, 85mm suggested','not recorded in file; suggested f/2-2.8, 1/125 s, ISO 800-3200, RAW','media/incoming/1000162216.jpg','','observed','PENDING_REVIEW',NULL,'ce92c7832365b435742a8a769cd142bd28baab1d19f971ce434b6f4cc21a4bee','2026-11-13T20:52:13Z',NULL);
INSERT INTO "reference_shots" VALUES('RSH-0002','INS-0002','REF-000002',NULL,NULL,'shot_proposals.csv','candles on bare shoulder with orange cheek glow, downcast gaze','PROPOSED-0002','','','CU','forehead (top of head cropped) to upper arm; one hand at bottom edge','front three-quarter, model''s head turned towards her near shoulder','eye level or slightly above, level','1:1 square; face upper centre-left, twin flames lower centre-right forming an eye-to-flame diagonal; hair fills left third; plain teal-black background','still pose: head tilted down, eyes lowered to the flames, hand holding upper arm','none (still image)','not recorded in file and image may be synthetic; 85mm suggested','not recorded in file; suggested f/2.8-4, 1/125 s, ISO 400-1600, RAW','media/incoming/1000162212.jpg','','observed','PENDING_REVIEW',NULL,'fd095da24ab5252bcbe1b647a1c33f09c0c0557a84888b046a06d6b6042fb129','2026-11-13T20:52:13Z',NULL);
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
CREATE TABLE stage_history (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  project_id TEXT NOT NULL REFERENCES projects(id),
  from_stage TEXT,
  to_stage   TEXT NOT NULL,
  note       TEXT,
  at         TEXT NOT NULL
);
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
