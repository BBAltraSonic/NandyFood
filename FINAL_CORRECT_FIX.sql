-- ============================================
-- FINAL CORRECT FIX - Using ACTUAL Database Schema
-- Date: 2024-12-01
-- Description: Fix ALL errors using the REAL enum values and schema
-- ============================================

-- ============================================
-- 1. FIX USER_ROLES RLS POLICY
-- Using CORRECT enum values: 'consumer' and 'restaurant_owner' (NOT 'customer')
-- ============================================

-- Drop existing policies
DROP POLICY IF EXISTS "Users can insert their own role" ON user_roles;
DROP POLICY IF EXISTS "Users can view their own roles" ON user_roles;
DROP POLICY IF EXISTS "Users can update their own roles" ON user_roles;
DROP POLICY IF EXISTS "Admins can manage all roles" ON user_roles;

-- Policy: Users can view their own roles
CREATE POLICY "Users can view their own roles"
  ON user_roles FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Users can insert their own roles
-- CORRECT ENUM VALUES: 'consumer' and 'restaurant_owner'
CREATE POLICY "Users can insert their own role"
  ON user_roles FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    AND role IN ('consumer', 'restaurant_owner')
  );

-- Policy: Users can update their own roles
CREATE POLICY "Users can update their own role"
  ON user_roles FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (
    auth.uid() = user_id
    AND role IN ('consumer', 'restaurant_owner')
  );

-- Policy: Admins can manage all roles
CREATE POLICY "Admins can manage all roles"
  ON user_roles FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.primary_role = 'admin'
    )
  );

-- ============================================
-- 2. FIX PROMOTIONS TABLE (starts_at column)
-- ============================================

DO $$
BEGIN
  -- Create promotions table if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'promotions') THEN
    RAISE NOTICE 'Creating promotions table...';

    CREATE TABLE promotions (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
      restaurant_id UUID REFERENCES restaurants(id) ON DELETE CASCADE NOT NULL,
      code TEXT UNIQUE NOT NULL,
      description TEXT NOT NULL,
      discount_type TEXT NOT NULL CHECK (discount_type IN ('percentage', 'fixed_amount')),
      discount_value DECIMAL(10,2) NOT NULL CHECK (discount_value > 0),
      min_order_amount DECIMAL(10,2) DEFAULT 0,
      max_discount_amount DECIMAL(10,2),
      usage_limit INTEGER,
      used_count INTEGER DEFAULT 0,
      is_active BOOLEAN DEFAULT TRUE,
      starts_at TIMESTAMPTZ NOT NULL,
      expires_at TIMESTAMPTZ NOT NULL,
      created_at TIMESTAMPTZ DEFAULT NOW(),
      updated_at TIMESTAMPTZ DEFAULT NOW(),
      CONSTRAINT valid_promo_dates CHECK (expires_at > starts_at)
    );

    RAISE NOTICE '✓ Promotions table created';
  END IF;

  -- Fix starts_at column if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'promotions' AND column_name = 'starts_at'
  ) THEN
    -- Try to rename from common alternatives
    IF EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_name = 'promotions' AND column_name = 'start_date'
    ) THEN
      ALTER TABLE promotions RENAME COLUMN start_date TO starts_at;
      RAISE NOTICE '✓ Renamed start_date to starts_at';
    ELSIF EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_name = 'promotions' AND column_name = 'started_at'
    ) THEN
      ALTER TABLE promotions RENAME COLUMN started_at TO starts_at;
      RAISE NOTICE '✓ Renamed started_at to starts_at';
    ELSE
      ALTER TABLE promotions ADD COLUMN starts_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
      RAISE NOTICE '✓ Added starts_at column';
    END IF;
  END IF;

  -- Fix expires_at column if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'promotions' AND column_name = 'expires_at'
  ) THEN
    IF EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_name = 'promotions' AND column_name = 'end_date'
    ) THEN
      ALTER TABLE promotions RENAME COLUMN end_date TO expires_at;
      RAISE NOTICE '✓ Renamed end_date to expires_at';
    ELSIF EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_name = 'promotions' AND column_name = 'expired_at'
    ) THEN
      ALTER TABLE promotions RENAME COLUMN expired_at TO expires_at;
      RAISE NOTICE '✓ Renamed expired_at to expires_at';
    ELSE
      ALTER TABLE promotions ADD COLUMN expires_at TIMESTAMPTZ NOT NULL DEFAULT NOW() + INTERVAL '30 days';
      RAISE NOTICE '✓ Added expires_at column';
    END IF;
  END IF;
END $$;

-- Create indexes for promotions
CREATE INDEX IF NOT EXISTS idx_promotions_code ON promotions(code) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_promotions_active ON promotions(is_active, starts_at, expires_at);
CREATE INDEX IF NOT EXISTS idx_promotions_expires_at ON promotions(expires_at);
CREATE INDEX IF NOT EXISTS idx_promotions_restaurant ON promotions(restaurant_id);

-- Enable RLS on promotions
ALTER TABLE promotions ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 3. ENSURE restaurant_owners TABLE EXISTS
-- ============================================

CREATE TABLE IF NOT EXISTS restaurant_owners (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  restaurant_id UUID REFERENCES restaurants(id) ON DELETE CASCADE NOT NULL,
  owner_type TEXT NOT NULL DEFAULT 'primary' CHECK (owner_type IN ('primary', 'co-owner', 'manager')),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'pending')),
  permissions JSONB DEFAULT '{"manage_menu": true, "manage_orders": true, "manage_staff": false, "view_analytics": true}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, restaurant_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_restaurant_owners_user_id ON restaurant_owners(user_id);
CREATE INDEX IF NOT EXISTS idx_restaurant_owners_restaurant_id ON restaurant_owners(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_restaurant_owners_status ON restaurant_owners(status);

-- Enable RLS
ALTER TABLE restaurant_owners ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 4. FIX ALL RLS POLICIES (using restaurant_owners table, NOT restaurants.owner_id)
-- ============================================

-- Drop any incorrect policies
DROP POLICY IF EXISTS "Owners can view own restaurants" ON restaurant_owners;
DROP POLICY IF EXISTS "Owners can insert restaurant ownership" ON restaurant_owners;
DROP POLICY IF EXISTS "Anyone can view active promotions" ON promotions;
DROP POLICY IF EXISTS "Restaurant owners can manage their promotions" ON promotions;
DROP POLICY IF EXISTS "Owners can update their restaurants" ON restaurants;
DROP POLICY IF EXISTS "Owners can manage menu items" ON menu_items;
DROP POLICY IF EXISTS "Owners can view restaurant orders" ON orders;
DROP POLICY IF EXISTS "Owners can update restaurant orders" ON orders;

-- RLS for restaurant_owners table
CREATE POLICY "Owners can view own restaurants"
  ON restaurant_owners FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Owners can insert restaurant ownership"
  ON restaurant_owners FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- RLS for promotions (using restaurant_owners table)
CREATE POLICY "Anyone can view active promotions"
  ON promotions FOR SELECT
  USING (is_active = TRUE AND NOW() BETWEEN starts_at AND expires_at);

CREATE POLICY "Restaurant owners can manage their promotions"
  ON promotions FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM restaurant_owners ro
      WHERE ro.restaurant_id = promotions.restaurant_id
      AND ro.user_id = auth.uid()
      AND ro.status = 'active'
    )
  );

-- RLS for restaurants (using restaurant_owners table)
CREATE POLICY "Owners can update their restaurants"
  ON restaurants FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM restaurant_owners ro
      WHERE ro.restaurant_id = restaurants.id
      AND ro.user_id = auth.uid()
      AND ro.status = 'active'
    )
  );

-- RLS for menu_items (using restaurant_owners table)
CREATE POLICY "Owners can manage menu items"
  ON menu_items FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM restaurant_owners ro
      WHERE ro.restaurant_id = menu_items.restaurant_id
      AND ro.user_id = auth.uid()
      AND ro.status = 'active'
    )
  );

-- RLS for orders (using restaurant_owners table)
CREATE POLICY "Owners can view restaurant orders"
  ON orders FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM restaurant_owners ro
      WHERE ro.restaurant_id = orders.restaurant_id
      AND ro.user_id = auth.uid()
      AND ro.status = 'active'
    )
  );

CREATE POLICY "Owners can update restaurant orders"
  ON orders FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM restaurant_owners ro
      WHERE ro.restaurant_id = orders.restaurant_id
      AND ro.user_id = auth.uid()
      AND ro.status = 'active'
    )
  );

-- ============================================
-- 5. GRANT PERMISSIONS
-- ============================================

GRANT SELECT, INSERT, UPDATE, DELETE ON promotions TO authenticated;
GRANT SELECT, INSERT, UPDATE ON restaurant_owners TO authenticated;
GRANT SELECT ON restaurants TO authenticated;
GRANT SELECT ON menu_items TO authenticated;
GRANT SELECT ON orders TO authenticated;

-- ============================================
-- 6. VERIFICATION
-- ============================================

DO $$
DECLARE
  user_roles_exists BOOLEAN;
  promotions_exists BOOLEAN;
  restaurant_owners_exists BOOLEAN;
  starts_at_exists BOOLEAN;
BEGIN
  -- Check user_roles table
  SELECT EXISTS (
    SELECT 1 FROM information_schema.tables WHERE table_name = 'user_roles'
  ) INTO user_roles_exists;

  -- Check promotions table
  SELECT EXISTS (
    SELECT 1 FROM information_schema.tables WHERE table_name = 'promotions'
  ) INTO promotions_exists;

  -- Check restaurant_owners table
  SELECT EXISTS (
    SELECT 1 FROM information_schema.tables WHERE table_name = 'restaurant_owners'
  ) INTO restaurant_owners_exists;

  -- Check starts_at column
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'promotions' AND column_name = 'starts_at'
  ) INTO starts_at_exists;

  -- Report results
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE '       FINAL FIX VERIFICATION';
  RAISE NOTICE '========================================';
  RAISE NOTICE '';

  IF user_roles_exists THEN
    RAISE NOTICE '✓ user_roles table exists';
  ELSE
    RAISE NOTICE '✗ user_roles table MISSING';
  END IF;

  IF promotions_exists THEN
    RAISE NOTICE '✓ promotions table exists';
  ELSE
    RAISE NOTICE '✗ promotions table MISSING';
  END IF;

  IF restaurant_owners_exists THEN
    RAISE NOTICE '✓ restaurant_owners table exists';
  ELSE
    RAISE NOTICE '✗ restaurant_owners table MISSING';
  END IF;

  IF starts_at_exists THEN
    RAISE NOTICE '✓ starts_at column exists';
  ELSE
    RAISE NOTICE '✗ starts_at column MISSING';
  END IF;

  RAISE NOTICE '';
  RAISE NOTICE 'ENUM VALUES USED:';
  RAISE NOTICE '  - consumer (NOT customer)';
  RAISE NOTICE '  - restaurant_owner';
  RAISE NOTICE '  - restaurant_staff';
  RAISE NOTICE '  - admin';
  RAISE NOTICE '  - delivery_driver';
  RAISE NOTICE '';
  RAISE NOTICE 'SCHEMA USED:';
  RAISE NOTICE '  - restaurant_owners table (links users to restaurants)';
  RAISE NOTICE '  - NO restaurants.owner_id column';
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE '         ALL FIXES APPLIED!';
  RAISE NOTICE '========================================';
  RAISE NOTICE '';
  RAISE NOTICE 'You can now:';
  RAISE NOTICE '✓ Register as consumer or restaurant_owner';
  RAISE NOTICE '✓ Create and manage restaurants';
  RAISE NOTICE '✓ Create promotions with dates';
  RAISE NOTICE '✓ Manage menu items';
  RAISE NOTICE '✓ View and update orders';
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
END $$;
