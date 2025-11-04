-- =====================================================
-- NandyFood Database Schema
-- Migration: 025 - Enhanced Analytics System
-- Description: Creates comprehensive analytics tables for advanced reporting
-- =====================================================

-- Analytics Reports Table
CREATE TABLE IF NOT EXISTS public.analytics_reports (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    restaurant_id UUID REFERENCES public.restaurants(id) ON DELETE CASCADE NOT NULL,
    report_name VARCHAR(255) NOT NULL,
    report_type VARCHAR(50) NOT NULL, -- 'daily', 'weekly', 'monthly', 'custom'
    date_range_start DATE NOT NULL,
    date_range_end DATE NOT NULL,
    report_data JSONB NOT NULL,
    generated_at TIMESTAMPTZ DEFAULT NOW(),
    file_url TEXT, -- For stored PDF/Excel reports
    file_format VARCHAR(10), -- 'pdf', 'excel', 'csv'
    is_scheduled BOOLEAN DEFAULT FALSE,
    schedule_frequency VARCHAR(20), -- 'daily', 'weekly', 'monthly'
    created_by UUID REFERENCES public.user_profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Performance Benchmarks Table
CREATE TABLE IF NOT EXISTS public.performance_benchmarks (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    industry VARCHAR(50) NOT NULL, -- 'restaurant', 'fast_food', 'fine_dining', etc.
    cuisine_type VARCHAR(100),
    region VARCHAR(100),
    benchmark_date DATE NOT NULL,

    -- Revenue benchmarks
    avg_daily_revenue DECIMAL(10, 2),
    avg_weekly_revenue DECIMAL(10, 2),
    avg_monthly_revenue DECIMAL(10, 2),
    revenue_growth_rate DECIMAL(5, 2), -- percentage

    -- Order benchmarks
    avg_daily_orders INTEGER,
    avg_order_value DECIMAL(10, 2),
    completion_rate DECIMAL(5, 2), -- percentage
    cancellation_rate DECIMAL(5, 2), -- percentage

    -- Customer benchmarks
    avg_customer_retention_rate DECIMAL(5, 2), -- percentage
    avg_new_customers_per_day INTEGER,
    avg_customer_satisfaction DECIMAL(3, 2),

    -- Performance benchmarks
    avg_prep_time INTEGER, -- in minutes
    avg_response_time INTEGER, -- in minutes

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Predictive Analytics Table
CREATE TABLE IF NOT EXISTS public.predictive_analytics (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    restaurant_id UUID REFERENCES public.restaurants(id) ON DELETE CASCADE NOT NULL,
    prediction_date DATE NOT NULL,
    prediction_type VARCHAR(50) NOT NULL, -- 'demand', 'revenue', 'staffing', 'inventory'
    prediction_horizon INTEGER NOT NULL, -- days into future
    predicted_value DECIMAL(12, 2),
    confidence_score DECIMAL(3, 2), -- 0-1
    prediction_model VARCHAR(100),
    actual_value DECIMAL(12, 2), -- Filled when actual data is available
    accuracy_score DECIMAL(3, 2), -- Calculated later
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Analytics Cache Table for Performance
CREATE TABLE IF NOT EXISTS public.analytics_cache (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    restaurant_id UUID REFERENCES public.restaurants(id) ON DELETE CASCADE NOT NULL,
    cache_key VARCHAR(255) NOT NULL,
    cache_data JSONB NOT NULL,
    date_range_start DATE,
    date_range_end DATE,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(restaurant_id, cache_key)
);

-- Real-time Metrics Table
CREATE TABLE IF NOT EXISTS public.real_time_metrics (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    restaurant_id UUID REFERENCES public.restaurants(id) ON DELETE CASCADE NOT NULL,
    metric_timestamp TIMESTAMPTZ DEFAULT NOW(),

    -- Real-time order metrics
    active_orders INTEGER DEFAULT 0,
    pending_orders INTEGER DEFAULT 0,
    preparing_orders INTEGER DEFAULT 0,
    ready_orders INTEGER DEFAULT 0,

    -- Real-time revenue
    current_day_revenue DECIMAL(10, 2) DEFAULT 0,
    current_hour_revenue DECIMAL(10, 2) DEFAULT 0,
    current_day_orders INTEGER DEFAULT 0,
    current_hour_orders INTEGER DEFAULT 0,

    -- Real-time performance
    current_avg_prep_time INTEGER DEFAULT 0,
    current_avg_response_time INTEGER DEFAULT 0,
    staff_available INTEGER DEFAULT 0,
    queue_length INTEGER DEFAULT 0,

    -- System status
    is_accepting_orders BOOLEAN DEFAULT TRUE,
    kitchen_capacity_utilization DECIMAL(5, 2) DEFAULT 0, -- percentage

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Customer Segmentation Table
CREATE TABLE IF NOT EXISTS public.customer_segments (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    restaurant_id UUID REFERENCES public.restaurants(id) ON DELETE CASCADE NOT NULL,
    customer_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    segment_name VARCHAR(100) NOT NULL, -- 'loyal', 'at_risk', 'new', 'occasional', etc.
    segment_type VARCHAR(50) NOT NULL, -- 'behavioral', 'demographic', 'value_based'
    score DECIMAL(5, 2), -- segment score
    criteria JSONB, -- segmentation criteria
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(restaurant_id, customer_id)
);

-- Menu Performance Analytics
CREATE TABLE IF NOT EXISTS public.menu_performance_analytics (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    restaurant_id UUID REFERENCES public.restaurants(id) ON DELETE CASCADE NOT NULL,
    menu_item_id UUID REFERENCES public.menu_items(id) ON DELETE CASCADE NOT NULL,
    analysis_date DATE NOT NULL,

    -- Performance metrics
    popularity_score DECIMAL(5, 2), -- 0-100 based on orders
    profitability_score DECIMAL(5, 2), -- 0-100 based on profit margin
    trend_indicator VARCHAR(10), -- 'rising', 'stable', 'declining'
    growth_rate DECIMAL(5, 2), -- percentage change

    -- Category performance
    category_ranking INTEGER, -- ranking within category
    overall_ranking INTEGER, -- ranking within all menu items

    -- Recommendations
    recommendation VARCHAR(255), -- 'promote', 'optimize', 'consider_removal'
    reasoning TEXT,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(menu_item_id, analysis_date)
);

-- Staff Performance Analytics
CREATE TABLE IF NOT EXISTS public.staff_performance_analytics (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    restaurant_id UUID REFERENCES public.restaurants(id) ON DELETE CASCADE NOT NULL,
    staff_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE CASCADE,
    performance_date DATE NOT NULL,

    -- Efficiency metrics
    orders_processed INTEGER DEFAULT 0,
    avg_prep_time INTEGER DEFAULT 0, -- in minutes
    avg_order_time INTEGER DEFAULT 0, -- total time from order to completion

    -- Quality metrics
    accuracy_score DECIMAL(5, 2), -- order accuracy percentage
    customer_rating DECIMAL(3, 2),
    customer_complaints INTEGER DEFAULT 0,

    -- Productivity metrics
    revenue_generated DECIMAL(10, 2) DEFAULT 0,
    upsells_completed INTEGER DEFAULT 0,
    peak_hours_efficiency DECIMAL(5, 2), -- performance during peak hours

    -- Availability metrics
    shifts_worked INTEGER DEFAULT 0,
    overtime_hours DECIMAL(5, 2) DEFAULT 0,
    punctuality_score DECIMAL(5, 2), -- percentage

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(staff_id, performance_date)
);

-- Competitive Intelligence Table
CREATE TABLE IF NOT EXISTS public.competitive_intelligence (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    restaurant_id UUID REFERENCES public.restaurants(id) ON DELETE CASCADE NOT NULL,
    competitor_name VARCHAR(255) NOT NULL,
    competitor_location VARCHAR(255),
    data_collection_date DATE NOT NULL,

    -- Pricing intelligence
    avg_item_price DECIMAL(10, 2),
    price_composition_score DECIMAL(5, 2), -- how our prices compare
    value_proposition_score DECIMAL(5, 2),

    -- Market position
    market_share DECIMAL(5, 2), -- estimated local market share
    customer_satisfaction DECIMAL(3, 2),
    review_count INTEGER,

    -- Performance indicators
    estimated_daily_orders INTEGER,
    estimated_revenue DECIMAL(10, 2),
    promotion_frequency VARCHAR(50),

    -- Strengths and weaknesses
    identified_strengths TEXT[],
    identified_weaknesses TEXT[],
    market_opportunities TEXT[],

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Customer Journey Analytics
CREATE TABLE IF NOT EXISTS public.customer_journey_analytics (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    restaurant_id UUID REFERENCES public.restaurants(id) ON DELETE CASCADE NOT NULL,
    customer_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    journey_date DATE NOT NULL,

    -- Touchpoint tracking
    first_visit_time TIMESTAMPTZ,
    first_order_time TIMESTAMPTZ,
    last_visit_time TIMESTAMPTZ,
    last_order_time TIMESTAMPTZ,

    -- Funnel metrics
    viewed_menu INTEGER DEFAULT 0,
    added_to_cart INTEGER DEFAULT 0,
    initiated_checkout INTEGER DEFAULT 0,
    completed_order INTEGER DEFAULT 0,

    -- Behavioral metrics
    session_duration INTEGER DEFAULT 0, -- in minutes
    pages_viewed INTEGER DEFAULT 0,
    bounce_rate DECIMAL(5, 2),
    return_visits INTEGER DEFAULT 0,

    -- Conversion metrics
    conversion_funnel_stage VARCHAR(50), -- 'awareness', 'consideration', 'conversion', 'loyalty'
    abandonment_reason VARCHAR(255), -- if abandoned

    created_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(restaurant_id, customer_id, journey_date)
);

-- Create indexes for performance
CREATE INDEX idx_analytics_reports_restaurant_date ON public.analytics_reports(restaurant_id, generated_at DESC);
CREATE INDEX idx_analytics_reports_type ON public.analytics_reports(report_type, restaurant_id);

CREATE INDEX idx_performance_benchmarks_industry ON public.performance_benchmarks(industry, benchmark_date DESC);
CREATE INDEX idx_performance_benchmarks_region ON public.performance_benchmarks(region, benchmark_date DESC);

CREATE INDEX idx_predictive_analytics_restaurant_type ON public.predictive_analytics(restaurant_id, prediction_type, prediction_date DESC);
CREATE INDEX idx_predictive_analytics_date ON public.predictive_analytics(prediction_date, prediction_type);

CREATE INDEX idx_analytics_cache_restaurant_key ON public.analytics_cache(restaurant_id, cache_key);
CREATE INDEX idx_analytics_cache_expires ON public.analytics_cache(expires_at);

CREATE INDEX idx_real_time_metrics_restaurant_timestamp ON public.real_time_metrics(restaurant_id, metric_timestamp DESC);

CREATE INDEX idx_customer_segments_restaurant_type ON public.customer_segments(restaurant_id, segment_type);
CREATE INDEX idx_customer_segments_score ON public.customer_segments(segment_name, score DESC);

CREATE INDEX idx_menu_performance_item_date ON public.menu_performance_analytics(menu_item_id, analysis_date DESC);
CREATE INDEX idx_menu_performance_restaurant_score ON public.menu_performance_analytics(restaurant_id, popularity_score DESC);

CREATE INDEX idx_staff_performance_staff_date ON public.staff_performance_analytics(staff_id, performance_date DESC);
CREATE INDEX idx_staff_performance_restaurant_date ON public.staff_performance_analytics(restaurant_id, performance_date DESC);

CREATE INDEX idx_competitive_intelligence_restaurant ON public.competitive_intelligence(restaurant_id, data_collection_date DESC);
CREATE INDEX idx_competitive_intelligence_competitor ON public.competitive_intelligence(competitor_name, data_collection_date DESC);

CREATE INDEX idx_customer_journey_restaurant_customer ON public.customer_journey_analytics(restaurant_id, customer_id, journey_date DESC);
CREATE INDEX idx_customer_journey_funnel ON public.customer_journey_analytics(conversion_funnel_stage, journey_date DESC);

-- Add triggers for updated_at columns
CREATE TRIGGER update_analytics_reports_updated_at
    BEFORE UPDATE ON public.analytics_reports
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_performance_benchmarks_updated_at
    BEFORE UPDATE ON public.performance_benchmarks
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_predictive_analytics_updated_at
    BEFORE UPDATE ON public.predictive_analytics
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_customer_segments_updated_at
    BEFORE UPDATE ON public.customer_segments
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_menu_performance_analytics_updated_at
    BEFORE UPDATE ON public.menu_performance_analytics
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_staff_performance_analytics_updated_at
    BEFORE UPDATE ON public.staff_performance_analytics
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_competitive_intelligence_updated_at
    BEFORE UPDATE ON public.competitive_intelligence
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- Enable Row Level Security (RLS)
ALTER TABLE public.analytics_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.predictive_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.analytics_cache ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.real_time_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customer_segments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menu_performance_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.staff_performance_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.competitive_intelligence ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customer_journey_analytics ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Analytics reports policies
CREATE POLICY "Restaurant owners can view their analytics reports" ON public.analytics_reports
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.restaurant_owners
            WHERE user_id = auth.uid()
            AND restaurant_id = public.analytics_reports.restaurant_id
        )
    );

CREATE POLICY "Restaurant owners can create their analytics reports" ON public.analytics_reports
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.restaurant_owners
            WHERE user_id = auth.uid()
            AND restaurant_id = public.analytics_reports.restaurant_id
        )
    );

CREATE POLICY "Restaurant owners can update their analytics reports" ON public.analytics_reports
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.restaurant_owners
            WHERE user_id = auth.uid()
            AND restaurant_id = public.analytics_reports.restaurant_id
        )
    );

CREATE POLICY "Restaurant owners can delete their analytics reports" ON public.analytics_reports
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM public.restaurant_owners
            WHERE user_id = auth.uid()
            AND restaurant_id = public.analytics_reports.restaurant_id
        )
    );

-- Predictive analytics policies
CREATE POLICY "Restaurant owners can view their predictive analytics" ON public.predictive_analytics
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.restaurant_owners
            WHERE user_id = auth.uid()
            AND restaurant_id = public.predictive_analytics.restaurant_id
        )
    );

-- Analytics cache policies
CREATE POLICY "Restaurant owners can manage their analytics cache" ON public.analytics_cache
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.restaurant_owners
            WHERE user_id = auth.uid()
            AND restaurant_id = public.analytics_cache.restaurant_id
        )
    );

-- Real-time metrics policies
CREATE POLICY "Restaurant owners can view their real-time metrics" ON public.real_time_metrics
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.restaurant_owners
            WHERE user_id = auth.uid()
            AND restaurant_id = public.real_time_metrics.restaurant_id
        )
    );

-- Customer segments policies
CREATE POLICY "Restaurant owners can view their customer segments" ON public.customer_segments
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.restaurant_owners
            WHERE user_id = auth.uid()
            AND restaurant_id = public.customer_segments.restaurant_id
        )
    );

-- Menu performance analytics policies
CREATE POLICY "Restaurant owners can view their menu performance analytics" ON public.menu_performance_analytics
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.restaurant_owners
            WHERE user_id = auth.uid()
            AND restaurant_id = public.menu_performance_analytics.restaurant_id
        )
    );

-- Staff performance analytics policies
CREATE POLICY "Restaurant owners can view their staff performance analytics" ON public.staff_performance_analytics
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.restaurant_owners
            WHERE user_id = auth.uid()
            AND restaurant_id = public.staff_performance_analytics.restaurant_id
        )
    );

-- Competitive intelligence policies
CREATE POLICY "Restaurant owners can manage their competitive intelligence" ON public.competitive_intelligence
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.restaurant_owners
            WHERE user_id = auth.uid()
            AND restaurant_id = public.competitive_intelligence.restaurant_id
        )
    );

-- Customer journey analytics policies
CREATE POLICY "Restaurant owners can view their customer journey analytics" ON public.customer_journey_analytics
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.restaurant_owners
            WHERE user_id = auth.uid()
            AND restaurant_id = public.customer_journey_analytics.restaurant_id
        )
    );

-- Performance benchmarks policies (public read access)
CREATE POLICY "Everyone can view performance benchmarks" ON public.performance_benchmarks
    FOR SELECT USING (true);

-- Comments
COMMENT ON TABLE public.analytics_reports IS 'Stores generated analytics reports for restaurants';
COMMENT ON TABLE public.performance_benchmarks IS 'Industry and regional performance benchmarks for comparison';
COMMENT ON TABLE public.predictive_analytics IS 'Stores predictive analytics and forecasts for restaurants';
COMMENT ON TABLE public.analytics_cache IS 'Cache table for analytics queries to improve performance';
COMMENT ON TABLE public.real_time_metrics IS 'Real-time operational metrics for restaurants';
COMMENT ON TABLE public.customer_segments IS 'Customer segmentation data for targeted marketing';
COMMENT ON TABLE public.menu_performance_analytics IS 'Detailed performance analytics for menu items';
COMMENT ON TABLE public.staff_performance_analytics IS 'Performance metrics for restaurant staff members';
COMMENT ON TABLE public.competitive_intelligence IS 'Competitive analysis and market intelligence data';
COMMENT ON TABLE public.customer_journey_analytics IS 'Customer journey and funnel analytics';