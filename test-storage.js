// Test script to verify Supabase Storage setup
// Run with: node test-storage.js

require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL;
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

console.log('=== SUPABASE STORAGE TEST ===\n');

// Check environment variables
console.log('1. Checking environment variables...');
console.log('   SUPABASE_URL:', supabaseUrl ? '✓ Set' : '✗ Missing');
console.log('   SERVICE_ROLE_KEY:', serviceRoleKey ? '✓ Set' : '✗ Missing');

if (!supabaseUrl || !serviceRoleKey) {
  console.error('\n❌ Missing environment variables!');
  console.error('Make sure .env file has SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY');
  process.exit(1);
}

// Create Supabase client
const supabase = createClient(supabaseUrl, serviceRoleKey);

async function testStorage() {
  try {
    // Test 1: List buckets
    console.log('\n2. Listing storage buckets...');
    const { data: buckets, error: bucketsError } = await supabase.storage.listBuckets();
    
    if (bucketsError) {
      console.error('   ✗ Error listing buckets:', bucketsError.message);
      return;
    }
    
    console.log('   ✓ Found', buckets.length, 'bucket(s)');
    buckets.forEach(bucket => {
      console.log(`     - ${bucket.id} (${bucket.public ? 'public' : 'private'})`);
    });
    
    // Check if medicine-photos bucket exists
    const medicinePhotoBucket = buckets.find(b => b.id === 'medicine-photos');
    if (!medicinePhotoBucket) {
      console.error('\n   ✗ Bucket "medicine-photos" not found!');
      console.log('\n   📝 Create it by running:');
      console.log('      1. Go to Supabase Dashboard → Storage');
      console.log('      2. Click "New bucket"');
      console.log('      3. Name: medicine-photos');
      console.log('      4. Check "Public bucket"');
      console.log('      5. Click "Create"');
      return;
    }
    
    console.log('\n   ✓ Bucket "medicine-photos" exists');
    console.log('     Public:', medicinePhotoBucket.public ? 'Yes ✓' : 'No ✗');
    
    if (!medicinePhotoBucket.public) {
      console.warn('\n   ⚠️  Bucket is private! It should be public.');
      console.log('      Update it in Supabase Dashboard → Storage → medicine-photos → Settings');
    }
    
    // Test 2: Try to upload a test file
    console.log('\n3. Testing file upload...');
    const testFileName = 'test-user/test-' + Date.now() + '.txt';
    const testContent = 'This is a test file';
    
    const { data: uploadData, error: uploadError } = await supabase.storage
      .from('medicine-photos')
      .upload(testFileName, testContent, {
        contentType: 'text/plain',
        upsert: false
      });
    
    if (uploadError) {
      console.error('   ✗ Upload failed:', uploadError.message);
      console.error('   Error details:', JSON.stringify(uploadError, null, 2));
      return;
    }
    
    console.log('   ✓ Upload successful!');
    console.log('     Path:', uploadData.path);
    
    // Test 3: Get public URL
    console.log('\n4. Getting public URL...');
    const { data: { publicUrl } } = supabase.storage
      .from('medicine-photos')
      .getPublicUrl(testFileName);
    
    console.log('   ✓ Public URL:', publicUrl);
    
    // Test 4: Clean up - delete test file
    console.log('\n5. Cleaning up test file...');
    const { error: deleteError } = await supabase.storage
      .from('medicine-photos')
      .remove([testFileName]);
    
    if (deleteError) {
      console.warn('   ⚠️  Could not delete test file:', deleteError.message);
    } else {
      console.log('   ✓ Test file deleted');
    }
    
    console.log('\n✅ ALL TESTS PASSED!');
    console.log('Your Supabase Storage is configured correctly.');
    console.log('Photo uploads should work from your app now.');
    
  } catch (error) {
    console.error('\n❌ Test failed with error:', error.message);
    console.error('Stack trace:', error.stack);
  }
}

// Run tests
testStorage();
