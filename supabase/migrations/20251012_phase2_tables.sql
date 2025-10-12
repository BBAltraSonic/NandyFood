-- =====================================================
-- Phase 2: Database Tables and Policies
-- Created: October 12, 2025
-- =====================================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- 1. USER FAVORITES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS user_favorites (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  restaurant_id UUID NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, restaurant_id)
);

CREATE INDEX idx_user_favorites_user_id ON user_favorites(user_id);
CREATE INDEX idx_user_favorites_restaurant_id ON user_favorites(restaurant_id);

-- RLS Policies for user_favorites
ALTER TABLE user_favorites ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own favorites"
  ON user_favorites FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own favorites"
  ON user_favorites FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own favorites"
  ON user_favorites FOR DELETE
  USING (auth.uid() = user_id);

-- =====================================================
-- 2. SAVED CARTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS saved_carts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  name VARCHAR(100),
  restaurant_id UUID NOT NULL,
  items JSONB NOT NULL DEFAULT '[]'::jsonb,
  expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '7 days'),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_saved_carts_user_id ON saved_carts(user_id);
CREATE INDEX idx_saved_carts_expires_at ON saved_carts(expires_at);

-- RLS Policies for saved_carts
ALTER TABLE saved_carts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own carts"
  ON saved_carts FOR ALL
  USING (auth.uid() = user_id);

-- Auto-delete expired carts (run daily)
CREATE OR REPLACE FUNCTION delete_expired_carts()
RETURNS void AS $$
BEGIN
  DELETE FROM saved_carts WHERE expires_at < NOW();
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 3. REVIEWS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS reviews (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  restaurant_id UUID NOT NULL,
  order_id UUID,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  food_rating INTEGER CHECK (food_rating >= 1 AND food_rating <= 5),
  delivery_rating INTEGER CHECK (delivery_rating >= 1 AND delivery_rating <= 5),
  comment TEXT,
  photos TEXT[] DEFAULT ARRAY[]::TEXT[],
  helpful_count INTEGER DEFAULT 0,
  is_verified_purchase BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, restaurant_id, order_id)
);

CREATE INDEX idx_reviews_restaurant_id ON reviews(restaurant_id);
CREATE INDEX idx_reviews_user_id ON reviews(user_id);
CREATE INDEX idx_reviews_rating ON reviews(rating);
CREATE INDEX idx_reviews_created_at ON reviews(created_at DESC);

-- RLS Policies for reviews
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Reviews are publicly readable"
  ON reviews FOR SELECT
  USING (true);

CREATE POLICY "Users can insert own reviews"
  ON reviews FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own reviews"
  ON reviews FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own reviews"
  ON reviews FOR DELETE
  USING (auth.uid() = user_id);

-- =====================================================
-- 4. REVIEW HELPFUL TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS review_helpful (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  review_id UUID REFERENCES reviews(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(review_id, user_id)
);

CREATE INDEX idx_review_helpful_review_id ON review_helpful(review_id);

-- RLS Policies for review_helpful
ALTER TABLE review_helpful ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own helpful marks"
  ON review_helpful FOR ALL
  USING (auth.uid() = user_id);

-- Update helpful count trigger
CREATE OR REPLACE FUNCTION update_review_helpful_count()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE reviews
  SET helpful_count = (
    SELECT COUNT(*) FROM review_helpful WHERE review_id = COALESCE(NEW.review_id, OLD.review_id)
  )
  WHERE id = COALESCE(NEW.review_id, OLD.review_id);
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_helpful_count
AFTER INSERT OR DELETE ON review_helpful
FOR EACH ROW EXECUTE FUNCTION update_review_helpful_count();

-- =====================================================
-- 5. DIETARY PREFERENCES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS user_dietary_preferences (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
  vegetarian BOOLEAN DEFAULT FALSE,
  vegan BOOLEAN DEFAULT FALSE,
  gluten_free BOOLEAN DEFAULT FALSE,
  dairy_free BOOLEAN DEFAULT FALSE,
  nut_allergy BOOLEAN DEFAULT FALSE,
  halal BOOLEAN DEFAULT FALSE,
  kosher BOOLEAN DEFAULT FALSE,
  spice_level VARCHAR(20) DEFAULT 'medium',
  cuisine_preferences TEXT[] DEFAULT ARRAY[]::TEXT[],
  portion_preference VARCHAR(20) DEFAULT 'regular',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_dietary_preferences_user_id ON user_dietary_preferences(user_id);

-- RLS Policies
ALTER TABLE user_dietary_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own preferences"
  ON user_dietary_preferences FOR ALL
  USING (auth.uid() = user_id);

-- =====================================================
-- 6. NOTIFICATION PREFERENCES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS user_notification_preferences (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
  order_updates BOOLEAN DEFAULT TRUE,
  promotional_offers BOOLEAN DEFAULT TRUE,
  new_restaurant_alerts BOOLEAN DEFAULT TRUE,
  price_drop_alerts BOOLEAN DEFAULT FALSE,
  review_reminders BOOLEAN DEFAULT TRUE,
  newsletter BOOLEAN DEFAULT FALSE,
  quiet_hours_start TIME,
  quiet_hours_end TIME,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_notification_preferences_user_id ON user_notification_preferences(user_id);

-- RLS Policies
ALTER TABLE user_notification_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own notification preferences"
  ON user_notification_preferences FOR ALL
  USING (auth.uid() = user_id);

-- =====================================================
-- 7. ORDER ISSUES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS order_issues (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id UUID NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  issue_type VARCHAR(50) NOT NULL,
  description TEXT NOT NULL,
  status VARCHAR(20) DEFAULT 'open',
  resolution TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  resolved_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_order_issues_order_id ON order_issues(order_id);
CREATE INDEX idx_order_issues_user_id ON order_issues(user_id);
CREATE INDEX idx_order_issues_status ON order_issues(status);

-- RLS Policies
ALTER TABLE order_issues ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own issues"
  ON order_issues FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create issues"
  ON order_issues FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- =====================================================
-- 8. Enable Realtime on Tables
-- =====================================================
-- Enable realtime for orders (if not already enabled)
ALTER PUBLICATION supabase_realtime ADD TABLE IF NOT EXISTS orders;

-- Enable realtime for deliveries (if not already enabled)
ALTER PUBLICATION supabase_realtime ADD TABLE IF NOT EXISTS deliveries;

-- Enable realtime for reviews
ALTER PUBLICATION supabase_realtime ADD TABLE reviews;

-- =====================================================
-- 9. Helper Functions
-- =====================================================

-- Calculate restaurant average rating
CREATE OR REPLACE FUNCTION calculate_restaurant_rating(restaurant_uuid UUID)
RETURNS DECIMAL(3,2) AS $$
BEGIN
  RETURN (
    SELECT COALESCE(ROUND(AVG(rating)::numeric, 2), 0)
    FROM reviews
    WHERE restaurant_id = restaurant_uuid
  );
END;
$$ LANGUAGE plpgsql;

-- Get review statistics
CREATE OR REPLACE FUNCTION get_review_stats(restaurant_uuid UUID)
RETURNS TABLE(
  total_reviews BIGINT,
  average_rating DECIMAL(3,2),
  rating_5_count BIGINT,
  rating_4_count BIGINT,
  rating_3_count BIGINT,
  rating_2_count BIGINT,
  rating_1_count BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    COUNT(*)::BIGINT as total_reviews,
    COALESCE(ROUND(AVG(rating)::numeric, 2), 0) as average_rating,
    COUNT(CASE WHEN rating = 5 THEN 1 END)::BIGINT as rating_5_count,
    COUNT(CASE WHEN rating = 4 THEN 1 END)::BIGINT as rating_4_count,
    COUNT(CASE WHEN rating = 3 THEN 1 END)::BIGINT as rating_3_count,
    COUNT(CASE WHEN rating = 2 THEN 1 END)::BIGINT as rating_2_count,
    COUNT(CASE WHEN rating = 1 THEN 1 END)::BIGINT as rating_1_count
  FROM reviews
  WHERE restaurant_id = restaurant_uuid;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 10. Updated At Triggers
-- =====================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_saved_carts_updated_at
BEFORE UPDATE ON saved_carts
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reviews_updated_at
BEFORE UPDATE ON reviews
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_dietary_preferences_updated_at
BEFORE UPDATE ON user_dietary_preferences
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_notification_preferences_updated_at
BEFORE UPDATE ON user_notification_preferences
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- Migration Complete
-- =====================================================
-- All Phase 2 tables, indexes, policies, and functions created
-- Next: Configure Firebase and test real-time subscriptions
