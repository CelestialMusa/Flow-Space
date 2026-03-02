# JWT Validator Documentation

## Overview

The JWT Validator is a comprehensive utility for validating and decoding JWT tokens from external systems like Khonobuzz. It supports both raw JWT tokens and Fernet-encrypted tokens.

## Features

- **JWT Token Validation**: Validates token structure, signature, and expiration
- **Fernet Decryption**: Supports encrypted tokens using the Fernet symmetric encryption
- **User Information Extraction**: Extracts user_id and email from various field name formats
- **Role-based Dashboard Routing**: Determines appropriate dashboard URLs based on user roles
- **Express Middleware**: Ready-to-use middleware for route protection

## Installation

The required dependencies are already included in the project:

```bash
npm install jsonwebtoken fernet
```

## Environment Variables

Add these to your `.env` file:

```env
JWT_SECRET=your-super-secret-jwt-key-here
ENCRYPTION_KEY=your-fernet-encryption-key-here  # Optional, for encrypted tokens
```

## Usage

### 1. Direct Token Validation

```javascript
const { validateJwtToken, extractUserInfo, JWTValidationError } = require('./utils/jwtValidator');

try {
  const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
  
  // Validate the token
  const decodedToken = validateJwtToken(token);
  
  // Extract user information
  const userInfo = extractUserInfo(decodedToken);
  
  console.log('Valid user:', userInfo);
  // Output: { user_id: '123', email: 'user@example.com' }
  
} catch (error) {
  if (error instanceof JWTValidationError) {
    console.error('Token validation failed:', error.message);
  }
}
```

### 2. Express Middleware

```javascript
const { jwtAuthMiddleware, requireRole } = require('./middleware/jwtAuth');

// Protect routes with JWT authentication
app.get('/api/protected', jwtAuthMiddleware, (req, res) => {
  res.json({ message: 'Access granted', user: req.user });
});

// Role-based access control
app.get('/api/admin', jwtAuthMiddleware, requireRole('admin'), (req, res) => {
  res.json({ message: 'Admin access granted' });
});
```

### 3. API Endpoint for Token Validation

The system provides a REST endpoint for token validation:

```bash
POST /api/auth/validate-token
Content-Type: application/json

{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response:**
```json
{
  "success": true,
  "message": "Token validated successfully",
  "user": {
    "user_id": "123",
    "email": "user@example.com",
    "role": "developer"
  },
  "redirect": {
    "url": "/developer/dashboard",
    "role": "developer"
  },
  "token": {
    "user_id": "123",
    "email": "user@example.com",
    "role": "developer",
    "iat": 1642441600,
    "exp": 1642445200
  }
}
```

## Frontend Integration

### Landing Screen Token Input

```javascript
async function validateTokenAndRedirect(token) {
  try {
    const response = await fetch('/api/auth/validate-token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ token }),
    });

    const data = await response.json();

    if (data.success) {
      // Store user info and redirect to dashboard
      localStorage.setItem('user', JSON.stringify(data.user));
      localStorage.setItem('token', JSON.stringify(data.token));
      
      // Redirect based on role
      window.location.href = data.redirect.url;
    } else {
      alert('Invalid token: ' + data.message);
    }
  } catch (error) {
    console.error('Token validation failed:', error);
    alert('Token validation failed');
  }
}

// Usage with form input
document.getElementById('token-form').addEventListener('submit', (e) => {
  e.preventDefault();
  const token = document.getElementById('token-input').value;
  validateTokenAndRedirect(token);
});
```

## Token Formats Supported

### 1. Standard JWT Token
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoxMjMsImVtYWlsIjoidGVzdEBleGFtcGxlLmNvbSIsInJvbGUiOiJkZXZlbG9wZXIiLCJpYXQiOjE2NDI0NDE2MDAsImV4cCI6MTY0MjQ0NTIwMH0.signature
```

### 2. Fernet-Encrypted Token
```
gAAAAABf... (starts with gAAAA)
```

## User Field Mapping

The validator supports multiple field name variations:

**User ID fields:**
- `user_id`
- `uid`
- `sub`
- `userId`

**Email fields:**
- `email`
- `user_email`
- `email_address`

**Role fields:**
- `role`
- `user_role`

## Dashboard Routing

Based on user role, the system redirects to:

| Role | Dashboard URL |
|------|---------------|
| admin | `/admin/dashboard` |
| manager | `/manager/dashboard` |
| developer | `/developer/dashboard` |
| user | `/user/dashboard` |

## Error Handling

The validator provides specific error messages:

- `"Token is required and must be a string"`
- `"Invalid token format: expected 3 parts, got X"`
- `"Token has expired"`
- `"Invalid token signature"`
- `"Token missing required field: user_id"`
- `"Encrypted token detected but ENCRYPTION_KEY is not configured"`

## Security Considerations

1. **JWT Secret**: Always use a strong, unique JWT secret
2. **Token Expiration**: Tokens should have reasonable expiration times
3. **HTTPS**: Always use HTTPS in production to prevent token interception
4. **Environment Variables**: Never commit secrets to version control

## Testing

Run the test file to verify functionality:

```bash
node src/utils/testJwtValidator.js
```

## Troubleshooting

### Common Issues

1. **"JWT_SECRET is not configured"**
   - Add `JWT_SECRET` to your `.env` file

2. **"Invalid token signature"**
   - Ensure the JWT secret matches the one used to create the token
   - Check if the token was tampered with

3. **"Encrypted token detected but ENCRYPTION_KEY is not configured"**
   - Add `ENCRYPTION_KEY` to your `.env` file
   - Ensure the key is a valid Fernet key

4. **"Token has expired"**
   - The token has passed its expiration time
   - Generate a new token from the source system

## API Reference

### Functions

#### `validateJwtToken(token: string): Object`
Validates and decodes a JWT token.

**Parameters:**
- `token`: JWT token string to validate

**Returns:** Decoded token payload

**Throws:** `JWTValidationError`

#### `extractUserInfo(decodedToken: Object): Object`
Extracts user information from decoded token.

**Parameters:**
- `decodedToken`: Decoded JWT payload

**Returns:** `{ user_id: string, email: string }`

**Throws:** `JWTValidationError` if user_id is missing

### Middleware

#### `jwtAuthMiddleware(req, res, next)`
Express middleware for JWT authentication.

#### `optionalJwtAuthMiddleware(req, res, next)`
Optional JWT authentication that doesn't fail if no token is provided.

#### `requireRole(roles)`
Role-based access control middleware.

**Parameters:**
- `roles`: String or array of required roles

## License

This JWT validator is part of the Flow-Space project and follows the same license terms.
