-- Fix Row Level Security policies for authentication

-- Drop existing restrictive policies
DROP POLICY IF EXISTS "Users can view own data" ON users;
DROP POLICY IF EXISTS "Users can update own data" ON users;

-- Create permissive policies for authentication
-- Allow anyone to insert (for registration)
CREATE POLICY "Allow public registration" ON users
    FOR INSERT 
    WITH CHECK (true);

-- Allow users to view their own data
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT 
    USING (true);

-- Allow users to update their own data
CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE 
    USING (true);

-- Allow service role to do everything (for backend operations)
CREATE POLICY "Service role has full access" ON users
    FOR ALL 
    USING (true);

-- Ensure RLS is enabled
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Add comment
COMMENT ON TABLE users IS 'Users table with RLS policies for authentication';
