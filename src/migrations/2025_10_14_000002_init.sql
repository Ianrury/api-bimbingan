-- 2025_10_17_000002_email_verifications.sql

-- Tambah kolom opsional di users (kalau mau tandai verified)
ALTER TABLE users
ADD COLUMN IF NOT EXISTS email_verified_at TIMESTAMP NULL;

-- Tabel untuk token verifikasi email
CREATE TABLE IF NOT EXISTS email_verifications (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  used_at TIMESTAMPTZ NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_user_token UNIQUE (user_id, token_hash)
);

CREATE INDEX IF NOT EXISTS idx_email_verifications_user ON email_verifications(user_id);
CREATE INDEX IF NOT EXISTS idx_email_verifications_expires ON email_verifications(expires_at);
