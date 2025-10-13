-- =====================================================
-- NandyFood Database Schema
-- Migration: 013 - Row Level Security Policies
-- Description: RLS policies for role-based access control
-- =====================================================

-- ========================================
-- User Roles RLS Policies
-- ========================================
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

-- Users can view their own roles
CREATE POLICY "Users can view own roles"
    ON public.user_roles FOR SELECT
    USING (auth.uid() = user_id);

-- Users can insert their own consumer role (for upgrades)
CREATE POLICY "Users can request additional roles"
    ON public.user_roles FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Admins can manage all roles
CREATE POLICY "Admins can manage all roles"
    ON public.user_roles FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.user_roles
            WHERE user_id = auth.uid() 
            AND role = 'admin'
        )
    );

-- ========================================
-- Restaurant Owners RLS Policies
-- ========================================
ALTER TABLE public.restaurant_owners ENABLE ROW LEVEL SECURITY;

-- Owners can view their own restaurant ownership records
CREATE POLICY "Owners can view own restaurants"
    ON public.restaurant_owners FOR SELECT
    USING (auth.uid() = user_id);

-- Primary owners can manage co-owners and managers
CREATE POLICY "Primary owners can manage other owners"
    ON public.restaurant_owners FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.restaurant_owners
            WHERE user_id = auth.uid()
            AND restaurant_id = restaurant_owners.restaurant_id
            AND owner_type = 'primary'
            AND status = 'active'
        )
    );

-- Admins can manage all ownership records
CREATE POLICY "Admins can manage restaurant owners"
    ON public.restaurant_owners FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.user_roles
            WHERE user_id = auth.uid() AND role = 'admin'
        )
    );

-- ========================================
-- Restaurant Staff RLS Policies
-- ========================================
ALTER TABLE public.restaurant_staff ENABLE ROW LEVEL SECURITY;

-- Staff can view their own records
CREATE POLICY "Staff can view own records"
    ON public.restaurant_staff FOR SELECT
    USING (auth.uid() = user_id);

-- Restaurant owners and managers can view staff
CREATE POLICY "Owners can view restaurant staff"
    ON public.restaurant_staff FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.restaurant_owners
            WHERE user_id = auth.uid()
            AND restaurant_id = restaurant_staff.restaurant_id
            AND status = 'active'
            AND (permissions->>'manage_staff')::boolean = true
        )
    );

-- Owners with manage_staff permission can insert/update/delete staff
CREATE POLICY "Owners can manage staff"
    ON public.restaurant_staff FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.restaurant_owners
            WHERE user_id = auth.uid()
            AND restaurant_id = restaurant_staff.restaurant_id
            AND status = 'active'
            AND (permissions->>'manage_staff')::boolean = true
        )
    );

-- ========================================
-- Restaurants RLS Policies (Update)
-- ========================================

-- Owners can update their restaurants
DROP POLICY IF EXISTS "Owners can update their restaurants" ON public.restaurants;
CREATE POLICY "Owners can update their restaurants"
    ON public.restaurants FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.restaurant_owners
            WHERE user_id = auth.uid()
            AND restaurant_id = restaurants.id
            AND status = 'active'
            AND (permissions->>'manage_settings')::boolean = true
        )
    );

-- Everyone can view active restaurants (existing policy should remain)
-- This is already covered by existing RLS, just documenting

-- ========================================
-- Menu Items RLS Policies (Update)
-- ========================================

-- Owners can manage menu items for their restaurants
DROP POLICY IF EXISTS "Owners can manage menu items" ON public.menu_items;
CREATE POLICY "Owners can manage menu items"
    ON public.menu_items FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.restaurant_owners
            WHERE user_id = auth.uid()
            AND restaurant_id = menu_items.restaurant_id
            AND status = 'active'
            AND (permissions->>'manage_menu')::boolean = true
        )
    );

-- Staff with permissions can view menu items
CREATE POLICY "Staff can view menu items"
    ON public.menu_items FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.restaurant_staff
            WHERE user_id = auth.uid()
            AND restaurant_id = menu_items.restaurant_id
            AND status = 'active'
            AND (permissions->>'view_menu')::boolean = true
        )
    );

-- ========================================
-- Orders RLS Policies (Update)
-- ========================================

-- Owners can view orders for their restaurants
DROP POLICY IF EXISTS "Owners can view restaurant orders" ON public.orders;
CREATE POLICY "Owners can view restaurant orders"
    ON public.orders FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.restaurant_owners
            WHERE user_id = auth.uid()
            AND restaurant_id = orders.restaurant_id
            AND status = 'active'
        )
    );

-- Owners can update orders
DROP POLICY IF EXISTS "Owners can update restaurant orders" ON public.orders;
CREATE POLICY "Owners can update restaurant orders"
    ON public.orders FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.restaurant_owners
            WHERE user_id = auth.uid()
            AND restaurant_id = orders.restaurant_id
            AND status = 'active'
            AND (permissions->>'manage_orders')::boolean = true
        )
    );

-- Staff can view orders
CREATE POLICY "Staff can view restaurant orders"
    ON public.orders FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.restaurant_staff
            WHERE user_id = auth.uid()
            AND restaurant_id = orders.restaurant_id
            AND status = 'active'
            AND (permissions->>'view_orders')::boolean = true
        )
    );

-- Staff with permission can update orders
CREATE POLICY "Staff can update orders"
    ON public.orders FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.restaurant_staff
            WHERE user_id = auth.uid()
            AND restaurant_id = orders.restaurant_id
            AND status = 'active'
            AND (permissions->>'update_orders')::boolean = true
        )
    );

-- ========================================
-- Restaurant Analytics RLS Policies
-- ========================================
ALTER TABLE public.restaurant_analytics ENABLE ROW LEVEL SECURITY;

-- Owners with view_analytics permission can view analytics
CREATE POLICY "Owners can view analytics"
    ON public.restaurant_analytics FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.restaurant_owners
            WHERE user_id = auth.uid()
            AND restaurant_id = restaurant_analytics.restaurant_id
            AND status = 'active'
            AND (permissions->>'view_analytics')::boolean = true
        )
    );

-- System can insert/update analytics (service role)
CREATE POLICY "System can manage analytics"
    ON public.restaurant_analytics FOR ALL
    USING (auth.jwt()->>'role' = 'service_role');

-- ========================================
-- Menu Item Analytics RLS Policies
-- ========================================
ALTER TABLE public.menu_item_analytics ENABLE ROW LEVEL SECURITY;

-- Owners can view menu item analytics
CREATE POLICY "Owners can view menu analytics"
    ON public.menu_item_analytics FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.restaurant_owners
            WHERE user_id = auth.uid()
            AND restaurant_id = menu_item_analytics.restaurant_id
            AND status = 'active'
            AND (permissions->>'view_analytics')::boolean = true
        )
    );

-- System can manage menu analytics
CREATE POLICY "System can manage menu analytics"
    ON public.menu_item_analytics FOR ALL
    USING (auth.jwt()->>'role' = 'service_role');

-- Comments
COMMENT ON POLICY "Users can view own roles" ON public.user_roles IS 'Users can see their own role assignments';
COMMENT ON POLICY "Owners can manage menu items" ON public.menu_items IS 'Restaurant owners with permission can manage menu items';
COMMENT ON POLICY "Owners can view restaurant orders" ON public.orders IS 'Restaurant owners can view orders for their restaurants';
