-- =====================================================
-- NandyFood Database Schema
-- Migration: 026 - Analytics Database Functions
-- Description: Creates SQL functions for enhanced analytics queries
-- =====================================================

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Function to get comprehensive revenue analytics
CREATE OR REPLACE FUNCTION get_revenue_analytics(
    p_restaurant_id UUID,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE(
    total_revenue DECIMAL,
    gross_revenue DECIMAL,
    net_revenue DECIMAL,
    target_revenue DECIMAL,
    revenue_growth_rate DECIMAL,
    average_order_value DECIMAL,
    revenue_per_customer DECIMAL,
    total_orders BIGINT,
    unique_customers BIGINT
) AS $$
BEGIN
    RETURN QUERY
    WITH
    order_data AS (
        SELECT
            o.id,
            o.total_amount,
            o.platform_fee,
            o.delivery_fee,
            o.status,
            o.customer_id,
            o.created_at,
            COALESCE(o.total_amount - o.platform_fee - COALESCE(o.delivery_fee, 0), 0) as net_amount
        FROM orders o
        WHERE o.restaurant_id = p_restaurant_id
        AND o.created_at::date >= p_start_date
        AND o.created_at::date <= p_end_date
        AND o.status NOT IN ('cancelled', 'rejected')
    ),
    previous_period_data AS (
        SELECT
            COALESCE(SUM(total_amount), 0) as prev_revenue,
            COUNT(*) as prev_orders
        FROM orders o
        WHERE o.restaurant_id = p_restaurant_id
        AND o.created_at::date >= p_start_date - INTERVAL '30 days'
        AND o.created_at::date < p_start_date
        AND o.status NOT IN ('cancelled', 'rejected')
    ),
    current_period AS (
        SELECT
            COALESCE(SUM(total_amount), 0) as total_revenue,
            COALESCE(SUM(total_amount), 0) as gross_revenue,
            COALESCE(SUM(net_amount), 0) as net_revenue,
            COUNT(*) as total_orders,
            COUNT(DISTINCT customer_id) as unique_customers,
            COALESCE(AVG(total_amount), 0) as average_order_value
        FROM order_data
    ),
    target_data AS (
        SELECT COALESCE(target_daily_revenue * (p_end_date - p_start_date + 1), 0) as target_revenue
        FROM restaurants
        WHERE id = p_restaurant_id
    )
    SELECT
        cp.total_revenue,
        cp.gross_revenue,
        cp.net_revenue,
        td.target_revenue,
        CASE
            WHEN ppd.prev_revenue > 0
            THEN ((cp.total_revenue - ppd.prev_revenue) / ppd.prev_revenue) * 100
            ELSE 0
        END as revenue_growth_rate,
        cp.average_order_value,
        CASE
            WHEN cp.unique_customers > 0
            THEN cp.total_revenue / cp.unique_customers
            ELSE 0
        END as revenue_per_customer,
        cp.total_orders,
        cp.unique_customers
    FROM current_period cp
    CROSS JOIN previous_period_data ppd
    CROSS JOIN target_data td;
END;
$$ LANGUAGE plpgsql;

-- Function to get daily revenue data
CREATE OR REPLACE FUNCTION get_daily_revenue_data(
    p_restaurant_id UUID,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE(
    date DATE,
    revenue DECIMAL,
    orders BIGINT,
    avg_order_value DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        o.created_at::date as date,
        COALESCE(SUM(o.total_amount), 0) as revenue,
        COUNT(*) as orders,
        COALESCE(AVG(o.total_amount), 0) as avg_order_value
    FROM orders o
    WHERE o.restaurant_id = p_restaurant_id
    AND o.created_at::date >= p_start_date
    AND o.created_at::date <= p_end_date
    AND o.status NOT IN ('cancelled', 'rejected')
    GROUP BY o.created_at::date
    ORDER BY date;
END;
$$ LANGUAGE plpgsql;

-- Function to get weekly revenue data
CREATE OR REPLACE FUNCTION get_weekly_revenue_data(
    p_restaurant_id UUID,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE(
    week_start DATE,
    week_end DATE,
    revenue DECIMAL,
    orders BIGINT,
    week_number INTEGER,
    year INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        date_trunc('week', o.created_at)::date as week_start,
        (date_trunc('week', o.created_at)::date + INTERVAL '6 days')::date as week_end,
        COALESCE(SUM(o.total_amount), 0) as revenue,
        COUNT(*) as orders,
        EXTRACT(WEEK FROM o.created_at)::INTEGER as week_number,
        EXTRACT(YEAR FROM o.created_at)::INTEGER as year
    FROM orders o
    WHERE o.restaurant_id = p_restaurant_id
    AND o.created_at::date >= p_start_date
    AND o.created_at::date <= p_end_date
    AND o.status NOT IN ('cancelled', 'rejected')
    GROUP BY date_trunc('week', o.created_at), EXTRACT(WEEK FROM o.created_at), EXTRACT(YEAR FROM o.created_at)
    ORDER BY week_start;
END;
$$ LANGUAGE plpgsql;

-- Function to get monthly revenue data
CREATE OR REPLACE FUNCTION get_monthly_revenue_data(
    p_restaurant_id UUID,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE(
    month_start DATE,
    month_end DATE,
    revenue DECIMAL,
    orders BIGINT,
    month INTEGER,
    year INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        date_trunc('month', o.created_at)::date as month_start,
        (date_trunc('month', o.created_at)::date + INTERVAL '1 month - 1 day')::date as month_end,
        COALESCE(SUM(o.total_amount), 0) as revenue,
        COUNT(*) as orders,
        EXTRACT(MONTH FROM o.created_at)::INTEGER as month,
        EXTRACT(YEAR FROM o.created_at)::INTEGER as year
    FROM orders o
    WHERE o.restaurant_id = p_restaurant_id
    AND o.created_at::date >= p_start_date
    AND o.created_at::date <= p_end_date
    AND o.status NOT IN ('cancelled', 'rejected')
    GROUP BY date_trunc('month', o.created_at), EXTRACT(MONTH FROM o.created_at), EXTRACT(YEAR FROM o.created_at)
    ORDER BY month_start;
END;
$$ LANGUAGE plpgsql;

-- Function to get revenue by category
CREATE OR REPLACE FUNCTION get_revenue_by_category(
    p_restaurant_id UUID,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE(
    category TEXT,
    revenue DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COALESCE(mi.category, 'Uncategorized') as category,
        COALESCE(SUM(oi.quantity * oi.price), 0) as revenue
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.id
    JOIN menu_items mi ON oi.menu_item_id = mi.id
    WHERE o.restaurant_id = p_restaurant_id
    AND o.created_at::date >= p_start_date
    AND o.created_at::date <= p_end_date
    AND o.status NOT IN ('cancelled', 'rejected')
    GROUP BY mi.category
    ORDER BY revenue DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to get revenue by payment method
CREATE OR REPLACE FUNCTION get_revenue_by_payment_method(
    p_restaurant_id UUID,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE(
    payment_method TEXT,
    revenue DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COALESCE(o.payment_method, 'Unknown') as payment_method,
        COALESCE(SUM(o.total_amount), 0) as revenue
    FROM orders o
    WHERE o.restaurant_id = p_restaurant_id
    AND o.created_at::date >= p_start_date
    AND o.created_at::date <= p_end_date
    AND o.status NOT IN ('cancelled', 'rejected')
    GROUP BY o.payment_method
    ORDER BY revenue DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to get revenue by time of day
CREATE OR REPLACE FUNCTION get_revenue_by_time_of_day(
    p_restaurant_id UUID,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE(
    time_slot TEXT,
    revenue DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        CASE
            WHEN EXTRACT(HOUR FROM o.created_at) < 6 THEN 'Late Night (12AM-6AM)'
            WHEN EXTRACT(HOUR FROM o.created_at) < 11 THEN 'Morning (6AM-11AM)'
            WHEN EXTRACT(HOUR FROM o.created_at) < 15 THEN 'Lunch (11AM-3PM)'
            WHEN EXTRACT(HOUR FROM o.created_at) < 19 THEN 'Afternoon (3PM-7PM)'
            ELSE 'Evening (7PM-12AM)'
        END as time_slot,
        COALESCE(SUM(o.total_amount), 0) as revenue
    FROM orders o
    WHERE o.restaurant_id = p_restaurant_id
    AND o.created_at::date >= p_start_date
    AND o.created_at::date <= p_end_date
    AND o.status NOT IN ('cancelled', 'rejected')
    GROUP BY
        CASE
            WHEN EXTRACT(HOUR FROM o.created_at) < 6 THEN 'Late Night (12AM-6AM)'
            WHEN EXTRACT(HOUR FROM o.created_at) < 11 THEN 'Morning (6AM-11AM)'
            WHEN EXTRACT(HOUR FROM o.created_at) < 15 THEN 'Lunch (11AM-3PM)'
            WHEN EXTRACT(HOUR FROM o.created_at) < 19 THEN 'Afternoon (3PM-7PM)'
            ELSE 'Evening (7PM-12AM)'
        END
    ORDER BY revenue DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to get revenue by day of week
CREATE OR REPLACE FUNCTION get_revenue_by_day_of_week(
    p_restaurant_id UUID,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE(
    day_of_week TEXT,
    revenue DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        TO_CHAR(o.created_at, 'Day') as day_of_week,
        COALESCE(SUM(o.total_amount), 0) as revenue
    FROM orders o
    WHERE o.restaurant_id = p_restaurant_id
    AND o.created_at::date >= p_start_date
    AND o.created_at::date <= p_end_date
    AND o.status NOT IN ('cancelled', 'rejected')
    GROUP BY TO_CHAR(o.created_at, 'Day'), EXTRACT(DOW FROM o.created_at)
    ORDER BY EXTRACT(DOW FROM o.created_at);
END;
$$ LANGUAGE plpgsql;

-- Function to get revenue forecast (simplified version)
CREATE OR REPLACE FUNCTION get_revenue_forecast(
    p_restaurant_id UUID,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE(
    next_7_days DECIMAL,
    next_30_days DECIMAL,
    next_90_days DECIMAL,
    confidence_score DECIMAL,
    forecast_model TEXT,
    seasonal_factors JSONB
) AS $$
DECLARE
    daily_avg DECIMAL;
    trend_factor DECIMAL;
    seasonal_data JSONB;
BEGIN
    -- Calculate daily average from recent data
    SELECT COALESCE(SUM(total_amount) / NULLIF(COUNT(*), 0), 0) / NULLIF((p_end_date - p_start_date + 1), 0)
    INTO daily_avg
    FROM orders
    WHERE restaurant_id = p_restaurant_id
    AND created_at::date >= p_start_date
    AND created_at::date <= p_end_date
    AND status NOT IN ('cancelled', 'rejected');

    -- Simple trend calculation (could be enhanced with ML)
    SELECT COALESCE(
        (SELECT AVG(CASE WHEN EXTRACT(DOW FROM created_at) = EXTRACT(DOW FROM CURRENT_DATE)
                        THEN total_amount ELSE 0 END)
         FROM orders
         WHERE restaurant_id = p_restaurant_id
         AND created_at >= CURRENT_DATE - INTERVAL '14 days'
         AND status NOT IN ('cancelled', 'rejected')) / NULLIF(daily_avg, 0), 1.0
    ) INTO trend_factor;

    -- Simple seasonal factors (day of week patterns)
    SELECT jsonb_build_object(
        'weekend_boost', 1.2,
        'weekday_multiplier', 0.9,
        'lunch_rush_boost', 1.15,
        'dinner_rush_boost', 1.25
    ) INTO seasonal_data;

    RETURN QUERY
    SELECT
        daily_avg * 7 * trend_factor as next_7_days,
        daily_avg * 30 * trend_factor as next_30_days,
        daily_avg * 90 * trend_factor as next_90_days,
        0.75 as confidence_score, -- Moderate confidence
        'linear_trend_with_seasonal_adjustment' as forecast_model,
        seasonal_data as seasonal_factors;
END;
$$ LANGUAGE plpgsql;

-- Function to get customer analytics
CREATE OR REPLACE FUNCTION get_customer_analytics(
    p_restaurant_id UUID,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE(
    total_customers BIGINT,
    new_customers BIGINT,
    returning_customers BIGINT,
    active_customers BIGINT,
    customer_retention_rate DECIMAL,
    customer_acquisition_rate DECIMAL,
    churn_rate DECIMAL,
    customer_lifetime_value DECIMAL,
    avg_orders_per_customer DECIMAL,
    avg_days_between_orders DECIMAL,
    customer_satisfaction_score DECIMAL
) AS $$
DECLARE
    previous_start_date DATE;
    previous_customers BIGINT;
BEGIN
    previous_start_date := p_start_date - INTERVAL '30 days';

    -- Get previous period customers for retention calculation
    SELECT COUNT(DISTINCT o.customer_id)
    INTO previous_customers
    FROM orders o
    WHERE o.restaurant_id = p_restaurant_id
    AND o.created_at::date >= previous_start_date
    AND o.created_at::date < p_start_date
    AND o.status NOT IN ('cancelled', 'rejected');

    RETURN QUERY
    WITH
    current_customers AS (
        SELECT DISTINCT customer_id
        FROM orders o
        WHERE o.restaurant_id = p_restaurant_id
        AND o.created_at::date >= p_start_date
        AND o.created_at::date <= p_end_date
        AND o.status NOT IN ('cancelled', 'rejected')
    ),
    previous_period_customers AS (
        SELECT DISTINCT customer_id
        FROM orders o
        WHERE o.restaurant_id = p_restaurant_id
        AND o.created_at::date >= previous_start_date
        AND o.created_at::date < p_start_date
        AND o.status NOT IN ('cancelled', 'rejected')
    ),
    customer_stats AS (
        SELECT
            COUNT(*) as total_customers,
            COUNT(*) FILTER (WHERE customer_id NOT IN (SELECT customer_id FROM previous_period_customers)) as new_customers,
            COUNT(*) FILTER (WHERE customer_id IN (SELECT customer_id FROM previous_period_customers)) as returning_customers,
            COALESCE(AVG(order_count), 0) as avg_orders_per_customer,
            COALESCE(AVG(days_between_orders), 0) as avg_days_between_orders
        FROM (
            SELECT
                o.customer_id,
                COUNT(*) as order_count,
                CASE
                    WHEN COUNT(*) > 1
                    THEN AVG((EXTRACT(EPOCH FROM (o2.created_at - o.created_at)) / 86400))
                    ELSE NULL
                END as days_between_orders
            FROM orders o
            LEFT JOIN orders o2 ON o.customer_id = o2.customer_id AND o2.created_at > o.created_at
            WHERE o.restaurant_id = p_restaurant_id
            AND o.created_at::date >= p_start_date
            AND o.created_at::date <= p_end_date
            AND o.status NOT IN ('cancelled', 'rejected')
            GROUP BY o.customer_id
        ) customer_orders
    ),
    satisfaction_data AS (
        SELECT COALESCE(AVG(rating), 0) as avg_satisfaction
        FROM reviews r
        JOIN orders o ON r.order_id = o.id
        WHERE o.restaurant_id = p_restaurant_id
        AND o.created_at::date >= p_start_date
        AND o.created_at::date <= p_end_date
    )
    SELECT
        cs.total_customers,
        cs.new_customers,
        cs.returning_customers,
        cs.total_customers as active_customers,
        CASE
            WHEN previous_customers > 0
            THEN (cs.returning_customers::DECIMAL / previous_customers) * 100
            ELSE 0
        END as customer_retention_rate,
        CASE
            WHEN cs.total_customers > 0
            THEN (cs.new_customers::DECIMAL / cs.total_customers) * 100
            ELSE 0
        END as customer_acquisition_rate,
        CASE
            WHEN previous_customers > 0
            THEN ((previous_customers - cs.returning_customers)::DECIMAL / previous_customers) * 100
            ELSE 0
        END as churn_rate,
        CASE
            WHEN cs.total_customers > 0
            THEN (SELECT COALESCE(SUM(total_amount), 0) FROM orders WHERE restaurant_id = p_restaurant_id) / cs.total_customers
            ELSE 0
        END as customer_lifetime_value,
        cs.avg_orders_per_customer,
        cs.avg_days_between_orders,
        sd.avg_satisfaction
    FROM customer_stats cs
    CROSS JOIN satisfaction_data sd;
END;
$$ LANGUAGE plpgsql;

-- Function to get conversion funnel
CREATE OR REPLACE FUNCTION get_conversion_funnel(
    p_restaurant_id UUID,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE(
    total_visitors BIGINT,
    menu_viewers BIGINT,
    cart_adders BIGINT,
    checkout_starters BIGINT,
    order_completers BIGINT
) AS $$
BEGIN
    RETURN QUERY
    WITH
    all_visitors AS (
        SELECT COUNT(DISTINCT customer_id) as count
        FROM customer_journey_analytics cja
        WHERE cja.restaurant_id = p_restaurant_id
        AND cja.journey_date >= p_start_date
        AND cja.journey_date <= p_end_date
    ),
    orders_data AS (
        SELECT
            COUNT(DISTINCT o.customer_id) as total_completers,
            COUNT(*) as total_orders
        FROM orders o
        WHERE o.restaurant_id = p_restaurant_id
        AND o.created_at::date >= p_start_date
        AND o.created_at::date <= p_end_date
        AND o.status NOT IN ('cancelled', 'rejected')
    )
    SELECT
        COALESCE(av.count, 0) as total_visitors,
        COALESCE((SELECT COUNT(DISTINCT customer_id) FROM customer_journey_analytics WHERE restaurant_id = p_restaurant_id AND journey_date >= p_start_date AND journey_date <= p_end_date AND viewed_menu > 0), 0) as menu_viewers,
        COALESCE((SELECT COUNT(DISTINCT customer_id) FROM customer_journey_analytics WHERE restaurant_id = p_restaurant_id AND journey_date >= p_start_date AND journey_date <= p_end_date AND added_to_cart > 0), 0) as cart_adders,
        COALESCE((SELECT COUNT(DISTINCT customer_id) FROM customer_journey_analytics WHERE restaurant_id = p_restaurant_id AND journey_date >= p_start_date AND journey_date <= p_end_date AND initiated_checkout > 0), 0) as checkout_starters,
        COALESCE(od.total_completers, 0) as order_completers
    FROM all_visitors av
    CROSS JOIN orders_data od;
END;
$$ LANGUAGE plpgsql;

-- Function to get real-time metrics
CREATE OR REPLACE FUNCTION get_real_time_metrics(
    p_restaurant_id UUID,
    p_hour_start TIMESTAMPTZ,
    p_day_start TIMESTAMPTZ
)
RETURNS TABLE(
    active_orders BIGINT,
    pending_orders BIGINT,
    preparing_orders BIGINT,
    ready_orders BIGINT,
    current_day_revenue DECIMAL,
    current_hour_revenue DECIMAL,
    current_day_orders BIGINT,
    current_hour_orders BIGINT,
    current_avg_prep_time INTEGER,
    current_avg_response_time INTEGER,
    staff_available INTEGER,
    queue_length INTEGER,
    is_accepting_orders BOOLEAN,
    kitchen_capacity_utilization DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    WITH
    order_status_counts AS (
        SELECT
            status,
            COUNT(*) as count
        FROM orders
        WHERE restaurant_id = p_restaurant_id
        AND status IN ('pending', 'confirmed', 'preparing', 'ready_for_pickup')
        GROUP BY status
    ),
    revenue_data AS (
        SELECT
            COALESCE(SUM(CASE WHEN created_at >= p_hour_start THEN total_amount ELSE 0 END), 0) as hour_revenue,
            COALESCE(SUM(CASE WHEN created_at >= p_day_start THEN total_amount ELSE 0 END), 0) as day_revenue,
            COUNT(CASE WHEN created_at >= p_hour_start THEN 1 END) as hour_orders,
            COUNT(CASE WHEN created_at >= p_day_start THEN 1 END) as day_orders
        FROM orders
        WHERE restaurant_id = p_restaurant_id
        AND status NOT IN ('cancelled', 'rejected')
    ),
    performance_data AS (
        SELECT
            COALESCE(AVG(EXTRACT(EPOCH FROM (updated_at - created_at)) / 60), 0) as avg_prep_time,
            COALESCE(AVG(CASE WHEN status = 'confirmed'
                        THEN EXTRACT(EPOCH FROM (updated_at - created_at)) / 60
                        ELSE NULL END), 0) as avg_response_time
        FROM orders
        WHERE restaurant_id = p_restaurant_id
        AND created_at >= p_day_start
        AND status IN ('delivered', 'completed')
    ),
    restaurant_data AS (
        SELECT
            is_accepting_orders,
            max_staff,
            (SELECT COUNT(*) FROM staff_management WHERE restaurant_id = p_restaurant_id AND is_active = true) as active_staff
        FROM restaurants
        WHERE id = p_restaurant_id
    )
    SELECT
        COALESCE((SELECT count FROM order_status_counts WHERE status = 'confirmed'), 0) +
        COALESCE((SELECT count FROM order_status_counts WHERE status = 'preparing'), 0) +
        COALESCE((SELECT count FROM order_status_counts WHERE status = 'ready_for_pickup'), 0) as active_orders,
        COALESCE((SELECT count FROM order_status_counts WHERE status = 'pending'), 0) as pending_orders,
        COALESCE((SELECT count FROM order_status_counts WHERE status = 'preparing'), 0) as preparing_orders,
        COALESCE((SELECT count FROM order_status_counts WHERE status = 'ready_for_pickup'), 0) as ready_orders,
        rd.day_revenue as current_day_revenue,
        rd.hour_revenue as current_hour_revenue,
        rd.day_orders as current_day_orders,
        rd.hour_orders as current_hour_orders,
        COALESCE(pd.avg_prep_time, 0)::INTEGER as current_avg_prep_time,
        COALESCE(pd.avg_response_time, 0)::INTEGER as current_avg_response_time,
        COALESCE(restaurant_data.active_staff, 0) as staff_available,
        COALESCE((SELECT count FROM order_status_counts WHERE status = 'pending'), 0) as queue_length,
        COALESCE(restaurant_data.is_accepting_orders, true) as is_accepting_orders,
        CASE
            WHEN restaurant_data.max_staff > 0
            THEN ((SELECT count FROM order_status_counts WHERE status = 'preparing')::DECIMAL / restaurant_data.max_staff) * 100
            ELSE 0
        END as kitchen_capacity_utilization
    FROM revenue_data rd
    CROSS JOIN performance_data pd
    CROSS JOIN restaurant_data
    LEFT JOIN order_status_counts osc ON true;
END;
$$ LANGUAGE plpgsql;

-- Function to get top performing menu items
CREATE OR REPLACE FUNCTION get_top_performing_menu_items(
    p_restaurant_id UUID,
    p_start_date DATE,
    p_end_date DATE,
    p_limit INTEGER DEFAULT 10
)
RETURNS TABLE(
    id UUID,
    item_name TEXT,
    category TEXT,
    price DECIMAL,
    total_orders BIGINT,
    total_revenue DECIMAL,
    popularity_score DECIMAL,
    profit_margin DECIMAL,
    growth_rate DECIMAL,
    customer_rating DECIMAL,
    times_viewed BIGINT,
    conversion_rate DECIMAL,
    trend_indicator TEXT
) AS $$
BEGIN
    RETURN QUERY
    WITH
    item_performance AS (
        SELECT
            mi.id,
            mi.name as item_name,
            mi.category,
            mi.price,
            COALESCE(SUM(oi.quantity), 0) as total_orders,
            COALESCE(SUM(oi.quantity * oi.price), 0) as total_revenue,
            COALESCE(SUM(oi.quantity * (oi.price - mi.cost_price)), 0) as total_profit,
            COALESCE(mia.times_viewed, 0) as times_viewed
        FROM menu_items mi
        LEFT JOIN order_items oi ON mi.id = oi.menu_item_id
        LEFT JOIN orders o ON oi.order_id = o.id
        LEFT JOIN menu_item_analytics mia ON mi.id = mia.menu_item_id AND mia.date >= p_start_date AND mia.date <= p_end_date
        WHERE mi.restaurant_id = p_restaurant_id
        AND mi.is_available = true
        AND (o.id IS NULL OR (o.created_at::date >= p_start_date AND o.created_at::date <= p_end_date AND o.status NOT IN ('cancelled', 'rejected')))
        GROUP BY mi.id, mi.name, mi.category, mi.price, mi.cost_price, mia.times_viewed
    ),
    previous_period AS (
        SELECT
            mi.id,
            COALESCE(SUM(oi.quantity), 0) as prev_orders,
            COALESCE(SUM(oi.quantity * oi.price), 0) as prev_revenue
        FROM menu_items mi
        LEFT JOIN order_items oi ON mi.id = oi.menu_item_id
        LEFT JOIN orders o ON oi.order_id = o.id
        WHERE mi.restaurant_id = p_restaurant_id
        AND o.created_at::date >= p_start_date - INTERVAL '30 days'
        AND o.created_at::date < p_start_date
        AND o.status NOT IN ('cancelled', 'rejected')
        GROUP BY mi.id
    ),
    item_ratings AS (
        SELECT
            mi.id,
            COALESCE(AVG(r.rating), 0) as avg_rating
        FROM menu_items mi
        LEFT JOIN order_items oi ON mi.id = oi.menu_item_id
        LEFT JOIN orders o ON oi.order_id = o.id
        LEFT JOIN reviews r ON o.id = r.order_id AND r.menu_item_id = mi.id
        WHERE mi.restaurant_id = p_restaurant_id
        AND o.created_at::date >= p_start_date
        AND o.created_at::date <= p_end_date
        GROUP BY mi.id
    )
    SELECT
        ip.id,
        ip.item_name,
        ip.category,
        ip.price,
        ip.total_orders,
        ip.total_revenue,
        -- Popularity score based on orders and revenue
        CASE
            WHEN (SELECT MAX(total_orders) FROM item_performance) > 0
            THEN (ip.total_orders::DECIMAL / (SELECT MAX(total_orders) FROM item_performance)) * 100
            ELSE 0
        END as popularity_score,
        CASE
            WHEN ip.total_revenue > 0
            THEN (ip.total_profit / ip.total_revenue) * 100
            ELSE 0
        END as profit_margin,
        CASE
            WHEN pp.prev_orders > 0
            THEN ((ip.total_orders - pp.prev_orders)::DECIMAL / pp.prev_orders) * 100
            ELSE 0
        END as growth_rate,
        COALESCE(ir.avg_rating, 0) as customer_rating,
        ip.times_viewed,
        CASE
            WHEN ip.times_viewed > 0
            THEN (ip.total_orders::DECIMAL / ip.times_viewed) * 100
            ELSE 0
        END as conversion_rate,
        CASE
            WHEN ip.total_orders > (pp.prev_orders * 1.1)
            THEN 'rising'
            WHEN ip.total_orders < (pp.prev_orders * 0.9)
            THEN 'declining'
            ELSE 'stable'
        END as trend_indicator
    FROM item_performance ip
    LEFT JOIN previous_period pp ON ip.id = pp.id
    LEFT JOIN item_ratings ir ON ip.id = ir.id
    WHERE ip.total_orders > 0
    ORDER BY ip.total_revenue DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- Function to update real-time metrics
CREATE OR REPLACE FUNCTION update_real_time_metrics(
    p_restaurant_id UUID
)
RETURNS VOID AS $$
DECLARE
    now_time TIMESTAMPTZ := NOW();
    hour_start TIMESTAMPTZ;
    day_start TIMESTAMPTZ;
    metrics_data RECORD;
BEGIN
    hour_start := date_trunc('hour', now_time);
    day_start := date_trunc('day', now_time);

    -- Get current metrics
    SELECT * INTO metrics_data
    FROM get_real_time_metrics(p_restaurant_id, hour_start, day_start);

    -- Insert or update real-time metrics
    INSERT INTO real_time_metrics (
        restaurant_id,
        metric_timestamp,
        active_orders,
        pending_orders,
        preparing_orders,
        ready_orders,
        current_day_revenue,
        current_hour_revenue,
        current_day_orders,
        current_hour_orders,
        current_avg_prep_time,
        current_avg_response_time,
        staff_available,
        queue_length,
        is_accepting_orders,
        kitchen_capacity_utilization
    ) VALUES (
        p_restaurant_id,
        now_time,
        metrics_data.active_orders,
        metrics_data.pending_orders,
        metrics_data.preparing_orders,
        metrics_data.ready_orders,
        metrics_data.current_day_revenue,
        metrics_data.current_hour_revenue,
        metrics_data.current_day_orders,
        metrics_data.current_hour_orders,
        metrics_data.current_avg_prep_time,
        metrics_data.current_avg_response_time,
        metrics_data.staff_available,
        metrics_data.queue_length,
        metrics_data.is_accepting_orders,
        metrics_data.kitchen_capacity_utilization
    )
    ON CONFLICT (restaurant_id, metric_timestamp)
    DO UPDATE SET
        active_orders = EXCLUDED.active_orders,
        pending_orders = EXCLUDED.pending_orders,
        preparing_orders = EXCLUDED.preparing_orders,
        ready_orders = EXCLUDED.ready_orders,
        current_day_revenue = EXCLUDED.current_day_revenue,
        current_hour_revenue = EXCLUDED.current_hour_revenue,
        current_day_orders = EXCLUDED.current_day_orders,
        current_hour_orders = EXCLUDED.current_hour_orders,
        current_avg_prep_time = EXCLUDED.current_avg_prep_time,
        current_avg_response_time = EXCLUDED.current_avg_response_time,
        staff_available = EXCLUDED.staff_available,
        queue_length = EXCLUDED.queue_length,
        is_accepting_orders = EXCLUDED.is_accepting_orders,
        kitchen_capacity_utilization = EXCLUDED.kitchen_capacity_utilization;

END;
$$ LANGUAGE plpgsql;

-- Comments
COMMENT ON FUNCTION get_revenue_analytics IS 'Gets comprehensive revenue analytics for a restaurant within a date range';
COMMENT ON FUNCTION get_daily_revenue_data IS 'Gets daily revenue breakdown for analytics charts';
COMMENT ON FUNCTION get_weekly_revenue_data IS 'Gets weekly revenue breakdown for trend analysis';
COMMENT ON FUNCTION get_monthly_revenue_data IS 'Gets monthly revenue breakdown for long-term trends';
COMMENT ON FUNCTION get_revenue_by_category IS 'Gets revenue breakdown by menu category';
COMMENT ON FUNCTION get_revenue_by_payment_method IS 'Gets revenue breakdown by payment method';
COMMENT ON FUNCTION get_revenue_by_time_of_day IS 'Gets revenue breakdown by time of day';
COMMENT ON FUNCTION get_revenue_by_day_of_week IS 'Gets revenue breakdown by day of week';
COMMENT ON FUNCTION get_revenue_forecast IS 'Generates revenue forecast using historical data';
COMMENT ON FUNCTION get_customer_analytics IS 'Gets comprehensive customer analytics and metrics';
COMMENT ON FUNCTION get_conversion_funnel IS 'Gets customer conversion funnel data';
COMMENT ON FUNCTION get_real_time_metrics IS 'Gets real-time operational metrics for a restaurant';
COMMENT ON FUNCTION get_top_performing_menu_items IS 'Gets top performing menu items with detailed metrics';
COMMENT ON FUNCTION update_real_time_metrics IS 'Updates real-time metrics table with current data';