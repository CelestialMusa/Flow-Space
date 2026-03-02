/**
 * JWT Authentication Middleware for Express
 * This middleware validates JWT tokens and extracts user information
 */

const { validateJwtToken, extractUserInfo, JWTValidationError } = require('../utils/jwtValidator');

/**
 * Express middleware to validate JWT tokens
 * 
 * Usage:
 * app.get('/protected', jwtAuthMiddleware, (req, res) => {
 *   // req.user contains the validated user information
 *   res.json({ message: 'Access granted', user: req.user });
 * });
 * 
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 * @param {Function} next - Express next function
 */
function jwtAuthMiddleware(req, res, next) {
  try {
    // Get token from Authorization header
    const authHeader = req.headers.authorization;
    
    if (!authHeader) {
      return res.status(401).json({
        error: 'Authorization header is required',
        message: 'Please provide a valid JWT token in the Authorization header'
      });
    }

    // Extract token from "Bearer <token>" format
    const tokenMatch = authHeader.match(/^Bearer\s+(.+)$/);
    
    if (!tokenMatch) {
      return res.status(401).json({
        error: 'Invalid authorization format',
        message: 'Authorization header must be in format: Bearer <token>'
      });
    }

    const token = tokenMatch[1];

    // Validate the JWT token
    const decodedToken = validateJwtToken(token);
    
    // Extract user information
    const userInfo = extractUserInfo(decodedToken);
    
    // Attach user info to request object
    req.user = userInfo;
    req.token = decodedToken; // Full decoded token for additional access if needed
    
    console.log(`JWT authentication successful for user_id: ${userInfo.user_id}`);
    next();
    
  } catch (error) {
    if (error instanceof JWTValidationError) {
      return res.status(401).json({
        error: 'Invalid token',
        message: error.message
      });
    } else {
      console.error('Unexpected error in JWT middleware:', error);
      return res.status(500).json({
        error: 'Authentication failed',
        message: 'An unexpected error occurred during authentication'
      });
    }
  }
}

/**
 * Optional JWT authentication middleware
 * This middleware doesn't fail if no token is provided, but validates it if present
 * 
 * Usage:
 * app.get('/optional-auth', optionalJwtAuthMiddleware, (req, res) => {
 *   if (req.user) {
 *     res.json({ message: 'Authenticated', user: req.user });
 *   } else {
 *     res.json({ message: 'Not authenticated' });
 *   }
 * });
 */
function optionalJwtAuthMiddleware(req, res, next) {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader) {
      // No token provided, continue without authentication
      return next();
    }

    const tokenMatch = authHeader.match(/^Bearer\s+(.+)$/);
    
    if (!tokenMatch) {
      // Invalid format, continue without authentication
      return next();
    }

    const token = tokenMatch[1];

    // Validate the JWT token
    const decodedToken = validateJwtToken(token);
    const userInfo = extractUserInfo(decodedToken);
    
    // Attach user info to request object
    req.user = userInfo;
    req.token = decodedToken;
    
    console.log(`Optional JWT authentication successful for user_id: ${userInfo.user_id}`);
    next();
    
  } catch (error) {
    // Log error but continue without authentication
    console.warn('Optional JWT authentication failed:', error.message);
    next();
  }
}

/**
 * Role-based access control middleware
 * This middleware checks if the authenticated user has the required role
 * 
 * @param {string|Array} requiredRoles - Required role(s) to access the resource
 * @returns {Function} Express middleware function
 */
function requireRole(requiredRoles) {
  const roles = Array.isArray(requiredRoles) ? requiredRoles : [requiredRoles];
  
  return (req, res, next) => {
    // First ensure user is authenticated
    if (!req.user) {
      return res.status(401).json({
        error: 'Authentication required',
        message: 'Please provide a valid JWT token'
      });
    }

    // Check if user has required role
    const userRole = req.token.role || req.token.user_role || 'user';
    
    if (!roles.includes(userRole)) {
      return res.status(403).json({
        error: 'Insufficient permissions',
        message: `Required role: ${roles.join(' or ')}. Current role: ${userRole}`
      });
    }

    console.log(`Role-based access granted for user_id: ${req.user.user_id}, role: ${userRole}`);
    next();
  };
}

module.exports = {
  jwtAuthMiddleware,
  optionalJwtAuthMiddleware,
  requireRole,
};
