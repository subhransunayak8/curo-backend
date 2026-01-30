-- Remove the custom OTP table since we're using Supabase Auth
DROP TABLE IF EXISTS otp_verifications;

-- Update users table to use email instead of phone as primary identifier
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS email VARCHAR(255) UNIQUE,
ADD COLUMN IF NOT EXISTS auth_user_id UUID UNIQUE REFERENCES auth.users(id);

-- Make phone optional since we're using email now
ALTER TABLE users 
ALTER COLUMN phone DROP NOT NULL;

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_auth_user_id ON users(auth_user_id);
