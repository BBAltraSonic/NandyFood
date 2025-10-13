-- =====================================================
-- NandyFood Database Schema
-- Migration: 011 - Restaurant Ownership System
-- Description: Creates restaurant owners and staff tables
-- =====================================================

-- Restaurant Owners Table
CREATE TABLE IF NOT EXISTS public.restaurant_owners (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    restaurant_id UUID REFERENCES public.restaurants(id) ON DELETE CASCADE NOT NULL,
    owner_type TEXT CHECK (owner_type IN ('primary', 'co-owner', 'manager')) DEFAULT 'primary',
    permissions JSONB DEFAULT '{
        "manage_menu": true,
        "manage_orders": true,
        "manage_staff": false,
        "view_analytics": true,
        "manage_settings": false
    }'::jsonb,
    status TEXT CHECK (status IN ('active', 'pending', 'suspended', 'removed')) DEFAULT 'pending',
    verification_documents JSONB DEFAULT '[]'::jsonb,
    verified_at TIMESTAMPTZ,
    verified_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Each user can only be an owner of a restaurant once
    UNIQUE(user_id, restaurant_id)
);

-- Create indexes
CREATE INDEX idx_restaurant_owners_user_id ON public.restaurant_owners(user_id);
CREATE INDEX idx_restaurant_owners_restaurant_id ON public.restaurant_owners(restaurant_id);
CREATE INDEX idx_restaurant_owners_status ON public.restaurant_owners(status);
CREATE INDEX idx_restaurant_owners_owner_type ON public.restaurant_owners(owner_type);

-- Restaurant Staff Table
CREATE TABLE IF NOT EXISTS public.restaurant_staff (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    restaurant_id UUID REFERENCES public.restaurants(id) ON DELETE CASCADE NOT NULL,
    role TEXT CHECK (role IN ('manager', 'chef', 'cashier', 'server', 'delivery_coordinator')) NOT NULL,
    permissions JSONB DEFAULT '{
        "view_orders": true,
        "update_orders": false,
        "view_menu": true,
        "update_menu": false
    }'::jsonb,
    employment_type TEXT CHECK (employment_type IN ('full-time', 'part-time', 'contractor')) DEFAULT 'full-time',
    status TEXT CHECK (status IN ('active', 'on_leave', 'suspended', 'terminated')) DEFAULT 'active',
    hired_date DATE DEFAULT CURRENT_DATE,
    termination_date DATE,
    hourly_rate DECIMAL(10, 2),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Each user can only be staff once per restaurant
    UNIQUE(user_id, restaurant_id)
);

-- Create indexes
CREATE INDEX idx_restaurant_staff_user_id ON public.restaurant_staff(user_id);
CREATE INDEX idx_restaurant_staff_restaurant_id ON public.restaurant_staff(restaurant_id);
CREATE INDEX idx_restaurant_staff_role ON public.restaurant_staff(role);
CREATE INDEX idx_restaurant_staff_status ON public.restaurant_staff(status);

-- Add triggers for updated_at
DROP TRIGGER IF EXISTS update_restaurant_owners_updated_at ON public.restaurant_owners;
CREATE TRIGGER update_restaurant_owners_updated_at
    BEFORE UPDATE ON public.restaurant_owners
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_restaurant_staff_updated_at ON public.restaurant_staff;
CREATE TRIGGER update_restaurant_staff_updated_at
    BEFORE UPDATE ON public.restaurant_staff
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- Comments
COMMENT ON TABLE public.restaurant_owners IS 'Stores restaurant ownership information and permissions';
COMMENT ON TABLE public.restaurant_staff IS 'Stores restaurant staff members and their roles';
COMMENT ON COLUMN public.restaurant_owners.owner_type IS 'Type of ownership: primary, co-owner, or manager';
COMMENT ON COLUMN public.restaurant_owners.permissions IS 'JSON object defining what the owner can do';
COMMENT ON COLUMN public.restaurant_staff.role IS 'Staff role within the restaurant';
COMMENT ON COLUMN public.restaurant_staff.permissions IS 'JSON object defining staff permissions';
