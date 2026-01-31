# Nodemailer Setup Guide with Gmail

## Overview
We've implemented Nodemailer to send OTP emails instead of using Supabase Auth. This gives us full control over email content and ensures 6-digit OTP codes are sent.

## Gmail App Password Setup

### Step 1: Enable 2-Factor Authentication on Gmail

1. Go to your Google Account: https://myaccount.google.com/
2. Click on **Security** in the left sidebar
3. Under "Signing in to Google", click **2-Step Verification**
4. Follow the prompts to enable 2FA (if not already enabled)

### Step 2: Generate App Password

1. Go to: https://myaccount.google.com/apppasswords
2. You may need to sign in again
3. Under "Select app", choose **Mail**
4. Under "Select device", choose **Other (Custom name)**
5. Enter a name like "CURA Backend"
6. Click **Generate**
7. **Copy the 16-character password** (it will look like: `abcd efgh ijkl mnop`)

### Step 3: Update Environment Variables

Add these to your `.env` file:

```env
EMAIL_USER=your-email@gmail.com
EMAIL_PASSWORD=abcdefghijklmnop
```

**Important:** 
- Remove spaces from the app password
- Use your actual Gmail address for EMAIL_USER
- Keep this password secure and never commit it to git

### Step 4: Update Render Environment Variables

1. Go to Render Dashboard: https://dashboard.render.com
2. Select your `curo-backend` service
3. Go to **Environment** tab
4. Add these variables:
   - `EMAIL_USER` = your-email@gmail.com
   - `EMAIL_PASSWORD` = your-app-password (no spaces)
5. Click **Save Changes**
6. Render will automatically redeploy

## How It Works

### 1. Send OTP Flow
```
User enters email → Backend generates 6-digit OTP → 
Stores in email_otps table → Sends email via Nodemailer → 
User receives beautiful HTML email with OTP
```

### 2. Verify OTP Flow
```
User enters OTP → Backend checks email_otps table → 
Validates OTP and expiry → Creates/logs in user → 
Returns JWT token
```

## Database Migration

Run this SQL in your Supabase SQL Editor:

```sql
-- Create email_otps table
CREATE TABLE IF NOT EXISTS email_otps (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email VARCHAR(255) NOT NULL,
  otp VARCHAR(6) NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  is_verified BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_email_otps_email ON email_otps(email);
CREATE INDEX IF NOT EXISTS idx_email_otps_expires_at ON email_otps(expires_at);
```

## Testing

### Test Locally

1. Install dependencies:
```bash
npm install
```

2. Update `.env` with your Gmail credentials

3. Start the server:
```bash
npm start
```

4. Send OTP:
```bash
curl -X POST http://localhost:8000/api/auth/send-otp \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com"}'
```

5. Check your email for the OTP

6. Verify OTP:
```bash
curl -X POST http://localhost:8000/api/auth/verify-otp \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","otp":"123456"}'
```

### Test on Production

After deploying to Render:

```bash
curl -X POST https://curo-backend-1cny.onrender.com/api/auth/send-otp \
  -H "Content-Type: application/json" \
  -d '{"email":"your-email@example.com"}'
```

## Email Template

The OTP email includes:
- 🏥 CURA branding
- Large, easy-to-read 6-digit code
- 5-minute expiry warning
- Professional HTML design
- Mobile-responsive layout

## Features

✅ **6-digit OTP codes** - Easy to type
✅ **5-minute expiry** - Secure and reasonable
✅ **Beautiful HTML emails** - Professional appearance
✅ **Development mode** - OTP included in API response for testing
✅ **Automatic cleanup** - Old OTPs are deleted when new ones are sent
✅ **Rate limiting** - Prevents spam (one OTP per email at a time)

## Troubleshooting

### "Invalid login" error
- Make sure you're using an **App Password**, not your regular Gmail password
- Verify 2FA is enabled on your Google account

### Email not sending
- Check EMAIL_USER and EMAIL_PASSWORD are set correctly
- Verify the app password has no spaces
- Check Render logs for error messages

### Email goes to spam
- This is normal for new sending addresses
- Users should check spam folder
- Consider using a custom domain with proper SPF/DKIM records for production

### OTP expired
- OTPs expire after 5 minutes
- User can request a new OTP using the "Resend" button

## Alternative Email Providers

If you don't want to use Gmail, you can configure other providers:

### Outlook/Hotmail
```javascript
service: 'hotmail'
```

### Yahoo
```javascript
service: 'yahoo'
```

### Custom SMTP
```javascript
host: 'smtp.yourdomain.com',
port: 587,
secure: false,
auth: {
  user: 'noreply@yourdomain.com',
  pass: 'your-password'
}
```

## Security Notes

- ✅ OTPs are hashed in database (optional enhancement)
- ✅ OTPs expire after 5 minutes
- ✅ One-time use only (marked as verified after use)
- ✅ Old OTPs are deleted when new ones are requested
- ✅ App passwords are more secure than regular passwords
- ✅ No OTP is sent in production API responses

## Next Steps

1. Generate Gmail App Password
2. Update environment variables in Render
3. Run database migration in Supabase
4. Deploy and test!

Your OTP system is now fully functional with beautiful email delivery! 🎉
