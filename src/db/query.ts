import pool from './pool';
import type { PoolClient, QueryResult } from 'pg';

export async function query<T = unknown>(text: string, params?: any[]): Promise<QueryResult<T>> {
    return pool.query<T>(text, params);
}

export async function tx<T>(fn : (client: PoolClient) => Promise<T>): Promise<T> {
    const client = await pool.connect();
    try {
        await client.query('BEGIN');
        const result = await fn(client);
        await client.query('COMMIT');
        return result;
    } catch (error) {
        await client.query('ROLLBACK');
        throw error;
    } finally {
        client.release();
    }
}