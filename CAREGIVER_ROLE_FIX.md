# Caregiver Role Registration Fix

## Issue
When caregivers registered through the caregiver app, they were being saved in the database with `role: 'user'` instead of `role: 'caregiver'`.

This caused issues because:
- Caregivers couldn't access caregiver-specific features
- Role-based permissions were incorrect
- Users and caregivers were indistinguishable in the database

## Root Cause

### Backend Code (Before Fix)
The `authService.js` hardcoded the role as `'user'` for all registrations:

```javascript
async register(email, password, name = null) {
  // ...
  const { data: newUser, error } = await supabaseAdmin
    .from('users')
    .insert({
      email,
      password_hash: passwordHash,
      full_name: name,
      role: 'user',  // ❌ Hardcoded as 'user'
      created_at: new Date().toISOString()
    })
  // ...
}
```

The `authRoutes.js` didn't accept or pass the role parameter:
```javascript
const { email, password, name } = req.body;  // ❌ No role
const result = await authService.register(email, password, name);
```

### Android App (Already Correct)
The caregiver app was already sending the correct role:
```kotlin
data class RegisterRequest(
    val email: String,
    val password: String,
    val name: String,
    val role: String = "caregiver"  // ✅ Correct
)
```

## Fix Applied ✅

### 1. Updated authService.js
**File**: `backend/src/services/authService.js`

```javascript
// Before
async register(email, password, name = null) {
  // ...
  role: 'user',  // ❌ Hardcoded
  // ...
}

// After
async register(email, password, name = null, role = 'user') {
  console.log(`Registering new user: ${email} with role: ${role}`);
  // ...
  role: role,  // ✅ Use parameter
  // ...
  console.log(`User registered successfully: ${email} with role: ${role}`);
}
```

**Changes**:
- Added `role` parameter with default value `'user'`
- Use the `role` parameter instead of hardcoded value
- Added logging to track role assignment

### 2. Updated authRoutes.js
**File**: `backend/src/routes/authRoutes.js`

```javascript
// Before
body('name').optional().trim(),
async (req, res) => {
  const { email, password, name } = req.body;  // ❌ No role
  const result = await authService.register(email, password, name);
}

// After
body('name').optional().trim(),
body('role').optional().isIn(['user', 'caregiver']).withMessage('Invalid role'),
async (req, res) => {
  const { email, password, name, role } = req.body;  // ✅ Include role
  const result = await authService.register(email, password, name, role);
}
```

**Changes**:
- Added validation for `role` field (must be 'user' or 'caregiver')
- Extract `role` from request body
- Pass `role` to authService.register()

## How It Works Now

### Registration Flow

#### User App Registration
```
Request:
{
  "email": "user@example.com",
  "password": "password123",
  "name": "John Doe"
  // No role specified
}

Backend:
- role parameter defaults to 'user'
- User saved with role: 'user' ✅
```

#### Caregiver App Registration
```
Request:
{
  "email": "caregiver@example.com",
  "password": "password123",
  "name": "Jane Smith",
  "role": "caregiver"  // ✅ Specified
}

Backend:
- role parameter = 'caregiver'
- User saved with role: 'caregiver' ✅
```

## Validation

### Role Validation
```javascript
body('role').optional().isIn(['user', 'caregiver'])
```

**Valid Values**:
- `'user'` - Regular users (patient/family)
- `'caregiver'` - Caregivers

**Invalid Values**:
- `'admin'` - Rejected
- `'doctor'` - Rejected
- Any other value - Rejected

### Error Response
```json
{
  "errors": [
    {
      "msg": "Invalid role",
      "param": "role",
      "location": "body"
    }
  ]
}
```

## Database Impact

### Before Fix
```sql
-- All registrations
SELECT email, role FROM users;

email                    | role
------------------------|------
user@example.com        | user
caregiver@example.com   | user  ❌ Wrong!
```

### After Fix
```sql
-- Correct role assignment
SELECT email, role FROM users;

email                    | role
------------------------|----------
user@example.com        | user      ✅
caregiver@example.com   | caregiver ✅
```

## Testing

### Test User Registration
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@test.com",
    "password": "password123",
    "name": "Test User"
  }'

# Expected: role = 'user' (default)
```

### Test Caregiver Registration
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "caregiver@test.com",
    "password": "password123",
    "name": "Test Caregiver",
    "role": "caregiver"
  }'

# Expected: role = 'caregiver'
```

### Test Invalid Role
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@test.com",
    "password": "password123",
    "name": "Test Admin",
    "role": "admin"
  }'

# Expected: 400 Bad Request - "Invalid role"
```

## Backward Compatibility

### Existing User App ✅
The user app doesn't send a `role` parameter, so it defaults to `'user'`:
```javascript
// No role in request
const { email, password, name, role } = req.body;
// role = undefined

// authService.register(email, password, name, role)
// role defaults to 'user' ✅
```

### Existing Caregiver App ✅
The caregiver app already sends `role: 'caregiver'`:
```kotlin
RegisterRequest(
    email = email,
    password = password,
    name = name,
    role = "caregiver"  // ✅ Already correct
)
```

## Logging

### Registration Logs
```
Before:
Registering new user: caregiver@example.com
User registered successfully: caregiver@example.com

After:
Registering new user: caregiver@example.com with role: caregiver
User registered successfully: caregiver@example.com with role: caregiver
```

This helps with debugging and auditing user registrations.

## Security Considerations

### Role Validation
- Only `'user'` and `'caregiver'` roles are allowed
- Prevents privilege escalation (can't register as admin)
- Server-side validation (can't be bypassed)

### Default Role
- Default is `'user'` (least privilege)
- Explicit role required for caregiver access
- Prevents accidental privilege assignment

## Impact on Features

### Role-Based Access Control
```javascript
// Example middleware
function requireCaregiver(req, res, next) {
  if (req.user.role !== 'caregiver') {
    return res.status(403).json({ error: 'Caregiver access required' });
  }
  next();
}

// Now works correctly
router.get('/caregiver/patients', requireCaregiver, getPatients);
```

### Database Queries
```sql
-- Get all caregivers
SELECT * FROM users WHERE role = 'caregiver';

-- Get all regular users
SELECT * FROM users WHERE role = 'user';

-- Now returns correct results ✅
```

## Migration for Existing Data

If you have existing caregivers registered with `role: 'user'`, update them:

```sql
-- Update existing caregivers
UPDATE users 
SET role = 'caregiver' 
WHERE email LIKE '%caregiver%' 
  OR email IN (
    'specific@caregiver.com',
    'another@caregiver.com'
  );

-- Verify
SELECT email, role FROM users WHERE role = 'caregiver';
```

## Summary

**Issue**: Caregivers registered with `role: 'user'` instead of `role: 'caregiver'`
**Cause**: Backend hardcoded role as `'user'` and didn't accept role parameter
**Fix**: 
- Added `role` parameter to authService.register()
- Added role validation and extraction in authRoutes
- Use role from request or default to 'user'
**Impact**: Caregivers now correctly registered with `role: 'caregiver'`
**Status**: ✅ Fixed and tested

---

**Fixed**: January 31, 2026
**Priority**: High (affects user permissions)
