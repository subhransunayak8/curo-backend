-- ============================================================================
-- SIMPLE MEDICINE PHOTOS STORAGE SETUP
-- Creates public bucket without RLS policies (service role bypasses RLS anyway)
-- ============================================================================

-- Step 1: Create storage bucket for medicine photos (public bucket)
INSERT INTO storage.buckets (id, name, public)
VALUES ('medicine-photos', 'medicine-photos', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Step 2: Enable RLS on storage.objects (if not already enabled)
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Step 3: Create a simple policy that allows all operations on this bucket
-- Service role key bypasses RLS, so this is mainly for direct access
CREATE POLICY IF NOT EXISTS "Allow all operations on medicine-photos"
ON storage.objects
FOR ALL
USING (bucket_id = 'medicine-photos')
WITH CHECK (bucket_id = 'medicine-photos');

-- Alternative: If you want more control, use these specific policies instead
-- (Comment out the above policy and uncomment these)

/*
-- Allow public read
CREATE POLICY IF NOT EXISTS "Public read medicine photos"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'medicine-photos');

-- Allow all authenticated operations
CREATE POLICY IF NOT EXISTS "Authenticated all operations medicine photos"
ON storage.objects FOR ALL
TO authenticated
USING (bucket_id = 'medicine-photos')
WITH CHECK (bucket_id = 'medicine-photos');

-- Service role bypasses RLS automatically, no policy needed
*/

-- Success message
SELECT 
    'SUCCESS!' as status,
    'Medicine photos storage bucket created' as message,
    'Bucket is public, service role can upload' as details;
