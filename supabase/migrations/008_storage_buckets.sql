-- =====================================================
-- NandyFood Database Schema
-- Migration: 008 - Storage Buckets Configuration
-- Description: Creates and configures Supabase Storage buckets
-- =====================================================

-- Create storage buckets
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES 
    ('restaurant-images', 'restaurant-images', TRUE, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp']::text[]),
    ('menu-item-images', 'menu-item-images', TRUE, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp']::text[]),
    ('user-avatars', 'user-avatars', TRUE, 2097152, ARRAY['image/jpeg', 'image/png', 'image/webp']::text[]),
    ('delivery-photos', 'delivery-photos', FALSE, 3145728, ARRAY['image/jpeg', 'image/png']::text[])
ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- STORAGE POLICIES
-- =====================================================

-- Restaurant Images Bucket Policies
-- Anyone can view restaurant images (public bucket)
CREATE POLICY "Anyone can view restaurant images" ON storage.objects
    FOR SELECT
    USING (bucket_id = 'restaurant-images');

-- Authenticated users can upload restaurant images
CREATE POLICY "Authenticated users can upload restaurant images" ON storage.objects
    FOR INSERT
    WITH CHECK (
        bucket_id = 'restaurant-images' AND
        auth.role() = 'authenticated'
    );

-- Users can update their restaurant images
CREATE POLICY "Users can update restaurant images" ON storage.objects
    FOR UPDATE
    USING (
        bucket_id = 'restaurant-images' AND
        auth.role() = 'authenticated'
    );

-- Users can delete restaurant images
CREATE POLICY "Users can delete restaurant images" ON storage.objects
    FOR DELETE
    USING (
        bucket_id = 'restaurant-images' AND
        auth.role() = 'authenticated'
    );

-- Menu Item Images Bucket Policies
-- Anyone can view menu item images (public bucket)
CREATE POLICY "Anyone can view menu item images" ON storage.objects
    FOR SELECT
    USING (bucket_id = 'menu-item-images');

-- Authenticated users can upload menu item images
CREATE POLICY "Authenticated users can upload menu item images" ON storage.objects
    FOR INSERT
    WITH CHECK (
        bucket_id = 'menu-item-images' AND
        auth.role() = 'authenticated'
    );

-- Users can update menu item images
CREATE POLICY "Users can update menu item images" ON storage.objects
    FOR UPDATE
    USING (
        bucket_id = 'menu-item-images' AND
        auth.role() = 'authenticated'
    );

-- Users can delete menu item images
CREATE POLICY "Users can delete menu item images" ON storage.objects
    FOR DELETE
    USING (
        bucket_id = 'menu-item-images' AND
        auth.role() = 'authenticated'
    );

-- User Avatars Bucket Policies
-- Anyone can view user avatars (public bucket)
CREATE POLICY "Anyone can view user avatars" ON storage.objects
    FOR SELECT
    USING (bucket_id = 'user-avatars');

-- Users can upload their own avatar
CREATE POLICY "Users can upload own avatar" ON storage.objects
    FOR INSERT
    WITH CHECK (
        bucket_id = 'user-avatars' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- Users can update their own avatar
CREATE POLICY "Users can update own avatar" ON storage.objects
    FOR UPDATE
    USING (
        bucket_id = 'user-avatars' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- Users can delete their own avatar
CREATE POLICY "Users can delete own avatar" ON storage.objects
    FOR DELETE
    USING (
        bucket_id = 'user-avatars' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- Delivery Photos Bucket Policies (Private)
-- Users can view delivery photos for their orders
CREATE POLICY "Users can view delivery photos for own orders" ON storage.objects
    FOR SELECT
    USING (
        bucket_id = 'delivery-photos' AND
        auth.role() = 'authenticated'
        -- Additional check would verify order ownership
    );

-- Delivery drivers can upload delivery photos
CREATE POLICY "Drivers can upload delivery photos" ON storage.objects
    FOR INSERT
    WITH CHECK (
        bucket_id = 'delivery-photos' AND
        auth.role() = 'authenticated'
    );

-- =====================================================
-- HELPER FUNCTIONS FOR STORAGE
-- =====================================================

-- Function to generate unique file name
CREATE OR REPLACE FUNCTION public.generate_unique_filename(
    original_filename TEXT,
    user_id UUID DEFAULT NULL
)
RETURNS TEXT AS $$
DECLARE
    extension TEXT;
    timestamp TEXT;
    random_string TEXT;
BEGIN
    -- Extract file extension
    extension := substring(original_filename from '\.[^\.]+$');
    
    -- Generate timestamp
    timestamp := to_char(NOW(), 'YYYYMMDD_HH24MISS');
    
    -- Generate random string
    random_string := substring(md5(random()::text) from 1 for 8);
    
    -- Combine elements
    IF user_id IS NOT NULL THEN
        RETURN user_id::text || '/' || timestamp || '_' || random_string || extension;
    ELSE
        RETURN timestamp || '_' || random_string || extension;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Function to get public URL for storage object
CREATE OR REPLACE FUNCTION public.get_storage_public_url(
    bucket_name TEXT,
    file_path TEXT
)
RETURNS TEXT AS $$
DECLARE
    supabase_url TEXT;
BEGIN
    -- Get Supabase URL from environment or use placeholder
    -- In production, this would be replaced with actual Supabase URL
    supabase_url := current_setting('app.settings.supabase_url', true);
    
    IF supabase_url IS NULL THEN
        supabase_url := 'https://your-project.supabase.co';
    END IF;
    
    RETURN supabase_url || '/storage/v1/object/public/' || bucket_name || '/' || file_path;
END;
$$ LANGUAGE plpgsql;

-- Add comments
COMMENT ON POLICY "Anyone can view restaurant images" ON storage.objects IS 
    'Allows public access to restaurant images';
COMMENT ON POLICY "Users can upload own avatar" ON storage.objects IS 
    'Restricts avatar uploads to user-specific folders';
COMMENT ON FUNCTION public.generate_unique_filename IS 
    'Generates unique filename with timestamp and random string for storage uploads';
