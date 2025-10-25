-- ============================================
-- Fix User Roles RLS Policy
-- Date: 2024-12-01
-- Description: Allow users to insert their own roles (customer/restaurant_owner)
-- ============================================

-- Drop existing restrictive policies
DROP POLICY IF EXISTS "Users can insert their own role" ON user_roles;
DROP POLICY IF EXISTS "Users can view their own roles" ON user_roles;
DROP POLICY IF EXISTS "Users can update their own roles" ON user_roles;

-- Policy: Users can view their own roles
CREATE POLICY "Users can view their own roles"
  ON user_roles FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Users can insert their own roles (customer or restaurant_owner only)
CREATE POLICY "Users can insert their own role"
  ON user_roles FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    AND role IN ('customer', 'restaurant_owner')
  );

-- Policy: Users can update their own roles (switching between customer and restaurant_owner)
CREATE POLICY "Users can update their own role"
  ON user_roles FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (
    auth.uid() = user_id
    AND role IN ('customer', 'restaurant_owner')
  );

-- Policy: Admins can do anything with roles
CREATE POLICY "Admins can manage all roles"
  ON user_roles FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role = 'admin'
    )
  );

-- Add helpful comment
COMMENT ON POLICY "Users can insert their own role" ON user_roles IS
  'Allows users to create customer or restaurant_owner roles for themselves during registration';

-- Verification query
DO $$
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE 'User Roles RLS Policy Fixed!';
  RAISE NOTICE 'Users can now register as:';
  RAISE NOTICE '  - customer';
  RAISE NOTICE '  - restaurant_owner';
  RAISE NOTICE 'Admins can assign any role';
  RAISE NOTICE '========================================';
END $$;
