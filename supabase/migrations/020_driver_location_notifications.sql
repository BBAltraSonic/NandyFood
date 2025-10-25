-- Driver Location Tracking Table
CREATE TABLE IF NOT EXISTS driver_locations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  driver_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  accuracy DOUBLE PRECISION, -- meters
  heading DOUBLE PRECISION, -- degrees
  speed DOUBLE PRECISION, -- km/h
  distance_to_customer DOUBLE PRECISION, -- calculated distance in km
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_driver_locations_driver_id ON driver_locations(driver_id);
CREATE INDEX idx_driver_locations_order_id ON driver_locations(order_id);
CREATE INDEX idx_driver_locations_updated_at ON driver_locations(updated_at DESC);

-- Enable RLS
ALTER TABLE driver_locations ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Drivers can insert their own location"
  ON driver_locations FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = driver_id);

CREATE POLICY "Drivers can update their own location"
  ON driver_locations FOR UPDATE
  TO authenticated
  USING (auth.uid() = driver_id);

CREATE POLICY "Customers can view driver location for their orders"
  ON driver_locations FOR SELECT
  TO authenticated
  USING (
    order_id IN (
      SELECT id FROM orders WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Drivers can view their own location"
  ON driver_locations FOR SELECT
  TO authenticated
  USING (auth.uid() = driver_id);

CREATE POLICY "Restaurant owners can view driver locations for their orders"
  ON driver_locations FOR SELECT
  TO authenticated
  USING (
    order_id IN (
      SELECT o.id 
      FROM orders o
      INNER JOIN restaurant_owners ro ON ro.restaurant_id = o.restaurant_id
      WHERE ro.user_id = auth.uid()
    )
  );

-- Notification Logs Table
CREATE TABLE IF NOT EXISTS notification_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  type VARCHAR(50) NOT NULL, -- 'order_status', 'driver_location', 'promotional', etc.
  title TEXT NOT NULL,
  body TEXT,
  user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  target_count INTEGER DEFAULT 0,
  sent_count INTEGER DEFAULT 0,
  failed_count INTEGER DEFAULT 0,
  payload JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_notification_logs_user_id ON notification_logs(user_id);
CREATE INDEX idx_notification_logs_order_id ON notification_logs(order_id);
CREATE INDEX idx_notification_logs_type ON notification_logs(type);
CREATE INDEX idx_notification_logs_created_at ON notification_logs(created_at DESC);

-- Enable RLS
ALTER TABLE notification_logs ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "System can insert notification logs"
  ON notification_logs FOR INSERT
  TO service_role
  WITH CHECK (true);

CREATE POLICY "Users can view their own notification logs"
  ON notification_logs FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Function to update driver location timestamp
CREATE OR REPLACE FUNCTION update_driver_location_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_driver_location_timestamp
  BEFORE UPDATE ON driver_locations
  FOR EACH ROW
  EXECUTE FUNCTION update_driver_location_timestamp();

-- Function to clean up old driver locations (keep last 24 hours)
CREATE OR REPLACE FUNCTION cleanup_old_driver_locations()
RETURNS void AS $$
BEGIN
  DELETE FROM driver_locations
  WHERE updated_at < NOW() - INTERVAL '24 hours';
END;
$$ LANGUAGE plpgsql;

-- Add columns to orders table for better tracking
ALTER TABLE orders
ADD COLUMN IF NOT EXISTS driver_assigned_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS picked_up_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS nearby_notified_at TIMESTAMP WITH TIME ZONE;

-- Function to trigger driver location notification
CREATE OR REPLACE FUNCTION notify_driver_location_update()
RETURNS TRIGGER AS $$
DECLARE
  v_order_id UUID;
  v_user_id UUID;
  v_distance DOUBLE PRECISION;
BEGIN
  -- Get order and user information
  SELECT o.id, o.user_id
  INTO v_order_id, v_user_id
  FROM orders o
  WHERE o.id = NEW.order_id;

  -- Only send notification if distance is calculated and significant change
  IF NEW.distance_to_customer IS NOT NULL AND NEW.distance_to_customer < 2.0 THEN
    -- Call edge function to send notification
    PERFORM
      net.http_post(
        url := current_setting('app.supabase_url') || '/functions/v1/send-driver-location-notification',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || current_setting('app.supabase_anon_key')
        ),
        body := jsonb_build_object(
          'order_id', v_order_id::text,
          'user_id', v_user_id::text,
          'driver_name', 
            (SELECT full_name FROM user_profiles WHERE id = NEW.driver_id),
          'driver_lat', NEW.latitude,
          'driver_lng', NEW.longitude,
          'distance_km', NEW.distance_to_customer
        )
      );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for driver location updates
CREATE TRIGGER trigger_notify_driver_location
  AFTER INSERT OR UPDATE ON driver_locations
  FOR EACH ROW
  WHEN (NEW.distance_to_customer IS NOT NULL AND NEW.distance_to_customer < 2.0)
  EXECUTE FUNCTION notify_driver_location_update();

-- Function to trigger order status notification
CREATE OR REPLACE FUNCTION notify_order_status_change()
RETURNS TRIGGER AS $$
BEGIN
  -- Only trigger on status change
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    -- Call edge function to send notification
    PERFORM
      net.http_post(
        url := current_setting('app.supabase_url') || '/functions/v1/send-order-notification',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || current_setting('app.supabase_anon_key')
        ),
        body := jsonb_build_object(
          'order_id', NEW.id::text,
          'user_id', NEW.user_id::text,
          'status', NEW.status,
          'restaurant_name', 
            (SELECT name FROM restaurants WHERE id = NEW.restaurant_id),
          'estimated_time',
            CASE 
              WHEN NEW.estimated_delivery_time IS NOT NULL 
              THEN to_char(NEW.estimated_delivery_time, 'HH:MI AM')
              ELSE NULL
            END
        )
      );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for order status changes
CREATE TRIGGER trigger_notify_order_status
  AFTER UPDATE ON orders
  FOR EACH ROW
  EXECUTE FUNCTION notify_order_status_change();

COMMENT ON TABLE driver_locations IS 'Real-time driver location tracking for deliveries';
COMMENT ON TABLE notification_logs IS 'Log of all notifications sent through the system';
