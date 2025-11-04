-- =====================================================
-- NandyFood Database Schema
-- Migration: 024 - Enhance Staff Management
-- Description: Updates restaurant_staff table with enhanced roles and permissions
-- =====================================================

-- First, let's check if the table exists and has the current structure
DO $$
BEGIN
    -- Drop the existing table if it has conflicting structure
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_name = 'restaurant_staff'
        AND table_schema = 'public'
    ) THEN
        -- Check if the role column needs to be updated
        IF EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_name = 'restaurant_staff'
            AND column_name = 'role'
            AND data_type = 'text'
        ) THEN
            -- Update existing data to use new role types
            UPDATE public.restaurant_staff
            SET role = 'basic_staff'
            WHERE role NOT IN ('manager', 'chef', 'cashier', 'server', 'delivery_coordinator', 'basic_staff');

            -- Add new role type if it doesn't exist
            ALTER TABLE public.restaurant_staff
            DROP CONSTRAINT IF EXISTS restaurant_staff_role_check;

            ADD CONSTRAINT restaurant_staff_role_check
            CHECK (role IN ('manager', 'chef', 'cashier', 'server', 'delivery_coordinator', 'basic_staff'));
        END IF;
    END IF;
END $$;

-- Create or update the restaurant_staff table with enhanced structure
CREATE TABLE IF NOT EXISTS public.restaurant_staff (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    restaurant_id UUID REFERENCES public.restaurants(id) ON DELETE CASCADE NOT NULL,
    role TEXT CHECK (role IN ('manager', 'chef', 'cashier', 'server', 'delivery_coordinator', 'basic_staff')) NOT NULL,
    permissions JSONB DEFAULT '{
        "view_orders": true,
        "update_orders": false,
        "view_menu": true,
        "update_menu": false,
        "manage_staff": false,
        "view_analytics": false,
        "manage_settings": false,
        "process_payments": false,
        "view_reports": false
    }'::jsonb,
    employment_type TEXT CHECK (employment_type IN ('full-time', 'part-time', 'contractor')) DEFAULT 'full-time',
    status TEXT CHECK (status IN ('active', 'on_leave', 'suspended', 'terminated', 'pending')) DEFAULT 'active',
    hired_date DATE DEFAULT CURRENT_DATE,
    termination_date DATE,
    hourly_rate DECIMAL(10, 2),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Each user can only be staff once per restaurant
    UNIQUE(user_id, restaurant_id)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_restaurant_staff_user_id ON public.restaurant_staff(user_id);
CREATE INDEX IF NOT EXISTS idx_restaurant_staff_restaurant_id ON public.restaurant_staff(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_restaurant_staff_role ON public.restaurant_staff(role);
CREATE INDEX IF NOT EXISTS idx_restaurant_staff_status ON public.restaurant_staff(status);
CREATE INDEX IF NOT EXISTS idx_restaurant_staff_employment_type ON public.restaurant_staff(employment_type);

-- Add trigger for updated_at if it doesn't exist
DROP TRIGGER IF EXISTS update_restaurant_staff_updated_at ON public.restaurant_staff;
CREATE TRIGGER update_restaurant_staff_updated_at
    BEFORE UPDATE ON public.restaurant_staff
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- Create a function to set default permissions based on role
CREATE OR REPLACE FUNCTION set_default_staff_permissions()
RETURNS TRIGGER AS $$
BEGIN
    -- Only set permissions if they are null or empty
    IF NEW.permissions IS NULL OR NEW.permissions = '{}'::jsonb THEN
        CASE NEW.role
            WHEN 'manager' THEN
                NEW.permissions := '{
                    "view_orders": true,
                    "update_orders": true,
                    "view_menu": true,
                    "update_menu": true,
                    "manage_staff": true,
                    "view_analytics": true,
                    "manage_settings": false,
                    "process_payments": true,
                    "view_reports": true
                }'::jsonb;
            WHEN 'chef' THEN
                NEW.permissions := '{
                    "view_orders": true,
                    "update_orders": true,
                    "view_menu": true,
                    "update_menu": false,
                    "manage_staff": false,
                    "view_analytics": false,
                    "manage_settings": false,
                    "process_payments": false,
                    "view_reports": false
                }'::jsonb;
            WHEN 'cashier' THEN
                NEW.permissions := '{
                    "view_orders": true,
                    "update_orders": true,
                    "view_menu": true,
                    "update_menu": false,
                    "manage_staff": false,
                    "view_analytics": false,
                    "manage_settings": false,
                    "process_payments": true,
                    "view_reports": false
                }'::jsonb;
            WHEN 'server' THEN
                NEW.permissions := '{
                    "view_orders": true,
                    "update_orders": false,
                    "view_menu": true,
                    "update_menu": false,
                    "manage_staff": false,
                    "view_analytics": false,
                    "manage_settings": false,
                    "process_payments": false,
                    "view_reports": false
                }'::jsonb;
            WHEN 'delivery_coordinator' THEN
                NEW.permissions := '{
                    "view_orders": true,
                    "update_orders": true,
                    "view_menu": false,
                    "update_menu": false,
                    "manage_staff": false,
                    "view_analytics": false,
                    "manage_settings": false,
                    "process_payments": false,
                    "view_reports": false
                }'::jsonb;
            ELSE -- basic_staff
                NEW.permissions := '{
                    "view_orders": true,
                    "update_orders": false,
                    "view_menu": true,
                    "update_menu": false,
                    "manage_staff": false,
                    "view_analytics": false,
                    "manage_settings": false,
                    "process_payments": false,
                    "view_reports": false
                }'::jsonb;
        END CASE;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically set permissions based on role
DROP TRIGGER IF EXISTS set_staff_permissions_trigger ON public.restaurant_staff;
CREATE TRIGGER set_staff_permissions_trigger
    BEFORE INSERT OR UPDATE ON public.restaurant_staff
    FOR EACH ROW
    EXECUTE FUNCTION set_default_staff_permissions();

-- Create a function to check if a user has specific staff permission
CREATE OR REPLACE FUNCTION has_staff_permission(
    user_id_param UUID,
    restaurant_id_param UUID,
    permission_param TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
    permission_exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM public.restaurant_staff rs
        WHERE rs.user_id = user_id_param
        AND rs.restaurant_id = restaurant_id_param
        AND rs.status = 'active'
        AND (rs.permissions->>permission_param)::boolean = true
    ) INTO permission_exists;

    RETURN COALESCE(permission_exists, false);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a function to get restaurant staff with user profiles
CREATE OR REPLACE FUNCTION get_restaurant_staff_with_profiles(restaurant_id_param UUID)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    restaurant_id UUID,
    role TEXT,
    permissions JSONB,
    employment_type TEXT,
    status TEXT,
    hired_date DATE,
    termination_date DATE,
    hourly_rate DECIMAL(10, 2),
    notes TEXT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    email TEXT,
    full_name TEXT,
    phone_number TEXT,
    avatar_url TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        rs.id,
        rs.user_id,
        rs.restaurant_id,
        rs.role,
        rs.permissions,
        rs.employment_type,
        rs.status,
        rs.hired_date,
        rs.termination_date,
        rs.hourly_rate,
        rs.notes,
        rs.created_at,
        rs.updated_at,
        up.email,
        up.full_name,
        up.phone_number,
        up.avatar_url
    FROM public.restaurant_staff rs
    LEFT JOIN public.user_profiles up ON rs.user_id = up.id
    WHERE rs.restaurant_id = restaurant_id_param
    ORDER BY
        CASE rs.role
            WHEN 'manager' THEN 1
            WHEN 'chef' THEN 2
            WHEN 'cashier' THEN 3
            WHEN 'server' THEN 4
            WHEN 'delivery_coordinator' THEN 5
            ELSE 6
        END,
        rs.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update existing staff records to use the new default permissions
UPDATE public.restaurant_staff
SET permissions = '{
    "view_orders": true,
    "update_orders": false,
    "view_menu": true,
    "update_menu": false,
    "manage_staff": false,
    "view_analytics": false,
    "manage_settings": false,
    "process_payments": false,
    "view_reports": false
}'::jsonb
WHERE permissions = '{}'::jsonb OR permissions IS NULL;

-- Create Row Level Security (RLS) policies for restaurant_staff
ALTER TABLE public.restaurant_staff ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view staff for their restaurants" ON public.restaurant_staff;
DROP POLICY IF EXISTS "Restaurant owners can manage staff" ON public.restaurant_staff;
DROP POLICY IF EXISTS "Staff can view their own record" ON public.restaurant_staff;

-- Create RLS policies

-- Users can view staff for restaurants they own or work at
CREATE POLICY "Users can view staff for their restaurants" ON public.restaurant_staff
    FOR SELECT USING (
        -- Restaurant owners can view all staff
        EXISTS (
            SELECT 1 FROM public.restaurant_owners ro
            WHERE ro.user_id = auth.uid()
            AND ro.restaurant_id = restaurant_staff.restaurant_id
            AND ro.status = 'active'
        )
        OR
        -- Staff can view other staff at their restaurant
        EXISTS (
            SELECT 1 FROM public.restaurant_staff rs
            WHERE rs.user_id = auth.uid()
            AND rs.restaurant_id = restaurant_staff.restaurant_id
            AND rs.status = 'active'
        )
    );

-- Restaurant owners can manage staff
CREATE POLICY "Restaurant owners can manage staff" ON public.restaurant_staff
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.restaurant_owners ro
            WHERE ro.user_id = auth.uid()
            AND ro.restaurant_id = restaurant_staff.restaurant_id
            AND ro.status = 'active'
            AND (ro.permissions->>'manage_staff')::boolean = true
        )
    );

-- Staff can view and update their own record
CREATE POLICY "Staff can view their own record" ON public.restaurant_staff
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Staff can update their own record" ON public.restaurant_staff
    FOR UPDATE USING (user_id = auth.uid());

-- Comments
COMMENT ON TABLE public.restaurant_staff IS 'Enhanced restaurant staff table with detailed roles and permissions';
COMMENT ON COLUMN public.restaurant_staff.role IS 'Staff role: manager, chef, cashier, server, delivery_coordinator, or basic_staff';
COMMENT ON COLUMN public.restaurant_staff.permissions IS 'JSON object defining detailed staff permissions';
COMMENT ON COLUMN public.restaurant_staff.employment_type IS 'Employment type: full-time, part-time, or contractor';
COMMENT ON COLUMN public.restaurant_staff.status IS 'Staff status: active, on_leave, suspended, terminated, or pending';
COMMENT ON FUNCTION has_staff_permission IS 'Checks if a user has a specific permission within a restaurant';
COMMENT ON FUNCTION get_restaurant_staff_with_profiles IS 'Returns restaurant staff with joined user profile information';