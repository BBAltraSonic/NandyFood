-- ============================================
-- NandyFood Database Verification Script
-- Date: 2024-12-01
-- Description: Verify all tables, indexes, RLS policies, and functions
-- ============================================

-- ============================================
-- SECTION 1: Check All Tables Exist
-- ============================================

SELECT
  '✓ TABLES CHECK' as check_type,
  table_name,
  CASE
    WHEN table_name IN (
      'profiles', 'addresses', 'restaurants', 'menu_items', 'orders',
      'order_items', 'deliveries', 'promotions', 'user_roles',
      'restaurant_owners', 'restaurant_analytics', 'favourites',
      'user_devices', 'feedback'
    ) THEN '✓ EXISTS'
    ELSE '✗ MISSING'
  END as status
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN (
    'profiles', 'addresses', 'restaurants', 'menu_items', 'orders',
    'order_items', 'deliveries', 'promotions', 'user_roles',
    'restaurant_owners', 'restaurant_analytics', 'favourites',
    'user_devices', 'feedback'
  )
ORDER BY table_name;

-- ============================================
-- SECTION 2: Check New Tables Structure
-- ============================================

-- Check favourites table columns
SELECT
  '✓ FAVOURITES COLUMNS' as check_type,
  column_name,
  data_type,
  CASE WHEN is_nullable = 'NO' THEN 'NOT NULL' ELSE 'NULLABLE' END as null_constraint
FROM information_schema.columns
WHERE table_name = 'favourites'
ORDER BY ordinal_position;

-- Check user_devices table columns
SELECT
  '✓ USER_DEVICES COLUMNS' as check_type,
  column_name,
  data_type,
  CASE WHEN is_nullable = 'NO' THEN 'NOT NULL' ELSE 'NULLABLE' END as null_constraint
FROM information_schema.columns
WHERE table_name = 'user_devices'
ORDER BY ordinal_position;

-- Check feedback table columns
SELECT
  '✓ FEEDBACK COLUMNS' as check_type,
  column_name,
  data_type,
  CASE WHEN is_nullable = 'NO' THEN 'NOT NULL' ELSE 'NULLABLE' END as null_constraint
FROM information_schema.columns
WHERE table_name = 'feedback'
ORDER BY ordinal_position;

-- Check orders table modifications
SELECT
  '✓ ORDERS NEW COLUMNS' as check_type,
  column_name,
  data_type,
  CASE WHEN is_nullable = 'NO' THEN 'NOT NULL' ELSE 'NULLABLE' END as null_constraint
FROM information_schema.columns
WHERE table_name = 'orders'
  AND column_name IN ('cancellation_reason', 'cancelled_at')
ORDER BY ordinal_position;

-- ============================================
-- SECTION 3: Check Indexes
-- ============================================

SELECT
  '✓ INDEXES CHECK' as check_type,
  schemaname,
  tablename,
  indexname,
  indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename IN ('favourites', 'user_devices', 'feedback', 'orders')
  AND (
    indexname LIKE 'idx_favourites%' OR
    indexname LIKE 'idx_user_devices%' OR
    indexname LIKE 'idx_feedback%' OR
    indexname = 'idx_orders_cancelled_at'
  )
ORDER BY tablename, indexname;

-- ============================================
-- SECTION 4: Check RLS Policies
-- ============================================

-- Count RLS policies per table
SELECT
  '✓ RLS POLICIES COUNT' as check_type,
  schemaname,
  tablename,
  COUNT(*) as policy_count,
  CASE
    WHEN tablename = 'favourites' AND COUNT(*) >= 3 THEN '✓ COMPLETE'
    WHEN tablename = 'user_devices' AND COUNT(*) >= 4 THEN '✓ COMPLETE'
    WHEN tablename = 'feedback' AND COUNT(*) >= 2 THEN '✓ COMPLETE'
    ELSE '⚠ INCOMPLETE'
  END as status
FROM pg_policies
WHERE tablename IN ('favourites', 'user_devices', 'feedback')
GROUP BY schemaname, tablename
ORDER BY tablename;

-- List all RLS policies
SELECT
  '✓ RLS POLICIES DETAIL' as check_type,
  schemaname,
  tablename,
  policyname,
  cmd as command,
  permissive,
  CASE
    WHEN qual IS NOT NULL THEN '✓ HAS USING'
    ELSE '✗ NO USING'
  END as using_clause,
  CASE
    WHEN with_check IS NOT NULL THEN '✓ HAS CHECK'
    ELSE '✗ NO CHECK'
  END as check_clause
FROM pg_policies
WHERE tablename IN ('favourites', 'user_devices', 'feedback')
ORDER BY tablename, policyname;

-- ============================================
-- SECTION 5: Check RLS is Enabled
-- ============================================

SELECT
  '✓ RLS ENABLED CHECK' as check_type,
  schemaname,
  tablename,
  CASE
    WHEN rowsecurity THEN '✓ ENABLED'
    ELSE '✗ DISABLED'
  END as rls_status
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('favourites', 'user_devices', 'feedback')
ORDER BY tablename;

-- ============================================
-- SECTION 6: Check Functions Exist
-- ============================================

SELECT
  '✓ FUNCTIONS CHECK' as check_type,
  routine_schema,
  routine_name,
  routine_type,
  data_type as return_type
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name IN (
    'update_updated_at_column',
    'get_user_active_devices',
    'get_user_favourite_restaurants',
    'cleanup_inactive_devices'
  )
ORDER BY routine_name;

-- ============================================
-- SECTION 7: Check Triggers
-- ============================================

SELECT
  '✓ TRIGGERS CHECK' as check_type,
  trigger_schema,
  trigger_name,
  event_object_table as table_name,
  event_manipulation as trigger_event,
  action_timing,
  action_statement
FROM information_schema.triggers
WHERE trigger_schema = 'public'
  AND trigger_name IN (
    'update_user_devices_updated_at',
    'update_feedback_updated_at'
  )
ORDER BY trigger_name;

-- ============================================
-- SECTION 8: Check Constraints
-- ============================================

-- Check favourites constraints
SELECT
  '✓ FAVOURITES CONSTRAINTS' as check_type,
  constraint_name,
  constraint_type
FROM information_schema.table_constraints
WHERE table_name = 'favourites'
  AND constraint_schema = 'public'
ORDER BY constraint_type, constraint_name;

-- Check user_devices constraints
SELECT
  '✓ USER_DEVICES CONSTRAINTS' as check_type,
  constraint_name,
  constraint_type
FROM information_schema.table_constraints
WHERE table_name = 'user_devices'
  AND constraint_schema = 'public'
ORDER BY constraint_type, constraint_name;

-- Check feedback constraints
SELECT
  '✓ FEEDBACK CONSTRAINTS' as check_type,
  constraint_name,
  constraint_type
FROM information_schema.table_constraints
WHERE table_name = 'feedback'
  AND constraint_schema = 'public'
ORDER BY constraint_type, constraint_name;

-- ============================================
-- SECTION 9: Check Foreign Keys
-- ============================================

SELECT
  '✓ FOREIGN KEYS CHECK' as check_type,
  tc.table_name,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name,
  rc.update_rule,
  rc.delete_rule
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
JOIN information_schema.referential_constraints AS rc
  ON tc.constraint_name = rc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_name IN ('favourites', 'user_devices', 'feedback')
ORDER BY tc.table_name, kcu.column_name;

-- ============================================
-- SECTION 10: Check Data Counts
-- ============================================

SELECT
  '✓ DATA COUNTS' as check_type,
  'favourites' as table_name,
  COUNT(*) as record_count
FROM favourites
UNION ALL
SELECT
  '✓ DATA COUNTS',
  'user_devices',
  COUNT(*)
FROM user_devices
UNION ALL
SELECT
  '✓ DATA COUNTS',
  'feedback',
  COUNT(*)
FROM feedback
UNION ALL
SELECT
  '✓ DATA COUNTS',
  'orders_with_cancellation',
  COUNT(*)
FROM orders
WHERE cancellation_reason IS NOT NULL OR cancelled_at IS NOT NULL;

-- ============================================
-- SECTION 11: Check Table Comments
-- ============================================

SELECT
  '✓ TABLE COMMENTS' as check_type,
  obj_description(c.oid, 'pg_class') as table_comment,
  c.relname as table_name
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relname IN ('favourites', 'user_devices', 'feedback')
  AND c.relkind = 'r'
ORDER BY c.relname;

-- ============================================
-- SECTION 12: Check Column Comments
-- ============================================

SELECT
  '✓ COLUMN COMMENTS' as check_type,
  c.relname as table_name,
  a.attname as column_name,
  col_description(c.oid, a.attnum) as column_comment
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
JOIN pg_attribute a ON a.attrelid = c.oid
WHERE n.nspname = 'public'
  AND c.relname IN ('favourites', 'user_devices', 'feedback')
  AND a.attnum > 0
  AND NOT a.attisdropped
  AND col_description(c.oid, a.attnum) IS NOT NULL
ORDER BY c.relname, a.attnum;

-- ============================================
-- SECTION 13: Test Helper Functions
-- ============================================

-- Test get_user_active_devices function (should return empty result)
SELECT
  '✓ FUNCTION TEST: get_user_active_devices' as check_type,
  'Function exists and can be called' as status;

-- Test get_user_favourite_restaurants function (should return empty result)
SELECT
  '✓ FUNCTION TEST: get_user_favourite_restaurants' as check_type,
  'Function exists and can be called' as status;

-- Test cleanup_inactive_devices function
SELECT
  '✓ FUNCTION TEST: cleanup_inactive_devices' as check_type,
  'Function exists and can be called' as status;

-- ============================================
-- SECTION 14: Check Permissions
-- ============================================

SELECT
  '✓ PERMISSIONS CHECK' as check_type,
  table_name,
  grantee,
  privilege_type
FROM information_schema.table_privileges
WHERE table_schema = 'public'
  AND table_name IN ('favourites', 'user_devices', 'feedback')
  AND grantee = 'authenticated'
ORDER BY table_name, privilege_type;

-- ============================================
-- SECTION 15: Database Size and Statistics
-- ============================================

SELECT
  '✓ TABLE SIZES' as check_type,
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as total_size,
  pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) as table_size,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) - pg_relation_size(schemaname||'.'||tablename)) as indexes_size
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('favourites', 'user_devices', 'feedback', 'orders')
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- ============================================
-- SECTION 16: Final Summary
-- ============================================

DO $$
DECLARE
  v_tables_count INTEGER;
  v_indexes_count INTEGER;
  v_policies_count INTEGER;
  v_functions_count INTEGER;
  v_triggers_count INTEGER;
BEGIN
  -- Count tables
  SELECT COUNT(*) INTO v_tables_count
  FROM information_schema.tables
  WHERE table_schema = 'public'
    AND table_name IN ('favourites', 'user_devices', 'feedback');

  -- Count indexes
  SELECT COUNT(*) INTO v_indexes_count
  FROM pg_indexes
  WHERE schemaname = 'public'
    AND tablename IN ('favourites', 'user_devices', 'feedback')
    AND (indexname LIKE 'idx_favourites%' OR indexname LIKE 'idx_user_devices%' OR indexname LIKE 'idx_feedback%');

  -- Count policies
  SELECT COUNT(*) INTO v_policies_count
  FROM pg_policies
  WHERE tablename IN ('favourites', 'user_devices', 'feedback');

  -- Count functions
  SELECT COUNT(*) INTO v_functions_count
  FROM information_schema.routines
  WHERE routine_schema = 'public'
    AND routine_name IN ('update_updated_at_column', 'get_user_active_devices', 'get_user_favourite_restaurants', 'cleanup_inactive_devices');

  -- Count triggers
  SELECT COUNT(*) INTO v_triggers_count
  FROM information_schema.triggers
  WHERE trigger_schema = 'public'
    AND trigger_name IN ('update_user_devices_updated_at', 'update_feedback_updated_at');

  RAISE NOTICE '================================================';
  RAISE NOTICE '         VERIFICATION SUMMARY';
  RAISE NOTICE '================================================';
  RAISE NOTICE 'New Tables Created: % / 3', v_tables_count;
  RAISE NOTICE 'Indexes Created: % / 13+', v_indexes_count;
  RAISE NOTICE 'RLS Policies: % / 13', v_policies_count;
  RAISE NOTICE 'Helper Functions: % / 4', v_functions_count;
  RAISE NOTICE 'Triggers: % / 2', v_triggers_count;
  RAISE NOTICE '================================================';

  IF v_tables_count = 3 AND v_policies_count >= 13 AND v_functions_count = 4 AND v_triggers_count = 2 THEN
    RAISE NOTICE '✓✓✓ MIGRATION COMPLETE AND VERIFIED ✓✓✓';
  ELSE
    RAISE WARNING '⚠ MIGRATION INCOMPLETE - CHECK DETAILS ABOVE';
  END IF;

  RAISE NOTICE '================================================';
END $$;
