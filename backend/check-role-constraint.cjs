const path = require('path');
const { Pool } = require('pg');
require('dotenv').config({ path: path.join(__dirname, '.env') });

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432', 10),
  database: process.env.DB_NAME || 'flow_space',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres',
});

async function checkConstraint() {
  try {
    // Check constraint definition
    const result = await pool.query(`
      SELECT 
        conname as constraint_name,
        pg_get_constraintdef(oid) as constraint_definition
      FROM pg_constraint
      WHERE conname = 'users_role_check'
      AND conrelid = 'users'::regclass
    `);
    
    if (result.rows.length > 0) {
      console.log('Constraint found:');
      console.log(JSON.stringify(result.rows, null, 2));
    } else {
      console.log('No constraint found. Checking existing roles...');
      const roles = await pool.query('SELECT DISTINCT role FROM users WHERE role IS NOT NULL');
      console.log('Existing roles in database:');
      roles.rows.forEach(r => console.log(`  - ${r.role}`));
    }
  } catch (e) {
    console.error('Error:', e.message);
  } finally {
    await pool.end();
  }
}

checkConstraint();

