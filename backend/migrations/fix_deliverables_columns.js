const { Pool } = require('pg');
require('dotenv').config();

const dbConfig = {
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'flow_space',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD,
  ssl: false
};

console.log(`\n🔧 Updating deliverables table schema...`);
console.log(`📋 Database: ${dbConfig.database} @ ${dbConfig.host}\n`);

const pool = new Pool(dbConfig);

async function updateDeliverablesTable() {
  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');
    
    console.log('📦 Adding missing columns to deliverables table...');
    
    // Add columns that might be missing
    const columnsToAdd = [
      'definition_of_done JSONB DEFAULT \'[]\'',
      'evidence JSONB DEFAULT \'[]\'',
      'readiness_gates JSONB DEFAULT \'[]\'',
      'priority VARCHAR(20) DEFAULT \'Medium\'',
      'sprint_ids UUID[] DEFAULT \'{}\'',
      'epic_id UUID REFERENCES epics(id) ON DELETE SET NULL',
      'evidence_links JSONB DEFAULT \'[]\''
    ];
    
    for (const columnDef of columnsToAdd) {
      const columnName = columnDef.split(' ')[0];
      try {
        await client.query(`
          ALTER TABLE deliverables 
          ADD COLUMN IF NOT EXISTS ${columnDef}
        `);
        console.log(`✅ Added column: ${columnName}`);
      } catch (error) {
        console.log(`⚠️ Column ${columnName} might already exist or error: ${error.message}`);
      }
    }
    
    await client.query('COMMIT');
    
    console.log('\n✅ Deliverables table schema updated successfully!');
    console.log('🎯 Deliverables API should now work without errors\n');
    
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('\n❌ Error updating deliverables table:', error.message);
    console.error('Error detail:', error.detail);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

updateDeliverablesTable();
