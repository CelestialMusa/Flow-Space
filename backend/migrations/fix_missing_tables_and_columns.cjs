/**
 * Fix Missing Tables and Columns Migration
 * 
 * This script identifies and creates missing tables and columns
 * based on what the Sequelize models expect vs what exists in the database.
 * 
 * Run with: node migrations/fix_missing_tables_and_columns.js
 */

const { Pool } = require('pg');
require('dotenv').config();

const pool = process.env.DATABASE_URL
  ? new Pool({
      connectionString: process.env.DATABASE_URL,
      ssl: { rejectUnauthorized: false },
    })
  : new Pool({
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT, 10) || 5432,
      database: process.env.DB_NAME || 'flow_space',
      user: process.env.DB_USER || 'postgres',
      password: process.env.DB_PASSWORD || 'postgres',
    });

async function fixMissingTablesAndColumns() {
  const client = await pool.connect();
  
  try {
    console.log('🔍 Analyzing database schema and fixing missing tables/columns...\n');
    
    await client.query('BEGIN');
    
    // ============================================================
    // 1. FIX SPRINTS TABLE - Add missing columns
    // ============================================================
    console.log('📊 Fixing sprints table...');
    
    const sprintColumns = [
      { name: 'description', type: 'TEXT', nullable: true },
      { name: 'created_by', type: 'VARCHAR(255)', nullable: true },
      { name: 'planned_points', type: 'INTEGER', nullable: true, default: 0 },
      { name: 'carried_over_points', type: 'INTEGER', nullable: true, default: 0 },
      { name: 'added_during_sprint', type: 'INTEGER', nullable: true, default: 0 },
      { name: 'removed_during_sprint', type: 'INTEGER', nullable: true, default: 0 },
      { name: 'code_coverage', type: 'INTEGER', nullable: true },
      { name: 'escaped_defects', type: 'INTEGER', nullable: true },
      { name: 'defects_opened', type: 'INTEGER', nullable: true },
      { name: 'defects_closed', type: 'INTEGER', nullable: true },
      { name: 'defect_severity_mix', type: 'JSONB', nullable: true },
      { name: 'code_review_completion', type: 'INTEGER', nullable: true },
      { name: 'documentation_status', type: 'VARCHAR(50)', nullable: true },
      { name: 'uat_notes', type: 'TEXT', nullable: true },
      { name: 'uat_pass_rate', type: 'INTEGER', nullable: true },
      { name: 'risks_identified', type: 'INTEGER', nullable: true },
      { name: 'risks', type: 'TEXT', nullable: true },
      { name: 'risks_mitigated', type: 'INTEGER', nullable: true },
      { name: 'blockers', type: 'TEXT', nullable: true },
      { name: 'decisions', type: 'TEXT', nullable: true },
      { name: 'reviewed_at', type: 'TIMESTAMP', nullable: true },
    ];
    
    for (const col of sprintColumns) {
      try {
        const defaultValue = col.default !== undefined ? `DEFAULT ${col.default}` : '';
        const nullable = col.nullable ? '' : 'NOT NULL';
        await client.query(`
          ALTER TABLE sprints 
          ADD COLUMN IF NOT EXISTS ${col.name} ${col.type} ${nullable} ${defaultValue}
        `);
        console.log(`  ✅ Added column: sprints.${col.name}`);
      } catch (err) {
        if (err.code !== '42701') { // Column already exists
          console.log(`  ⚠️  Could not add sprints.${col.name}: ${err.message}`);
        }
      }
    }
    
    // Add test_pass_rate if it doesn't exist (as INTEGER)
    try {
      await client.query(`
        ALTER TABLE sprints 
        ADD COLUMN IF NOT EXISTS test_pass_rate INTEGER DEFAULT 0
      `);
      console.log(`  ✅ Added column: sprints.test_pass_rate`);
    } catch (err) {
      if (err.code !== '42701') {
        console.log(`  ⚠️  Could not add test_pass_rate: ${err.message}`);
      }
    }
    
    // ============================================================
    // 2. FIX DELIVERABLES TABLE - Add missing columns
    // ============================================================
    console.log('\n📦 Fixing deliverables table...');
    
    const deliverableColumns = [
      { name: 'owner_id', type: 'UUID', nullable: true, reference: 'users(id)' },
      { name: 'priority', type: 'VARCHAR(20)', nullable: true, default: "'Medium'" },
      { name: 'demo_link', type: 'VARCHAR(500)', nullable: true },
      { name: 'repo_link', type: 'VARCHAR(500)', nullable: true },
      { name: 'test_summary_link', type: 'VARCHAR(500)', nullable: true },
      { name: 'user_guide_link', type: 'VARCHAR(500)', nullable: true },
      { name: 'test_pass_rate', type: 'INTEGER', nullable: true },
      { name: 'code_coverage', type: 'INTEGER', nullable: true },
      { name: 'escaped_defects', type: 'INTEGER', nullable: true },
      { name: 'defect_severity_mix', type: 'JSONB', nullable: true },
      { name: 'submitted_at', type: 'TIMESTAMP', nullable: true },
      { name: 'approved_at', type: 'TIMESTAMP', nullable: true },
    ];
    
    for (const col of deliverableColumns) {
      try {
        const defaultValue = col.default ? `DEFAULT ${col.default}` : '';
        const reference = col.reference ? `REFERENCES ${col.reference} ON DELETE SET NULL` : '';
        await client.query(`
          ALTER TABLE deliverables 
          ADD COLUMN IF NOT EXISTS ${col.name} ${col.type} ${defaultValue} ${reference}
        `);
        console.log(`  ✅ Added column: deliverables.${col.name}`);
      } catch (err) {
        if (err.code !== '42701') {
          console.log(`  ⚠️  Could not add deliverables.${col.name}: ${err.message}`);
        }
      }
    }
    
    // Ensure evidence_links exists (might be named differently)
    try {
      await client.query(`
        ALTER TABLE deliverables 
        ADD COLUMN IF NOT EXISTS evidence_links JSONB DEFAULT '[]'::jsonb
      `);
      console.log(`  ✅ Ensured evidence_links column exists`);
    } catch (err) {
      if (err.code !== '42701') {
        console.log(`  ⚠️  Could not add evidence_links: ${err.message}`);
      }
    }
    
    // ============================================================
    // 3. ENSURE SPRINT_METRICS TABLE EXISTS
    // ============================================================
    console.log('\n📈 Ensuring sprint_metrics table exists...');
    
    await client.query(`
      CREATE TABLE IF NOT EXISTS sprint_metrics (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        sprint_id UUID REFERENCES sprints(id) ON DELETE CASCADE,
        planned_points INTEGER DEFAULT 0,
        completed_points INTEGER DEFAULT 0,
        velocity DECIMAL(5,2) DEFAULT 0,
        test_pass_rate DECIMAL(5,2) DEFAULT 0,
        defect_count INTEGER DEFAULT 0,
        uat_notes TEXT,
        quality_score DECIMAL(5,2) DEFAULT 0,
        points_added_during_sprint INTEGER DEFAULT 0,
        points_removed_during_sprint INTEGER DEFAULT 0,
        scope_changes TEXT,
        blockers TEXT,
        decisions TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(sprint_id)
      )
    `);
    console.log('  ✅ sprint_metrics table ensured');
    
    // ============================================================
    // 4. ENSURE SPRINT_DELIVERABLES TABLE EXISTS (junction table)
    // ============================================================
    console.log('\n🔗 Ensuring sprint_deliverables table exists...');
    
    await client.query(`
      CREATE TABLE IF NOT EXISTS sprint_deliverables (
        id SERIAL PRIMARY KEY,
        sprint_id UUID REFERENCES sprints(id) ON DELETE CASCADE,
        deliverable_id UUID REFERENCES deliverables(id) ON DELETE CASCADE,
        points INTEGER DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(sprint_id, deliverable_id)
      )
    `);
    console.log('  ✅ sprint_deliverables table ensured');
    
    // ============================================================
    // 5. ENSURE DELIVERABLE_SPRINTS TABLE EXISTS (alternative junction)
    // ============================================================
    console.log('\n🔗 Ensuring deliverable_sprints table exists (for Sequelize)...');
    
    await client.query(`
      CREATE TABLE IF NOT EXISTS deliverable_sprints (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        deliverable_id UUID NOT NULL REFERENCES deliverables(id) ON DELETE CASCADE,
        sprint_id UUID NOT NULL REFERENCES sprints(id) ON DELETE CASCADE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(deliverable_id, sprint_id)
      )
    `);
    console.log('  ✅ deliverable_sprints table ensured');
    
    // ============================================================
    // 6. ENSURE PROJECT_MEMBERS TABLE EXISTS
    // ============================================================
    console.log('\n👥 Ensuring project_members table exists...');
    
    await client.query(`
      CREATE TABLE IF NOT EXISTS project_members (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        role VARCHAR(50) NOT NULL,
        joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(project_id, user_id)
      )
    `);
    console.log('  ✅ project_members table ensured');
    
    // ============================================================
    // 7. ENSURE EPICS TABLE EXISTS (if referenced)
    // ============================================================
    console.log('\n📋 Ensuring epics table exists...');
    
    await client.query(`
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
      )
    `);
    console.log('  ✅ epics table ensured');
    
    // ============================================================
    // 8. CREATE INDEXES FOR PERFORMANCE
    // ============================================================
    console.log('\n🔍 Creating indexes...');
    
    const indexes = [
      'CREATE INDEX IF NOT EXISTS idx_sprints_project ON sprints(project_id)',
      'CREATE INDEX IF NOT EXISTS idx_sprints_created_by ON sprints(created_by)',
      'CREATE INDEX IF NOT EXISTS idx_deliverables_project ON deliverables(project_id)',
      'CREATE INDEX IF NOT EXISTS idx_deliverables_owner ON deliverables(owner_id)',
      'CREATE INDEX IF NOT EXISTS idx_deliverables_sprint ON deliverables(sprint_id)',
      'CREATE INDEX IF NOT EXISTS idx_sprint_metrics_sprint ON sprint_metrics(sprint_id)',
      'CREATE INDEX IF NOT EXISTS idx_sprint_deliverables_sprint ON sprint_deliverables(sprint_id)',
      'CREATE INDEX IF NOT EXISTS idx_sprint_deliverables_deliverable ON sprint_deliverables(deliverable_id)',
      'CREATE INDEX IF NOT EXISTS idx_deliverable_sprints_deliverable ON deliverable_sprints(deliverable_id)',
      'CREATE INDEX IF NOT EXISTS idx_deliverable_sprints_sprint ON deliverable_sprints(sprint_id)',
      'CREATE INDEX IF NOT EXISTS idx_project_members_project ON project_members(project_id)',
      'CREATE INDEX IF NOT EXISTS idx_project_members_user ON project_members(user_id)',
      'CREATE INDEX IF NOT EXISTS idx_epics_project ON epics(project_id)',
    ];
    
    for (const index of indexes) {
      try {
        await client.query(index);
        console.log(`  ✅ Created index: ${index.split(' ')[5]}`);
      } catch (err) {
        console.log(`  ⚠️  Could not create index: ${err.message}`);
      }
    }
    
    await client.query('COMMIT');
    
    // ============================================================
    // VERIFICATION
    // ============================================================
    console.log('\n🔍 Verifying tables and columns...\n');
    
    // Check sprints columns
    const sprintCols = await client.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'sprints' 
      ORDER BY ordinal_position
    `);
    console.log(`📊 Sprints table has ${sprintCols.rows.length} columns`);
    
    // Check deliverables columns
    const deliverableCols = await client.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'deliverables' 
      ORDER BY ordinal_position
    `);
    console.log(`📦 Deliverables table has ${deliverableCols.rows.length} columns`);
    
    // Check if key tables exist
    const tables = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name IN ('sprints', 'deliverables', 'sprint_metrics', 'sprint_deliverables', 'deliverable_sprints', 'project_members', 'epics')
      ORDER BY table_name
    `);
    
    console.log('\n✅ Tables verified:');
    tables.rows.forEach(row => {
      console.log(`   ✓ ${row.table_name}`);
    });
    
    console.log('\n🎉 Migration completed successfully!');
    console.log('\n📝 Summary:');
    console.log('   - Added missing columns to sprints table');
    console.log('   - Added missing columns to deliverables table');
    console.log('   - Ensured sprint_metrics table exists');
    console.log('   - Ensured sprint_deliverables table exists');
    console.log('   - Ensured deliverable_sprints table exists');
    console.log('   - Ensured project_members table exists');
    console.log('   - Ensured epics table exists');
    console.log('   - Created performance indexes');
    
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('\n❌ Migration failed:', error.message);
    console.error('Error code:', error.code);
    console.error('Error detail:', error.detail);
    throw error;
    
  } finally {
    client.release();
    await pool.end();
  }
}

// Run migration if this file is executed directly
if (require.main === module) {
  fixMissingTablesAndColumns()
    .then(() => {
      console.log('\n✅ Fix migration finished successfully');
      process.exit(0);
    })
    .catch((error) => {
      console.error('\n❌ Migration failed:', error);
      process.exit(1);
    });
}

module.exports = { fixMissingTablesAndColumns };

