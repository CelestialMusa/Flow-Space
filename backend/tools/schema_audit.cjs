/**
 * Schema Audit (repo scan -> DB diff)
 *
 * Run:
 *   cd backend
 *   node tools/schema_audit.cjs
 */

const fs = require('fs');
const path = require('path');
const { Pool } = require('pg');

require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

const repoRoot = path.join(__dirname, '..', '..'); // Flow-Space-git/

function walk(dir, files = []) {
  let entries;
  try {
    entries = fs.readdirSync(dir, { withFileTypes: true });
  } catch {
    return files;
  }
  for (const ent of entries) {
    if (ent.isDirectory()) {
      if (['node_modules', '.git', 'build', '.dart_tool', '.idea', '.vscode'].includes(ent.name)) continue;
      walk(path.join(dir, ent.name), files);
    } else if (ent.isFile()) {
      files.push(path.join(dir, ent.name));
    }
  }
  return files;
}

function readTextSafe(filePath) {
  try {
    return fs.readFileSync(filePath, 'utf8');
  } catch {
    return null;
  }
}

function extractTablesFromText(text) {
  const found = new Set();
  if (!text) return found;

  let m;

  // CREATE TABLE [IF NOT EXISTS] table_name
  const createRe = /\bCREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?("?)([a-zA-Z_][a-zA-Z0-9_]*)\1\b/gi;
  while ((m = createRe.exec(text))) found.add(m[2]);

  // Sequelize tableName: 'table'
  const tableNameRe = /\btableName\s*:\s*['"]([a-zA-Z_][a-zA-Z0-9_]*)['"]/g;
  while ((m = tableNameRe.exec(text))) found.add(m[1]);

  // Only use DML extraction for .sql files or explicit query strings; this function
  // is meant for DDL + model metadata, not generic text.

  return found;
}

function poolFromEnv() {
  if (process.env.DATABASE_URL) {
    return new Pool({
      connectionString: process.env.DATABASE_URL,
      ssl: process.env.DATABASE_SSL === 'false' ? false : { rejectUnauthorized: false },
    });
  }
  return new Pool({
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '5432', 10),
    database: process.env.DB_NAME || 'flow_space',
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || 'postgres',
  });
}

async function main() {
  console.log('🔎 Scanning backend schema + Sequelize models for DB tables...');

  const backendRoot = path.join(repoRoot, 'backend');
  const backendSqlRoots = [
    backendRoot,
    path.join(repoRoot, 'migrations'),
    repoRoot,
  ].filter((p) => fs.existsSync(p));

  const expected = new Set();
  let scannedFiles = 0;

  // 1) Authoritative: schema/migration files (.sql, .cjs) and backend/server.js (DDL strings)
  for (const root of backendSqlRoots) {
    const files = walk(root);
    for (const f of files) {
      const ext = path.extname(f).toLowerCase();
      if (!['.sql', '.cjs'].includes(ext)) continue;
      const text = readTextSafe(f);
      if (!text) continue;
      for (const t of extractTablesFromText(text)) expected.add(t);
      scannedFiles++;
    }
  }

  // Include DDL embedded in backend/server.js (ESM .js but still plain text scan)
  const serverJs = path.join(backendRoot, 'server.js');
  const serverText = readTextSafe(serverJs);
  if (serverText) {
    for (const t of extractTablesFromText(serverText)) expected.add(t);
  }

  // 2) Sequelize models (tableName declarations)
  const modelsDir = path.join(backendRoot, 'node-backend', 'src', 'models');
  if (fs.existsSync(modelsDir)) {
    const modelFiles = walk(modelsDir).filter((f) => f.toLowerCase().endsWith('.js'));
    const tableNameRe = /\btableName\s*:\s*['"]([a-zA-Z_][a-zA-Z0-9_]*)['"]/g;
    for (const f of modelFiles) {
      const text = readTextSafe(f);
      if (!text) continue;
      let m;
      while ((m = tableNameRe.exec(text))) expected.add(m[1]);
    }
  }

  // Filter obvious false-positives from simplistic regexes
  for (const x of ['IF', 'if', 'table', 'TABLE']) expected.delete(x);

  console.log(`✅ Scanned ${scannedFiles} migration/schema files (+ server.js + Sequelize models)`);
  console.log(`📌 Expected tables from schema/models: ${expected.size}`);

  const pool = poolFromEnv();
  try {
    const existingRes = await pool.query(
      `SELECT table_name
       FROM information_schema.tables
       WHERE table_schema = 'public'
       ORDER BY table_name`
    );
    const existing = new Set(existingRes.rows.map((r) => r.table_name));
    const missing = Array.from(expected).filter((t) => !existing.has(t)).sort();

    console.log(`🗄️  DB tables (public schema): ${existing.size}`);
    console.log(`❗ Missing expected tables: ${missing.length}`);
    if (missing.length) {
      for (const t of missing) console.log(` - ${t}`);
    }

    const reportPath = path.join(repoRoot, 'SCHEMA_AUDIT_REPORT.json');
    fs.writeFileSync(
      reportPath,
      JSON.stringify(
        {
          scanned_at: new Date().toISOString(),
          expected_tables: Array.from(expected).sort(),
          existing_tables: Array.from(existing).sort(),
          missing_tables: missing,
        },
        null,
        2
      )
    );
    console.log(`\n📝 Wrote report: ${reportPath}`);
  } finally {
    await pool.end();
  }
}

main().catch((err) => {
  console.error('❌ Schema audit failed:', err);
  process.exit(1);
});


