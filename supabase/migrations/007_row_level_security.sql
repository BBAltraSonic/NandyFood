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
