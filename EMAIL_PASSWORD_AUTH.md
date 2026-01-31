# Email/Password Authentication

## Overview
Switched from OTP-based authentication to traditional email/password authentication for simplicity and reliability.

## API Endpoints

### 1. Register New User
**POST** `/api/auth/register`

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "securepassword123",
  "name": "John Doe" // optional
}
```

**Response (201):**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "user_id": "uuid",
  "email": "user@example.com",
  "name": "John Doe"
}
```

**Errors:**
- `400` - Validation error (invalid email, password too short)
- `409` - User already exists
- `500` - Server error

### 2. Login
**POST** `/api/auth/login`

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "securepassword123"
}
```

**Response (200):**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "user_id": "uuid",
  "email": "user@example.com",
  "name": "John Doe"
}
```

**Errors:**
- `400` - Validation error
- `401` - Invalid email or password
- `500` - Server error

### 3. Logout
**POST** `/api/auth/logout`

**Response (200):**
```json
{
  "message": "Logged out successfully"
}
```

## Database Migration

Run this SQL in your Supabase SQL Editor:

```sql
-- Add password field to users table
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS password_hash VARCHAR(255);

-- Drop OTP tables (no longer needed)
DROP TABLE IF EXISTS email_otps;
DROP TABLE IF EXISTS otp_verifications;

-- Make email required and unique
ALTER TABLE users 
ALTER COLUMN email SET NOT NULL;

-- Ensure indexes exist
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
```

## Security Features

✅ **Password Hashing** - Bcrypt with salt rounds of 10
✅ **JWT Tokens** - Secure token-based authentication
✅ **Email Validation** - Server-side email format validation
✅ **Password Requirements** - Minimum 6 characters
✅ **Unique Emails** - Database constraint prevents duplicates

## Testing

### Test Registration
```bash
curl -X POST http://localhost:8000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "name": "Test User"
  }'
```

### Test Login
```bash
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

### Test with Token
```bash
curl -X GET http://localhost:8000/api/users/profile \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

## Android App Integration

Update your Android app to use email/password instead of OTP:

### 1. Update Auth Models
```kotlin
data class RegisterRequest(
    val email: String,
    val password: String,
    val name: String? = null
)

data class LoginRequest(
    val email: String,
    val password: String
)

data class AuthResponse(
    @SerializedName("access_token")
    val accessToken: String,
    @SerializedName("token_type")
    val tokenType: String,
    @SerializedName("user_id")
    val userId: String,
    @SerializedName("email")
    val email: String,
    @SerializedName("name")
    val name: String?
)
```

### 2. Update API Service
```kotlin
interface ApiService {
    @POST("auth/register")
    suspend fun register(@Body request: RegisterRequest): Response<AuthResponse>
    
    @POST("auth/login")
    suspend fun login(@Body request: LoginRequest): Response<AuthResponse>
    
    @POST("auth/logout")
    suspend fun logout(): Response<MessageResponse>
}
```

### 3. Update Repository
```kotlin
class AuthRepository {
    suspend fun register(email: String, password: String, name: String?): Result<AuthResponse> {
        return try {
            val response = apiService.register(RegisterRequest(email, password, name))
            if (response.isSuccessful && response.body() != null) {
                Result.success(response.body()!!)
            } else {
                Result.failure(Exception("Registration failed"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    suspend fun login(email: String, password: String): Result<AuthResponse> {
        return try {
            val response = apiService.login(LoginRequest(email, password))
            if (response.isSuccessful && response.body() != null) {
                Result.success(response.body()!!)
            } else {
                Result.failure(Exception("Login failed"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
```

### 4. Update UI
- **Login Screen**: Email + Password fields + Login button
- **Register Screen**: Email + Password + Name fields + Register button
- Remove OTP screen entirely

## Benefits

✅ **Simple** - No email service configuration needed
✅ **Fast** - Instant login, no waiting for emails
✅ **Reliable** - No email delivery issues
✅ **Familiar** - Standard authentication flow
✅ **Secure** - Industry-standard bcrypt password hashing
✅ **Offline-friendly** - Works without email service

## Password Reset (Future Enhancement)

To add password reset functionality later:

1. Add `reset_token` and `reset_token_expires` columns to users table
2. Create `/api/auth/forgot-password` endpoint
3. Create `/api/auth/reset-password` endpoint
4. Use email service to send reset links

## Environment Variables

No email configuration needed! Just ensure these are set:

```env
JWT_SECRET=your_secret_key_here
JWT_EXPIRES_IN=30d
```

## Migration from OTP

If you have existing users with OTP-based accounts:

1. Run the database migration
2. Users will need to "register" again with a password
3. Or implement a "set password" flow for existing users

## Next Steps

1. Run database migration in Supabase
2. Deploy backend to Render
3. Update Android app with email/password UI
4. Test registration and login flows
5. Remove OTP-related code from Android app

Your authentication is now simpler, faster, and more reliable! 🎉
