-- =====================================================
-- NandyFood Database Schema
-- Migration: 004 - Menu Items Table
-- Description: Creates menu_items table for restaurant menus
-- =====================================================

-- Create menu_items table
CREATE TABLE IF NOT EXISTS public.menu_items (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    restaurant_id UUID REFERENCES public.restaurants(id) ON DELETE CASCADE NOT NULL,
    
    -- Basic information
    name TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL, -- e.g., 'Appetizers', 'Main Course', 'Desserts', 'Beverages'
    
    -- Pricing
    price DECIMAL(10, 2) NOT NULL CHECK (price >= 0),
    original_price DECIMAL(10, 2), -- For displaying discounts
    
    -- Dietary and allergen information
    dietary_tags TEXT[] DEFAULT ARRAY[]::TEXT[], -- e.g., ['vegetarian', 'vegan', 'gluten-free', 'dairy-free']
    allergens TEXT[] DEFAULT ARRAY[]::TEXT[], -- e.g., ['nuts', 'dairy', 'eggs', 'shellfish']
    spice_level INTEGER DEFAULT 0 CHECK (spice_level BETWEEN 0 AND 5), -- 0 = not spicy, 5 = very spicy
    calories INTEGER,
    
    -- Images
    image_url TEXT,
    thumbnail_url TEXT,
    
    -- Customization options (stored as JSONB)
    customization_options JSONB DEFAULT '[]'::jsonb,
    -- Example: [{"name": "Size", "options": ["Small", "Medium", "Large"], "prices": [0, 2, 4]}, ...]
    
    -- Availability
    is_available BOOLEAN DEFAULT TRUE,
    is_featured BOOLEAN DEFAULT FALSE,
    is_popular BOOLEAN DEFAULT FALSE,
    prep_time INTEGER DEFAULT 15, -- in minutes
    
    -- Inventory
    stock_quantity INTEGER, -- NULL means unlimited
    max_quantity_per_order INTEGER DEFAULT 10,
    
    -- Stats
    order_count INTEGER DEFAULT 0,
    rating DECIMAL(3, 2) DEFAULT 0.0 CHECK (rating >= 0 AND rating <= 5),
    review_count INTEGER DEFAULT 0,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb,
    
    -- Constraints
    CONSTRAINT valid_rating CHECK (rating >= 0 AND rating <= 5)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_menu_items_restaurant_id ON public.menu_items(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_menu_items_category ON public.menu_items(restaurant_id, category);
CREATE INDEX IF NOT EXISTS idx_menu_items_is_available ON public.menu_items(restaurant_id, is_available) WHERE is_available = TRUE;
CREATE INDEX IF NOT EXISTS idx_menu_items_is_featured ON public.menu_items(restaurant_id, is_featured) WHERE is_featured = TRUE;
CREATE INDEX IF NOT EXISTS idx_menu_items_is_popular ON public.menu_items(is_popular) WHERE is_popular = TRUE;
CREATE INDEX IF NOT EXISTS idx_menu_items_price ON public.menu_items(price);
CREATE INDEX IF NOT EXISTS idx_menu_items_dietary_tags ON public.menu_items USING gin(dietary_tags);
CREATE INDEX IF NOT EXISTS idx_menu_items_order_count ON public.menu_items(order_count DESC);
CREATE INDEX IF NOT EXISTS idx_menu_items_rating ON public.menu_items(rating DESC);

-- Create full-text search index
CREATE INDEX IF NOT EXISTS idx_menu_items_search ON public.menu_items USING gin(to_tsvector('english', name || ' ' || COALESCE(description, '') || ' ' || category));

-- Create trigger for updated_at
DROP TRIGGER IF EXISTS update_menu_items_updated_at ON public.menu_items;
CREATE TRIGGER update_menu_items_updated_at
    BEFORE UPDATE ON public.menu_items
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- Function to check stock availability
CREATE OR REPLACE FUNCTION public.check_menu_item_stock(
    item_id UUID,
    requested_quantity INTEGER
) RETURNS BOOLEAN AS $$
DECLARE
    current_stock INTEGER;
    max_allowed INTEGER;
BEGIN
    SELECT stock_quantity, max_quantity_per_order
    INTO current_stock, max_allowed
    FROM public.menu_items
    WHERE id = item_id AND is_available = TRUE;
    
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- Check if stock is unlimited (NULL)
    IF current_stock IS NULL THEN
        RETURN requested_quantity <= max_allowed;
    END IF;
    
    -- Check stock availability and max quantity
    RETURN current_stock >= requested_quantity AND requested_quantity <= max_allowed;
END;
$$ LANGUAGE plpgsql;

-- Function to decrease stock after order
CREATE OR REPLACE FUNCTION public.decrease_menu_item_stock(
    item_id UUID,
    quantity INTEGER
) RETURNS VOID AS $$
BEGIN
    UPDATE public.menu_items
    SET 
        stock_quantity = GREATEST(0, COALESCE(stock_quantity, 0) - quantity),
        order_count = order_count + 1
    WHERE id = item_id AND stock_quantity IS NOT NULL;
END;
$$ LANGUAGE plpgsql;

-- Add comments
COMMENT ON TABLE public.menu_items IS 'Stores menu items for each restaurant';
COMMENT ON COLUMN public.menu_items.customization_options IS 'JSON array of customization options with names, choices, and prices';
COMMENT ON COLUMN public.menu_items.stock_quantity IS 'NULL means unlimited stock, otherwise tracks available quantity';
COMMENT ON FUNCTION public.check_menu_item_stock IS 'Validates if requested quantity is available and within limits';
