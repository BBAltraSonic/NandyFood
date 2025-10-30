-- =====================================================
-- NandyFood Database Schema
-- Migration: 022_remove_delivery_features_and_focus_on_preparation
-- Description: Removes delivery features and focuses on preparation tracking
-- =====================================================

-- First, migrate existing delivery orders to ready_for_pickup status
UPDATE public.orders
SET status = 'ready_for_pickup',
    updated_at = NOW()
WHERE status IN ('out_for_delivery', 'delivered');

-- Remove the deliveries table completely
DROP TABLE IF EXISTS public.deliveries CASCADE;

-- Update orders table to remove delivery-specific fields and add preparation tracking
ALTER TABLE public.orders
    -- Remove delivery-specific fields
    DROP COLUMN IF EXISTS delivery_lat,
    DROP COLUMN IF EXISTS delivery_lng,
    DROP COLUMN IF EXISTS delivery_fee,
    DROP COLUMN IF EXISTS tip_amount,
    DROP COLUMN IF EXISTS estimated_delivery_at,
    DROP COLUMN IF EXISTS picked_up_at,
    DROP COLUMN IF EXISTS delivered_at,

    -- Rename delivery_address to pickup_address (keep for pickup info)
    RENAME COLUMN delivery_address TO pickup_address,
    RENAME COLUMN delivery_instructions TO pickup_instructions,

    -- Add preparation tracking fields
    ADD COLUMN estimated_preparation_time INTEGER DEFAULT 15, -- in minutes
    ADD COLUMN actual_preparation_time INTEGER, -- in minutes
    ADD COLUMN preparation_started_at TIMESTAMPTZ,
    ADD COLUMN preparation_completed_at TIMESTAMPTZ,
    ADD COLUMN customer_notified_at TIMESTAMPTZ,
    ADD COLUMN pickup_ready_confirmed_at TIMESTAMPTZ;

-- Update the order status check constraint to remove delivery statuses
ALTER TABLE public.orders
    DROP CONSTRAINT IF EXISTS orders_status_check;
ALTER TABLE public.orders
    ADD CONSTRAINT orders_status_check CHECK (
        status IN ('placed', 'confirmed', 'preparing', 'ready_for_pickup', 'cancelled')
    );

-- Update the order status timestamp function to remove delivery statuses
CREATE OR REPLACE FUNCTION public.update_order_status_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status != OLD.status THEN
        CASE NEW.status
            WHEN 'confirmed' THEN
                NEW.confirmed_at := NOW();
            WHEN 'preparing' THEN
                NEW.preparing_at := NOW();
                NEW.preparation_started_at := NOW();
            WHEN 'ready_for_pickup' THEN
                NEW.ready_at := NOW();
                NEW.preparation_completed_at := NOW();
            WHEN 'cancelled' THEN
                NEW.cancelled_at := NOW();
        END CASE;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add function to calculate preparation time analytics
CREATE OR REPLACE FUNCTION public.update_preparation_analytics()
RETURNS TRIGGER AS $$
BEGIN
    -- Calculate actual preparation time when preparation is completed
    IF NEW.status = 'ready_for_pickup' AND OLD.status != 'ready_for_pickup' THEN
        IF NEW.preparation_started_at IS NOT NULL THEN
            NEW.actual_preparation_time := EXTRACT(EPOCH FROM (NOW() - NEW.preparation_started_at)) / 60;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for preparation analytics
DROP TRIGGER IF EXISTS update_preparation_analytics_trigger ON public.orders;
CREATE TRIGGER update_preparation_analytics_trigger
    BEFORE UPDATE ON public.orders
    FOR EACH ROW
    WHEN (OLD.status IS DISTINCT FROM NEW.status)
    EXECUTE FUNCTION public.update_preparation_analytics();

-- Function to mark order as ready and notify customer
CREATE OR REPLACE FUNCTION public.mark_order_ready_for_pickup(order_id_param UUID)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT
) AS $$
DECLARE
    order_record RECORD;
BEGIN
    -- Get order details
    SELECT * INTO order_record
    FROM public.orders
    WHERE id = order_id_param AND status = 'preparing';

    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, 'Order not found or not in preparing status';
        RETURN;
    END IF;

    -- Update order status
    UPDATE public.orders
    SET
        status = 'ready_for_pickup',
        pickup_ready_confirmed_at = NOW(),
        updated_at = NOW()
    WHERE id = order_id_param;

    RETURN QUERY SELECT TRUE, 'Order marked as ready for pickup';
END;
$$ LANGUAGE plpgsql;

-- Function to start preparation
CREATE OR REPLACE FUNCTION public.start_order_preparation(order_id_param UUID, estimated_minutes INTEGER DEFAULT NULL)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT
) AS $$
DECLARE
    order_record RECORD;
BEGIN
    -- Get order details
    SELECT * INTO order_record
    FROM public.orders
    WHERE id = order_id_param AND status = 'confirmed';

    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, 'Order not found or not confirmed';
        RETURN;
    END IF;

    -- Update order status and estimated time
    UPDATE public.orders
    SET
        status = 'preparing',
        preparation_started_at = NOW(),
        estimated_preparation_time = COALESCE(estimated_minutes, estimated_preparation_time),
        updated_at = NOW()
    WHERE id = order_id_param;

    RETURN QUERY SELECT TRUE, 'Order preparation started';
END;
$$ LANGUAGE plpgsql;

-- Function to get restaurant preparation analytics
CREATE OR REPLACE FUNCTION public.get_restaurant_preparation_analytics(restaurant_id_param UUID, days_param INTEGER DEFAULT 7)
RETURNS TABLE (
    date DATE,
    total_orders BIGINT,
    avg_estimated_time DECIMAL(5,2),
    avg_actual_time DECIMAL(5,2),
    preparation_efficiency DECIMAL(5,2) -- percentage
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        DATE(o.created_at) as date,
        COUNT(*) as total_orders,
        ROUND(AVG(o.estimated_preparation_time), 2) as avg_estimated_time,
        ROUND(AVG(o.actual_preparation_time), 2) as avg_actual_time,
        CASE
            WHEN AVG(o.estimated_preparation_time) > 0
            THEN ROUND((AVG(o.estimated_preparation_time) / AVG(o.actual_preparation_time)) * 100, 2)
            ELSE 0
        END as preparation_efficiency
    FROM public.orders o
    WHERE
        o.restaurant_id = restaurant_id_param
        AND o.status IN ('ready_for_pickup', 'cancelled')
        AND o.created_at >= NOW() - INTERVAL '1 day' * days_param
        AND o.actual_preparation_time IS NOT NULL
    GROUP BY DATE(o.created_at)
    ORDER BY date DESC;
END;
$$ LANGUAGE plpgsql;

-- Update the calculate_order_total function to remove delivery fees and tips
CREATE OR REPLACE FUNCTION public.calculate_order_total(order_id_param UUID)
RETURNS DECIMAL AS $$
DECLARE
    calculated_total DECIMAL(10, 2);
BEGIN
    SELECT
        COALESCE(o.subtotal, 0) +
        COALESCE(o.tax_amount, 0) -
        COALESCE(o.discount_amount, 0) -
        COALESCE(o.promo_discount, 0)
    INTO calculated_total
    FROM public.orders o
    WHERE o.id = order_id_param;

    RETURN COALESCE(calculated_total, 0);
END;
$$ LANGUAGE plpgsql;

-- Update indexes - remove delivery-related indexes
DROP INDEX IF EXISTS idx_deliveries_order_id;
DROP INDEX IF EXISTS idx_deliveries_driver_id;
DROP INDEX IF EXISTS idx_deliveries_status;
DROP INDEX IF EXISTS idx_deliveries_location;

-- Add new indexes for preparation tracking
CREATE INDEX IF NOT EXISTS idx_orders_estimated_preparation_time ON public.orders(estimated_preparation_time);
CREATE INDEX IF NOT EXISTS idx_orders_actual_preparation_time ON public.orders(actual_preparation_time) WHERE actual_preparation_time IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_orders_preparation_started_at ON public.orders(preparation_started_at DESC) WHERE preparation_started_at IS NOT NULL;
CREATE INDEX IF EXISTS idx_orders_pickup_ready_confirmed_at ON public.orders(pickup_ready_confirmed_at DESC) WHERE pickup_ready_confirmed_at IS NOT NULL;

-- Update comments
COMMENT ON TABLE public.orders IS 'Stores customer orders with focus on preparation tracking and pickup';
COMMENT ON COLUMN public.orders.pickup_address IS 'JSON object containing pickup location details (can be restaurant or customer location)';
COMMENT ON COLUMN public.orders.estimated_preparation_time IS 'Estimated preparation time in minutes';
COMMENT ON COLUMN public.orders.actual_preparation_time IS 'Actual preparation time in minutes, calculated automatically';
COMMENT ON COLUMN public.orders.preparation_started_at IS 'Timestamp when preparation actually started';
COMMENT ON COLUMN public.orders.preparation_completed_at IS 'Timestamp when preparation was completed';
COMMENT ON COLUMN public.orders.customer_notified_at IS 'Timestamp when customer was notified about order status';
COMMENT ON COLUMN public.orders.pickup_ready_confirmed_at IS 'Timestamp when restaurant confirmed order is ready for pickup';

-- Create a view for preparation tracking
CREATE OR REPLACE VIEW public.preparation_tracking_view AS
SELECT
    o.id,
    o.restaurant_id,
    o.user_id,
    o.status,
    o.estimated_preparation_time,
    o.actual_preparation_time,
    o.preparation_started_at,
    o.preparation_completed_at,
    o.ready_at,
    o.pickup_ready_confirmed_at,
    o.created_at as placed_at,
    r.name as restaurant_name,
    up.full_name as customer_name,
    CASE
        WHEN o.status = 'preparing' AND o.preparation_started_at IS NOT NULL THEN
            GREATEST(0, o.estimated_preparation_time -
                EXTRACT(EPOCH FROM (NOW() - o.preparation_started_at)) / 60)
        WHEN o.status = 'confirmed' THEN o.estimated_preparation_time
        ELSE NULL
    END as remaining_minutes,
    CASE
        WHEN o.actual_preparation_time IS NOT NULL AND o.estimated_preparation_time > 0 THEN
            ROUND((o.estimated_preparation_time / o.actual_preparation_time) * 100, 2)
        ELSE NULL
    END as efficiency_percentage
FROM public.orders o
LEFT JOIN public.restaurants r ON o.restaurant_id = r.id
LEFT JOIN public.user_profiles up ON o.user_id = up.id
WHERE o.status IN ('confirmed', 'preparing', 'ready_for_pickup');

COMMENT ON VIEW public.preparation_tracking_view IS 'Real-time view for order preparation tracking with analytics';

-- RLS policies for the new preparation tracking view
ALTER VIEW public.preparation_tracking_view OWNER TO postgres;
DROP POLICY IF EXISTS "Users can view preparation tracking for their orders" ON public.preparation_tracking_view;
DROP POLICY IF EXISTS "Restaurants can view preparation tracking for their orders" ON public.preparation_tracking_view;

-- Note: Views don't directly support RLS, but we can secure the underlying tables
-- The orders table already has RLS policies that will protect this view