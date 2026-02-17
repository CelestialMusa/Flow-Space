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

console.log(`\n🔧 Adding missing epics relationship tables...`);
console.log(`📋 Database: ${dbConfig.database} @ ${dbConfig.host}\n`);

const pool = new Pool(dbConfig);

async function addEpicsRelationshipTables() {
  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');
    
    console.log('📦 Creating sprint_epics table...');
    await client.query(`
      CREATE TABLE IF NOT EXISTS sprint_epics (
        sprint_id UUID REFERENCES sprints(id) ON DELETE CASCADE,
        epic_id UUID REFERENCES epics(id) ON DELETE CASCADE,
        PRIMARY KEY (sprint_id, epic_id)
      )
    `);
    console.log('✅ sprint_epics table created');
    
    console.log('📦 Creating deliverable_epics table...');
    await client.query(`
      CREATE TABLE IF NOT EXISTS deliverable_epics (
        deliverable_id UUID REFERENCES deliverables(id) ON DELETE CASCADE,
        epic_id UUID REFERENCES epics(id) ON DELETE CASCADE,
        PRIMARY KEY (deliverable_id, epic_id)
      )
    `);
    console.log('✅ deliverable_epics table created');
    
    await client.query('COMMIT');
    
    console.log('\n✅ Epics relationship tables added successfully!');
    console.log('🎯 Epics API should now work without errors\n');
    
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('\n❌ Error adding epics tables:', error.message);
    console.error('Error detail:', error.detail);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

addEpicsRelationshipTables();
