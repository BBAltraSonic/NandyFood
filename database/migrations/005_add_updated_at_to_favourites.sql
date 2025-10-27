-- Migration: Add updated_at column and trigger to favourites table
-- Safety: Uses IF NOT EXISTS to avoid errors if re-run

-- 1) Column
ALTER TABLE favourites
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- 2) Trigger to update updated_at on row updates
-- Requires the common trigger function update_updated_at_column() present in schema
DROP TRIGGER IF EXISTS update_favourites_updated_at ON favourites;
CREATE TRIGGER update_favourites_updated_at
BEFORE UPDATE ON favourites
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

