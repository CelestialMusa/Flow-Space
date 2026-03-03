/**
 * Test file for JWT Validator
 * This demonstrates how to use the jwtValidator module
 */

const { validateJwtToken, extractUserInfo, JWTValidationError } = require('./jwtValidator');

// Example usage
async function testJwtValidator() {
  try {
    // Example JWT token (replace with actual token for testing)
    const testToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoxMjMsImVtYWlsIjoidGVzdEBleGFtcGxlLmNvbSIsImlhdCI6MTY0MjQ0MTYwMCwiZXhwIjoxNjQyNDQ1MjAwfQ.example-signature';
    
    console.log('Testing JWT validation...');
    
    // Validate the token
    const decodedToken = validateJwtToken(testToken);
    console.log('✅ Token validated successfully:', decodedToken);
    
    // Extract user info
    const userInfo = extractUserInfo(decodedToken);
    console.log('✅ User info extracted:', userInfo);
    
    console.log('JWT Validator test completed successfully!');
    
  } catch (error) {
    if (error instanceof JWTValidationError) {
      console.error('❌ JWT Validation Error:', error.message);
    } else {
      console.error('❌ Unexpected Error:', error.message);
    }
  }
}

// Test with encrypted token (if ENCRYPTION_KEY is set)
async function testEncryptedToken() {
  try {
    // This would be an actual Fernet-encrypted token
    const encryptedToken = 'gAAAAABf...'; // Replace with actual encrypted token
    
    console.log('Testing encrypted token validation...');
    
    const decodedToken = validateJwtToken(encryptedToken);
    const userInfo = extractUserInfo(decodedToken);
    
    console.log('✅ Encrypted token validated successfully:', userInfo);
    
  } catch (error) {
    if (error instanceof JWTValidationError) {
      console.error('❌ JWT Validation Error:', error.message);
    } else {
      console.error('❌ Unexpected Error:', error.message);
    }
  }
}

// Export for use in other files
module.exports = {
  testJwtValidator,
  testEncryptedToken,
};

// Run tests if this file is executed directly
if (require.main === module) {
  testJwtValidator();
}
