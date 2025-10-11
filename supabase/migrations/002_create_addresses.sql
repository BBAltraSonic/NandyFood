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

-- Add comments
COMMENT ON TABLE public.addresses IS 'Stores user delivery addresses';
COMMENT ON COLUMN public.addresses.label IS 'User-friendly label for the address (Home, Work, etc.)';
COMMENT ON COLUMN public.addresses.is_default IS 'Indicates if this is the users default delivery address';
