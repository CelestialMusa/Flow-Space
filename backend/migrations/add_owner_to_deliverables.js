
const { Pool } = require('pg');
const path = require('path');
const fs = require('fs');

// Use the app's env loader
try {
  require('../node-backend/src/config/env-loader.js');
} catch (e) {
  console.log('⚠️ Could not load env-loader.js, falling back to manual loading');
  // Try to load .env from different locations
  const envPath = path.join(__dirname, '..', '.env');
  if (fs.existsSync(envPath)) {
    require('dotenv').config({ path: envPath });
  } else {
    require('dotenv').config();
  }
}

function getPool() {
  const dbConfig = {
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT ? parseInt(process.env.DB_PORT, 10) : 5432,
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD ? String(process.env.DB_PASSWORD) : '', // Ensure string
    database: process.env.DB_NAME || 'flow_space',
    max: 10,
  };
  
  console.log('DB Config:', { 
    ...dbConfig, 
    password: dbConfig.password ? '***' : '(empty)' 
  });
  
  return new Pool(dbConfig);
}

async function run() {
  const pool = getPool();
  
  try {
    console.log('🔧 Adding owner_id to deliverables table...');
    
    // Check if column exists
    const checkRes = await pool.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name='deliverables' AND column_name='owner_id'
    `);
    
    if (checkRes.rows.length === 0) {
      await pool.query(`
        ALTER TABLE deliverables 
        ADD COLUMN owner_id UUID REFERENCES users(id) ON DELETE SET NULL
      `);
      console.log('✅ Added owner_id column');
      
      await pool.query('CREATE INDEX IF NOT EXISTS idx_deliverables_owner ON deliverables(owner_id)');
      console.log('✅ Added index for owner_id');
    } else {
      console.log('ℹ️ owner_id column already exists');
    }
    
    console.log('✅ Migration completed successfully!');
  } catch (error) {
    console.error('❌ Migration failed:', error);
    throw error;
  } finally {
    await pool.end();
  }
}

if (require.main === module) {
  run().catch(console.error);
}
