import crypto from "crypto";
import { env } from "../config/env";
import { dbPool } from "../db/pool";

export function hashToken(token: string) {
  return crypto.createHash("sha256").update(token).digest("hex");
}

export async function createEmailVerification(userId: number) {
  const token = crypto.randomBytes(32).toString("hex");
  const tokenHash = hashToken(token);
  const expiresSql = `NOW() + INTERVAL '${env.EMAIL_VERIFY_EXPIRES_HOURS} HOURS'`;

  await dbPool.query(
    `INSERT INTO email_verifications (user_id, token_hash, expires_at)
     VALUES ($1, $2, ${expiresSql})`,
    [userId, tokenHash]
  );

  return token;
}

export async function useEmailVerification(token: string) {
  const tokenHash = hashToken(token);

  const { rows } = await dbPool.query(
    `SELECT * FROM email_verifications
     WHERE token_hash = $1
       AND used_at IS NULL
       AND expires_at > NOW()
     LIMIT 1`,
    [tokenHash]
  );

  const rec = rows[0];
  if (!rec) return null;

  await dbPool.query(
    `UPDATE email_verifications
       SET used_at = NOW()
     WHERE id = $1`,
    [rec.id]
  );

  return rec as {
    id: number;
    user_id: number;
  };
}

export async function markUserEmailVerified(userId: number) {
  await dbPool.query(
    `UPDATE users SET email_verified_at = NOW() WHERE id = $1`,
    [userId]
  );
}
