/**
 * Create Client Reviewer Test Account
 * 
 * Creates a test account for Client Reviewer role:
 * Email: client@example.com
 * Password: Test#871329!
 * Role: clientReviewer
 * 
 * Run: node backend/create-client-reviewer.cjs
 */

const path = require('path');
const { Pool } = require('pg');
const { v4: uuidv4 } = require('uuid');
require('dotenv').config({ path: path.join(__dirname, '.env') });

// Try to load bcrypt from node-backend directory
let bcrypt;
try {
  // Try bcryptjs first (used in server.js)
  bcrypt = require('bcryptjs');
} catch (e1) {
  try {
    // Try bcrypt from node-backend
    bcrypt = require(path.join(__dirname, 'node-backend', 'node_modules', 'bcrypt'));
  } catch (e2) {
    // Fallback: use crypto for password hashing
    const crypto = require('crypto');
    bcrypt = {
      hash: async (password, rounds) => {
        return new Promise((resolve, reject) => {
          const salt = crypto.randomBytes(16).toString('hex');
          crypto.pbkdf2(password, salt, 10000, 64, 'sha512', (err, derivedKey) => {
            if (err) reject(err);
            resolve(`$2b$${rounds}$${salt}${derivedKey.toString('hex')}`);
          });
        });
      }
    };
  }
}

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

async function createClientReviewer() {
  console.log('🚀 Creating Client Reviewer test account...\n');
  
  const pool = poolFromEnv();
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const email = 'client@example.com';
    const password = 'Test#871329!';
    const firstName = 'Client';
    const lastName = 'Reviewer';
    // Use 'client' role (as per database constraint, not 'clientReviewer')
    const role = 'client';

    // Check if user already exists
    console.log('🔍 Checking if user already exists...');
    const existingUser = await client.query(
      'SELECT id, email, first_name, last_name, role FROM users WHERE email = $1',
      [email]
    );

    if (existingUser.rows.length > 0) {
      const user = existingUser.rows[0];
      console.log(`⚠️  User already exists:`);
      console.log(`   Email: ${user.email}`);
      console.log(`   Name: ${user.first_name} ${user.last_name}`);
      console.log(`   Role: ${user.role}`);
      console.log(`   ID: ${user.id}`);
      console.log('\n💡 To recreate, delete the user first using delete-test-users.cjs');
      await client.query('ROLLBACK');
      return;
    }

    // Hash password
    console.log('🔐 Hashing password...');
    const hashedPassword = await bcrypt.hash(password, 10);
    const userId = uuidv4();

    // Determine which columns exist in the users table
    const tableInfo = await client.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'users' 
      AND table_schema = 'public'
    `);
    
    const columns = tableInfo.rows.map(r => r.column_name);
    const hasPasswordHash = columns.includes('password_hash');
    const hasHashedPassword = columns.includes('hashed_password');
    const hasName = columns.includes('name');
    const hasFirstName = columns.includes('first_name');

    // Build INSERT query based on available columns
    let insertQuery;
    let insertValues;
    let valuePlaceholders;

    if (hasFirstName && hasHashedPassword) {
      // Use first_name, last_name, hashed_password
      insertQuery = `
        INSERT INTO users (id, email, hashed_password, first_name, last_name, role, is_active, created_at, updated_at)
        VALUES ($1, $2, $3, $4, $5, $6, $7, NOW(), NOW())
        RETURNING id, email, first_name, last_name, role, is_active, created_at
      `;
      insertValues = [userId, email, hashedPassword, firstName, lastName, role, true];
      valuePlaceholders = '$1, $2, $3, $4, $5, $6, $7';
    } else if (hasFirstName && hasPasswordHash) {
      // Use first_name, last_name, password_hash
      insertQuery = `
        INSERT INTO users (id, email, password_hash, first_name, last_name, role, is_active, created_at, updated_at)
        VALUES ($1, $2, $3, $4, $5, $6, $7, NOW(), NOW())
        RETURNING id, email, first_name, last_name, role, is_active, created_at
      `;
      insertValues = [userId, email, hashedPassword, firstName, lastName, role, true];
      valuePlaceholders = '$1, $2, $3, $4, $5, $6, $7';
    } else if (hasName && hasPasswordHash) {
      // Use name, password_hash
      const fullName = `${firstName} ${lastName}`;
      insertQuery = `
        INSERT INTO users (id, email, password_hash, name, role, is_active, created_at, updated_at)
        VALUES ($1, $2, $3, $4, $5, $6, NOW(), NOW())
        RETURNING id, email, name, role, is_active, created_at
      `;
      insertValues = [userId, email, hashedPassword, fullName, role, true];
      valuePlaceholders = '$1, $2, $3, $4, $5, $6';
    } else {
      throw new Error('Unable to determine users table schema');
    }

    console.log('📝 Inserting user into database...');
    const result = await client.query(insertQuery, insertValues);

    if (result.rows.length === 0) {
      throw new Error('User creation failed - no rows returned');
    }

    const user = result.rows[0];
    const userName = user.first_name && user.last_name 
      ? `${user.first_name} ${user.last_name}` 
      : user.name || email;

    await client.query('COMMIT');

    console.log('\n' + '='.repeat(60));
    console.log('✅ Client Reviewer account created successfully!');
    console.log('='.repeat(60));
    console.log(`📧 Email: ${user.email}`);
    console.log(`🔑 Password: ${password}`);
    console.log(`👤 Name: ${userName}`);
    console.log(`🎭 Role: ${user.role}`);
    console.log(`🆔 User ID: ${user.id}`);
    console.log(`✅ Active: ${user.is_active}`);
    console.log(`📅 Created: ${user.created_at}`);
    console.log('='.repeat(60));
    console.log('\n💡 You can now use these credentials to login:');
    console.log(`   Email: ${user.email}`);
    console.log(`   Password: ${password}`);
    console.log('\n');

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('\n❌ Error creating user:', error.message);
    console.error(error);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

createClientReviewer().catch(console.error);

