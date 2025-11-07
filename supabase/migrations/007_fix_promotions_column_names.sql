-- =====================================================
-- NandyFood Database Schema
-- Migration: 007 - Fix Promotions Column Names
-- Description: Renames promotions table columns to match Dart code
-- =====================================================

-- Rename columns to match Dart model expectations
ALTER TABLE public.promotions
RENAME COLUMN starts_at TO start_date;

ALTER TABLE public.promotions
RENAME COLUMN expires_at TO end_date;

-- Update the constraint to use new column names
DROP TRIGGER IF EXISTS update_promotions_updated_at ON public.promotions;
CREATE TRIGGER update_promotions_updated_at
    BEFORE UPDATE ON public.promotions
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- Update indexes to use new column names
DROP INDEX IF EXISTS idx_promotions_active;
CREATE INDEX IF NOT EXISTS idx_promotions_active ON public.promotions(is_active, start_date, end_date);

DROP INDEX IF EXISTS idx_promotions_expires_at;
CREATE INDEX IF NOT EXISTS idx_promotions_end_date ON public.promotions(end_date);

-- Update the validation function to use new column names
CREATE OR REPLACE FUNCTION public.validate_promotion_code(
    promo_code_param TEXT,
    user_id_param UUID,
    order_amount_param DECIMAL,
    restaurant_id_param UUID
) RETURNS TABLE (
    valid BOOLEAN,
    discount_amount DECIMAL,
    message TEXT
) AS $$
DECLARE
    promo_record RECORD;
    user_usage_count INTEGER;
BEGIN
    -- Find active promotion
    SELECT * INTO promo_record
    FROM public.promotions
    WHERE
        code = promo_code_param AND
        is_active = TRUE AND
        NOW() BETWEEN start_date AND end_date;

    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, 0.00::DECIMAL, 'Invalid or expired promotion code';
        RETURN;
    END IF;

    -- Check minimum order amount
    IF order_amount_param < promo_record.min_order_amount THEN
        RETURN QUERY SELECT FALSE, 0.00::DECIMAL,
            'Minimum order amount of $' || promo_record.min_order_amount::TEXT || ' required';
        RETURN;
    END IF;

    -- Check total usage limit
    IF promo_record.total_usage_limit IS NOT NULL AND
       promo_record.current_usage_count >= promo_record.total_usage_limit THEN
        RETURN QUERY SELECT FALSE, 0.00::DECIMAL, 'Promotion code usage limit exceeded';
        RETURN;
    END IF;

    -- Check user usage limit
    SELECT COUNT(*) INTO user_usage_count
    FROM public.promotion_usage
    WHERE promotion_id = promo_record.id AND user_id = user_id_param;

    IF user_usage_count >= promo_record.user_limit THEN
        RETURN QUERY SELECT FALSE, 0.00::DECIMAL, 'You have already used this promotion code';
        RETURN;
    END IF;

    -- Calculate discount
    DECLARE
        calculated_discount DECIMAL;
    BEGIN
        CASE promo_record.discount_type
            WHEN 'percentage' THEN
                calculated_discount := (order_amount_param * promo_record.discount_value / 100);
                IF promo_record.max_discount IS NOT NULL THEN
                    calculated_discount := LEAST(calculated_discount, promo_record.max_discount);
                END IF;
            WHEN 'fixed_amount' THEN
                calculated_discount := promo_record.discount_value;
            WHEN 'free_delivery' THEN
                -- Will be handled by application logic
                calculated_discount := 0;
        END CASE;

        RETURN QUERY SELECT TRUE, calculated_discount, 'Promotion code applied successfully';
    END;
END;
$$ LANGUAGE plpgsql;

-- Update the constraint to use new column names
ALTER TABLE public.promotions
DROP CONSTRAINT IF EXISTS valid_promo_dates;

ALTER TABLE public.promotions
ADD CONSTRAINT valid_promo_dates CHECK (end_date > start_date);

-- Add comment
COMMENT ON COLUMN public.promotions.start_date IS 'Start date/time when promotion becomes active';
COMMENT ON COLUMN public.promotions.end_date IS 'End date/time when promotion expires';