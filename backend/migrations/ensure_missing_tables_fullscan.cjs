/**
 * Ensure Missing Tables (from full scan)
 *
 * This migration is intentionally **idempotent**:
 * - CREATE TABLE IF NOT EXISTS
 * - ALTER TABLE ... ADD COLUMN IF NOT EXISTS
 * - CREATE OR REPLACE VIEW for legacy aliases
 *
 * Run:
 *   cd backend
 *   node migrations/ensure_missing_tables_fullscan.cjs
 */

const path = require('path');
const { Pool } = require('pg');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

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

async function columnExists(pool, table, column) {
  const res = await pool.query(
    `SELECT 1
     FROM information_schema.columns
     WHERE table_schema='public' AND table_name=$1 AND column_name=$2
     LIMIT 1`,
    [table, column]
  );
  return res.rows.length > 0;
}

async function runStatements(pool, statements) {
  for (const { label, sql } of statements) {
    try {
      await pool.query(sql);
      console.log(`✅ ${label}`);
    } catch (err) {
      // Don't abort everything: log and continue.
      console.log(`⚠️  ${label}: ${err.message}`);
    }
  }
}

async function main() {
  console.log('🚀 Ensuring missing tables/views/columns exist (fullscan)...');
  const pool = poolFromEnv();

  try {
    // Ensure extension used by UUID defaults
    await pool.query('CREATE EXTENSION IF NOT EXISTS "pgcrypto"');

    // ------------------------------------------------------------------
    // 1) Core missing tables used by backend/server.js flows
    // ------------------------------------------------------------------
    const coreTables = [
      {
        label: 'Create sprint_deliverables (used by deliverable create/link logic)',
        sql: `
          CREATE TABLE IF NOT EXISTS sprint_deliverables (
            id SERIAL PRIMARY KEY,
            sprint_id UUID REFERENCES sprints(id) ON DELETE CASCADE,
            deliverable_id UUID REFERENCES deliverables(id) ON DELETE CASCADE,
            points INTEGER DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(sprint_id, deliverable_id)
          );
        `,
      },
      {
        label: 'Create digital_signatures',
        sql: `
          CREATE TABLE IF NOT EXISTS digital_signatures (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            report_id UUID REFERENCES sign_off_reports(id) ON DELETE CASCADE,
            user_id UUID REFERENCES users(id) ON DELETE SET NULL,
            signature_data TEXT,
            signed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            ip_address INET,
            user_agent TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          );
        `,
      },
      {
        label: 'Create documents',
        sql: `
          CREATE TABLE IF NOT EXISTS documents (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            name VARCHAR(255) NOT NULL,
            description TEXT,
            file_path TEXT NOT NULL,
            file_type VARCHAR(100),
            file_size BIGINT,
            mime_type VARCHAR(100),
            project_id UUID REFERENCES projects(id) ON DELETE SET NULL,
            deliverable_id UUID REFERENCES deliverables(id) ON DELETE SET NULL,
            sprint_id UUID REFERENCES sprints(id) ON DELETE SET NULL,
            uploaded_by UUID REFERENCES users(id) ON DELETE SET NULL,
            tags TEXT[] DEFAULT '{}',
            version INTEGER DEFAULT 1,
            is_archived BOOLEAN DEFAULT false,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          );
        `,
      },
      {
        label: 'Create docusign_envelopes',
        sql: `
          CREATE TABLE IF NOT EXISTS docusign_envelopes (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            report_id UUID NOT NULL REFERENCES sign_off_reports(id) ON DELETE CASCADE,
            envelope_id VARCHAR(255) NOT NULL UNIQUE,
            status VARCHAR(50) DEFAULT 'created',
            signer_email VARCHAR(255) NOT NULL,
            signer_name VARCHAR(255) NOT NULL,
            signer_role VARCHAR(50),
            created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            sent_at TIMESTAMP,
            delivered_at TIMESTAMP,
            signed_at TIMESTAMP,
            completed_at TIMESTAMP,
            declined_at TIMESTAMP,
            decline_reason TEXT,
            voided_at TIMESTAMP,
            void_reason TEXT,
            metadata JSONB DEFAULT '{}'::jsonb,
            created_at TIMESTAMP DEFAULT NOW(),
            updated_at TIMESTAMP DEFAULT NOW()
          );
        `,
      },
      {
        label: 'Create report_exports',
        sql: `
          CREATE TABLE IF NOT EXISTS report_exports (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            report_id UUID REFERENCES sign_off_reports(id) ON DELETE CASCADE,
            export_type VARCHAR(50) NOT NULL,
            format VARCHAR(20) NOT NULL,
            file_path TEXT,
            file_size BIGINT,
            exported_by UUID REFERENCES users(id) ON DELETE SET NULL,
            exported_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            expires_at TIMESTAMP,
            download_count INTEGER DEFAULT 0,
            metadata JSONB DEFAULT '{}'::jsonb
          );
        `,
      },
      {
        label: 'Create change_requests',
        sql: `
          CREATE TABLE IF NOT EXISTS change_requests (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            report_id UUID REFERENCES sign_off_reports(id) ON DELETE CASCADE,
            requested_by UUID REFERENCES users(id) ON DELETE SET NULL,
            status VARCHAR(50) DEFAULT 'open',
            description TEXT NOT NULL,
            priority VARCHAR(20) DEFAULT 'medium',
            resolution TEXT,
            resolved_by UUID REFERENCES users(id) ON DELETE SET NULL,
            resolved_at TIMESTAMP,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          );
        `,
      },
      {
        label: 'Create deliverable_artifacts',
        sql: `
          CREATE TABLE IF NOT EXISTS deliverable_artifacts (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            deliverable_id UUID NOT NULL REFERENCES deliverables(id) ON DELETE CASCADE,
            filename VARCHAR(255) NOT NULL,
            original_name VARCHAR(255) NOT NULL,
            file_type VARCHAR(50) NOT NULL,
            file_size INTEGER NOT NULL,
            url VARCHAR(500) NOT NULL,
            uploaded_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            uploader_name VARCHAR(255),
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          );
        `,
      },
      {
        label: 'Create epics',
        sql: `
          CREATE TABLE IF NOT EXISTS epics (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            title VARCHAR(255) NOT NULL,
            description TEXT,
            status VARCHAR(50) DEFAULT 'draft',
            project_id UUID REFERENCES projects(id) ON DELETE SET NULL,
            sprint_ids UUID[] DEFAULT '{}',
            deliverable_ids UUID[] DEFAULT '{}',
            start_date TIMESTAMP,
            target_date TIMESTAMP,
            created_by UUID REFERENCES users(id) ON DELETE SET NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          );
        `,
      },
      {
        label: 'Create sprint_epics',
        sql: `
          CREATE TABLE IF NOT EXISTS sprint_epics (
            sprint_id UUID REFERENCES sprints(id) ON DELETE CASCADE,
            epic_id UUID REFERENCES epics(id) ON DELETE CASCADE,
            PRIMARY KEY (sprint_id, epic_id)
          );
        `,
      },
      {
        label: 'Create deliverable_epics',
        sql: `
          CREATE TABLE IF NOT EXISTS deliverable_epics (
            deliverable_id UUID REFERENCES deliverables(id) ON DELETE CASCADE,
            epic_id UUID REFERENCES epics(id) ON DELETE CASCADE,
            PRIMARY KEY (deliverable_id, epic_id)
          );
        `,
      },
      {
        label: 'Create email_verification_tokens',
        sql: `
          CREATE TABLE IF NOT EXISTS email_verification_tokens (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            token VARCHAR(255) NOT NULL UNIQUE,
            expires_at TIMESTAMP NOT NULL,
            used_at TIMESTAMP,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          );
        `,
      },
      {
        label: 'Create user_roles',
        sql: `
          CREATE TABLE IF NOT EXISTS user_roles (
            id SERIAL PRIMARY KEY,
            name VARCHAR(50) UNIQUE NOT NULL,
            display_name VARCHAR(100) NOT NULL,
            description TEXT,
            color VARCHAR(7),
            icon VARCHAR(50),
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          );
        `,
      },
      {
        label: 'Create permissions',
        sql: `
          CREATE TABLE IF NOT EXISTS permissions (
            id SERIAL PRIMARY KEY,
            name VARCHAR(100) UNIQUE NOT NULL,
            description TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          );
        `,
      },
      {
        label: 'Create role_permissions',
        sql: `
          CREATE TABLE IF NOT EXISTS role_permissions (
            id SERIAL PRIMARY KEY,
            role_id INTEGER REFERENCES user_roles(id) ON DELETE CASCADE,
            permission_id INTEGER REFERENCES permissions(id) ON DELETE CASCADE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(role_id, permission_id)
          );
        `,
      },
      {
        label: 'Create app_config',
        sql: `
          CREATE TABLE IF NOT EXISTS app_config (
            key VARCHAR(100) PRIMARY KEY,
            value JSONB NOT NULL DEFAULT '{}'::jsonb,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          );
        `,
      },
    ];

    await runStatements(pool, coreTables);

    // ------------------------------------------------------------------
    // 2) Ensure key columns exist for Sprint/Deliverable creation
    // ------------------------------------------------------------------
    const deliverablesNeeds = [
      { col: 'project_id', sql: `ALTER TABLE deliverables ADD COLUMN IF NOT EXISTS project_id UUID REFERENCES projects(id) ON DELETE CASCADE;` },
      { col: 'definition_of_done', sql: `ALTER TABLE deliverables ADD COLUMN IF NOT EXISTS definition_of_done JSONB DEFAULT '[]'::jsonb;` },
      { col: 'priority', sql: `ALTER TABLE deliverables ADD COLUMN IF NOT EXISTS priority VARCHAR(20) DEFAULT 'Medium';` },
      { col: 'created_by', sql: `ALTER TABLE deliverables ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES users(id) ON DELETE SET NULL;` },
      { col: 'assigned_to', sql: `ALTER TABLE deliverables ADD COLUMN IF NOT EXISTS assigned_to UUID REFERENCES users(id) ON DELETE SET NULL;` },
      { col: 'due_date', sql: `ALTER TABLE deliverables ADD COLUMN IF NOT EXISTS due_date TIMESTAMP;` },
    ];

    for (const need of deliverablesNeeds) {
      // Some columns may exist with different types in your environment; avoid hard failures by checking existence.
      if (!(await columnExists(pool, 'deliverables', need.col))) {
        await runStatements(pool, [{ label: `Add deliverables.${need.col}`, sql: need.sql }]);
      }
    }

    if (!(await columnExists(pool, 'sprints', 'project_id'))) {
      await runStatements(pool, [
        {
          label: 'Add sprints.project_id (required by sprint create endpoints)',
          sql: `ALTER TABLE sprints ADD COLUMN IF NOT EXISTS project_id UUID REFERENCES projects(id) ON DELETE CASCADE;`,
        },
      ]);
    }

    // ------------------------------------------------------------------
    // 3) Legacy compatibility aliases as VIEWS (avoid duplicate tables)
    // ------------------------------------------------------------------
    const legacyViews = [
      {
        label: 'Create/replace view activity_log -> activity_logs',
        sql: `CREATE OR REPLACE VIEW activity_log AS SELECT * FROM activity_logs;`,
      },
      {
        label: 'Create/replace view audit_log -> audit_logs',
        sql: `CREATE OR REPLACE VIEW audit_log AS SELECT * FROM audit_logs;`,
      },
      {
        label: 'Create/replace view reports -> sign_off_reports',
        sql: `CREATE OR REPLACE VIEW reports AS SELECT * FROM sign_off_reports;`,
      },
      {
        label: 'Create/replace view sign_offs -> sign_off_reports',
        sql: `CREATE OR REPLACE VIEW sign_offs AS SELECT * FROM sign_off_reports;`,
      },
    ];

    await runStatements(pool, legacyViews);

    // profiles view (legacy compat) depends on what columns your `users` table has.
    // Try to build a best-effort view with stable columns.
    try {
      const hasName = await columnExists(pool, 'users', 'name');
      const hasFirst = await columnExists(pool, 'users', 'first_name');
      const hasLast = await columnExists(pool, 'users', 'last_name');
      const hasRole = await columnExists(pool, 'users', 'role');

      let fullNameExpr = 'email';
      if (hasName) fullNameExpr = 'name';
      else if (hasFirst && hasLast) fullNameExpr = `TRIM(COALESCE(first_name,'') || ' ' || COALESCE(last_name,''))`;

      const roleExpr = hasRole ? 'role' : `'user'::text AS role`;

      await pool.query(`
        CREATE OR REPLACE VIEW profiles AS
        SELECT
          id,
          email,
          ${fullNameExpr} AS full_name,
          ${roleExpr},
          created_at,
          updated_at
        FROM users;
      `);
      console.log('✅ Create/replace view profiles -> users');
    } catch (err) {
      console.log(`⚠️  Create/replace view profiles -> users: ${err.message}`);
    }

    // Helpful indexes (safe to skip if fail)
    const indexes = [
      { label: 'Index sprint_deliverables(sprint_id)', sql: `CREATE INDEX IF NOT EXISTS idx_sprint_deliverables_sprint_id ON sprint_deliverables(sprint_id);` },
      { label: 'Index sprint_deliverables(deliverable_id)', sql: `CREATE INDEX IF NOT EXISTS idx_sprint_deliverables_deliverable_id ON sprint_deliverables(deliverable_id);` },
      { label: 'Index deliverables(project_id)', sql: `CREATE INDEX IF NOT EXISTS idx_deliverables_project_id ON deliverables(project_id);` },
      { label: 'Index sprints(project_id)', sql: `CREATE INDEX IF NOT EXISTS idx_sprints_project_id ON sprints(project_id);` },
    ];
    await runStatements(pool, indexes);

    console.log('🎉 ensure_missing_tables_fullscan completed');
  } finally {
    await pool.end();
  }
}

main().catch((err) => {
  console.error('❌ ensure_missing_tables_fullscan failed:', err);
  process.exit(1);
});


