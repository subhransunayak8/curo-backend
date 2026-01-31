# 🚀 Blood Transfusion Feature - Backend Deployment Guide

## Quick Deployment (5 Minutes)

### Step 1: Run Database Migration

#### Option A: Supabase SQL Editor (Recommended)
1. Open https://supabase.com/dashboard
2. Select your project
3. Go to **SQL Editor**
4. Click **New Query**
5. Copy entire contents of `migrations/create_blood_transfusion_tables.sql`
6. Paste and click **Run**
7. Verify: Should see "Success. No rows returned"

#### Option B: Command Line
```bash
psql -h your-db-host.supabase.co -U postgres -d postgres -f migrations/create_blood_transfusion_tables.sql
```

### Step 2: Verify Tables Created
Run this query in SQL Editor:
```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name LIKE 'blood_transfusion%';
```

Should return:
- blood_transfusions
- blood_transfusion_progress
- blood_transfusion_notes
- blood_transfusion_alerts

### Step 3: Deploy Backend Code

#### If using Render.com:
```bash
cd cura/backend
git add .
git commit -m "feat: Add blood transfusion monitoring API"
git push origin main
```

Render will auto-deploy in ~2 minutes.

#### If using other hosting:
```bash
# Restart your Node.js server
pm2 restart cura-backend
# or
npm run start
```

### Step 4: Test API

```bash
# Health check
curl https://curo-backend-1cny.onrender.com/health

# Test blood transfusion endpoint (requires auth token)
curl -X POST https://curo-backend-1cny.onrender.com/api/blood-transfusion/start \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "taskId": "test-123",
    "patientId": "patient-456",
    "pouchVolumeMl": 450,
    "dropFactor": "STANDARD",
    "dropRatePerMinute": 50,
    "startTime": "2026-01-31T10:00:00Z",
    "expectedEndTime": "2026-01-31T13:00:00Z",
    "alertThresholdMinutes": 15
  }'
```

---

## Verification Checklist

- [ ] Database tables created
- [ ] RLS policies active
- [ ] Backend deployed
- [ ] API endpoints responding
- [ ] Authentication working
- [ ] Can create transfusion record
- [ ] Can query transfusion history

---

## Rollback Plan

If something goes wrong:

### Rollback Database
```sql
DROP TABLE IF EXISTS blood_transfusion_alerts CASCADE;
DROP TABLE IF EXISTS blood_transfusion_notes CASCADE;
DROP TABLE IF EXISTS blood_transfusion_progress CASCADE;
DROP TABLE IF EXISTS blood_transfusions CASCADE;
DROP VIEW IF EXISTS blood_transfusion_summary;
```

### Rollback Code
```bash
git revert HEAD
git push origin main
```

---

## Troubleshooting

### Issue: Tables not created
**Solution**: Check Supabase logs, verify SQL syntax

### Issue: RLS blocking queries
**Solution**: Verify user is authenticated, check RLS policies

### Issue: API 404
**Solution**: Verify routes registered in server.js, restart server

### Issue: API 401
**Solution**: Check authorization token, verify user exists

---

## Next Steps

After deployment:
1. Test all API endpoints
2. Update Android app to use new endpoints
3. Test end-to-end flow
4. Monitor for errors
5. Deploy to production

---

**Deployment Time**: ~5 minutes  
**Downtime**: None (backward compatible)  
**Risk Level**: Low
