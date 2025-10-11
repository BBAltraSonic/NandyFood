-- Fixed Migration - Remove earthdistance dependency and simplify geolocation indexes

-- Remove the problematic indexes that use ll_to_earth
DROP INDEX IF EXISTS idx_addresses_location;
DROP INDEX IF EXISTS idx_restaurants_location;

-- Create simpler indexes for latitude/longitude
CREATE INDEX IF NOT EXISTS idx_addresses_lat_lon ON public.addresses(latitude, longitude) WHERE latitude IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_restaurants_lat_lon ON public.restaurants(latitude, longitude);

-- Success message
SELECT 'Geolocation indexes fixed!' as status;
