-- ============================================================================
-- DATABASE STRUCTURE DIAGNOSTIC SCRIPT
-- Run this first to see what exists in your database
-- ============================================================================

-- 1. List all tables in the public schema
SELECT 
    '=== ALL TABLES ===' as section,
    table_name,
    (SELECT COUNT(*) 
     FROM information_schema.columns 
     WHERE table_name = t.table_name 
     AND table_schema = 'public') as column_count
FROM information_schema.tables t
WHERE table_schema = 'public'
AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- 2. Check if users table exists and show its structure
SELECT 
    '=== USERS TABLE STRUCTURE ===' as section,
    column_name,
    data_type,
    character_maximum_length,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'users'
ORDER BY ordinal_position;

-- 3. Count rows in users table
SELECT 
    '=== USERS TABLE DATA ===' as section,
    COUNT(*) as total_users
FROM users;

-- 4. Show sample user data (first 3 rows, hiding sensitive info)
SELECT 
    '=== SAMPLE USERS ===' as section,
    id,
    email,
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'name'
    ) THEN 'name column exists' ELSE 'name column missing' END as name_status,
    created_at
FROM users
LIMIT 3;

-- 5. Check for existing SOP-related tables
SELECT 
    '=== SOP TABLES CHECK ===' as section,
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'patients') 
        THEN 'EXISTS' ELSE 'MISSING' END as patients_table,
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'patient_medicines') 
        THEN 'EXISTS' ELSE 'MISSING' END as patient_medicines_table,
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'sops') 
        THEN 'EXISTS' ELSE 'MISSING' END as sops_table,
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'sop_steps') 
        THEN 'EXISTS' ELSE 'MISSING' END as sop_steps_table,
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'caregivers') 
        THEN 'EXISTS' ELSE 'MISSING' END as caregivers_table;

-- 6. Check for other related tables
SELECT 
    '=== OTHER TABLES ===' as section,
    table_name
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_type = 'BASE TABLE'
AND table_name NOT IN ('users', 'patients', 'patient_medicines', 'sops', 'sop_steps', 'caregivers')
ORDER BY table_name;

-- 7. Check for existing functions
SELECT 
    '=== FUNCTIONS ===' as section,
    routine_name,
    routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name LIKE '%update%'
ORDER BY routine_name;

-- 8. Check RLS status on users table
SELECT 
    '=== RLS STATUS ===' as section,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
AND tablename = 'users';

-- 9. Show all foreign key relationships
SELECT 
    '=== FOREIGN KEYS ===' as section,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
AND tc.table_schema = 'public'
ORDER BY tc.table_name;

-- 10. Summary
SELECT 
    '=== SUMMARY ===' as section,
    (SELECT COUNT(*) FROM information_schema.tables 
     WHERE table_schema = 'public' AND table_type = 'BASE TABLE') as total_tables,
    (SELECT COUNT(*) FROM users) as total_users,
    (SELECT CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'patients') 
        THEN 'YES' ELSE 'NO' END) as sop_system_exists;

-- ============================================================================
-- DIAGNOSTIC COMPLETE
-- Review the results above to understand your database structure
-- ============================================================================
