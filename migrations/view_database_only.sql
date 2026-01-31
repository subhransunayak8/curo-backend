-- ============================================================================
-- VIEW DATABASE STRUCTURE ONLY - NO CREATION, JUST VIEWING
-- Run this and copy ALL the results
-- ============================================================================

-- 1. Show all table names
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- 2. Show all columns in users table
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'users'
ORDER BY ordinal_position;

-- 3. Show all columns in ALL tables
SELECT 
    table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'public'
ORDER BY table_name, ordinal_position;
