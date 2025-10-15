-- Migration: PayFast Payment Integration
-- Created: 2025-01-14
-- Description: Adds PayFast-specific tables and updates existing payment structures

-- =====================================================
-- 1. UPDATE ORDERS TABLE
-- =====================================================
-- Add PayFast-specific columns to orders table
ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS payfast_transaction_id TEXT,
ADD COLUMN IF NOT EXISTS payfast_signature TEXT,
ADD COLUMN IF NOT EXISTS payment_gateway TEXT DEFAULT 'cash',
ADD COLUMN IF NOT EXISTS payment_reference TEXT;

-- Create index for payment reference lookups
CREATE INDEX IF NOT EXISTS idx_orders_payment_reference 
ON orders(payment_reference);

-- Add comments
COMMENT ON COLUMN orders.payfast_transaction_id IS 'PayFast transaction ID for tracking';
COMMENT ON COLUMN orders.payfast_signature IS 'PayFast signature for verification';
COMMENT ON COLUMN orders.payment_gateway IS 'Payment gateway used (cash, payfast)';
COMMENT ON COLUMN orders.payment_reference IS 'Unique payment reference ID';

-- =====================================================
-- 2. UPDATE PAYMENT_METHODS TABLE
-- =====================================================
-- Drop old Paystack columns if they exist
ALTER TABLE payment_methods 
DROP COLUMN IF EXISTS paystack_authorization_code CASCADE;

-- Add PayFast columns
ALTER TABLE payment_methods 
ADD COLUMN IF NOT EXISTS payfast_token TEXT,
ADD COLUMN IF NOT EXISTS payment_gateway TEXT DEFAULT 'cash';

-- Update existing payment methods table structure
COMMENT ON COLUMN payment_methods.payfast_token IS 'PayFast token for saved payment methods';
COMMENT ON COLUMN payment_methods.payment_gateway IS 'Payment gateway identifier';

-- =====================================================
-- 3. CREATE PAYMENT_TRANSACTIONS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS payment_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id TEXT NOT NULL,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    amount DECIMAL(10, 2) NOT NULL,
    payment_method TEXT NOT NULL DEFAULT 'cash',
    payment_reference TEXT UNIQUE,
    payment_gateway TEXT DEFAULT 'cash',
    status TEXT NOT NULL DEFAULT 'pending',
    metadata JSONB,
    payment_response JSONB,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT valid_status CHECK (status IN ('pending', 'completed', 'failed', 'cancelled', 'refunded')),
    CONSTRAINT valid_payment_method CHECK (payment_method IN ('cash', 'payfast', 'card')),
    CONSTRAINT valid_amount CHECK (amount > 0)
);

-- Create indexes for payment transactions
CREATE INDEX IF NOT EXISTS idx_payment_transactions_order_id 
ON payment_transactions(order_id);

CREATE INDEX IF NOT EXISTS idx_payment_transactions_user_id 
ON payment_transactions(user_id);

CREATE INDEX IF NOT EXISTS idx_payment_transactions_reference 
ON payment_transactions(payment_reference);

CREATE INDEX IF NOT EXISTS idx_payment_transactions_status 
ON payment_transactions(status);

CREATE INDEX IF NOT EXISTS idx_payment_transactions_created_at 
ON payment_transactions(created_at DESC);

-- Add comments
COMMENT ON TABLE payment_transactions IS 'Payment transaction records for all payment methods';
COMMENT ON COLUMN payment_transactions.order_id IS 'Associated order ID';
COMMENT ON COLUMN payment_transactions.payment_reference IS 'Unique payment reference for tracking';
COMMENT ON COLUMN payment_transactions.payment_gateway IS 'Gateway used (cash, payfast)';
COMMENT ON COLUMN payment_transactions.metadata IS 'Additional payment initialization data';
COMMENT ON COLUMN payment_transactions.payment_response IS 'Gateway response data';

-- =====================================================
-- 4. CREATE PAYMENT_WEBHOOK_LOGS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS payment_webhook_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transaction_id TEXT NOT NULL,
    payload JSONB NOT NULL,
    source_ip TEXT,
    signature TEXT,
    status TEXT NOT NULL,
    processed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT valid_webhook_status CHECK (status IN ('verified', 'rejected', 'pending'))
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_webhook_logs_transaction_id 
ON payment_webhook_logs(transaction_id);

CREATE INDEX IF NOT EXISTS idx_webhook_logs_created_at 
ON payment_webhook_logs(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_webhook_logs_status 
ON payment_webhook_logs(status);

-- Add comments
COMMENT ON TABLE payment_webhook_logs IS 'Log of all PayFast webhook notifications for debugging';
COMMENT ON COLUMN payment_webhook_logs.transaction_id IS 'PayFast transaction ID';
COMMENT ON COLUMN payment_webhook_logs.payload IS 'Full webhook payload';
COMMENT ON COLUMN payment_webhook_logs.source_ip IS 'IP address of webhook sender';
COMMENT ON COLUMN payment_webhook_logs.status IS 'Verification status of webhook';

-- =====================================================
-- 5. CREATE PAYMENT_REFUND_REQUESTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS payment_refund_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    payment_reference TEXT NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    reason TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    processed_by UUID REFERENCES auth.users(id),
    processed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT valid_refund_status CHECK (status IN ('pending', 'approved', 'rejected', 'completed')),
    CONSTRAINT valid_refund_amount CHECK (amount > 0)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_refund_requests_payment_reference 
ON payment_refund_requests(payment_reference);

CREATE INDEX IF NOT EXISTS idx_refund_requests_status 
ON payment_refund_requests(status);

CREATE INDEX IF NOT EXISTS idx_refund_requests_created_at 
ON payment_refund_requests(created_at DESC);

-- Add comments
COMMENT ON TABLE payment_refund_requests IS 'Refund requests for PayFast payments (manual processing)';
COMMENT ON COLUMN payment_refund_requests.payment_reference IS 'Payment reference to refund';
COMMENT ON COLUMN payment_refund_requests.reason IS 'Reason for refund request';
COMMENT ON COLUMN payment_refund_requests.processed_by IS 'Admin user who processed the refund';

-- =====================================================
-- 6. ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Enable RLS
ALTER TABLE payment_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_webhook_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_refund_requests ENABLE ROW LEVEL SECURITY;

-- Payment Transactions Policies
-- Users can view their own transactions
CREATE POLICY "Users can view own payment transactions"
ON payment_transactions FOR SELECT
USING (auth.uid() = user_id);

-- Users can insert their own transactions
CREATE POLICY "Users can create payment transactions"
ON payment_transactions FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Service role can do everything
CREATE POLICY "Service role full access to payment transactions"
ON payment_transactions FOR ALL
USING (auth.jwt()->>'role' = 'service_role');

-- Webhook Logs Policies
-- Only service role can access webhook logs
CREATE POLICY "Service role full access to webhook logs"
ON payment_webhook_logs FOR ALL
USING (auth.jwt()->>'role' = 'service_role');

-- Refund Requests Policies
-- Users can view their own refund requests
CREATE POLICY "Users can view own refund requests"
ON payment_refund_requests FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM payment_transactions
        WHERE payment_transactions.payment_reference = payment_refund_requests.payment_reference
        AND payment_transactions.user_id = auth.uid()
    )
);

-- Users can create refund requests for their payments
CREATE POLICY "Users can create refund requests"
ON payment_refund_requests FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM payment_transactions
        WHERE payment_transactions.payment_reference = payment_refund_requests.payment_reference
        AND payment_transactions.user_id = auth.uid()
    )
);

-- Service role can do everything
CREATE POLICY "Service role full access to refund requests"
ON payment_refund_requests FOR ALL
USING (auth.jwt()->>'role' = 'service_role');

-- =====================================================
-- 7. TRIGGERS AND FUNCTIONS
-- =====================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_payment_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for payment_transactions
DROP TRIGGER IF EXISTS payment_transactions_updated_at ON payment_transactions;
CREATE TRIGGER payment_transactions_updated_at
    BEFORE UPDATE ON payment_transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_payment_updated_at();

-- Trigger for refund_requests
DROP TRIGGER IF EXISTS refund_requests_updated_at ON payment_refund_requests;
CREATE TRIGGER refund_requests_updated_at
    BEFORE UPDATE ON payment_refund_requests
    FOR EACH ROW
    EXECUTE FUNCTION update_payment_updated_at();

-- =====================================================
-- 8. GRANTS
-- =====================================================

-- Grant access to authenticated users
GRANT SELECT, INSERT ON payment_transactions TO authenticated;
GRANT SELECT, INSERT ON payment_refund_requests TO authenticated;

-- Grant full access to service role
GRANT ALL ON payment_transactions TO service_role;
GRANT ALL ON payment_webhook_logs TO service_role;
GRANT ALL ON payment_refund_requests TO service_role;

-- =====================================================
-- MIGRATION COMPLETE
-- =====================================================
