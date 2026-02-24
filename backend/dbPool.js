// Database pool configuration for ES Module compatibility
import pkg from 'pg';
const { Pool } = pkg;

// Safest approach: Use DATABASE_URL if available, otherwise use individual credentials
function createPool() {
  if (process.env.DATABASE_URL) {
  console.log('🛜 Using DATABASE_URL (safest approach)');
    console.log('📊 Connection URL:', '***CONFIGURED***');
    
    // Determine if SSL should be used based on connection string
    const isLocalhost = process.env.DATABASE_URL.includes('localhost') || 
                        process.env.DATABASE_URL.includes('127.0.0.1');
    
    const poolConfig = {
      connectionString: process.env.DATABASE_URL,
    };
    
    // Only use SSL for remote connections (not localhost)
    if (!isLocalhost) {
      poolConfig.ssl = {
        rejectUnauthorized: false,
      };
    }
    
    return new Pool(poolConfig);
  } else {
    // Fallback to individual credentials for local development
    // Default password: empty string when not set (common for local PostgreSQL); set DB_PASSWORD in .env if your postgres user has a password
    const password = process.env.DB_PASSWORD ?? '';
    console.log('🛜 Using individual database credentials');
    console.log('📊 Host:', process.env.DB_HOST || 'localhost');

  return new Pool({
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT || '5432', 10),
      database: process.env.DB_NAME || 'flowspace_sit',
      user: process.env.DB_USER || 'postgres',
      password: password,
  });
  }
}

const pool = createPool();

// Test database connection
pool.on('connect', () => {
  console.log('✅ Connected to PostgreSQL database via DATABASE_URL');
});

export default pool;
