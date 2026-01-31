# Quick Installation Guide for Medicine Photo Upload

## Step 1: Install Dependencies

```bash
cd backend
npm install multer uuid
```

## Step 2: Setup Supabase Storage

### Option A: Using Supabase Dashboard
1. Go to your Supabase Dashboard
2. Navigate to Storage
3. Click "Create bucket"
4. Name: `medicine-photos`
5. Set as Public bucket
6. Click "Create bucket"

### Option B: Using SQL (Recommended)
1. Go to Supabase Dashboard → SQL Editor
2. Copy and paste the contents of `migrations/setup_medicine_photos_storage.sql`
3. Click "Run"

## Step 3: Verify Installation

### Check Backend
```bash
# Start the server
npm run dev

# You should see:
# 🚀 CURA Backend running on port 3000
```

### Test Upload Endpoint
```bash
# Test with curl (replace with actual image path)
curl -X POST http://localhost:3000/api/upload/medicine-photo \
  -F "photo=@/path/to/test-image.jpg" \
  -F "userId=test-user-123"

# Expected response:
# {
#   "success": true,
#   "photoUrl": "https://...supabase.co/storage/v1/object/public/medicine-photos/...",
#   "fileName": "test-user-123/uuid.jpg"
# }
```

## Step 4: Update Android App

The Android app files are already updated. Just make sure to:

1. Update the backend URL in `PhotoUploadRepository.kt`:
   ```kotlin
   // For production, change to your actual backend URL
   private val baseUrl = "https://your-backend-url.com/api/upload"
   ```

2. Rebuild and run the app

## Verification Checklist

- [ ] Dependencies installed (`multer`, `uuid`)
- [ ] Backend server starts without errors
- [ ] Storage bucket `medicine-photos` exists in Supabase
- [ ] Upload endpoint responds to test requests
- [ ] Android app can upload photos
- [ ] Photos appear in Supabase Storage
- [ ] Photo URLs are saved in database

## Common Issues

### "Bucket not found"
- Run the SQL migration script
- Or manually create the bucket in Supabase Dashboard

### "Module not found: multer"
- Run `npm install` in the backend directory

### Upload fails with 413 (Payload Too Large)
- File is larger than 5MB
- Compress the image or increase the limit in `uploadRoutes.js`

### CORS errors
- Check CORS configuration in `server.js`
- Ensure your frontend origin is allowed
