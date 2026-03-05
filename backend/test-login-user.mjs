import pool from './dbPool.js';

async function testUser() {
  try {
    console.log('🔍 Checking for test users...');
    
    const emails = ['ad_20260129@example.com', 'deliverylead_20260129@example.com'];
    
    for (const email of emails) {
      const result = await pool.query(
        `SELECT 
          id, 
          email, 
          first_name, 
          last_name, 
          role, 
          is_active,
          CASE 
            WHEN password_hash IS NOT NULL THEN 'has password_hash' 
            ELSE 'no password' 
          END as password_status
        FROM users 
        WHERE email = $1`,
        [email]
      );
      
      if (result.rows.length > 0) {
        const user = result.rows[0];
        console.log(`\n✅ Found user: ${user.email}`);
        console.log(`   Name: ${user.first_name || ''} ${user.last_name || ''}`);
        console.log(`   Role: ${user.role}`);
        console.log(`   Active: ${user.is_active}`);
        console.log(`   Password: ${user.password_status}`);
      } else {
        console.log(`\n❌ User not found: ${email}`);
      }
    }
    
    await pool.end();
    console.log('\n✅ Test complete');
  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error(error.stack);
    process.exit(1);
  }
}

testUser();

