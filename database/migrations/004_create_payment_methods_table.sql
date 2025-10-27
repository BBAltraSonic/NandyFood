-- Migration: Create payment_methods table for storing user payment methods
-- Description: Stores non-sensitive payment method metadata and default flag

-- Ensure required extension for UUID generation
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS public.payment_methods (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL DEFAULT 'card',
  brand TEXT NOT NULL,
  last4 TEXT NOT NULL,
  expiry_month SMALLINT NOT NULL CHECK (expiry_month BETWEEN 1 AND 12),
  expiry_year SMALLINT NOT NULL CHECK (expiry_year BETWEEN 0 AND 99),
  cardholder_name TEXT,
  is_default BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_payment_methods_user_id ON public.payment_methods(user_id);
CREATE INDEX IF NOT EXISTS idx_payment_methods_is_default ON public.payment_methods(is_default);

-- Enforce only one default payment method per user
CREATE UNIQUE INDEX IF NOT EXISTS payment_methods_one_default_per_user_idx
  ON public.payment_methods(user_id)
  WHERE is_default;

-- Enable Row Level Security
ALTER TABLE public.payment_methods ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'payment_methods' AND policyname = 'Allow users to select their payment methods'
  ) THEN
    CREATE POLICY "Allow users to select their payment methods"
      ON public.payment_methods FOR SELECT
      USING (auth.uid() = user_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'payment_methods' AND policyname = 'Allow users to insert their payment methods'
  ) THEN
    CREATE POLICY "Allow users to insert their payment methods"
      ON public.payment_methods FOR INSERT
      WITH CHECK (auth.uid() = user_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'payment_methods' AND policyname = 'Allow users to update their payment methods'
  ) THEN
    CREATE POLICY "Allow users to update their payment methods"
      ON public.payment_methods FOR UPDATE
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'payment_methods' AND policyname = 'Allow users to delete their payment methods'
  ) THEN
    CREATE POLICY "Allow users to delete their payment methods"
      ON public.payment_methods FOR DELETE
      USING (auth.uid() = user_id);
  END IF;
END $$;

-- Trigger to auto-update updated_at
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'update_payment_methods_updated_at'
  ) THEN
    CREATE TRIGGER update_payment_methods_updated_at
      BEFORE UPDATE ON public.payment_methods
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  END IF;
END $$;

-- Comments
COMMENT ON TABLE public.payment_methods IS 'Stores user payment method metadata (non-sensitive) and default flag';
COMMENT ON COLUMN public.payment_methods.is_default IS 'Indicates if this is the default payment method for the user';

