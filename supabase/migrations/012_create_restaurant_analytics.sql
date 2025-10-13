-- =====================================================
-- NandyFood Database Schema
-- Migration: 012 - Restaurant Analytics System
-- Description: Creates analytics and metrics tables
-- =====================================================

-- Restaurant Analytics Table (Daily Metrics)
CREATE TABLE IF NOT EXISTS public.restaurant_analytics (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    restaurant_id UUID REFERENCES public.restaurants(id) ON DELETE CASCADE NOT NULL,
    date DATE NOT NULL,
    
    -- Order metrics
    total_orders INTEGER DEFAULT 0,
    completed_orders INTEGER DEFAULT 0,
    cancelled_orders INTEGER DEFAULT 0,
    rejected_orders INTEGER DEFAULT 0,
    
    -- Revenue metrics
    total_revenue DECIMAL(10, 2) DEFAULT 0,
    average_order_value DECIMAL(10, 2) DEFAULT 0,
    highest_order_value DECIMAL(10, 2) DEFAULT 0,
    lowest_order_value DECIMAL(10, 2) DEFAULT 0,
    
    -- Customer metrics
    new_customers INTEGER DEFAULT 0,
    returning_customers INTEGER DEFAULT 0,
    unique_customers INTEGER DEFAULT 0,
    
    -- Performance metrics
    average_prep_time INTEGER DEFAULT 0, -- in minutes
    average_delivery_time INTEGER DEFAULT 0, -- in minutes
    average_response_time INTEGER DEFAULT 0, -- time to accept order in minutes
    
    -- Satisfaction metrics
    customer_satisfaction_score DECIMAL(3, 2),
    total_reviews INTEGER DEFAULT 0,
    average_rating DECIMAL(3, 2),
    
    -- Additional metadata
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Each restaurant can only have one analytics record per day
    UNIQUE(restaurant_id, date)
);

-- Create indexes
CREATE INDEX idx_restaurant_analytics_restaurant_id ON public.restaurant_analytics(restaurant_id);
CREATE INDEX idx_restaurant_analytics_date ON public.restaurant_analytics(date DESC);
CREATE INDEX idx_restaurant_analytics_restaurant_date ON public.restaurant_analytics(restaurant_id, date DESC);

-- Restaurant Menu Item Analytics
CREATE TABLE IF NOT EXISTS public.menu_item_analytics (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    restaurant_id UUID REFERENCES public.restaurants(id) ON DELETE CASCADE NOT NULL,
    menu_item_id UUID REFERENCES public.menu_items(id) ON DELETE CASCADE NOT NULL,
    date DATE NOT NULL,
    
    times_ordered INTEGER DEFAULT 0,
    total_revenue DECIMAL(10, 2) DEFAULT 0,
    times_viewed INTEGER DEFAULT 0,
    conversion_rate DECIMAL(5, 2), -- percentage
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(menu_item_id, date)
);

CREATE INDEX idx_menu_item_analytics_restaurant ON public.menu_item_analytics(restaurant_id);
CREATE INDEX idx_menu_item_analytics_item ON public.menu_item_analytics(menu_item_id);
CREATE INDEX idx_menu_item_analytics_date ON public.menu_item_analytics(date DESC);

-- Add triggers for updated_at
DROP TRIGGER IF EXISTS update_restaurant_analytics_updated_at ON public.restaurant_analytics;
CREATE TRIGGER update_restaurant_analytics_updated_at
    BEFORE UPDATE ON public.restaurant_analytics
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_menu_item_analytics_updated_at ON public.menu_item_analytics;
CREATE TRIGGER update_menu_item_analytics_updated_at
    BEFORE UPDATE ON public.menu_item_analytics
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- Comments
COMMENT ON TABLE public.restaurant_analytics IS 'Stores daily analytics and metrics for restaurants';
COMMENT ON TABLE public.menu_item_analytics IS 'Stores daily analytics for individual menu items';
COMMENT ON COLUMN public.restaurant_analytics.date IS 'The date for which these metrics apply';
COMMENT ON COLUMN public.restaurant_analytics.customer_satisfaction_score IS 'Overall satisfaction score for the day';
