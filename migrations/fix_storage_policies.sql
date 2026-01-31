-- ============================================================================
-- FIX MEDICINE PHOTOS STORAGE POLICIES
-- Allows service role (backend) to upload photos
-- ============================================================================

-- Step 1: Drop existing policies
DROP POLICY IF EXISTS "Users can upload medicine photos" ON storage.objects;
DROP POLICY IF EXISTS "Public can view medicine photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their medicine photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their medicine photos" ON storage.objects;

-- Step 2: Create new policies that work with service role

-- Allow service role to insert (for backend uploads)
CREATE POLICY "Service role can upload medicine photos"
ON storage.objects FOR INSERT
TO service_role
WITH CHECK (bucket_id = 'medicine-photos');

-- Allow authenticated users to upload their own photos
CREATE POLICY "Authenticated users can upload medicine photos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'medicine-photos' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Allow public read access
CREATE POLICY "Public can view medicine photos"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'medicine-photos');

-- Allow service role to update
CREATE POLICY "Service role can update medicine photos"
ON storage.objects FOR UPDATE
TO service_role
USING (bucket_id = 'medicine-photos');

-- Allow authenticated users to update their own photos
CREATE POLICY "Authenticated users can update their medicine photos"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'medicine-photos' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Allow service role to delete
CREATE POLICY "Service role can delete medicine photos"
ON storage.objects FOR DELETE
TO service_role
USING (bucket_id = 'medicine-photos');

-- Allow authenticated users to delete their own photos
CREATE POLICY "Authenticated users can delete their medicine photos"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'medicine-photos' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Success message
SELECT 
    'SUCCESS!' as status,
    'Storage policies updated for service role access' as message,
    'Backend can now upload photos using service role key' as details;
