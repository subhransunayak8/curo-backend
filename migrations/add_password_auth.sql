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

COMMENT ON COLUMN users.password_hash IS 'Bcrypt hashed password';
