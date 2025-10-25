-- =====================================================
-- NandyFood Database Schema - COMPLETE COMBINED MIGRATION
-- Includes: All base migrations + Critical 20241201 additions
-- Description: Complete database setup with all features
-- =====================================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- NandyFood Database Schema
-- Migration: 001 - User Profiles Table
-- Description: Creates user_profiles table with authentication integration
-- =====================================================

-- Create user_profiles table
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT NOT NULL UNIQUE,
    full_name TEXT,
    phone_number TEXT,
    avatar_url TEXT,
    date_of_birth DATE,
    gender TEXT CHECK (gender IN ('male', 'female', 'other', 'prefer_not_to_say')),
    
    -- Preferences
    notification_enabled BOOLEAN DEFAULT TRUE,
    email_notifications BOOLEAN DEFAULT TRUE,
    sms_notifications BOOLEAN DEFAULT FALSE,
    push_notifications BOOLEAN DEFAULT TRUE,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    last_login_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Additional fields
    preferences JSONB DEFAULT '{}'::jsonb,
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON public.user_profiles(email);
CREATE INDEX IF NOT EXISTS idx_user_profiles_phone ON public.user_profiles(phone_number);
CREATE INDEX IF NOT EXISTS idx_user_profiles_created_at ON public.user_profiles(created_at);
CREATE INDEX IF NOT EXISTS idx_user_profiles_is_active ON public.user_profiles(is_active);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updated_at
DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON public.user_profiles;
CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- Create function to handle new user creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_profiles (id, email, full_name)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email)
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for automatic profile creation on signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- Add comments for documentation
COMMENT ON TABLE public.user_profiles IS 'Stores user profile information linked to auth.users';
COMMENT ON COLUMN public.user_profiles.id IS 'References auth.users.id, automatically set on user creation';
COMMENT ON COLUMN public.user_profiles.preferences IS 'JSON object for storing user preferences like dietary restrictions, favorite cuisines, etc.';
COMMENT ON COLUMN public.user_profiles.metadata IS 'JSON object for storing additional metadata';

-- =====================================================
-- NandyFood Database Schema
-- Migration: 002 - Addresses Table
-- Description: Creates addresses table for user delivery locations
-- =====================================================

-- Create addresses table
CREATE TABLE IF NOT EXISTS public.addresses (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE NOT NULL,
    
    -- Address details
    label TEXT NOT NULL, -- e.g., 'Home', 'Work', 'Other'
    address_line1 TEXT NOT NULL,
    address_line2 TEXT,
    city TEXT NOT NULL,
    state TEXT NOT NULL,
    postal_code TEXT NOT NULL,
    country TEXT DEFAULT 'USA' NOT NULL,
    
    -- Geolocation
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    
    -- Additional info
    delivery_instructions TEXT,
    phone_number TEXT,
    is_default BOOLEAN DEFAULT FALSE,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT valid_coordinates CHECK (
        (latitude IS NULL AND longitude IS NULL) OR
        (latitude IS NOT NULL AND longitude IS NOT NULL AND
         latitude BETWEEN -90 AND 90 AND
         longitude BETWEEN -180 AND 180)
    )
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_addresses_user_id ON public.addresses(user_id);
CREATE INDEX IF NOT EXISTS idx_addresses_is_default ON public.addresses(user_id, is_default) WHERE is_default = TRUE;
CREATE INDEX IF NOT EXISTS idx_addresses_lat_lon ON public.addresses(latitude, longitude) WHERE latitude IS NOT NULL;

-- Create trigger for updated_at
DROP TRIGGER IF EXISTS update_addresses_updated_at ON public.addresses;
CREATE TRIGGER update_addresses_updated_at
    BEFORE UPDATE ON public.addresses
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- Function to ensure only one default address per user
CREATE OR REPLACE FUNCTION public.ensure_single_default_address()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_default = TRUE THEN
        UPDATE public.addresses
        SET is_default = FALSE
        WHERE user_id = NEW.user_id AND id != NEW.id AND is_default = TRUE;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for default address management
DROP TRIGGER IF EXISTS ensure_single_default_address_trigger ON public.addresses;
CREATE TRIGGER ensure_single_default_address_trigger
    BEFORE INSERT OR UPDATE ON public.addresses
    FOR EACH ROW
    WHEN (NEW.is_default = TRUE)
    EXECUTE FUNCTION public.ensure_single_default_address();

-- Add comments
COMMENT ON TABLE public.addresses IS 'Stores user delivery addresses';
COMMENT ON COLUMN public.addresses.label IS 'User-friendly label for the address (Home, Work, etc.)';
COMMENT ON COLUMN public.addresses.is_default IS 'Indicates if this is the users default delivery address';

-- =====================================================
-- NandyFood Database Schema
-- Migration: 003 - Restaurants Table
-- Description: Creates restaurants table with location support
-- =====================================================

-- Enable PostGIS for geospatial queries (if available)
-- CREATE EXTENSION IF NOT EXISTS postgis;

-- Create restaurants table
CREATE TABLE IF NOT EXISTS public.restaurants (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    
    -- Basic information
    name TEXT NOT NULL,
    description TEXT,
    cuisine_type TEXT NOT NULL,
    phone_number TEXT,
    email TEXT,
    website_url TEXT,
    
    -- Location
    address_line1 TEXT NOT NULL,
    address_line2 TEXT,
    city TEXT NOT NULL,
    state TEXT NOT NULL,
    postal_code TEXT NOT NULL,
    country TEXT DEFAULT 'USA' NOT NULL,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    
    -- Business details
    delivery_radius DECIMAL(5, 2) DEFAULT 5.0 NOT NULL, -- in kilometers
    estimated_delivery_time INTEGER DEFAULT 30 NOT NULL, -- in minutes
    minimum_order_amount DECIMAL(10, 2) DEFAULT 10.00,
    delivery_fee DECIMAL(10, 2) DEFAULT 2.99,
    
    -- Ratings and reviews
    rating DECIMAL(3, 2) DEFAULT 0.0 CHECK (rating >= 0 AND rating <= 5),
    total_reviews INTEGER DEFAULT 0,
    
    -- Operating hours (stored as JSONB for flexibility)
    opening_hours JSONB DEFAULT '{
        "monday": {"open": "09:00", "close": "22:00"},
        "tuesday": {"open": "09:00", "close": "22:00"},
        "wednesday": {"open": "09:00", "close": "22:00"},
        "thursday": {"open": "09:00", "close": "22:00"},
        "friday": {"open": "09:00", "close": "23:00"},
        "saturday": {"open": "09:00", "close": "23:00"},
        "sunday": {"open": "10:00", "close": "21:00"}
    }'::jsonb,
    
    -- Features
    dietary_options TEXT[] DEFAULT ARRAY[]::TEXT[], -- e.g., ['vegetarian', 'vegan', 'gluten-free']
    features TEXT[] DEFAULT ARRAY[]::TEXT[], -- e.g., ['outdoor-seating', 'wifi', 'parking']
    
    -- Images
    logo_url TEXT,
    cover_image_url TEXT,
    image_urls TEXT[] DEFAULT ARRAY[]::TEXT[],
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    is_accepting_orders BOOLEAN DEFAULT TRUE,
    is_featured BOOLEAN DEFAULT FALSE,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb,
    
    -- Constraints
    CONSTRAINT valid_restaurant_coordinates CHECK (
        latitude BETWEEN -90 AND 90 AND
        longitude BETWEEN -180 AND 180
    ),
    CONSTRAINT valid_delivery_radius CHECK (delivery_radius > 0 AND delivery_radius <= 50),
    CONSTRAINT valid_rating CHECK (rating >= 0 AND rating <= 5)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_restaurants_name ON public.restaurants(name);
CREATE INDEX IF NOT EXISTS idx_restaurants_cuisine_type ON public.restaurants(cuisine_type);
CREATE INDEX IF NOT EXISTS idx_restaurants_rating ON public.restaurants(rating DESC);
CREATE INDEX IF NOT EXISTS idx_restaurants_is_active ON public.restaurants(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_restaurants_is_featured ON public.restaurants(is_featured) WHERE is_featured = TRUE;
CREATE INDEX IF NOT EXISTS idx_restaurants_lat_lon ON public.restaurants(latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_restaurants_dietary_options ON public.restaurants USING gin(dietary_options);
CREATE INDEX IF NOT EXISTS idx_restaurants_created_at ON public.restaurants(created_at);

-- Create full-text search index
CREATE INDEX IF NOT EXISTS idx_restaurants_search ON public.restaurants USING gin(to_tsvector('english', name || ' ' || COALESCE(description, '') || ' ' || cuisine_type));

-- Create trigger for updated_at
DROP TRIGGER IF EXISTS update_restaurants_updated_at ON public.restaurants;
CREATE TRIGGER update_restaurants_updated_at
    BEFORE UPDATE ON public.restaurants
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- Function to calculate distance between restaurant and user
CREATE OR REPLACE FUNCTION public.calculate_distance(
    lat1 DECIMAL, lon1 DECIMAL, lat2 DECIMAL, lon2 DECIMAL
) RETURNS DECIMAL AS $$
DECLARE
    earth_radius DECIMAL := 6371; -- Earth's radius in kilometers
    dlat DECIMAL;
    dlon DECIMAL;
    a DECIMAL;
    c DECIMAL;
BEGIN
    dlat := radians(lat2 - lat1);
    dlon := radians(lon2 - lon1);
    a := sin(dlat/2) * sin(dlat/2) + cos(radians(lat1)) * cos(radians(lat2)) * sin(dlon/2) * sin(dlon/2);
    c := 2 * atan2(sqrt(a), sqrt(1-a));
    RETURN earth_radius * c;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function to find restaurants within delivery range
CREATE OR REPLACE FUNCTION public.find_nearby_restaurants(
    user_lat DECIMAL,
    user_lon DECIMAL,
    max_distance DECIMAL DEFAULT 10.0
)
RETURNS TABLE (
    restaurant_id UUID,
    restaurant_name TEXT,
    distance DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        r.id,
        r.name,
        public.calculate_distance(user_lat, user_lon, r.latitude, r.longitude) as dist
    FROM public.restaurants r
    WHERE 
        r.is_active = TRUE AND
        r.is_accepting_orders = TRUE AND
        public.calculate_distance(user_lat, user_lon, r.latitude, r.longitude) <= LEAST(r.delivery_radius, max_distance)
    ORDER BY dist ASC;
END;
$$ LANGUAGE plpgsql;

-- Add comments
COMMENT ON TABLE public.restaurants IS 'Stores restaurant information and locations';
COMMENT ON COLUMN public.restaurants.delivery_radius IS 'Maximum delivery distance in kilometers';
COMMENT ON COLUMN public.restaurants.dietary_options IS 'Array of dietary options offered (vegetarian, vegan, etc.)';
COMMENT ON FUNCTION public.calculate_distance IS 'Calculates distance between two coordinates using Haversine formula';

-- =====================================================
-- NandyFood Database Schema
-- Migration: 004 - Menu Items Table
-- Description: Creates menu_items table for restaurant menus
-- =====================================================

-- Create menu_items table
CREATE TABLE IF NOT EXISTS public.menu_items (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    restaurant_id UUID REFERENCES public.restaurants(id) ON DELETE CASCADE NOT NULL,
    
    -- Basic information
    name TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL, -- e.g., 'Appetizers', 'Main Course', 'Desserts', 'Beverages'
    
    -- Pricing
    price DECIMAL(10, 2) NOT NULL CHECK (price >= 0),
    original_price DECIMAL(10, 2), -- For displaying discounts
    
    -- Dietary and allergen information
    dietary_tags TEXT[] DEFAULT ARRAY[]::TEXT[], -- e.g., ['vegetarian', 'vegan', 'gluten-free', 'dairy-free']
    allergens TEXT[] DEFAULT ARRAY[]::TEXT[], -- e.g., ['nuts', 'dairy', 'eggs', 'shellfish']
    spice_level INTEGER DEFAULT 0 CHECK (spice_level BETWEEN 0 AND 5), -- 0 = not spicy, 5 = very spicy
    calories INTEGER,
    
    -- Images
    image_url TEXT,
    thumbnail_url TEXT,
    
    -- Customization options (stored as JSONB)
    customization_options JSONB DEFAULT '[]'::jsonb,
    -- Example: [{"name": "Size", "options": ["Small", "Medium", "Large"], "prices": [0, 2, 4]}, ...]
    
    -- Availability
    is_available BOOLEAN DEFAULT TRUE,
    is_featured BOOLEAN DEFAULT FALSE,
    is_popular BOOLEAN DEFAULT FALSE,
    prep_time INTEGER DEFAULT 15, -- in minutes
    
    -- Inventory
    stock_quantity INTEGER, -- NULL means unlimited
    max_quantity_per_order INTEGER DEFAULT 10,
    
    -- Stats
    order_count INTEGER DEFAULT 0,
    rating DECIMAL(3, 2) DEFAULT 0.0 CHECK (rating >= 0 AND rating <= 5),
    review_count INTEGER DEFAULT 0,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb,
    
    -- Constraints
    CONSTRAINT valid_rating CHECK (rating >= 0 AND rating <= 5)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_menu_items_restaurant_id ON public.menu_items(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_menu_items_category ON public.menu_items(restaurant_id, category);
CREATE INDEX IF NOT EXISTS idx_menu_items_is_available ON public.menu_items(restaurant_id, is_available) WHERE is_available = TRUE;
CREATE INDEX IF NOT EXISTS idx_menu_items_is_featured ON public.menu_items(restaurant_id, is_featured) WHERE is_featured = TRUE;
CREATE INDEX IF NOT EXISTS idx_menu_items_is_popular ON public.menu_items(is_popular) WHERE is_popular = TRUE;
CREATE INDEX IF NOT EXISTS idx_menu_items_price ON public.menu_items(price);
CREATE INDEX IF NOT EXISTS idx_menu_items_dietary_tags ON public.menu_items USING gin(dietary_tags);
CREATE INDEX IF NOT EXISTS idx_menu_items_order_count ON public.menu_items(order_count DESC);
CREATE INDEX IF NOT EXISTS idx_menu_items_rating ON public.menu_items(rating DESC);

-- Create full-text search index
CREATE INDEX IF NOT EXISTS idx_menu_items_search ON public.menu_items USING gin(to_tsvector('english', name || ' ' || COALESCE(description, '') || ' ' || category));

-- Create trigger for updated_at
DROP TRIGGER IF EXISTS update_menu_items_updated_at ON public.menu_items;
CREATE TRIGGER update_menu_items_updated_at
    BEFORE UPDATE ON public.menu_items
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- Function to check stock availability
CREATE OR REPLACE FUNCTION public.check_menu_item_stock(
    item_id UUID,
    requested_quantity INTEGER
) RETURNS BOOLEAN AS $$
DECLARE
    current_stock INTEGER;
    max_allowed INTEGER;
BEGIN
    SELECT stock_quantity, max_quantity_per_order
    INTO current_stock, max_allowed
    FROM public.menu_items
    WHERE id = item_id AND is_available = TRUE;
    
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- Check if stock is unlimited (NULL)
    IF current_stock IS NULL THEN
        RETURN requested_quantity <= max_allowed;
    END IF;
    
    -- Check stock availability and max quantity
    RETURN current_stock >= requested_quantity AND requested_quantity <= max_allowed;
END;
$$ LANGUAGE plpgsql;

-- Function to decrease stock after order
CREATE OR REPLACE FUNCTION public.decrease_menu_item_stock(
    item_id UUID,
    quantity INTEGER
) RETURNS VOID AS $$
BEGIN
    UPDATE public.menu_items
    SET 
        stock_quantity = GREATEST(0, COALESCE(stock_quantity, 0) - quantity),
        order_count = order_count + 1
    WHERE id = item_id AND stock_quantity IS NOT NULL;
END;
$$ LANGUAGE plpgsql;

-- Add comments
COMMENT ON TABLE public.menu_items IS 'Stores menu items for each restaurant';
COMMENT ON COLUMN public.menu_items.customization_options IS 'JSON array of customization options with names, choices, and prices';
COMMENT ON COLUMN public.menu_items.stock_quantity IS 'NULL means unlimited stock, otherwise tracks available quantity';
COMMENT ON FUNCTION public.check_menu_item_stock IS 'Validates if requested quantity is available and within limits';

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

-- =====================================================
-- NandyFood Database Schema
-- Migration: 007 - Row Level Security (RLS) Policies
-- Description: Implements comprehensive security policies
-- =====================================================

-- Enable Row Level Security on all tables
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.restaurants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menu_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.deliveries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.promotions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.promotion_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_methods ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- USER PROFILES POLICIES
-- =====================================================

-- Users can view their own profile
CREATE POLICY "Users can view own profile" ON public.user_profiles
    FOR SELECT
    USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile" ON public.user_profiles
    FOR UPDATE
    USING (auth.uid() = id);

-- Users can insert their own profile (handled by trigger, but policy for safety)
CREATE POLICY "Users can insert own profile" ON public.user_profiles
    FOR INSERT
    WITH CHECK (auth.uid() = id);

-- =====================================================
-- ADDRESSES POLICIES
-- =====================================================

-- Users can view their own addresses
CREATE POLICY "Users can view own addresses" ON public.addresses
    FOR SELECT
    USING (auth.uid() = user_id);

-- Users can create their own addresses
CREATE POLICY "Users can insert own addresses" ON public.addresses
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own addresses
CREATE POLICY "Users can update own addresses" ON public.addresses
    FOR UPDATE
    USING (auth.uid() = user_id);

-- Users can delete their own addresses
CREATE POLICY "Users can delete own addresses" ON public.addresses
    FOR DELETE
    USING (auth.uid() = user_id);

-- =====================================================
-- RESTAURANTS POLICIES
-- =====================================================

-- Anyone can view active restaurants (no authentication required)
CREATE POLICY "Anyone can view active restaurants" ON public.restaurants
    FOR SELECT
    USING (is_active = TRUE);

-- Future: Add policies for restaurant owners/admins to manage their restaurants

-- =====================================================
-- MENU ITEMS POLICIES
-- =====================================================

-- Anyone can view available menu items (no authentication required)
CREATE POLICY "Anyone can view menu items" ON public.menu_items
    FOR SELECT
    USING (TRUE);

-- Future: Add policies for restaurant owners to manage menu items

-- =====================================================
-- ORDERS POLICIES
-- =====================================================

-- Users can view their own orders
CREATE POLICY "Users can view own orders" ON public.orders
    FOR SELECT
    USING (auth.uid() = user_id);

-- Users can create their own orders
CREATE POLICY "Users can create orders" ON public.orders
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own orders (limited fields, e.g., cancel)
CREATE POLICY "Users can update own orders" ON public.orders
    FOR UPDATE
    USING (
        auth.uid() = user_id AND
        status IN ('placed', 'confirmed') -- Only allow updates for certain statuses
    );

-- Future: Add policies for restaurant staff to view/update orders for their restaurant
-- CREATE POLICY "Restaurant staff can view restaurant orders" ON public.orders
--     FOR SELECT
--     USING (restaurant_id IN (SELECT id FROM restaurants WHERE owner_id = auth.uid()));

-- =====================================================
-- ORDER ITEMS POLICIES
-- =====================================================

-- Users can view their own order items
CREATE POLICY "Users can view own order items" ON public.order_items
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.orders
            WHERE orders.id = order_items.order_id
            AND orders.user_id = auth.uid()
        )
    );

-- Users can insert order items for their own orders
CREATE POLICY "Users can create order items" ON public.order_items
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.orders
            WHERE orders.id = order_items.order_id
            AND orders.user_id = auth.uid()
        )
    );

-- =====================================================
-- DELIVERIES POLICIES
-- =====================================================

-- Users can view delivery info for their own orders
CREATE POLICY "Users can view own delivery info" ON public.deliveries
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.orders
            WHERE orders.id = deliveries.order_id
            AND orders.user_id = auth.uid()
        )
    );

-- Future: Add policies for delivery drivers to view/update their assigned deliveries
-- CREATE POLICY "Drivers can view assigned deliveries" ON public.deliveries
--     FOR SELECT
--     USING (driver_id = auth.uid());

-- CREATE POLICY "Drivers can update assigned deliveries" ON public.deliveries
--     FOR UPDATE
--     USING (driver_id = auth.uid());

-- =====================================================
-- PROMOTIONS POLICIES
-- =====================================================

-- Anyone can view active promotions
CREATE POLICY "Anyone can view active promotions" ON public.promotions
    FOR SELECT
    USING (
        is_active = TRUE AND
        NOW() BETWEEN starts_at AND expires_at
    );

-- Future: Add policies for admin to manage promotions

-- =====================================================
-- PROMOTION USAGE POLICIES
-- =====================================================

-- Users can view their own promotion usage
CREATE POLICY "Users can view own promotion usage" ON public.promotion_usage
    FOR SELECT
    USING (auth.uid() = user_id);

-- System/authenticated users can insert promotion usage (during order creation)
CREATE POLICY "Users can record promotion usage" ON public.promotion_usage
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- =====================================================
-- PAYMENT METHODS POLICIES
-- =====================================================

-- Users can view their own payment methods
CREATE POLICY "Users can view own payment methods" ON public.payment_methods
    FOR SELECT
    USING (auth.uid() = user_id);

-- Users can create their own payment methods
CREATE POLICY "Users can create payment methods" ON public.payment_methods
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own payment methods
CREATE POLICY "Users can update own payment methods" ON public.payment_methods
    FOR UPDATE
    USING (auth.uid() = user_id);

-- Users can delete their own payment methods
CREATE POLICY "Users can delete own payment methods" ON public.payment_methods
    FOR DELETE
    USING (auth.uid() = user_id);

-- =====================================================
-- ADDITIONAL SECURITY FUNCTIONS
-- =====================================================

-- Function to check if user is order owner
CREATE OR REPLACE FUNCTION public.is_order_owner(order_id_param UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.orders
        WHERE id = order_id_param
        AND user_id = auth.uid()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if order can be cancelled
CREATE OR REPLACE FUNCTION public.can_cancel_order(order_id_param UUID)
RETURNS BOOLEAN AS $$
DECLARE
    order_status TEXT;
BEGIN
    SELECT status INTO order_status
    FROM public.orders
    WHERE id = order_id_param
    AND user_id = auth.uid();
    
    RETURN order_status IN ('placed', 'confirmed');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- GRANT PERMISSIONS
-- =====================================================

-- Grant usage on public schema
GRANT USAGE ON SCHEMA public TO authenticated, anon;

-- Grant SELECT on specific tables to anon users (for public data)
GRANT SELECT ON public.restaurants TO anon;
GRANT SELECT ON public.menu_items TO anon;
GRANT SELECT ON public.promotions TO anon;

-- Grant ALL on tables to authenticated users (policies will restrict access)
GRANT ALL ON public.user_profiles TO authenticated;
GRANT ALL ON public.addresses TO authenticated;
GRANT ALL ON public.orders TO authenticated;
GRANT ALL ON public.order_items TO authenticated;
GRANT ALL ON public.deliveries TO authenticated;
GRANT ALL ON public.promotion_usage TO authenticated;
GRANT ALL ON public.payment_methods TO authenticated;

-- Grant SELECT on restaurants and menu_items to authenticated users
GRANT SELECT ON public.restaurants TO authenticated;
GRANT SELECT ON public.menu_items TO authenticated;
GRANT SELECT ON public.promotions TO authenticated;

-- Add comments
COMMENT ON POLICY "Users can view own profile" ON public.user_profiles IS 
    'Allows users to view only their own profile data';
COMMENT ON POLICY "Anyone can view active restaurants" ON public.restaurants IS 
    'Allows public access to active restaurant listings';
COMMENT ON FUNCTION public.is_order_owner IS 
    'Helper function to check if authenticated user owns a specific order';

-- Migration: Update payment_methods table for Paystack
-- This migration updates the payment_methods table to store Paystack authorization codes
-- instead of Stripe payment method IDs

-- Drop the old Stripe column if it exists
ALTER TABLE payment_methods 
DROP COLUMN IF EXISTS stripe_payment_method_id;

-- Add Paystack-specific columns
ALTER TABLE payment_methods 
ADD COLUMN IF NOT EXISTS paystack_authorization_code TEXT,
ADD COLUMN IF NOT EXISTS card_type TEXT,
ADD COLUMN IF NOT EXISTS last_four TEXT,
ADD COLUMN IF NOT EXISTS expiry_month TEXT,
ADD COLUMN IF NOT EXISTS expiry_year TEXT,
ADD COLUMN IF NOT EXISTS bank TEXT,
ADD COLUMN IF NOT EXISTS country_code TEXT,
ADD COLUMN IF NOT EXISTS is_reusable BOOLEAN DEFAULT true;

-- Add index on authorization code for faster lookups
CREATE INDEX IF NOT EXISTS idx_payment_methods_auth_code 
ON payment_methods(paystack_authorization_code);

-- Add index on user_id for faster user-specific queries
CREATE INDEX IF NOT EXISTS idx_payment_methods_user_id 
ON payment_methods(user_id);

-- Add comments for documentation
COMMENT ON COLUMN payment_methods.paystack_authorization_code IS 'Paystack authorization code for recurring payments';
COMMENT ON COLUMN payment_methods.card_type IS 'Type of card (visa, mastercard, etc.)';
COMMENT ON COLUMN payment_methods.last_four IS 'Last 4 digits of the card';
COMMENT ON COLUMN payment_methods.expiry_month IS 'Card expiry month (MM)';
COMMENT ON COLUMN payment_methods.expiry_year IS 'Card expiry year (YYYY)';
COMMENT ON COLUMN payment_methods.bank IS 'Issuing bank name';
COMMENT ON COLUMN payment_methods.country_code IS 'Country code (NG, GH, ZA, etc.)';
COMMENT ON COLUMN payment_methods.is_reusable IS 'Whether this authorization can be used for future payments';

-- =====================================================
-- NandyFood Database Schema
-- Migration: 008 - Storage Buckets Configuration
-- Description: Creates and configures Supabase Storage buckets
-- =====================================================

-- Create storage buckets
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES 
    ('restaurant-images', 'restaurant-images', TRUE, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp']::text[]),
    ('menu-item-images', 'menu-item-images', TRUE, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp']::text[]),
    ('user-avatars', 'user-avatars', TRUE, 2097152, ARRAY['image/jpeg', 'image/png', 'image/webp']::text[]),
    ('delivery-photos', 'delivery-photos', FALSE, 3145728, ARRAY['image/jpeg', 'image/png']::text[])
ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- STORAGE POLICIES
-- =====================================================

-- Restaurant Images Bucket Policies
-- Anyone can view restaurant images (public bucket)
CREATE POLICY "Anyone can view restaurant images" ON storage.objects
    FOR SELECT
    USING (bucket_id = 'restaurant-images');

-- Authenticated users can upload restaurant images
CREATE POLICY "Authenticated users can upload restaurant images" ON storage.objects
    FOR INSERT
    WITH CHECK (
        bucket_id = 'restaurant-images' AND
        auth.role() = 'authenticated'
    );

-- Users can update their restaurant images
CREATE POLICY "Users can update restaurant images" ON storage.objects
    FOR UPDATE
    USING (
        bucket_id = 'restaurant-images' AND
        auth.role() = 'authenticated'
    );

-- Users can delete restaurant images
CREATE POLICY "Users can delete restaurant images" ON storage.objects
    FOR DELETE
    USING (
        bucket_id = 'restaurant-images' AND
        auth.role() = 'authenticated'
    );

-- Menu Item Images Bucket Policies
-- Anyone can view menu item images (public bucket)
CREATE POLICY "Anyone can view menu item images" ON storage.objects
    FOR SELECT
    USING (bucket_id = 'menu-item-images');

-- Authenticated users can upload menu item images
CREATE POLICY "Authenticated users can upload menu item images" ON storage.objects
    FOR INSERT
    WITH CHECK (
        bucket_id = 'menu-item-images' AND
        auth.role() = 'authenticated'
    );

-- Users can update menu item images
CREATE POLICY "Users can update menu item images" ON storage.objects
    FOR UPDATE
    USING (
        bucket_id = 'menu-item-images' AND
        auth.role() = 'authenticated'
    );

-- Users can delete menu item images
CREATE POLICY "Users can delete menu item images" ON storage.objects
    FOR DELETE
    USING (
        bucket_id = 'menu-item-images' AND
        auth.role() = 'authenticated'
    );

-- User Avatars Bucket Policies
-- Anyone can view user avatars (public bucket)
CREATE POLICY "Anyone can view user avatars" ON storage.objects
    FOR SELECT
    USING (bucket_id = 'user-avatars');

-- Users can upload their own avatar
CREATE POLICY "Users can upload own avatar" ON storage.objects
    FOR INSERT
    WITH CHECK (
        bucket_id = 'user-avatars' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- Users can update their own avatar
CREATE POLICY "Users can update own avatar" ON storage.objects
    FOR UPDATE
    USING (
        bucket_id = 'user-avatars' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- Users can delete their own avatar
CREATE POLICY "Users can delete own avatar" ON storage.objects
    FOR DELETE
    USING (
        bucket_id = 'user-avatars' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- Delivery Photos Bucket Policies (Private)
-- Users can view delivery photos for their orders
CREATE POLICY "Users can view delivery photos for own orders" ON storage.objects
    FOR SELECT
    USING (
        bucket_id = 'delivery-photos' AND
        auth.role() = 'authenticated'
        -- Additional check would verify order ownership
    );

-- Delivery drivers can upload delivery photos
CREATE POLICY "Drivers can upload delivery photos" ON storage.objects
    FOR INSERT
    WITH CHECK (
        bucket_id = 'delivery-photos' AND
        auth.role() = 'authenticated'
    );

-- =====================================================
-- HELPER FUNCTIONS FOR STORAGE
-- =====================================================

-- Function to generate unique file name
CREATE OR REPLACE FUNCTION public.generate_unique_filename(
    original_filename TEXT,
    user_id UUID DEFAULT NULL
)
RETURNS TEXT AS $$
DECLARE
    extension TEXT;
    timestamp TEXT;
    random_string TEXT;
BEGIN
    -- Extract file extension
    extension := substring(original_filename from '\\.[^\\.]+$');
    
    -- Generate timestamp
    timestamp := to_char(NOW(), 'YYYYMMDD_HH24MISS');
    
    -- Generate random string
    random_string := substring(md5(random()::text) from 1 for 8);
    
    -- Combine elements
    IF user_id IS NOT NULL THEN
        RETURN user_id::text || '/' || timestamp || '_' || random_string || extension;
    ELSE
        RETURN timestamp || '_' || random_string || extension;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Function to get public URL for storage object
CREATE OR REPLACE FUNCTION public.get_storage_public_url(
    bucket_name TEXT,
    file_path TEXT
)
RETURNS TEXT AS $$
DECLARE
    supabase_url TEXT;
BEGIN
    -- Get Supabase URL from environment or use placeholder
    -- In production, this would be replaced with actual Supabase URL
    supabase_url := current_setting('app.settings.supabase_url', true);
    
    IF supabase_url IS NULL THEN
        supabase_url := 'https://your-project.supabase.co';
    END IF;
    
    RETURN supabase_url || '/storage/v1/object/public/' || bucket_name || '/' || file_path;
END;
$$ LANGUAGE plpgsql;

-- Add comments
COMMENT ON POLICY "Anyone can view restaurant images" ON storage.objects IS 
    'Allows public access to restaurant images';
COMMENT ON POLICY "Users can upload own avatar" ON storage.objects IS 
    'Restricts avatar uploads to user-specific folders';
COMMENT ON FUNCTION public.generate_unique_filename IS 
    'Generates unique filename with timestamp and random string for storage uploads';

-- ============================================
-- NandyFood Database Migration
-- Date: 2024-12-01
-- Description: Add new features - favourites, user_devices, feedback
-- ============================================

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
