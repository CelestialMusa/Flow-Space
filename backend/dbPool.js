// Database pool configuration for ES Module compatibility
import pkg from 'pg';
const { Pool } = pkg;

// Explicit DB connection mode - removes ambiguity and forces determinism
function createPool() {
  const mode = process.env.DB_CONNECTION_MODE;

  if (mode === 'external') {
    console.log('🛜 Using EXTERNAL database connection');
    console.log('📊 Connection URL:', process.env.DATABASE_URL ? '***CONFIGURED***' : 'NOT SET');
    return new Pool({
      connectionString: process.env.DATABASE_URL,
      ssl: {
        rejectUnauthorized: false,
      },
    });
  }

  console.log('🛜 Using ENV database connection');
  console.log('📊 Host:', process.env.DB_HOST || 'localhost');
  console.log('📊 User:', process.env.DB_USER || 'flow_space_user');
  console.log('📊 Database:', process.env.DB_NAME || 'flow_space');
  console.log('📊 Port:', process.env.DB_PORT || '5432');
  
  return new Pool({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'flow_space_user',
    password: process.env.DB_PASSWORD || 'postgres',
    database: process.env.DB_NAME || 'flow_space',
    port: parseInt(process.env.DB_PORT) || 5432,
    ssl: {
      rejectUnauthorized: false,
    },
  });
}

const pool = createPool();

// Test database connection
pool.on('connect', () => {
  console.log('Connected to PostgreSQL database');
});

export default pool;
