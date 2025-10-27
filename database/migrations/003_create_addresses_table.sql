-- Migration: Create addresses table for user delivery addresses
-- Description: Stores user addresses with geolocation and default flag

-- Ensure required extension for UUID generation
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS public.addresses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL DEFAULT 'home',
  street TEXT NOT NULL,
  city TEXT NOT NULL,
  state TEXT,
  zip_code TEXT NOT NULL,
  country TEXT NOT NULL DEFAULT 'South Africa',
  apartment TEXT,
  delivery_instructions TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  is_default BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_addresses_user_id ON public.addresses(user_id);
CREATE INDEX IF NOT EXISTS idx_addresses_is_default ON public.addresses(is_default);

-- Enforce only one default address per user
CREATE UNIQUE INDEX IF NOT EXISTS addresses_one_default_per_user_idx
  ON public.addresses(user_id)
  WHERE is_default;

-- Enable Row Level Security
ALTER TABLE public.addresses ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'addresses' AND policyname = 'Allow users to select their addresses'
  ) THEN
    CREATE POLICY "Allow users to select their addresses"
      ON public.addresses FOR SELECT
      USING (auth.uid() = user_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'addresses' AND policyname = 'Allow users to insert their addresses'
  ) THEN
    CREATE POLICY "Allow users to insert their addresses"
      ON public.addresses FOR INSERT
      WITH CHECK (auth.uid() = user_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'addresses' AND policyname = 'Allow users to update their addresses'
  ) THEN
    CREATE POLICY "Allow users to update their addresses"
      ON public.addresses FOR UPDATE
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'addresses' AND policyname = 'Allow users to delete their addresses'
  ) THEN
    CREATE POLICY "Allow users to delete their addresses"
      ON public.addresses FOR DELETE
      USING (auth.uid() = user_id);
  END IF;
END $$;

-- Trigger to auto-update updated_at
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'update_addresses_updated_at'
  ) THEN
    CREATE TRIGGER update_addresses_updated_at
      BEFORE UPDATE ON public.addresses
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  END IF;
END $$;

-- Comments
COMMENT ON TABLE public.addresses IS 'Stores user delivery addresses with optional geolocation and default flag';
COMMENT ON COLUMN public.addresses.is_default IS 'Indicates if this is the default address for the user';

