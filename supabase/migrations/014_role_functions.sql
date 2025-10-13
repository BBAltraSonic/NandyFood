-- =====================================================
-- NandyFood Database Schema
-- Migration: 014 - Database Functions and Triggers
-- Description: Functions for role management and analytics
-- =====================================================

-- ========================================
-- Function: Assign default consumer role on signup
-- ========================================
CREATE OR REPLACE FUNCTION public.assign_default_consumer_role()
RETURNS TRIGGER AS $$
BEGIN
    -- Insert consumer role for new user
    INSERT INTO public.user_roles (user_id, role, is_primary)
    VALUES (NEW.id, 'consumer', TRUE)
    ON CONFLICT (user_id, role) DO NOTHING;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger if any
DROP TRIGGER IF EXISTS on_user_created_assign_role ON auth.users;

-- Create trigger for automatic role assignment
CREATE TRIGGER on_user_created_assign_role
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.assign_default_consumer_role();

COMMENT ON FUNCTION public.assign_default_consumer_role IS 'Automatically assigns consumer role to new users';

-- ========================================
-- Function: Sync primary role to user_profiles
-- ========================================
CREATE OR REPLACE FUNCTION public.sync_primary_role()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_primary = TRUE THEN
        -- Update user_profiles with new primary role
        UPDATE public.user_profiles
        SET primary_role = NEW.role,
            updated_at = NOW()
        WHERE id = NEW.user_id;
        
        -- Set all other roles for this user to non-primary
        UPDATE public.user_roles
        SET is_primary = FALSE
        WHERE user_id = NEW.user_id
        AND id != NEW.id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for primary role sync
DROP TRIGGER IF EXISTS on_role_primary_change ON public.user_roles;
CREATE TRIGGER on_role_primary_change
    AFTER INSERT OR UPDATE OF is_primary ON public.user_roles
    FOR EACH ROW
    WHEN (NEW.is_primary = TRUE)
    EXECUTE FUNCTION public.sync_primary_role();

COMMENT ON FUNCTION public.sync_primary_role IS 'Syncs primary role changes to user_profiles table';

-- ========================================
-- Function: Check if user has specific permission
-- ========================================
CREATE OR REPLACE FUNCTION public.user_has_permission(
    p_user_id UUID,
    p_restaurant_id UUID,
    p_permission TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
    has_perm BOOLEAN := FALSE;
BEGIN
    -- Check in restaurant_owners table
    SELECT 
        COALESCE((permissions->>p_permission)::BOOLEAN, FALSE)
    INTO has_perm
    FROM public.restaurant_owners
    WHERE user_id = p_user_id
    AND restaurant_id = p_restaurant_id
    AND status = 'active';
    
    -- If not found, check in restaurant_staff table
    IF has_perm IS NULL OR has_perm = FALSE THEN
        SELECT 
            COALESCE((permissions->>p_permission)::BOOLEAN, FALSE)
        INTO has_perm
        FROM public.restaurant_staff
        WHERE user_id = p_user_id
        AND restaurant_id = p_restaurant_id
        AND status = 'active';
    END IF;
    
    RETURN COALESCE(has_perm, FALSE);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.user_has_permission IS 'Checks if a user has a specific permission for a restaurant';

-- ========================================
-- Function: Get all user permissions for a restaurant
-- ========================================
CREATE OR REPLACE FUNCTION public.get_user_restaurant_permissions(
    p_user_id UUID,
    p_restaurant_id UUID
)
RETURNS JSONB AS $$
DECLARE
    perms JSONB;
BEGIN
    -- First check restaurant_owners
    SELECT permissions INTO perms
    FROM public.restaurant_owners
    WHERE user_id = p_user_id
    AND restaurant_id = p_restaurant_id
    AND status = 'active';
    
    -- If not found, check restaurant_staff
    IF perms IS NULL THEN
        SELECT permissions INTO perms
        FROM public.restaurant_staff
        WHERE user_id = p_user_id
        AND restaurant_id = p_restaurant_id
        AND status = 'active';
    END IF;
    
    RETURN COALESCE(perms, '{}'::jsonb);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.get_user_restaurant_permissions IS 'Returns all permissions for a user in a specific restaurant';

-- ========================================
-- Function: Calculate daily restaurant analytics
-- ========================================
CREATE OR REPLACE FUNCTION public.calculate_daily_restaurant_analytics(
    p_restaurant_id UUID,
    p_date DATE DEFAULT CURRENT_DATE
)
RETURNS void AS $$
DECLARE
    v_total_orders INTEGER;
    v_completed_orders INTEGER;
    v_cancelled_orders INTEGER;
    v_rejected_orders INTEGER;
    v_total_revenue DECIMAL(10, 2);
    v_avg_order_value DECIMAL(10, 2);
    v_highest_order DECIMAL(10, 2);
    v_lowest_order DECIMAL(10, 2);
    v_new_customers INTEGER;
    v_returning_customers INTEGER;
    v_unique_customers INTEGER;
BEGIN
    -- Calculate order metrics
    SELECT
        COUNT(*) as total_orders,
        COUNT(*) FILTER (WHERE status = 'completed') as completed_orders,
        COUNT(*) FILTER (WHERE status = 'cancelled') as cancelled_orders,
        COUNT(*) FILTER (WHERE status = 'rejected') as rejected_orders,
        COALESCE(SUM(total_amount) FILTER (WHERE status = 'completed'), 0) as total_revenue,
        COALESCE(AVG(total_amount) FILTER (WHERE status = 'completed'), 0) as avg_order_value,
        COALESCE(MAX(total_amount) FILTER (WHERE status = 'completed'), 0) as highest_order,
        COALESCE(MIN(total_amount) FILTER (WHERE status = 'completed'), 0) as lowest_order,
        COUNT(DISTINCT user_id) as unique_customers
    INTO
        v_total_orders,
        v_completed_orders,
        v_cancelled_orders,
        v_rejected_orders,
        v_total_revenue,
        v_avg_order_value,
        v_highest_order,
        v_lowest_order,
        v_unique_customers
    FROM public.orders
    WHERE restaurant_id = p_restaurant_id
    AND DATE(created_at) = p_date;
    
    -- Calculate new vs returning customers
    SELECT
        COUNT(DISTINCT user_id) FILTER (
            WHERE NOT EXISTS (
                SELECT 1 FROM public.orders o2
                WHERE o2.user_id = orders.user_id
                AND o2.restaurant_id = p_restaurant_id
                AND DATE(o2.created_at) < p_date
            )
        ) as new_customers,
        COUNT(DISTINCT user_id) FILTER (
            WHERE EXISTS (
                SELECT 1 FROM public.orders o2
                WHERE o2.user_id = orders.user_id
                AND o2.restaurant_id = p_restaurant_id
                AND DATE(o2.created_at) < p_date
            )
        ) as returning_customers
    INTO v_new_customers, v_returning_customers
    FROM public.orders
    WHERE restaurant_id = p_restaurant_id
    AND DATE(created_at) = p_date;
    
    -- Insert or update analytics record
    INSERT INTO public.restaurant_analytics (
        restaurant_id,
        date,
        total_orders,
        completed_orders,
        cancelled_orders,
        rejected_orders,
        total_revenue,
        average_order_value,
        highest_order_value,
        lowest_order_value,
        new_customers,
        returning_customers,
        unique_customers
    )
    VALUES (
        p_restaurant_id,
        p_date,
        v_total_orders,
        v_completed_orders,
        v_cancelled_orders,
        v_rejected_orders,
        v_total_revenue,
        v_avg_order_value,
        v_highest_order,
        v_lowest_order,
        v_new_customers,
        v_returning_customers,
        v_unique_customers
    )
    ON CONFLICT (restaurant_id, date)
    DO UPDATE SET
        total_orders = EXCLUDED.total_orders,
        completed_orders = EXCLUDED.completed_orders,
        cancelled_orders = EXCLUDED.cancelled_orders,
        rejected_orders = EXCLUDED.rejected_orders,
        total_revenue = EXCLUDED.total_revenue,
        average_order_value = EXCLUDED.average_order_value,
        highest_order_value = EXCLUDED.highest_order_value,
        lowest_order_value = EXCLUDED.lowest_order_value,
        new_customers = EXCLUDED.new_customers,
        returning_customers = EXCLUDED.returning_customers,
        unique_customers = EXCLUDED.unique_customers,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION public.calculate_daily_restaurant_analytics IS 'Calculates and stores daily analytics for a restaurant';

-- ========================================
-- Function: Get restaurant dashboard metrics
-- ========================================
CREATE OR REPLACE FUNCTION public.get_restaurant_dashboard_metrics(
    p_restaurant_id UUID
)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'today_orders', (
            SELECT COUNT(*) FROM public.orders
            WHERE restaurant_id = p_restaurant_id
            AND DATE(created_at) = CURRENT_DATE
        ),
        'today_revenue', (
            SELECT COALESCE(SUM(total_amount), 0) FROM public.orders
            WHERE restaurant_id = p_restaurant_id
            AND DATE(created_at) = CURRENT_DATE
            AND status = 'completed'
        ),
        'pending_orders', (
            SELECT COUNT(*) FROM public.orders
            WHERE restaurant_id = p_restaurant_id
            AND status = 'pending'
        ),
        'avg_order_value', (
            SELECT COALESCE(AVG(total_amount), 0) FROM public.orders
            WHERE restaurant_id = p_restaurant_id
            AND DATE(created_at) = CURRENT_DATE
            AND status = 'completed'
        ),
        'active_menu_items', (
            SELECT COUNT(*) FROM public.menu_items
            WHERE restaurant_id = p_restaurant_id
            AND is_available = true
        ),
        'restaurant_rating', (
            SELECT COALESCE(rating, 0) FROM public.restaurants
            WHERE id = p_restaurant_id
        ),
        'total_reviews', (
            SELECT COALESCE(total_reviews, 0) FROM public.restaurants
            WHERE id = p_restaurant_id
        ),
        'is_accepting_orders', (
            SELECT COALESCE(is_accepting_orders, false) FROM public.restaurants
            WHERE id = p_restaurant_id
        )
    ) INTO result;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.get_restaurant_dashboard_metrics IS 'Returns dashboard metrics for a restaurant';

-- ========================================
-- Function: Get restaurant owned by user
-- ========================================
CREATE OR REPLACE FUNCTION public.get_user_restaurants(
    p_user_id UUID
)
RETURNS TABLE (
    restaurant_id UUID,
    restaurant_name TEXT,
    owner_type TEXT,
    status TEXT,
    permissions JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ro.restaurant_id,
        r.name,
        ro.owner_type,
        ro.status,
        ro.permissions
    FROM public.restaurant_owners ro
    JOIN public.restaurants r ON r.id = ro.restaurant_id
    WHERE ro.user_id = p_user_id
    AND ro.status = 'active'
    ORDER BY 
        CASE ro.owner_type
            WHEN 'primary' THEN 1
            WHEN 'co-owner' THEN 2
            WHEN 'manager' THEN 3
        END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.get_user_restaurants IS 'Returns all restaurants owned/managed by a user';

-- ========================================
-- Function: Update order status with notification
-- ========================================
CREATE OR REPLACE FUNCTION public.update_order_status_with_notification()
RETURNS TRIGGER AS $$
BEGIN
    -- If order status changed to 'accepted', calculate estimated delivery time
    IF NEW.status = 'accepted' AND OLD.status = 'pending' THEN
        NEW.estimated_delivery_time = NOW() + (
            SELECT (estimated_delivery_time || ' minutes')::INTERVAL
            FROM public.restaurants
            WHERE id = NEW.restaurant_id
        );
    END IF;
    
    -- You can add notification logic here or trigger it from application
    -- For now, just return the new row
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS order_status_change_trigger ON public.orders;
CREATE TRIGGER order_status_change_trigger
    BEFORE UPDATE OF status ON public.orders
    FOR EACH ROW
    WHEN (OLD.status IS DISTINCT FROM NEW.status)
    EXECUTE FUNCTION public.update_order_status_with_notification();

COMMENT ON FUNCTION public.update_order_status_with_notification IS 'Handles order status changes and notifications';

-- ========================================
-- Create view for restaurant performance
-- ========================================
CREATE OR REPLACE VIEW public.restaurant_performance AS
SELECT
    r.id as restaurant_id,
    r.name as restaurant_name,
    r.rating,
    r.total_reviews,
    COALESCE(ra.total_orders, 0) as today_orders,
    COALESCE(ra.completed_orders, 0) as today_completed,
    COALESCE(ra.total_revenue, 0) as today_revenue,
    COALESCE(ra.average_order_value, 0) as today_avg_order_value,
    r.is_accepting_orders,
    r.is_active
FROM public.restaurants r
LEFT JOIN public.restaurant_analytics ra ON ra.restaurant_id = r.id AND ra.date = CURRENT_DATE;

COMMENT ON VIEW public.restaurant_performance IS 'Consolidated view of restaurant performance metrics';

-- Grant necessary permissions for service role
GRANT EXECUTE ON FUNCTION public.assign_default_consumer_role() TO service_role;
GRANT EXECUTE ON FUNCTION public.sync_primary_role() TO service_role;
GRANT EXECUTE ON FUNCTION public.user_has_permission(UUID, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_restaurant_permissions(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.calculate_daily_restaurant_analytics(UUID, DATE) TO service_role;
GRANT EXECUTE ON FUNCTION public.get_restaurant_dashboard_metrics(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_restaurants(UUID) TO authenticated;
