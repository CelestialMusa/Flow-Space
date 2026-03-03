/**
 * Delete Test User Accounts
 * 
 * This script deletes the following test user accounts:
 * - testclient_20260129@example.com
 * - test_viewer_20260130@example.com
 * 
 * Run: node backend/delete-test-users.cjs
 */

const path = require('path');
const { Pool } = require('pg');
require('dotenv').config({ path: path.join(__dirname, '.env') });

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

const emailsToDelete = [
  'testclient_20260129@example.com',
  'test_viewer_20260130@example.com'
];

async function deleteUser(pool, email) {
  try {
    // First, find the user by email
    const userResult = await pool.query(
      'SELECT id, email, first_name, last_name, role FROM users WHERE email = $1',
      [email]
    );

    if (userResult.rows.length === 0) {
      console.log(`⚠️  User not found: ${email}`);
      return { success: false, reason: 'not_found' };
    }

    const user = userResult.rows[0];
    const userName = user.first_name && user.last_name 
      ? `${user.first_name} ${user.last_name}` 
      : user.email;
    console.log(`\n📋 Found user: ${userName} (${user.email}) - Role: ${user.role}`);

    // Delete related data first (to avoid foreign key constraints)
    const deleteOperations = [
      { name: 'user_sessions', sql: 'DELETE FROM user_sessions WHERE user_id = $1' },
      { name: 'notifications (sent to)', sql: 'DELETE FROM notifications WHERE user_id = $1' },
      { name: 'notifications (created by)', sql: 'DELETE FROM notifications WHERE created_by = $1' },
      { name: 'sprint_assignments', sql: 'DELETE FROM sprint_assignments WHERE user_id = $1' },
      { name: 'project_members', sql: 'DELETE FROM project_members WHERE user_id = $1' },
      { name: 'audit_logs (user)', sql: 'DELETE FROM audit_logs WHERE user_id = $1' },
      { name: 'sign_off_reports (created by)', sql: 'UPDATE sign_off_reports SET created_by = NULL WHERE created_by = $1' },
      { name: 'sign_off_reports (approved by)', sql: 'UPDATE sign_off_reports SET approved_by = NULL WHERE approved_by = $1' },
      { name: 'deliverables (created by)', sql: 'UPDATE deliverables SET created_by = NULL WHERE created_by = $1' },
      { name: 'sprints (created by)', sql: 'UPDATE sprints SET created_by = NULL WHERE created_by = $1' },
      { name: 'projects (owner)', sql: 'UPDATE projects SET owner_id = NULL WHERE owner_id = $1' },
      { name: 'projects (created by)', sql: 'UPDATE projects SET created_by = NULL WHERE created_by = $1' },
      { name: 'users', sql: 'DELETE FROM users WHERE id = $1' }
    ];

    console.log(`\n🗑️  Deleting user and related data...`);
    
    for (const operation of deleteOperations) {
      try {
        const result = await pool.query(operation.sql, [user.id]);
        if (result.rowCount > 0) {
          console.log(`   ✅ Deleted from ${operation.name}: ${result.rowCount} row(s)`);
        }
      } catch (err) {
        // Ignore errors for tables that don't exist
        if (err.code === '42P01') {
          console.log(`   ⚠️  Table ${operation.name} does not exist, skipping...`);
        } else {
          console.log(`   ⚠️  Error deleting from ${operation.name}: ${err.message}`);
        }
      }
    }

    console.log(`\n✅ Successfully deleted user: ${user.email}`);
    return { success: true, user: user };

  } catch (error) {
    console.error(`\n❌ Error deleting user ${email}:`, error.message);
    return { success: false, reason: 'error', error: error.message };
  }
}

async function main() {
  console.log('🚀 Starting user deletion process...\n');
  console.log('📧 Users to delete:');
  emailsToDelete.forEach(email => console.log(`   - ${email}`));
  
  const pool = poolFromEnv();

  try {
    const results = [];
    
    for (const email of emailsToDelete) {
      const result = await deleteUser(pool, email);
      results.push({ email, ...result });
    }

    console.log('\n' + '='.repeat(60));
    console.log('📊 Deletion Summary:');
    console.log('='.repeat(60));
    
    results.forEach(({ email, success, reason, user }) => {
      if (success) {
        console.log(`✅ ${email} - DELETED`);
      } else if (reason === 'not_found') {
        console.log(`⚠️  ${email} - NOT FOUND (may have been already deleted)`);
      } else {
        console.log(`❌ ${email} - FAILED`);
      }
    });

    const successCount = results.filter(r => r.success).length;
    const notFoundCount = results.filter(r => r.reason === 'not_found').length;
    const failedCount = results.filter(r => !r.success && r.reason !== 'not_found').length;

    console.log('\n' + '='.repeat(60));
    console.log(`✅ Successfully deleted: ${successCount}`);
    console.log(`⚠️  Not found: ${notFoundCount}`);
    console.log(`❌ Failed: ${failedCount}`);
    console.log('='.repeat(60));

  } catch (error) {
    console.error('\n❌ Fatal error:', error);
    process.exit(1);
  } finally {
    await pool.end();
    console.log('\n✅ Database connection closed.');
  }
}

main().catch(console.error);

