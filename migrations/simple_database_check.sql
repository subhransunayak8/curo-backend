-- ============================================================================
-- SIMPLE DATABASE CHECK - Shows everything clearly
-- ============================================================================

-- 1. Show all tables
SELECT 'TABLE: ' || table_name as info
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- 2. Show users table columns
SELECT 'USERS COLUMN: ' || column_name || ' (' || data_type || ')' as info
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'users'
ORDER BY ordinal_position;

-- 3. Show first user ID (we'll need this)
SELECT 'FIRST USER ID: ' || id::text as info
FROM users
LIMIT 1;
