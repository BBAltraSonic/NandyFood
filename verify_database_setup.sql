-- =====================================================
-- Database Verification Script
-- Run this in Supabase SQL Editor to verify setup
-- =====================================================

-- Check all new tables exist
SELECT 
    'Tables Check' as check_type,
    table_name,
    CASE 
        WHEN table_name IN ('user_roles', 'restaurant_owners', 'restaurant_staff', 
                           'restaurant_analytics', 'menu_item_analytics') 
        THEN '✅ EXISTS'
        ELSE '❌ MISSING'
    END as status
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN ('user_roles', 'restaurant_owners', 'restaurant_staff', 
                   'restaurant_analytics', 'menu_item_analytics')
ORDER BY table_name;

-- Check enum types
SELECT 
    'Enum Types' as check_type,
    typname as type_name,
    '✅ EXISTS' as status
FROM pg_type
WHERE typname = 'user_role_type';

-- Check database functions
SELECT 
    'Functions' as check_type,
    routine_name as function_name,
    '✅ EXISTS' as status
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name IN ('assign_default_consumer_role', 'sync_primary_role', 
                     'user_has_permission', 'get_user_restaurant_permissions',
                     'get_restaurant_dashboard_metrics', 'get_user_restaurants')
ORDER BY routine_name;

-- Check RLS policies
SELECT 
    'RLS Policies' as check_type,
    tablename,
    policyname,
    '✅ EXISTS' as status
FROM pg_policies
WHERE schemaname = 'public'
AND tablename IN ('user_roles', 'restaurant_owners', 'restaurant_staff', 
                 'restaurant_analytics', 'menu_item_analytics')
ORDER BY tablename, policyname;

-- Check indexes
SELECT 
    'Indexes' as check_type,
    tablename,
    indexname,
    '✅ EXISTS' as status
FROM pg_indexes
WHERE schemaname = 'public'
AND tablename IN ('user_roles', 'restaurant_owners', 'restaurant_staff',
                 'restaurant_analytics', 'menu_item_analytics')
ORDER BY tablename, indexname;

-- Check triggers
SELECT 
    'Triggers' as check_type,
    trigger_name,
    event_object_table as table_name,
    '✅ EXISTS' as status
FROM information_schema.triggers
WHERE trigger_schema = 'public'
AND trigger_name IN ('on_user_created_assign_role', 'on_role_primary_change',
                    'update_restaurant_owners_updated_at', 'update_restaurant_staff_updated_at',
                    'update_restaurant_analytics_updated_at', 'update_menu_item_analytics_updated_at')
ORDER BY trigger_name;

-- Test user_has_permission function (will return false for non-existent user)
SELECT 
    'Function Test' as check_type,
    'user_has_permission' as function_name,
    public.user_has_permission(
        '00000000-0000-0000-0000-000000000000'::uuid,
        '00000000-0000-0000-0000-000000000000'::uuid,
        'manage_menu'
    ) as result,
    CASE 
        WHEN public.user_has_permission(
            '00000000-0000-0000-0000-000000000000'::uuid,
            '00000000-0000-0000-0000-000000000000'::uuid,
            'manage_menu'
        ) = false
        THEN '✅ WORKING'
        ELSE '❌ ERROR'
    END as status;

-- Summary
SELECT 
    'Summary' as section,
    COUNT(*) FILTER (WHERE table_name IN ('user_roles', 'restaurant_owners', 'restaurant_staff', 
                                         'restaurant_analytics', 'menu_item_analytics')) as total_tables,
    'Tables Created' as description
FROM information_schema.tables
WHERE table_schema = 'public'
UNION ALL
SELECT 
    'Summary',
    COUNT(*),
    'RLS Policies Created'
FROM pg_policies
WHERE schemaname = 'public'
AND tablename IN ('user_roles', 'restaurant_owners', 'restaurant_staff', 
                 'restaurant_analytics', 'menu_item_analytics')
UNION ALL
SELECT 
    'Summary',
    COUNT(*),
    'Functions Created'
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name IN ('assign_default_consumer_role', 'sync_primary_role', 
                     'user_has_permission', 'get_user_restaurant_permissions',
                     'get_restaurant_dashboard_metrics', 'get_user_restaurants')
UNION ALL
SELECT 
    'Summary',
    COUNT(*),
    'Triggers Created'
FROM information_schema.triggers
WHERE trigger_schema = 'public'
AND trigger_name IN ('on_user_created_assign_role', 'on_role_primary_change',
                    'update_restaurant_owners_updated_at', 'update_restaurant_staff_updated_at',
                    'update_restaurant_analytics_updated_at', 'update_menu_item_analytics_updated_at');
