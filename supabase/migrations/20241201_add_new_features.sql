-- ============================================
-- NandyFood Database Migration
-- Date: 2024-12-01
-- Description: Add new features - favourites, user_devices, feedback
-- ============================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- TABLE: favourites
-- Description: User favourite restaurants and menu items
-- ============================================

CREATE TABLE IF NOT EXISTS favourites (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('restaurant', 'menu_item')),
  restaurant_id UUID REFERENCES restaurants(id) ON DELETE CASCADE,
  menu_item_id UUID REFERENCES menu_items(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- Constraints
  CONSTRAINT favourites_restaurant_check CHECK (
    (type = 'restaurant' AND restaurant_id IS NOT NULL AND menu_item_id IS NULL) OR
    (type = 'menu_item' AND menu_item_id IS NOT NULL AND restaurant_id IS NULL)
  ),
  CONSTRAINT favourites_user_restaurant_unique UNIQUE(user_id, restaurant_id, type),
  CONSTRAINT favourites_user_menu_item_unique UNIQUE(user_id, menu_item_id, type)
);

-- Indexes for favourites
CREATE INDEX IF NOT EXISTS idx_favourites_user_id ON favourites(user_id);
CREATE INDEX IF NOT EXISTS idx_favourites_restaurant_id ON favourites(restaurant_id) WHERE restaurant_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_favourites_menu_item_id ON favourites(menu_item_id) WHERE menu_item_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_favourites_type ON favourites(type);
CREATE INDEX IF NOT EXISTS idx_favourites_created_at ON favourites(created_at DESC);

-- RLS Policies for favourites
ALTER TABLE favourites ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own favourites
DROP POLICY IF EXISTS "Users can view their own favourites" ON favourites;
CREATE POLICY "Users can view their own favourites"
  ON favourites FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Users can insert their own favourites
DROP POLICY IF EXISTS "Users can insert their own favourites" ON favourites;
CREATE POLICY "Users can insert their own favourites"
  ON favourites FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can delete their own favourites
DROP POLICY IF EXISTS "Users can delete their own favourites" ON favourites;
CREATE POLICY "Users can delete their own favourites"
  ON favourites FOR DELETE
  USING (auth.uid() = user_id);

-- Comment on favourites table
COMMENT ON TABLE favourites IS 'User favourite restaurants and menu items';
COMMENT ON COLUMN favourites.type IS 'Type of favourite: restaurant or menu_item';
COMMENT ON COLUMN favourites.restaurant_id IS 'Reference to restaurants table (for type=restaurant)';
COMMENT ON COLUMN favourites.menu_item_id IS 'Reference to menu_items table (for type=menu_item)';

-- ============================================
-- TABLE: user_devices
-- Description: FCM tokens and device metadata for push notifications
-- ============================================

CREATE TABLE IF NOT EXISTS user_devices (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  fcm_token TEXT UNIQUE NOT NULL,
  platform TEXT NOT NULL CHECK (platform IN ('ios', 'android', 'web')),
  device_name TEXT,
  app_version TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  last_used_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for user_devices
CREATE INDEX IF NOT EXISTS idx_user_devices_user_id ON user_devices(user_id);
CREATE INDEX IF NOT EXISTS idx_user_devices_fcm_token ON user_devices(fcm_token);
CREATE INDEX IF NOT EXISTS idx_user_devices_platform ON user_devices(platform);
CREATE INDEX IF NOT EXISTS idx_user_devices_is_active ON user_devices(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_user_devices_last_used ON user_devices(last_used_at DESC);

-- RLS Policies for user_devices
ALTER TABLE user_devices ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own devices
DROP POLICY IF EXISTS "Users can view their own devices" ON user_devices;
CREATE POLICY "Users can view their own devices"
  ON user_devices FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Users can insert their own devices
DROP POLICY IF EXISTS "Users can insert their own devices" ON user_devices;
CREATE POLICY "Users can insert their own devices"
  ON user_devices FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own devices
DROP POLICY IF EXISTS "Users can update their own devices" ON user_devices;
CREATE POLICY "Users can update their own devices"
  ON user_devices FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can delete their own devices
DROP POLICY IF EXISTS "Users can delete their own devices" ON user_devices;
CREATE POLICY "Users can delete their own devices"
  ON user_devices FOR DELETE
  USING (auth.uid() = user_id);

-- Comment on user_devices table
COMMENT ON TABLE user_devices IS 'User device information and FCM tokens for push notifications';
COMMENT ON COLUMN user_devices.fcm_token IS 'Firebase Cloud Messaging token (unique per device)';
COMMENT ON COLUMN user_devices.platform IS 'Device platform: ios, android, or web';
COMMENT ON COLUMN user_devices.device_name IS 'Human-readable device name';
COMMENT ON COLUMN user_devices.app_version IS 'App version at time of registration (format: 1.0.0+1)';
COMMENT ON COLUMN user_devices.is_active IS 'Whether this device is currently active';
COMMENT ON COLUMN user_devices.last_used_at IS 'Last time this device was used';

-- ============================================
-- TABLE: feedback
-- Description: User feedback, bug reports, and feature requests
-- ============================================

CREATE TABLE IF NOT EXISTS feedback (
  id TEXT PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('bug', 'featureRequest', 'improvement', 'complaint', 'compliment', 'support', 'rating', 'other')),
  message TEXT NOT NULL,
  rating INTEGER CHECK (rating >= 1 AND rating <= 5),
  metadata JSONB,
  status TEXT NOT NULL CHECK (status IN ('pending', 'inReview', 'acknowledged', 'resolved', 'closed')),
  submitted_at TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for feedback
CREATE INDEX IF NOT EXISTS idx_feedback_user_id ON feedback(user_id);
CREATE INDEX IF NOT EXISTS idx_feedback_status ON feedback(status);
CREATE INDEX IF NOT EXISTS idx_feedback_type ON feedback(type);
CREATE INDEX IF NOT EXISTS idx_feedback_submitted_at ON feedback(submitted_at DESC);
CREATE INDEX IF NOT EXISTS idx_feedback_rating ON feedback(rating) WHERE rating IS NOT NULL;

-- RLS Policies for feedback
ALTER TABLE feedback ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own feedback
DROP POLICY IF EXISTS "Users can view their own feedback" ON feedback;
CREATE POLICY "Users can view their own feedback"
  ON feedback FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Users can insert their own feedback
DROP POLICY IF EXISTS "Users can insert their own feedback" ON feedback;
CREATE POLICY "Users can insert their own feedback"
  ON feedback FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Support staff can view all feedback (role-based)
DROP POLICY IF EXISTS "Support staff can view all feedback" ON feedback;
CREATE POLICY "Support staff can view all feedback"
  ON feedback FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Policy: Support staff can update feedback status
DROP POLICY IF EXISTS "Support staff can update feedback" ON feedback;
CREATE POLICY "Support staff can update feedback"
  ON feedback FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Comment on feedback table
COMMENT ON TABLE feedback IS 'User feedback, bug reports, feature requests, and support tickets';
COMMENT ON COLUMN feedback.id IS 'Unique feedback ID (format: FB-timestamp)';
COMMENT ON COLUMN feedback.type IS 'Type of feedback: bug, featureRequest, improvement, complaint, compliment, support, rating, other';
COMMENT ON COLUMN feedback.rating IS 'User rating (1-5 stars), applicable for type=rating';
COMMENT ON COLUMN feedback.metadata IS 'Additional structured data (JSON format)';
COMMENT ON COLUMN feedback.status IS 'Processing status: pending, inReview, acknowledged, resolved, closed';

-- ============================================
-- TABLE MODIFICATIONS: orders
-- Description: Add cancellation fields to existing orders table
-- ============================================

-- Add cancellation fields if they don't exist
ALTER TABLE orders
  ADD COLUMN IF NOT EXISTS cancellation_reason TEXT,
  ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMP WITH TIME ZONE;

-- Create index for cancelled orders
CREATE INDEX IF NOT EXISTS idx_orders_cancelled_at ON orders(cancelled_at) WHERE cancelled_at IS NOT NULL;

-- Comment on new columns
COMMENT ON COLUMN orders.cancellation_reason IS 'User-provided reason for order cancellation';
COMMENT ON COLUMN orders.cancelled_at IS 'Timestamp when order was cancelled';

-- ============================================
-- FUNCTIONS: Auto-update timestamps
-- ============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for user_devices
DROP TRIGGER IF EXISTS update_user_devices_updated_at ON user_devices;
CREATE TRIGGER update_user_devices_updated_at
  BEFORE UPDATE ON user_devices
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Trigger for feedback
DROP TRIGGER IF EXISTS update_feedback_updated_at ON feedback;
CREATE TRIGGER update_feedback_updated_at
  BEFORE UPDATE ON feedback
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- FUNCTIONS: Helper functions
-- ============================================

-- Function to get user's active devices
CREATE OR REPLACE FUNCTION get_user_active_devices(p_user_id UUID)
RETURNS TABLE (
  device_id UUID,
  fcm_token TEXT,
  platform TEXT,
  device_name TEXT,
  app_version TEXT,
  last_used_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    id,
    user_devices.fcm_token,
    user_devices.platform,
    user_devices.device_name,
    user_devices.app_version,
    user_devices.last_used_at
  FROM user_devices
  WHERE user_id = p_user_id
    AND is_active = true
  ORDER BY user_devices.last_used_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user's favourite restaurants
CREATE OR REPLACE FUNCTION get_user_favourite_restaurants(p_user_id UUID)
RETURNS TABLE (
  favourite_id UUID,
  restaurant_id UUID,
  restaurant_name TEXT,
  created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    f.id,
    f.restaurant_id,
    r.name,
    f.created_at
  FROM favourites f
  JOIN restaurants r ON r.id = f.restaurant_id
  WHERE f.user_id = p_user_id
    AND f.type = 'restaurant'
  ORDER BY f.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to clean up inactive devices (older than 90 days)
CREATE OR REPLACE FUNCTION cleanup_inactive_devices()
RETURNS INTEGER AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  WITH deleted AS (
    DELETE FROM user_devices
    WHERE is_active = false
      OR last_used_at < NOW() - INTERVAL '90 days'
    RETURNING *
  )
  SELECT COUNT(*) INTO deleted_count FROM deleted;

  RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- GRANT PERMISSIONS
-- ============================================

-- Grant necessary permissions to authenticated users
GRANT SELECT, INSERT, UPDATE, DELETE ON favourites TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON user_devices TO authenticated;
GRANT SELECT, INSERT ON feedback TO authenticated;

-- Grant usage on sequences
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- ============================================
-- SUCCESS MESSAGE
-- ============================================

DO $$
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Migration 20241201_add_new_features.sql completed successfully!';
  RAISE NOTICE 'Tables created: favourites, user_devices, feedback';
  RAISE NOTICE 'Tables modified: orders (added cancellation fields)';
  RAISE NOTICE 'Functions created: 4 helper functions';
  RAISE NOTICE 'RLS policies enabled on all new tables';
  RAISE NOTICE '========================================';
END $$;
