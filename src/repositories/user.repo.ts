import type { QueryResultRow } from 'pg';
import { query } from '../db/query';

export type UserRow = QueryResultRow & {
  id: string;
  email: string;
  name: string;
  password: string;
  role: 'ADMIN'|'DOSEN'|'MAHASISWA'|'USER';
  created_at: string;
  updated_at: string;
};

export async function findByEmail(email: string) {
  const sql = `SELECT * FROM users WHERE email = $1 LIMIT 1`;
  const { rows } = await query<UserRow>(sql, [email]);
  return rows[0] ?? null;
}

export async function create(input: { email: string; name: string; password: string; role?: UserRow['role'] }) {
  const sql = `
    INSERT INTO users (email, name, password, role)
    VALUES ($1, $2, $3, COALESCE($4, 'USER'))
    RETURNING id, email, name, role, created_at, updated_at
  `;
  const { rows } = await query(sql, [input.email, input.name, input.password, input.role]);
  return rows[0];
}
