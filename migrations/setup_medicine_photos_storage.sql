-- ============================================================================
-- SETUP MEDICINE PHOTOS STORAGE
-- Creates Supabase Storage bucket and policies for medicine photos
-- ============================================================================

-- Step 1: Create storage bucket for medicine photos
INSERT INTO storage.buckets (id, name, public)
VALUES ('medicine-photos', 'medicine-photos', true)
ON CONFLICT (id) DO NOTHING;

-- Step 2: Allow authenticated users to upload their own medicine photos
CREATE POLICY "Users can upload medicine photos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'medicine-photos' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Step 3: Allow public read access to medicine photos
CREATE POLICY "Public can view medicine photos"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'medicine-photos');

-- Step 4: Allow users to update their own medicine photos
CREATE POLICY "Users can update their medicine photos"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'medicine-photos' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Step 5: Allow users to delete their own medicine photos
CREATE POLICY "Users can delete their medicine photos"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'medicine-photos' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Success message
SELECT 
    'SUCCESS!' as status,
    'Medicine photos storage bucket created' as message,
    'Bucket: medicine-photos (public read, authenticated write)' as details;
