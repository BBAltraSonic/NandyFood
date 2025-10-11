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
CREATE INDEX IF NOT EXISTS idx_restaurants_location ON public.restaurants USING gist(ll_to_earth(latitude, longitude));
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
