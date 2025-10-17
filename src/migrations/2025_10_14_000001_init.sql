-- =========================================================
-- 0) ENUM TYPES (PostgreSQL)
-- =========================================================
DO $$
BEGIN
  -- buat kalau belum ada
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'role_enum') THEN
    CREATE TYPE role_enum AS ENUM ('admin','pengajar','siswa');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'role_in_class_enum') THEN
    CREATE TYPE role_in_class_enum AS ENUM ('pengajar','siswa','asisten');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'assignment_state_enum') THEN
    CREATE TYPE assignment_state_enum AS ENUM ('draft','open','due','grace','closed','grading','returned');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'content_type_enum') THEN
    CREATE TYPE content_type_enum AS ENUM ('text','file','link','mixed');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'attendance_status_enum') THEN
    CREATE TYPE attendance_status_enum AS ENUM ('present','late','absent','excused');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'thread_scope_enum') THEN
    CREATE TYPE thread_scope_enum AS ENUM ('class','assignment','private');
  END IF;
END$$;

-- =========================================================
-- 1) AUTH & IDENTITAS
-- =========================================================
CREATE TABLE IF NOT EXISTS users (
  id               BIGSERIAL PRIMARY KEY,
  name             VARCHAR(191) NOT NULL,
  email            VARCHAR(191) NOT NULL UNIQUE,
  password         VARCHAR(191) NOT NULL,
  role             role_enum NOT NULL DEFAULT 'siswa',
  email_verified_at TIMESTAMPTZ NULL,
  meta             JSONB NULL,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at       TIMESTAMPTZ NULL
);

-- (opsional, kalau pakai flow reset password klasik)
CREATE TABLE IF NOT EXISTS password_resets (
  email       VARCHAR(191) NOT NULL,
  token       VARCHAR(191) NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_password_resets_email ON password_resets(email);

-- =========================================================
-- 2) ORGANIZATION & MEMBERSHIP
-- =========================================================
CREATE TABLE IF NOT EXISTS organizations (
  id          BIGSERIAL PRIMARY KEY,
  name        VARCHAR(191) NOT NULL,
  logo_url    TEXT NULL,
  domain      VARCHAR(191) NULL UNIQUE,
  settings    JSONB NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at  TIMESTAMPTZ NULL
);

-- per user bisa ikut banyak org dengan peran berbeda
CREATE TABLE IF NOT EXISTS user_organizations (
  id          BIGSERIAL PRIMARY KEY,
  org_id      BIGINT NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  user_id     BIGINT NOT NULL REFERENCES users(id)         ON DELETE CASCADE,
  org_role    role_enum NOT NULL DEFAULT 'admin', -- owner/admin/pengajar/siswa (pakai role_enum sederhana)
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (org_id, user_id)
);
CREATE INDEX IF NOT EXISTS idx_user_org_user ON user_organizations(user_id);
CREATE INDEX IF NOT EXISTS idx_user_org_org  ON user_organizations(org_id);

-- =========================================================
-- 3) KELAS & KEANGGOTAAN KELAS
-- =========================================================
CREATE TABLE IF NOT EXISTS classes (
  id            BIGSERIAL PRIMARY KEY,
  code          VARCHAR(64) NOT NULL UNIQUE,
  name          VARCHAR(191) NOT NULL,
  description   TEXT NULL,
  owner_id      BIGINT NOT NULL REFERENCES users(id),
  period_start  DATE NULL,
  period_end    DATE NULL,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at    TIMESTAMPTZ NULL
);
CREATE INDEX IF NOT EXISTS idx_classes_owner ON classes(owner_id);

CREATE TABLE IF NOT EXISTS class_members (
  id             BIGSERIAL PRIMARY KEY,
  class_id       BIGINT NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  user_id        BIGINT NOT NULL REFERENCES users(id)   ON DELETE CASCADE,
  role_in_class  role_in_class_enum NOT NULL DEFAULT 'siswa',
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (class_id, user_id)
);
CREATE INDEX IF NOT EXISTS idx_class_members_class ON class_members(class_id);
CREATE INDEX IF NOT EXISTS idx_class_members_user  ON class_members(user_id);

-- =========================================================
-- 4) RUBRIC & TEMPLATE
-- =========================================================
CREATE TABLE IF NOT EXISTS rubrics (
  id            BIGSERIAL PRIMARY KEY,
  title         VARCHAR(191) NOT NULL,
  description   TEXT NULL,
  config        JSONB NULL, -- optional level/scales global
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at    TIMESTAMPTZ NULL
);

CREATE TABLE IF NOT EXISTS rubric_items (
  id          BIGSERIAL PRIMARY KEY,
  rubric_id   BIGINT NOT NULL REFERENCES rubrics(id) ON DELETE CASCADE,
  criterion   VARCHAR(191) NOT NULL,
  weight      NUMERIC(5,2) NOT NULL DEFAULT 0, -- 0..100
  levels      JSONB NOT NULL,                  -- [{label,score},...]
  order_no    INT NOT NULL DEFAULT 0,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_rubric_items_rubric ON rubric_items(rubric_id);

CREATE TABLE IF NOT EXISTS assignment_templates (
  id           BIGSERIAL PRIMARY KEY,
  title        VARCHAR(191) NOT NULL,
  description  TEXT NULL,
  rubric_id    BIGINT NULL REFERENCES rubrics(id) ON DELETE SET NULL,
  defaults     JSONB NULL, -- deadline_offset, settings, dll
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at   TIMESTAMPTZ NULL
);

-- =========================================================
-- 5) ASSIGNMENTS, SUBMISSIONS, GRADES
-- =========================================================
CREATE TABLE IF NOT EXISTS assignments (
  id              BIGSERIAL PRIMARY KEY,
  class_id        BIGINT NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  title           VARCHAR(191) NOT NULL,
  description     TEXT NULL,
  rubric_id       BIGINT NULL REFERENCES rubrics(id) ON DELETE SET NULL,
  deadline_at     TIMESTAMPTZ NULL,
  grace_until_at  TIMESTAMPTZ NULL,
  state           assignment_state_enum NOT NULL DEFAULT 'draft',
  settings        JSONB NULL, -- submission_type, max_file, accept_ext, etc.
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at      TIMESTAMPTZ NULL
);
CREATE INDEX IF NOT EXISTS idx_assignments_class_state_deadline
  ON assignments(class_id, state, deadline_at);

CREATE TABLE IF NOT EXISTS submissions (
  id             BIGSERIAL PRIMARY KEY,
  assignment_id  BIGINT NOT NULL REFERENCES assignments(id) ON DELETE CASCADE,
  student_id     BIGINT NOT NULL REFERENCES users(id)       ON DELETE CASCADE,
  content_text   TEXT NULL,
  content_url    TEXT NULL,
  content_type   content_type_enum NOT NULL DEFAULT 'file',
  submitted_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_late        BOOLEAN NOT NULL DEFAULT FALSE,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (assignment_id, student_id)
);
CREATE INDEX IF NOT EXISTS idx_submissions_student_submitted
  ON submissions(student_id, submitted_at);

CREATE TABLE IF NOT EXISTS grades (
  id            BIGSERIAL PRIMARY KEY,
  submission_id BIGINT NOT NULL UNIQUE REFERENCES submissions(id) ON DELETE CASCADE,
  grader_id     BIGINT NOT NULL REFERENCES users(id),
  score_total   NUMERIC(6,2) NOT NULL DEFAULT 0,
  scores_json   JSONB NOT NULL, -- [{rubric_item_id, score, note}]
  feedback      TEXT NULL,
  graded_at     TIMESTAMPTZ NULL,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =========================================================
-- 6) SESSIONS & ATTENDANCE (QR)
-- =========================================================
CREATE TABLE IF NOT EXISTS sessions (
  id            BIGSERIAL PRIMARY KEY,
  class_id      BIGINT NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  topic         VARCHAR(191) NOT NULL,
  start_at      TIMESTAMPTZ NOT NULL,
  end_at        TIMESTAMPTZ NULL,
  qr_token_hash VARCHAR(191) NULL,
  qr_expire_at  TIMESTAMPTZ NULL,
  meta          JSONB NULL, -- meeting_link/room/etc
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_sessions_class_start ON sessions(class_id, start_at);

CREATE TABLE IF NOT EXISTS attendance (
  id           BIGSERIAL PRIMARY KEY,
  session_id   BIGINT NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
  user_id      BIGINT NOT NULL REFERENCES users(id)    ON DELETE CASCADE,
  status       attendance_status_enum NOT NULL DEFAULT 'present',
  device_info  JSONB NULL,
  lat          NUMERIC(10,7) NULL,
  lng          NUMERIC(10,7) NULL,
  scanned_at   TIMESTAMPTZ NULL,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (session_id, user_id)
);
CREATE INDEX IF NOT EXISTS idx_attendance_session ON attendance(session_id);
CREATE INDEX IF NOT EXISTS idx_attendance_user    ON attendance(user_id);

-- =========================================================
-- 7) DISKUSI / CHAT
-- =========================================================
CREATE TABLE IF NOT EXISTS threads (
  id           BIGSERIAL PRIMARY KEY,
  scope        thread_scope_enum NOT NULL,
  scope_id     BIGINT NOT NULL,
  created_by   BIGINT NOT NULL REFERENCES users(id),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_threads_scope ON threads(scope, scope_id);

CREATE TABLE IF NOT EXISTS messages (
  id            BIGSERIAL PRIMARY KEY,
  thread_id     BIGINT NOT NULL REFERENCES threads(id) ON DELETE CASCADE,
  sender_id     BIGINT NOT NULL REFERENCES users(id),
  body          TEXT NOT NULL,
  attachment_url TEXT NULL,
  meta          JSONB NULL,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_messages_thread_created ON messages(thread_id, created_at);

-- =========================================================
-- 8) NOTIFIKASI & AUDIT
-- =========================================================
CREATE TABLE IF NOT EXISTS notifications (
  id          BIGSERIAL PRIMARY KEY,
  user_id     BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type        VARCHAR(191) NOT NULL,
  payload     JSONB NOT NULL,
  read_at     TIMESTAMPTZ NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_notifications_user_read ON notifications(user_id, read_at);

CREATE TABLE IF NOT EXISTS audit_logs (
  id           BIGSERIAL PRIMARY KEY,
  actor_id     BIGINT NOT NULL REFERENCES users(id),
  action       VARCHAR(191) NOT NULL,
  target_type  VARCHAR(191) NOT NULL,
  target_id    BIGINT NULL,
  meta         JSONB NOT NULL,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_audit_actor_created ON audit_logs(actor_id, created_at);

-- =========================================================
-- 9) NICE-TO-HAVE (FILES, INTEGRATIONS, DEVICE SESSIONS)
-- =========================================================
CREATE TABLE IF NOT EXISTS files (
  id          BIGSERIAL PRIMARY KEY,
  owner_type  VARCHAR(191) NOT NULL,  -- e.g. 'assignments','messages','users'
  owner_id    BIGINT NOT NULL,
  url         TEXT NOT NULL,
  mime        VARCHAR(191) NULL,
  size_bytes  BIGINT NULL,
  meta        JSONB NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_files_owner ON files(owner_type, owner_id);

CREATE TABLE IF NOT EXISTS integrations (
  id          BIGSERIAL PRIMARY KEY,
  user_id     BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  provider    VARCHAR(64) NOT NULL, -- 'google','zoom','whatsapp'
  tokens      JSONB NOT NULL,       -- access/refresh
  meta        JSONB NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, provider)
);

CREATE TABLE IF NOT EXISTS device_sessions (
  id           BIGSERIAL PRIMARY KEY,
  user_id      BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  device_name  VARCHAR(191) NULL,
  ip_address   INET NULL,
  last_active  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_device_sessions_user ON device_sessions(user_id);
