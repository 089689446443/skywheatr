const fs = require('fs');
const path = require('path');

// ── Penentuan Database ──────────────────────────────────────────
// Jika ada DATABASE_URL, pakai PostgreSQL. Jika tidak, pakai SQLite lokal.
const usePostgres = !!process.env.DATABASE_URL;

let pgPool;
let sqliteDb;

if (usePostgres) {
  const { Pool } = require('pg');
  pgPool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: process.env.NODE_ENV === 'production'
      ? { rejectUnauthorized: false }
      : false,
    max: 10,
  });
  pgPool.on('error', (err) => console.error('[DB] PG client error:', err.message));
} else {
  const sqlite3 = require('sqlite3').verbose();
  const dbPath = path.join(__dirname, '..', 'skywheatr.db');
  sqliteDb = new sqlite3.Database(dbPath, (err) => {
    if (err) console.error('[DB] Gagal membuka SQLite:', err.message);
  });
}

// ── Fungsi Helper ──────────────────────────────────────────────
// Konversi format ? (SQLite) ke $1, $2 (PostgreSQL)
function convertPlaceholders(sql) {
  let i = 0;
  return sql.replace(/\?/g, () => `$${++i}`);
}

async function initializeSchema() {
  const tableSql = `
    CREATE TABLE IF NOT EXISTS locations (
      id          ${usePostgres ? 'SERIAL PRIMARY KEY' : 'INTEGER PRIMARY KEY AUTOINCREMENT'},
      name        TEXT    NOT NULL,
      country     TEXT    DEFAULT '',
      latitude    DOUBLE PRECISION NOT NULL,
      longitude   DOUBLE PRECISION NOT NULL,
      timezone    TEXT    DEFAULT '',
      is_primary  INTEGER DEFAULT 0,
      created_at  ${usePostgres ? 'TIMESTAMPTZ DEFAULT NOW()' : 'DATETIME DEFAULT CURRENT_TIMESTAMP'},
      updated_at  ${usePostgres ? 'TIMESTAMPTZ DEFAULT NOW()' : 'DATETIME DEFAULT CURRENT_TIMESTAMP'}
    )
  `;

  if (usePostgres) {
    const client = await pgPool.connect();
    try {
      await client.query(tableSql);
      console.log('[DB] Tabel locations siap digunakan (PostgreSQL).');
    } finally {
      client.release();
    }
  } else {
    return new Promise((resolve, reject) => {
      sqliteDb.run(tableSql, (err) => {
        if (err) return reject(err);
        console.log('[DB] Tabel locations siap digunakan (SQLite lokal).');
        resolve();
      });
    });
  }
}

async function dbAll(sql, params = []) {
  if (usePostgres) {
    const result = await pgPool.query(convertPlaceholders(sql), params);
    return result.rows;
  } else {
    return new Promise((resolve, reject) => {
      sqliteDb.all(sql, params, (err, rows) => {
        if (err) reject(err);
        else resolve(rows);
      });
    });
  }
}

async function dbGet(sql, params = []) {
  if (usePostgres) {
    const result = await pgPool.query(convertPlaceholders(sql), params);
    return result.rows[0] ?? null;
  } else {
    return new Promise((resolve, reject) => {
      sqliteDb.get(sql, params, (err, row) => {
        if (err) reject(err);
        else resolve(row ?? null);
      });
    });
  }
}

async function dbRun(sql, params = []) {
  const trimmed = sql.trim().toUpperCase();

  if (usePostgres) {
    let finalSql = sql;
    if (trimmed.startsWith('INSERT') && !trimmed.includes('RETURNING')) {
      finalSql = `${sql} RETURNING *`;
    }
    const result = await pgPool.query(convertPlaceholders(finalSql), params);
    return {
      lastID: result.rows[0]?.id ?? null,
      changes: result.rowCount ?? 0,
    };
  } else {
    // SQLite
    return new Promise((resolve, reject) => {
      sqliteDb.run(sql, params, function (err) {
        if (err) reject(err);
        else resolve({ lastID: this.lastID, changes: this.changes });
      });
    });
  }
}

module.exports = { initializeSchema, dbAll, dbGet, dbRun };
