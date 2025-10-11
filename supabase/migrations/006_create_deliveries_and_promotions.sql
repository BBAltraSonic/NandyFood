-- =====================================================
-- NandyFood Database Schema
-- Migration: 006 - Deliveries and Promotions Tables
-- Description: Creates delivery tracking and promotions tables
-- =====================================================

-- Create deliveries table
CREATE TABLE IF NOT EXISTS public.deliveries (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE UNIQUE NOT NULL,
    
    -- Driver information (for future driver app integration)
    driver_id UUID, -- References future drivers table
    driver_name TEXT,
    driver_phone TEXT,
    driver_photo_url TEXT,
    vehicle_type TEXT,
    vehicle_number TEXT,
    
    -- Real-time tracking
    current_lat DECIMAL(10, 8),
    current_lng DECIMAL(11, 8),
    last_location_update TIMESTAMPTZ,
    
    -- Route information
    pickup_lat DECIMAL(10, 8),
    pickup_lng DECIMAL(11, 8),
    dropoff_lat DECIMAL(10, 8),
    dropoff_lng DECIMAL(11, 8),
    estimated_distance DECIMAL(6, 2), -- in kilometers
    estimated_duration INTEGER, -- in minutes
    
    -- Status
    status TEXT DEFAULT 'assigned' CHECK (
        status IN ('assigned', 'heading_to_restaurant', 'at_restaurant', 'picked_up', 'in_transit', 'nearby', 'delivered', 'failed')
    ) NOT NULL,
    
    -- Timestamps
    assigned_at TIMESTAMPTZ DEFAULT NOW(),
    picked_up_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    
    -- Delivery proof
    delivery_photo_url TEXT,
    delivery_signature TEXT,
    delivery_notes TEXT,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Create promotions table
CREATE TABLE IF NOT EXISTS public.promotions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    
    -- Promotion details
    code TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    description TEXT,
    
    -- Discount configuration
    discount_type TEXT CHECK (discount_type IN ('percentage', 'fixed_amount', 'free_delivery')) NOT NULL,
    discount_value DECIMAL(10, 2) NOT NULL CHECK (discount_value >= 0),
    max_discount DECIMAL(10, 2), -- Maximum discount for percentage type
    
    -- Conditions
    min_order_amount DECIMAL(10, 2) DEFAULT 0.00,
    applicable_to TEXT[] DEFAULT ARRAY['all']::TEXT[], -- ['all'] or specific restaurant IDs
    first_order_only BOOLEAN DEFAULT FALSE,
    user_limit INTEGER DEFAULT 1, -- How many times a user can use this code
    total_usage_limit INTEGER, -- Total times the code can be used across all users
    current_usage_count INTEGER DEFAULT 0,
    
    -- Validity period
    starts_at TIMESTAMPTZ NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb,
    
    -- Constraints
    CONSTRAINT valid_promo_dates CHECK (expires_at > starts_at)
);

-- Create promotion usage tracking table
CREATE TABLE IF NOT EXISTS public.promotion_usage (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    promotion_id UUID REFERENCES public.promotions(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE NOT NULL,
    order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL NOT NULL,
    
    -- Discount applied
    discount_amount DECIMAL(10, 2) NOT NULL,
    
    -- Metadata
    used_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Prevent duplicate usage in same order
    CONSTRAINT unique_promo_per_order UNIQUE (order_id)
);

-- Create payment_methods table
CREATE TABLE IF NOT EXISTS public.payment_methods (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE NOT NULL,
    
    -- Payment method details
    type TEXT CHECK (type IN ('card', 'wallet', 'bank_account', 'upi')) NOT NULL,
    provider TEXT, -- e.g., 'stripe', 'paypal', 'razorpay'
    
    -- Card details (tokenized)
    card_last4 TEXT,
    card_brand TEXT, -- e.g., 'visa', 'mastercard', 'amex'
    card_exp_month INTEGER,
    card_exp_year INTEGER,
    
    -- External provider IDs
    stripe_payment_method_id TEXT,
    provider_customer_id TEXT,
    
    -- Status
    is_default BOOLEAN DEFAULT FALSE,
    is_verified BOOLEAN DEFAULT FALSE,
    
    -- Metadata
    nickname TEXT, -- User-friendly name for the payment method
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Create indexes for deliveries
CREATE INDEX IF NOT EXISTS idx_deliveries_order_id ON public.deliveries(order_id);
CREATE INDEX IF NOT EXISTS idx_deliveries_driver_id ON public.deliveries(driver_id);
CREATE INDEX IF NOT EXISTS idx_deliveries_status ON public.deliveries(status);
CREATE INDEX IF NOT EXISTS idx_deliveries_location ON public.deliveries USING gist(ll_to_earth(current_lat, current_lng)) WHERE current_lat IS NOT NULL;

-- Create indexes for promotions
CREATE INDEX IF NOT EXISTS idx_promotions_code ON public.promotions(code) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_promotions_active ON public.promotions(is_active, starts_at, expires_at);
CREATE INDEX IF NOT EXISTS idx_promotions_expires_at ON public.promotions(expires_at);

-- Create indexes for promotion usage
CREATE INDEX IF NOT EXISTS idx_promotion_usage_promotion_id ON public.promotion_usage(promotion_id);
CREATE INDEX IF NOT EXISTS idx_promotion_usage_user_id ON public.promotion_usage(user_id);
CREATE INDEX IF NOT EXISTS idx_promotion_usage_order_id ON public.promotion_usage(order_id);

-- Create indexes for payment methods
CREATE INDEX IF NOT EXISTS idx_payment_methods_user_id ON public.payment_methods(user_id);
CREATE INDEX IF NOT EXISTS idx_payment_methods_is_default ON public.payment_methods(user_id, is_default) WHERE is_default = TRUE;

-- Create triggers for updated_at
DROP TRIGGER IF EXISTS update_deliveries_updated_at ON public.deliveries;
CREATE TRIGGER update_deliveries_updated_at
    BEFORE UPDATE ON public.deliveries
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_promotions_updated_at ON public.promotions;
CREATE TRIGGER update_promotions_updated_at
    BEFORE UPDATE ON public.promotions
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_payment_methods_updated_at ON public.payment_methods;
CREATE TRIGGER update_payment_methods_updated_at
    BEFORE UPDATE ON public.payment_methods
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- Function to validate promotion code
CREATE OR REPLACE FUNCTION public.validate_promotion_code(
    promo_code_param TEXT,
    user_id_param UUID,
    order_amount_param DECIMAL,
    restaurant_id_param UUID
) RETURNS TABLE (
    valid BOOLEAN,
    discount_amount DECIMAL,
    message TEXT
) AS $$
DECLARE
    promo_record RECORD;
    user_usage_count INTEGER;
BEGIN
    -- Find active promotion
    SELECT * INTO promo_record
    FROM public.promotions
    WHERE 
        code = promo_code_param AND
        is_active = TRUE AND
        NOW() BETWEEN starts_at AND expires_at;
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, 0.00::DECIMAL, 'Invalid or expired promotion code';
        RETURN;
    END IF;
    
    -- Check minimum order amount
    IF order_amount_param < promo_record.min_order_amount THEN
        RETURN QUERY SELECT FALSE, 0.00::DECIMAL, 
            'Minimum order amount of $' || promo_record.min_order_amount::TEXT || ' required';
        RETURN;
    END IF;
    
    -- Check total usage limit
    IF promo_record.total_usage_limit IS NOT NULL AND 
       promo_record.current_usage_count >= promo_record.total_usage_limit THEN
        RETURN QUERY SELECT FALSE, 0.00::DECIMAL, 'Promotion code usage limit exceeded';
        RETURN;
    END IF;
    
    -- Check user usage limit
    SELECT COUNT(*) INTO user_usage_count
    FROM public.promotion_usage
    WHERE promotion_id = promo_record.id AND user_id = user_id_param;
    
    IF user_usage_count >= promo_record.user_limit THEN
        RETURN QUERY SELECT FALSE, 0.00::DECIMAL, 'You have already used this promotion code';
        RETURN;
    END IF;
    
    -- Calculate discount
    DECLARE
        calculated_discount DECIMAL;
    BEGIN
        CASE promo_record.discount_type
            WHEN 'percentage' THEN
                calculated_discount := (order_amount_param * promo_record.discount_value / 100);
                IF promo_record.max_discount IS NOT NULL THEN
                    calculated_discount := LEAST(calculated_discount, promo_record.max_discount);
                END IF;
            WHEN 'fixed_amount' THEN
                calculated_discount := promo_record.discount_value;
            WHEN 'free_delivery' THEN
                -- Will be handled by application logic
                calculated_discount := 0;
        END CASE;
        
        RETURN QUERY SELECT TRUE, calculated_discount, 'Promotion code applied successfully';
    END;
END;
$$ LANGUAGE plpgsql;

-- Add comments
COMMENT ON TABLE public.deliveries IS 'Tracks real-time delivery information for orders';
COMMENT ON TABLE public.promotions IS 'Stores promotional codes and their configurations';
COMMENT ON TABLE public.promotion_usage IS 'Tracks usage of promotion codes by users';
COMMENT ON TABLE public.payment_methods IS 'Stores tokenized payment method information';
