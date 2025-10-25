-- ============================================
-- FIX USER_ROLES RLS POLICIES FOR SELLER REGISTRATION
-- Date: 2024-12-XX
-- Issue: PostgresException code 42501 - RLS policy violation on INSERT
-- Solution: Allow authenticated users to insert/upsert their own roles
-- ============================================

-- Drop all existing policies on user_roles
DROP POLICY IF EXISTS "Users can insert their own role" ON user_roles;
DROP POLICY IF EXISTS "Users can view their own roles" ON user_roles;
DROP POLICY IF EXISTS "Users can update their own role" ON user_roles;
DROP POLICY IF EXISTS "Admins can manage all roles" ON user_roles;

-- Enable RLS (in case it was disabled)
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;

-- Policy 1: Allow users to SELECT their own roles
CREATE POLICY "Users can view their own roles"
  ON user_roles
  FOR SELECT
  USING (auth.uid() = user_id);

-- Policy 2: Allow users to INSERT their own roles
-- This allows registration with consumer or restaurant_owner role
CREATE POLICY "Users can insert their own role"
  ON user_roles
  FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    AND role IN ('consumer', 'restaurant_owner', 'delivery_driver')
  );

-- Policy 3: Allow users to UPDATE their own roles
-- This allows switching between roles or updating role metadata
CREATE POLICY "Users can update their own role"
  ON user_roles
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (
    auth.uid() = user_id
    AND role IN ('consumer', 'restaurant_owner', 'restaurant_staff', 'delivery_driver')
  );

-- Policy 4: Allow users to DELETE their own roles (optional, for cleanup)
CREATE POLICY "Users can delete their own role"
  ON user_roles
  FOR DELETE
  USING (auth.uid() = user_id AND is_primary = false);

-- Policy 5: Admins have full access
CREATE POLICY "Admins can manage all roles"
  ON user_roles
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.primary_role = 'admin'
    )
  );

-- Grant necessary permissions to authenticated users
GRANT SELECT, INSERT, UPDATE, DELETE ON user_roles TO authenticated;
GRANT USAGE ON SEQUENCE user_roles_id_seq TO authenticated;

-- Add helpful comments
COMMENT ON POLICY "Users can insert their own role" ON user_roles IS
  'Allows users to create consumer, restaurant_owner, or delivery_driver roles during registration';

COMMENT ON POLICY "Users can update their own role" ON user_roles IS
  'Allows users to update their role metadata or switch between roles';

COMMENT ON POLICY "Users can delete their own role" ON user_roles IS
  'Allows users to delete non-primary roles only';

-- Verification query
DO $$
DECLARE
  policy_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO policy_count
  FROM pg_policies
  WHERE schemaname = 'public' AND tablename = 'user_roles';

  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE '  USER_ROLES RLS POLICIES FIXED';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Total policies created: %', policy_count;
  RAISE NOTICE '';
  RAISE NOTICE 'Users can now:';
  RAISE NOTICE '  ✓ Register as consumer';
  RAISE NOTICE '  ✓ Register as restaurant_owner (seller)';
  RAISE NOTICE '  ✓ Register as delivery_driver';
  RAISE NOTICE '  ✓ View their own roles';
  RAISE NOTICE '  ✓ Update their roles';
  RAISE NOTICE '  ✓ Delete non-primary roles';
  RAISE NOTICE '';
  RAISE NOTICE 'Allowed role values for INSERT:';
  RAISE NOTICE '  - consumer';
  RAISE NOTICE '  - restaurant_owner';
  RAISE NOTICE '  - delivery_driver';
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
END $$;
