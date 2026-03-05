/**
 * JWT token validation and decoding
 */
const jwt = require('jsonwebtoken');
const Fernet = require('fernet');

class JWTValidationError extends Error {
  constructor(message) {
    super(message);
    this.name = 'JWTValidationError';
  }
}

/**
 * Validate and decode JWT token from Khonobuzz
 * 
 * This function:
 * 1. Validates the token structure (3 parts separated by dots)
 * 2. Verifies the token signature using JWT_SECRET
 * 3. Checks token expiration
 * 4. Extracts and validates required fields (user_id, email)
 * 
 * @param {string} token - JWT token string to validate
 * @returns {Object} Decoded token payload as dictionary
 * @throws {JWTValidationError} If token is invalid, expired, or missing required fields
 */
function validateJwtToken(token) {
  if (!token || typeof token !== 'string') {
    throw new JWTValidationError('Token is required and must be a string');
  }

  // Some deployments provide an encrypted token (Fernet) rather than a raw JWT.
  // Attempt to decrypt using ENCRYPTION_KEY before JWT validation.
  try {
    const encKey = (process.env.ENCRYPTION_KEY || '').trim();
    const looksEncrypted = token.startsWith('gAAAA');
    
    if (!encKey && looksEncrypted) {
      throw new JWTValidationError(
        'Encrypted token detected but ENCRYPTION_KEY is not configured'
      );
    }
    
    if (encKey) {
      try {
        // Use the fernet package for proper Fernet-compatible decryption
        const secret = new Fernet.Secret(encKey);
        const fernetToken = new Fernet.Token({
          secret: secret,
          token: token,
          ttl: 0
        });
        const decryptedToken = fernetToken.decode();
        if (decryptedToken) {
          console.log('Encrypted token detected and decrypted successfully');
          token = decryptedToken;
        }
      } catch (error) {
        console.warn(`Fernet decryption failed: ${error.message}. Proceeding as raw JWT`);
        // Proceed assuming raw JWT
      }
    }
  } catch (error) {
    if (error instanceof JWTValidationError) {
      throw error;
    }
    console.warn(`Failed to load settings for decryption: ${error.message}. Proceeding as raw JWT`);
  }

  // Validate token structure (JWT has 3 parts: header.payload.signature)
  const parts = token.split('.');
  if (parts.length !== 3) {
    throw new JWTValidationError(
      `Invalid token format: expected 3 parts, got ${parts.length}`
    );
  }

  try {
    const jwtSecret = process.env.JWT_SECRET_KEY || process.env.JWT_SECRET;
    if (!jwtSecret) {
      throw new JWTValidationError('JWT_SECRET_KEY is not configured');
    }

    // Decode and verify JWT token
    // Using HS256 algorithm (HMAC with SHA-256)
    // This matches the algorithm typically used by Khonobuzz
    const decoded = jwt.verify(token, jwtSecret, {
      algorithms: ['HS256'],
    });

    console.log(`JWT token validated successfully for user_id: ${decoded.user_id}`);
    return decoded;

  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      console.warn('JWT token has expired');
      throw new JWTValidationError('Token has expired');
    } else if (error.name === 'JsonWebTokenError') {
      if (error.message.includes('signature')) {
        console.warn('JWT token signature is invalid');
        throw new JWTValidationError('Invalid token signature');
      } else {
        console.warn(`Failed to decode JWT token: ${error.message}`);
        throw new JWTValidationError(`Invalid token format: ${error.message}`);
      }
    } else if (error.name === 'NotBeforeError') {
      console.warn('JWT token is not yet active');
      throw new JWTValidationError('Token is not yet active');
    } else {
      console.error(`Unexpected error validating JWT token: ${error.message}`);
      throw new JWTValidationError(`Token validation failed: ${error.message}`);
    }
  }
}

/**
 * Extract user information from decoded JWT token
 * 
 * Handles multiple field name variations:
 * - user_id, uid, sub (for user ID)
 * - email, user_email (for email)
 * 
 * Email is optional and can be resolved from Firestore if missing.
 * User ID is required for Firebase custom token generation.
 * 
 * @param {Object} decodedToken - Decoded JWT payload
 * @returns {Object} Dictionary with user_id (required) and email (optional)
 * @throws {JWTValidationError} If user_id is missing
 */
function extractUserInfo(decodedToken) {
  // Try multiple field names for user_id
  const userId = (
    decodedToken.user_id ||
    decodedToken.uid ||
    decodedToken.sub ||
    decodedToken.userId
  );

  // Try multiple field names for email (optional)
  const email = (
    decodedToken.email ||
    decodedToken.user_email ||
    decodedToken.email_address
  );

  // User ID is required (needed for Firebase custom token)
  if (!userId) {
    throw new JWTValidationError(
      `Token missing required field: user_id (or uid/sub). Available fields: ${Object.keys(decodedToken).join(', ')}`
    );
  }

  // Email is optional - can be resolved from Firestore
  // Convert to string and return empty string if undefined
  const emailStr = email ? String(email) : '';

  return {
    user_id: String(userId),
    email: emailStr,
  };
}

module.exports = {
  JWTValidationError,
  validateJwtToken,
  extractUserInfo,
};
