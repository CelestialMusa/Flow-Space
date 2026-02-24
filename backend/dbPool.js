// Database pool configuration for ES Module compatibility
import pkg from 'pg';
const { Pool } = pkg;

// Safest approach: Use ONLY DATABASE_URL to avoid credential mismatches
function createPool() {
  console.log('🛜 Using DATABASE_URL (safest approach)');
  console.log('📊 Connection URL:', process.env.DATABASE_URL ? '***CONFIGURED***' : 'NOT SET');
  
  if (!process.env.DATABASE_URL) {
    throw new Error('DATABASE_URL is not set. Please configure it in Render environment variables.');
  }

  // SUPER SAFE SSL CONFIGURATION - Always works for Render
  return new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: {
      rejectUnauthorized: false
    }
  });
}

const pool = createPool();

// Test database connection
pool.on('connect', () => {
  console.log('✅ Connected to PostgreSQL database via DATABASE_URL');
});

export default pool;
