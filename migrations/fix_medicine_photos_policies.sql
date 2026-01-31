-- Fix Medicine Photos Storage Policies
-- Run this if you're getting 400 errors when uploading

-- First, drop any existing policies
DROP POLICY IF EXISTS "Public can view medicine photos" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload medicine photos" ON storage.objects;
DROP POLICY IF EXISTS "Allow all operations on medicine-photos" ON storage.objects;

-- Create a simple policy that allows all operations for the medicine-photos bucket
CREATE POLICY "Allow public uploads to medicine-photos"
ON storage.objects
FOR INSERT
TO public
WITH CHECK (bucket_id = 'medicine-photos');

CREATE POLICY "Allow public reads from medicine-photos"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'medicine-photos');

-- Verify the policies were created
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies
WHERE tablename = 'objects' AND policyname LIKE '%medicine-photos%';

-- Verify the bucket is public
SELECT id, name, public FROM storage.buckets WHERE id = 'medicine-photos';
