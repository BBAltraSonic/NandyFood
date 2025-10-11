-- Migration: Update payment_methods table for Paystack
-- This migration updates the payment_methods table to store Paystack authorization codes
-- instead of Stripe payment method IDs

-- Drop the old Stripe column if it exists
ALTER TABLE payment_methods 
DROP COLUMN IF EXISTS stripe_payment_method_id;

-- Add Paystack-specific columns
ALTER TABLE payment_methods 
ADD COLUMN IF NOT EXISTS paystack_authorization_code TEXT,
ADD COLUMN IF NOT EXISTS card_type TEXT,
ADD COLUMN IF NOT EXISTS last_four TEXT,
ADD COLUMN IF NOT EXISTS expiry_month TEXT,
ADD COLUMN IF NOT EXISTS expiry_year TEXT,
ADD COLUMN IF NOT EXISTS bank TEXT,
ADD COLUMN IF NOT EXISTS country_code TEXT,
ADD COLUMN IF NOT EXISTS is_reusable BOOLEAN DEFAULT true;

-- Add index on authorization code for faster lookups
CREATE INDEX IF NOT EXISTS idx_payment_methods_auth_code 
ON payment_methods(paystack_authorization_code);

-- Add index on user_id for faster user-specific queries
CREATE INDEX IF NOT EXISTS idx_payment_methods_user_id 
ON payment_methods(user_id);

-- Add comments for documentation
COMMENT ON COLUMN payment_methods.paystack_authorization_code IS 'Paystack authorization code for recurring payments';
COMMENT ON COLUMN payment_methods.card_type IS 'Type of card (visa, mastercard, etc.)';
COMMENT ON COLUMN payment_methods.last_four IS 'Last 4 digits of the card';
COMMENT ON COLUMN payment_methods.expiry_month IS 'Card expiry month (MM)';
COMMENT ON COLUMN payment_methods.expiry_year IS 'Card expiry year (YYYY)';
COMMENT ON COLUMN payment_methods.bank IS 'Issuing bank name';
COMMENT ON COLUMN payment_methods.country_code IS 'Country code (NG, GH, ZA, etc.)';
COMMENT ON COLUMN payment_methods.is_reusable IS 'Whether this authorization can be used for future payments';
