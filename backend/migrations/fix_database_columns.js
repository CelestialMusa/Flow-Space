/**
 * Migration script to fix missing database columns and tables
 * - Add updated_at column to notifications table
 * - Add sprint_id column to deliverables table
 * - Add repository_files table
 * - Add missing indexes and triggers
 * 
 * Run this with: node migrations/fix_database_columns.js
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

async function addMissingColumns() {
  console.log('🔧 Adding missing database columns...');
  
  try {
    // Add updated_at column to notifications table if it doesn't exist
    const notificationsColumns = await pool.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'notifications'
    `);
    
    const existingNotificationColumns = notificationsColumns.rows.map(row => row.column_name);
    
    if (!existingNotificationColumns.includes('updated_at')) {
      await pool.query('ALTER TABLE notifications ADD COLUMN updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP');
      console.log('✅ Added updated_at column to notifications table');
    }

    // Add sprint_id column to deliverables table if it doesn't exist
    const deliverablesColumns = await pool.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'deliverables'
    `);
    
    const existingDeliverableColumns = deliverablesColumns.rows.map(row => row.column_name);
    
    if (!existingDeliverableColumns.includes('sprint_id')) {
      await pool.query('ALTER TABLE deliverables ADD COLUMN sprint_id UUID REFERENCES sprints(id) ON DELETE SET NULL');
      console.log('✅ Added sprint_id column to deliverables table');
    }

    // Create repository_files table if it doesn't exist
    await pool.query(`
      CREATE TABLE IF NOT EXISTS repository_files (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        name VARCHAR(255) NOT NULL,
        description TEXT,
        file_path VARCHAR(500) NOT NULL,
        file_type VARCHAR(50) NOT NULL,
        file_size BIGINT,
        content_type VARCHAR(100),
        created_by UUID REFERENCES users(id) ON DELETE CASCADE,
        project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log('✅ Created repository_files table');

    // Add missing indexes
    await pool.query('CREATE INDEX IF NOT EXISTS idx_deliverables_sprint ON deliverables(sprint_id)');
    console.log('✅ Added idx_deliverables_sprint index');

    await pool.query('CREATE INDEX IF NOT EXISTS idx_repository_files_project ON repository_files(project_id)');
    console.log('✅ Added idx_repository_files_project index');

    await pool.query('CREATE INDEX IF NOT EXISTS idx_repository_files_created_by ON repository_files(created_by)');
    console.log('✅ Added idx_repository_files_created_by index');

    await pool.query('CREATE INDEX IF NOT EXISTS idx_repository_files_type ON repository_files(file_type)');
    console.log('✅ Added idx_repository_files_type index');

    // Create updated_at trigger function if it doesn't exist
    await pool.query(`
      CREATE OR REPLACE FUNCTION update_updated_at_column()
      RETURNS TRIGGER AS $$
      BEGIN
        NEW.updated_at = CURRENT_TIMESTAMP;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql
    `);

    // Add missing triggers
    await pool.query('DROP TRIGGER IF EXISTS update_notifications_updated_at ON notifications');
    await pool.query(`
      CREATE TRIGGER update_notifications_updated_at 
      BEFORE UPDATE ON notifications
      FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()
    `);
    console.log('✅ Added update_notifications_updated_at trigger');

    await pool.query('DROP TRIGGER IF EXISTS update_repository_files_updated_at ON repository_files');
    await pool.query(`
      CREATE TRIGGER update_repository_files_updated_at 
      BEFORE UPDATE ON repository_files
      FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()
    `);
    console.log('✅ Added update_repository_files_updated_at trigger');

    console.log('🎉 Database column fixes completed successfully!');
    
  } catch (error) {
    console.error('❌ Error adding missing columns:', error);
    throw error;
  }
}

async function run() {
  try {
    console.log('🚀 Starting database column fixes migration...\n');
    
    await addMissingColumns();
    
  } catch (error) {
    console.error('❌ Migration failed:', error);
    throw error;
  } finally {
    await pool.end();
  }
}

// Run migration
if (require.main === module) {
  run().catch(console.error);
}

module.exports = {
  addMissingColumns,
  run
};
