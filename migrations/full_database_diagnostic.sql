-- ============================================================================
-- COMPLETE DATABASE DIAGNOSTIC
-- This will show EVERYTHING in your database
-- Copy ALL the results and share them
-- ============================================================================

-- ============================================================================
-- SECTION 1: ALL TABLES
-- ============================================================================
SELECT 
    '1. ALL TABLES' as diagnostic_section,
    table_name,
    (SELECT COUNT(*) FROM information_schema.columns 
     WHERE table_name = t.table_name AND table_schema = 'public') as total_columns
FROM information_schema.tables t
WHERE table_schema = 'public'
AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- ============================================================================
-- SECTION 2: USERS TABLE - COMPLETE STRUCTURE
-- ============================================================================
SELECT 
    '2. USERS TABLE COLUMNS' as diagnostic_section,
    ordinal_position as position,
    column_name,
    data_type,
    COALESCE(character_maximum_length::text, 'N/A') as max_length,
    is_nullable,
    COALESCE(column_default, 'NO DEFAULT') as default_value
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'users'
ORDER BY ordinal_position;

-- ============================================================================
-- SECTION 3: SAMPLE USER DATA
-- ============================================================================
SELECT 
    '3. SAMPLE USERS' as diagnostic_section,
    id,
    email,
    created_at
FROM users
LIMIT 5;

-- ============================================================================
-- SECTION 4: ALL OTHER TABLES AND THEIR COLUMNS
-- ============================================================================
SELECT 
    '4. ALL TABLE COLUMNS' as diagnostic_section,
    t.table_name,
    c.column_name,
    c.data_type,
    c.is_nullable
FROM information_schema.tables t
JOIN information_schema.columns c ON c.table_name = t.table_name
WHERE t.table_schema = 'public'
AND t.table_type = 'BASE TABLE'
ORDER BY t.table_name, c.ordinal_position;

-- ============================================================================
-- SECTION 5: CHECK FOR EXISTING SOP TABLES
-- ============================================================================
SELECT 
    '5. SOP TABLES STATUS' as diagnostic_section,
    'caregivers' as table_name,
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'caregivers') 
        THEN 'EXISTS' ELSE 'NOT EXISTS' END as status
UNION ALL
SELECT 
    '5. SOP TABLES STATUS',
    'patients',
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'patients') 
        THEN 'EXISTS' ELSE 'NOT EXISTS' END
UNION ALL
SELECT 
    '5. SOP TABLES STATUS',
    'patient_medicines',
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'patient_medicines') 
        THEN 'EXISTS' ELSE 'NOT EXISTS' END
UNION ALL
SELECT 
    '5. SOP TABLES STATUS',
    'sops',
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'sops') 
        THEN 'EXISTS' ELSE 'NOT EXISTS' END
UNION ALL
SELECT 
    '5. SOP TABLES STATUS',
    'sop_steps',
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'sop_steps') 
        THEN 'EXISTS' ELSE 'NOT EXISTS' END;

-- ============================================================================
-- SECTION 6: ALL FOREIGN KEYS
-- ============================================================================
SELECT 
    '6. FOREIGN KEYS' as diagnostic_section,
    tc.table_name as from_table,
    kcu.column_name as from_column,
    ccu.table_name as to_table,
    ccu.column_name as to_column
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
AND tc.table_schema = 'public'
ORDER BY tc.table_name;

-- ============================================================================
-- SECTION 7: ALL INDEXES
-- ============================================================================
SELECT 
    '7. INDEXES' as diagnostic_section,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- ============================================================================
-- SECTION 8: ALL FUNCTIONS
-- ============================================================================
SELECT 
    '8. FUNCTIONS' as diagnostic_section,
    routine_name,
    routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
ORDER BY routine_name;

-- ============================================================================
-- SECTION 9: ROW COUNTS FOR ALL TABLES
-- ============================================================================
SELECT 
    '9. ROW COUNTS' as diagnostic_section,
    'users' as table_name,
    COUNT(*) as row_count
FROM users
UNION ALL
SELECT 
    '9. ROW COUNTS',
    table_name,
    0 as row_count
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_type = 'BASE TABLE'
AND table_name != 'users'
ORDER BY table_name;

-- ============================================================================
-- SECTION 10: SUMMARY
-- ============================================================================
SELECT 
    '10. SUMMARY' as diagnostic_section,
    'Total Tables' as metric,
    COUNT(*)::text as value
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_type = 'BASE TABLE'
UNION ALL
SELECT 
    '10. SUMMARY',
    'Total Users',
    COUNT(*)::text
FROM users
UNION ALL
SELECT 
    '10. SUMMARY',
    'SOP System Exists',
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'patients') 
        THEN 'YES' ELSE 'NO' END;

-- ============================================================================
-- DIAGNOSTIC COMPLETE
-- Please copy ALL results above and share them
-- ============================================================================
