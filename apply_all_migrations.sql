-- =====================================================
-- NandyFood - Complete Database Setup
-- =====================================================
-- This file combines all migrations for easy application
-- Copy and paste this entire file into Supabase SQL Editor
-- URL: https://supabase.com/dashboard/project/brelcfytcagdtfkhbkaf/editor
-- =====================================================

-- =====================================================
-- MIGRATION 001: User Profiles Table
-- =====================================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

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

-- =====================================================
-- MIGRATION 002: Addresses Table
-- =====================================================

-- Enable earthdistance extension for geolocation
CREATE EXTENSION IF NOT EXISTS cube;
CREATE EXTENSION IF NOT EXISTS earthdistance;

-- Create addresses table
CREATE TABLE IF NOT EXISTS public.addresses (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE NOT NULL,
    
    -- Address details
    label TEXT NOT NULL,
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
CREATE INDEX IF NOT EXISTS idx_addresses_location ON public.addresses USING gist(ll_to_earth(latitude, longitude)) WHERE latitude IS NOT NULL;

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

COMMENT ON TABLE public.addresses IS 'Stores user delivery addresses';

-- =====================================================
-- MIGRATION 003: Restaurants Table  
-- =====================================================

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
    delivery_radius DECIMAL(5, 2) DEFAULT 5.0 NOT NULL,
    estimated_delivery_time INTEGER DEFAULT 30 NOT NULL,
    minimum_order_amount DECIMAL(10, 2) DEFAULT 10.00,
    delivery_fee DECIMAL(10, 2) DEFAULT 2.99,
    
    -- Ratings and reviews
    rating DECIMAL(3, 2) DEFAULT 0.0 CHECK (rating >= 0 AND rating <= 5),
    total_reviews INTEGER DEFAULT 0,
    
    -- Operating hours
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
    dietary_options TEXT[] DEFAULT ARRAY[]::TEXT[],
    features TEXT[] DEFAULT ARRAY[]::TEXT[],
    
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
CREATE INDEX IF NOT EXISTS idx_restaurants_location ON public.restaurants USING gist(ll_to_earth(latitude, longitude));
CREATE INDEX IF NOT EXISTS idx_restaurants_dietary_options ON public.restaurants USING gin(dietary_options);
CREATE INDEX IF NOT EXISTS idx_restaurants_created_at ON public.restaurants(created_at);
CREATE INDEX IF NOT EXISTS idx_restaurants_search ON public.restaurants USING gin(to_tsvector('english', name || ' ' || COALESCE(description, '') || ' ' || cuisine_type));

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
    earth_radius DECIMAL := 6371;
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

COMMENT ON TABLE public.restaurants IS 'Stores restaurant information and locations';

-- Continue in next message due to length...
