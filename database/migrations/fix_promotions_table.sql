-- ============================================
-- Fix Promotions Table Column Name
-- Date: 2024-12-01
-- Description: Fix starts_at column if it doesn't exist or has wrong name
-- ============================================

-- Check if promotions table exists and fix column name issues
DO $$
BEGIN
  -- If table doesn't exist, we'll create it with correct schema
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'promotions') THEN
    RAISE NOTICE 'Promotions table does not exist. Creating...';

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

    RAISE NOTICE 'Promotions table created successfully';

  -- If table exists but column is missing or wrong
  ELSIF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'promotions' AND column_name = 'starts_at'
  ) THEN
    RAISE NOTICE 'Column starts_at missing. Checking for alternatives...';

    -- Check if there's a start_date column instead
    IF EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_name = 'promotions' AND column_name = 'start_date'
    ) THEN
      RAISE NOTICE 'Found start_date column. Renaming to starts_at...';
      ALTER TABLE promotions RENAME COLUMN start_date TO starts_at;
      RAISE NOTICE 'Renamed start_date to starts_at';

    -- Check if there's a started_at column
    ELSIF EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_name = 'promotions' AND column_name = 'started_at'
    ) THEN
      RAISE NOTICE 'Found started_at column. Renaming to starts_at...';
      ALTER TABLE promotions RENAME COLUMN started_at TO starts_at;
      RAISE NOTICE 'Renamed started_at to starts_at';

    -- Column doesn't exist at all - add it
    ELSE
      RAISE NOTICE 'No start date column found. Adding starts_at...';
      ALTER TABLE promotions ADD COLUMN starts_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
      RAISE NOTICE 'Added starts_at column';
    END IF;

  ELSE
    RAISE NOTICE 'Promotions table and starts_at column already exist correctly';
  END IF;

  -- Ensure expires_at exists too
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'promotions' AND column_name = 'expires_at'
  ) THEN
    -- Check alternatives
    IF EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_name = 'promotions' AND column_name = 'end_date'
    ) THEN
      ALTER TABLE promotions RENAME COLUMN end_date TO expires_at;
      RAISE NOTICE 'Renamed end_date to expires_at';
    ELSIF EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_name = 'promotions' AND column_name = 'expired_at'
    ) THEN
      ALTER TABLE promotions RENAME COLUMN expired_at TO expires_at;
      RAISE NOTICE 'Renamed expired_at to expires_at';
    ELSE
      ALTER TABLE promotions ADD COLUMN expires_at TIMESTAMPTZ NOT NULL DEFAULT NOW() + INTERVAL '30 days';
      RAISE NOTICE 'Added expires_at column';
    END IF;
  END IF;

END $$;

-- Create indexes if they don't exist
CREATE INDEX IF NOT EXISTS idx_promotions_code ON promotions(code) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_promotions_active ON promotions(is_active, starts_at, expires_at);
CREATE INDEX IF NOT EXISTS idx_promotions_expires_at ON promotions(expires_at);
CREATE INDEX IF NOT EXISTS idx_promotions_restaurant ON promotions(restaurant_id);

-- Enable RLS if not already enabled
ALTER TABLE promotions ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to recreate them
DROP POLICY IF EXISTS "Anyone can view active promotions" ON promotions;
DROP POLICY IF EXISTS "Restaurant owners can manage their promotions" ON promotions;

-- Policy: Anyone can view active promotions
CREATE POLICY "Anyone can view active promotions"
  ON promotions FOR SELECT
  USING (
    is_active = TRUE AND
    NOW() BETWEEN starts_at AND expires_at
  );

-- Policy: Restaurant owners can manage their own promotions
CREATE POLICY "Restaurant owners can manage their promotions"
  ON promotions FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM restaurants r
      WHERE r.id = promotions.restaurant_id
      AND r.owner_id = auth.uid()
    )
  );

-- Grant permissions
GRANT SELECT ON promotions TO authenticated;
GRANT ALL ON promotions TO authenticated;

-- Add comments
COMMENT ON TABLE promotions IS 'Promotional codes and discounts for restaurants';
COMMENT ON COLUMN promotions.starts_at IS 'Promotion start date and time';
COMMENT ON COLUMN promotions.expires_at IS 'Promotion expiry date and time';
COMMENT ON COLUMN promotions.code IS 'Unique promotion code (e.g., SAVE20)';
COMMENT ON COLUMN promotions.discount_type IS 'Type of discount: percentage or fixed_amount';

-- Verification
DO $$
DECLARE
  col_exists BOOLEAN;
  table_exists BOOLEAN;
BEGIN
  -- Check table exists
  SELECT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_name = 'promotions'
  ) INTO table_exists;

  IF table_exists THEN
    RAISE NOTICE '✓ Promotions table exists';

    -- Check starts_at column
    SELECT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_name = 'promotions' AND column_name = 'starts_at'
    ) INTO col_exists;

    IF col_exists THEN
      RAISE NOTICE '✓ Column starts_at exists';
    ELSE
      RAISE NOTICE '✗ Column starts_at still missing!';
    END IF;

    -- Check expires_at column
    SELECT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_name = 'promotions' AND column_name = 'expires_at'
    ) INTO col_exists;

    IF col_exists THEN
      RAISE NOTICE '✓ Column expires_at exists';
    ELSE
      RAISE NOTICE '✗ Column expires_at still missing!';
    END IF;

  ELSE
    RAISE NOTICE '✗ Promotions table does not exist!';
  END IF;

  RAISE NOTICE '========================================';
  RAISE NOTICE 'Promotions table fix complete!';
  RAISE NOTICE '========================================';
END $$;
