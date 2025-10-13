-- =====================================================
-- NandyFood Database Schema
-- Migration: 010 - User Roles System
-- Description: Creates user roles table with enum types
-- =====================================================

-- Create user roles enum type
CREATE TYPE user_role_type AS ENUM (
    'consumer',
    'restaurant_owner',
    'restaurant_staff',
    'admin',
    'delivery_driver'
);

-- Create user_roles table
CREATE TABLE IF NOT EXISTS public.user_roles (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    role user_role_type NOT NULL DEFAULT 'consumer',
    is_primary BOOLEAN DEFAULT FALSE,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Ensure a user can only have one entry per role
    UNIQUE(user_id, role)
);

-- Create indexes for performance
CREATE INDEX idx_user_roles_user_id ON public.user_roles(user_id);
CREATE INDEX idx_user_roles_role ON public.user_roles(role);
CREATE INDEX idx_user_roles_primary ON public.user_roles(is_primary) WHERE is_primary = TRUE;

-- Add role-related fields to user_profiles table
ALTER TABLE public.user_profiles
ADD COLUMN IF NOT EXISTS primary_role user_role_type DEFAULT 'consumer',
ADD COLUMN IF NOT EXISTS role_verified BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS role_verification_date TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS role_metadata JSONB DEFAULT '{}'::jsonb;

CREATE INDEX IF NOT EXISTS idx_user_profiles_primary_role ON public.user_profiles(primary_role);

-- Add trigger to update updated_at
DROP TRIGGER IF EXISTS update_user_roles_updated_at ON public.user_roles;
CREATE TRIGGER update_user_roles_updated_at
    BEFORE UPDATE ON public.user_roles
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- Comments
COMMENT ON TABLE public.user_roles IS 'Stores user role assignments - users can have multiple roles';
COMMENT ON COLUMN public.user_roles.role IS 'The role assigned to the user';
COMMENT ON COLUMN public.user_roles.is_primary IS 'Indicates if this is the user''s primary/active role';
COMMENT ON COLUMN public.user_roles.metadata IS 'Additional role-specific metadata';
