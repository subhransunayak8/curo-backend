# CURA Backend API (Node.js)

Express.js backend for CURA Healthcare Platform with Supabase, MSG91 OTP, and Gemini AI.

## Tech Stack

- **Framework**: Express.js (Node.js)
- **Database**: Supabase (PostgreSQL)
- **Authentication**: JWT with OTP
- **SMS Provider**: MSG91
- **AI**: Google Gemini AI

## Quick Setup

### 1. Install Dependencies
```bash
cd backend-node
npm install
```

### 2. Configure Environment
```bash
cp .env.example .env
```

Edit `.env` with your credentials:
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
MSG91_AUTH_KEY=your_auth_key
GEMINI_API_KEY=your_gemini_key
JWT_SECRET=your_secret_key_here
```

### 3. Start Server
```bash
# Development
npm run dev

# Production
npm start
```

Visit http://localhost:8000 for API!

## API Endpoints

### Authentication
- `POST /api/auth/send-otp` - Send OTP
- `POST /api/auth/verify-otp` - Verify OTP & login
- `POST /api/auth/logout` - Logout

### Users
- `GET /api/users/profile?user_id=xxx` - Get profile
- `PUT /api/users/profile?user_id=xxx` - Update profile
- `POST /api/users/complete-registration?user_id=xxx` - Complete registration

### Prescriptions
- `POST /api/prescriptions/analyze` - Analyze prescription
- `GET /api/prescriptions/user/:user_id` - List user prescriptions
- `GET /api/prescriptions/:prescription_id` - Get prescription

## Project Structure
```
backend-node/
├── src/
│   ├── config/          # Configuration
│   ├── routes/          # API routes
│   ├── services/        # Business logic
│   └── server.js        # Entry point
├── .env                 # Environment variables
├── package.json
└── README.md
```

## Deployment

### Render.com
1. Create Web Service
2. Connect GitHub repo
3. Build Command: `npm install`
4. Start Command: `npm start`
5. Add environment variables
6. Deploy!

### Heroku
```bash
heroku create cura-backend-node
heroku config:set SUPABASE_URL=...
git push heroku master
```

## License
MIT
