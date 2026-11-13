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
CREATE TABLE id_counters (
  prefix TEXT PRIMARY KEY,
  next   INTEGER NOT NULL
);
INSERT INTO "id_counters" VALUES('GEN',9);
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
CREATE TABLE inspiration_genres (
  inspiration_id TEXT NOT NULL REFERENCES inspirations(id),
  genre_id       TEXT NOT NULL REFERENCES genres(id),
  PRIMARY KEY (inspiration_id, genre_id)
);
CREATE TABLE inspiration_links (
  inspiration_id TEXT NOT NULL REFERENCES inspirations(id),
  url            TEXT NOT NULL,                -- original link, unmodified
  url_norm       TEXT NOT NULL UNIQUE,         -- duplicate detection key
  PRIMARY KEY (inspiration_id, url)
);
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
