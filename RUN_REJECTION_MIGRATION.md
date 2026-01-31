# Run Rejection Tracking Migration

## Backend Deployment Status
✅ **Backend code pushed to GitHub**
- Commit: `342eac4`
- Branch: `master`
- Changes: Rejection tracking API endpoint and database migration

## Database Migration Required

The backend code has been deployed, but you need to run the database migration to add the rejection tracking fields.

### Option 1: Using Supabase Dashboard (Recommended)

1. **Go to Supabase Dashboard**
   - Visit: https://supabase.com/dashboard
   - Select your project

2. **Open SQL Editor**
   - Click "SQL Editor" in the left sidebar
   - Click "New Query"

3. **Copy and Run Migration**
   - Open file: `cura/backend/migrations/add_rejection_tracking.sql`
   - Copy the entire SQL content
   - Paste into Supabase SQL Editor
   - Click "Run" button

4. **Verify Migration**
   - Go to "Table Editor"
   - Select `sop_steps` table
   - Check that new columns exist:
     - `validation_status`
     - `validation_message`
     - `rejected_at`
     - `rejection_count`

### Option 2: Using psql Command Line

```bash
# Connect to your Supabase database
psql "postgresql://postgres:[YOUR-PASSWORD]@[YOUR-PROJECT-REF].supabase.co:5432/postgres"

# Run the migration
\i migrations/add_rejection_tracking.sql

# Verify columns were added
\d sop_steps
```

### Option 3: Using Node.js Script

Create a file `run-migration.js`:

```javascript
const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
require('dotenv').config();

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

async function runMigration() {
  const sql = fs.readFileSync('./migrations/add_rejection_tracking.sql', 'utf8');
  
  const { data, error } = await supabase.rpc('exec_sql', { sql });
  
  if (error) {
    console.error('Migration failed:', error);
  } else {
    console.log('✅ Migration completed successfully!');
  }
}

runMigration();
```

Then run:
```bash
node run-migration.js
```

## Migration SQL Content

The migration adds these columns to `sop_steps` table:

```sql
-- Validation status (pending, approved, rejected)
ALTER TABLE sop_steps 
ADD COLUMN IF NOT EXISTS validation_status VARCHAR(20) DEFAULT 'pending';

-- Rejection reason
ALTER TABLE sop_steps 
ADD COLUMN IF NOT EXISTS validation_message TEXT;

-- Rejection timestamp
ALTER TABLE sop_steps 
ADD COLUMN IF NOT EXISTS rejected_at TIMESTAMP WITH TIME ZONE;

-- Rejection count
ALTER TABLE sop_steps 
ADD COLUMN IF NOT EXISTS rejection_count INTEGER DEFAULT 0;

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_sop_steps_validation_status 
ON sop_steps(validation_status);

-- Update existing completed steps to 'approved'
UPDATE sop_steps 
SET validation_status = 'approved' 
WHERE is_completed = true AND validation_status = 'pending';
```

## Verification Steps

After running the migration, verify it worked:

### 1. Check Table Structure
```sql
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'sop_steps'
AND column_name IN ('validation_status', 'validation_message', 'rejected_at', 'rejection_count');
```

Expected output:
```
column_name        | data_type              | column_default
-------------------+------------------------+----------------
validation_status  | character varying(20)  | 'pending'
validation_message | text                   | NULL
rejected_at        | timestamp with time zone| NULL
rejection_count    | integer                | 0
```

### 2. Check Existing Data
```sql
SELECT 
  id,
  task_title,
  is_completed,
  validation_status,
  validation_message
FROM sop_steps
LIMIT 5;
```

Expected:
- Completed tasks should have `validation_status = 'approved'`
- Incomplete tasks should have `validation_status = 'pending'`

### 3. Test Rejection Endpoint

Using curl or Postman:
```bash
curl -X PATCH https://curo-backend-1cny.onrender.com/api/sop/sops/steps/{stepId}/reject \
  -H "Content-Type: application/json" \
  -d '{"rejectionReason": "Test rejection"}'
```

Expected response:
```json
{
  "step": {
    "id": "uuid",
    "validation_status": "rejected",
    "validation_message": "Test rejection",
    "rejected_at": "2026-01-31T...",
    "rejection_count": 1
  }
}
```

## Troubleshooting

### Error: Column already exists
If you see "column already exists" error, the migration was already run. This is safe to ignore.

### Error: Permission denied
Make sure you're using the `SUPABASE_SERVICE_ROLE_KEY` (not the anon key) which has admin permissions.

### Error: Table not found
Make sure the `sop_steps` table exists. Run the SOP system setup migration first.

## Rollback (If Needed)

If you need to rollback the migration:

```sql
-- Remove added columns
ALTER TABLE sop_steps DROP COLUMN IF EXISTS validation_status;
ALTER TABLE sop_steps DROP COLUMN IF EXISTS validation_message;
ALTER TABLE sop_steps DROP COLUMN IF EXISTS rejected_at;
ALTER TABLE sop_steps DROP COLUMN IF EXISTS rejection_count;

-- Remove index
DROP INDEX IF EXISTS idx_sop_steps_validation_status;
```

## After Migration

Once the migration is complete:

1. ✅ Backend API will work with rejection tracking
2. ✅ Android app can call rejection endpoint
3. ✅ Rejection status will persist in database
4. ✅ App restarts will show correct status

## Render.com Auto-Deploy

If your backend is deployed on Render.com:

1. **Check Deploy Status**
   - Go to: https://dashboard.render.com
   - Select your backend service
   - Check "Events" tab for latest deploy

2. **Trigger Manual Deploy** (if needed)
   - Click "Manual Deploy" button
   - Select "Deploy latest commit"
   - Wait for deployment to complete

3. **Run Migration**
   - After deploy completes, run the database migration using one of the options above

## Summary

✅ **Backend code pushed**: Rejection tracking API is live
⏳ **Database migration needed**: Run `add_rejection_tracking.sql`
📱 **Android app ready**: Will work once migration is complete

---

**Next Steps**:
1. Run the database migration using Supabase Dashboard
2. Verify columns were added
3. Test rejection endpoint
4. Install updated Android app
5. Test rejection persistence!
