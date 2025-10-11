-- =====================================================
-- NandyFood Database Schema
-- Migration: 005 - Orders and Order Items Tables
-- Description: Creates orders and order_items tables
-- =====================================================

-- Create orders table
CREATE TABLE IF NOT EXISTS public.orders (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    restaurant_id UUID REFERENCES public.restaurants(id) ON DELETE SET NULL NOT NULL,
    
    -- Delivery information
    delivery_address JSONB NOT NULL,
    delivery_lat DECIMAL(10, 8),
    delivery_lng DECIMAL(11, 8),
    delivery_instructions TEXT,
    contact_phone TEXT NOT NULL,
    
    -- Order status
    status TEXT DEFAULT 'placed' CHECK (
        status IN ('placed', 'confirmed', 'preparing', 'ready_for_pickup', 'out_for_delivery', 'delivered', 'cancelled')
    ) NOT NULL,
    
    -- Payment information
    payment_method TEXT NOT NULL CHECK (payment_method IN ('card', 'cash', 'wallet', 'upi')),
    payment_status TEXT DEFAULT 'pending' CHECK (payment_status IN ('pending', 'completed', 'failed', 'refunded')) NOT NULL,
    payment_intent_id TEXT, -- Stripe payment intent ID
    transaction_id TEXT,
    
    -- Pricing breakdown
    subtotal DECIMAL(10, 2) NOT NULL CHECK (subtotal >= 0),
    delivery_fee DECIMAL(10, 2) DEFAULT 0.00 CHECK (delivery_fee >= 0),
    tax_amount DECIMAL(10, 2) DEFAULT 0.00 CHECK (tax_amount >= 0),
    tip_amount DECIMAL(10, 2) DEFAULT 0.00 CHECK (tip_amount >= 0),
    discount_amount DECIMAL(10, 2) DEFAULT 0.00 CHECK (discount_amount >= 0),
    total_amount DECIMAL(10, 2) NOT NULL CHECK (total_amount >= 0),
    
    -- Promo code
    promo_code TEXT,
    promo_discount DECIMAL(10, 2) DEFAULT 0.00,
    
    -- Timestamps
    placed_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    estimated_delivery_at TIMESTAMPTZ,
    confirmed_at TIMESTAMPTZ,
    preparing_at TIMESTAMPTZ,
    ready_at TIMESTAMPTZ,
    picked_up_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,
    
    -- Notes and special instructions
    notes TEXT,
    special_instructions TEXT,
    cancellation_reason TEXT,
    
    -- Rating and feedback
    rating INTEGER CHECK (rating BETWEEN 1 AND 5),
    review TEXT,
    review_created_at TIMESTAMPTZ,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Create order_items table
CREATE TABLE IF NOT EXISTS public.order_items (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE NOT NULL,
    menu_item_id UUID REFERENCES public.menu_items(id) ON DELETE SET NULL,
    
    -- Item details (cached from menu_item for historical record)
    item_name TEXT NOT NULL,
    item_description TEXT,
    item_image_url TEXT,
    
    -- Pricing
    unit_price DECIMAL(10, 2) NOT NULL CHECK (unit_price >= 0),
    quantity INTEGER DEFAULT 1 NOT NULL CHECK (quantity > 0),
    subtotal DECIMAL(10, 2) NOT NULL CHECK (subtotal >= 0),
    
    -- Customizations
    customizations JSONB DEFAULT '[]'::jsonb,
    -- Example: [{"option": "Size", "choice": "Large", "price": 2.00}, ...]
    
    -- Special requests
    special_instructions TEXT,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Create indexes for orders
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON public.orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_restaurant_id ON public.orders(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_payment_status ON public.orders(payment_status);
CREATE INDEX IF NOT EXISTS idx_orders_placed_at ON public.orders(placed_at DESC);
CREATE INDEX IF NOT EXISTS idx_orders_delivered_at ON public.orders(delivered_at DESC);
CREATE INDEX IF NOT EXISTS idx_orders_user_placed ON public.orders(user_id, placed_at DESC);

-- Create indexes for order_items
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON public.order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_menu_item_id ON public.order_items(menu_item_id);

-- Create triggers for updated_at
DROP TRIGGER IF EXISTS update_orders_updated_at ON public.orders;
CREATE TRIGGER update_orders_updated_at
    BEFORE UPDATE ON public.orders
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- Function to calculate order total
CREATE OR REPLACE FUNCTION public.calculate_order_total(order_id_param UUID)
RETURNS DECIMAL AS $$
DECLARE
    calculated_total DECIMAL(10, 2);
BEGIN
    SELECT 
        COALESCE(o.subtotal, 0) + 
        COALESCE(o.delivery_fee, 0) + 
        COALESCE(o.tax_amount, 0) + 
        COALESCE(o.tip_amount, 0) - 
        COALESCE(o.discount_amount, 0) - 
        COALESCE(o.promo_discount, 0)
    INTO calculated_total
    FROM public.orders o
    WHERE o.id = order_id_param;
    
    RETURN COALESCE(calculated_total, 0);
END;
$$ LANGUAGE plpgsql;

-- Function to update order status timestamps
CREATE OR REPLACE FUNCTION public.update_order_status_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status != OLD.status THEN
        CASE NEW.status
            WHEN 'confirmed' THEN NEW.confirmed_at := NOW();
            WHEN 'preparing' THEN NEW.preparing_at := NOW();
            WHEN 'ready_for_pickup' THEN NEW.ready_at := NOW();
            WHEN 'out_for_delivery' THEN NEW.picked_up_at := NOW();
            WHEN 'delivered' THEN NEW.delivered_at := NOW();
            WHEN 'cancelled' THEN NEW.cancelled_at := NOW();
        END CASE;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for status timestamps
DROP TRIGGER IF EXISTS update_order_status_timestamp_trigger ON public.orders;
CREATE TRIGGER update_order_status_timestamp_trigger
    BEFORE UPDATE ON public.orders
    FOR EACH ROW
    WHEN (OLD.status IS DISTINCT FROM NEW.status)
    EXECUTE FUNCTION public.update_order_status_timestamp();

-- Add comments
COMMENT ON TABLE public.orders IS 'Stores customer orders';
COMMENT ON TABLE public.order_items IS 'Stores individual items within each order';
COMMENT ON COLUMN public.orders.delivery_address IS 'JSON object containing full delivery address details';
COMMENT ON COLUMN public.order_items.customizations IS 'JSON array of selected customizations with prices';
