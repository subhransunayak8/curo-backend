const express = require('express');
const { body, validationResult } = require('express-validator');
const authService = require('../services/authService');
const { supabase } = require('../config/supabase');

const router = express.Router();

// Send OTP
router.post('/send-otp',
  body('phone').matches(/^\+?[1-9]\d{9,14}$/).withMessage('Invalid phone number format'),
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { phone } = req.body;
      const result = await authService.sendOTP(phone);
      res.json(result);
    } catch (error) {
      console.error('Error in send-otp:', error);
      res.status(500).json({ error: 'Failed to send OTP' });
    }
  }
);

// Verify OTP
router.post('/verify-otp',
  body('phone').matches(/^\+?[1-9]\d{9,14}$/).withMessage('Invalid phone number format'),
  body('otp').isLength({ min: 4, max: 6 }).withMessage('Invalid OTP'),
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { phone, otp } = req.body;

      // Verify OTP
      const isValid = await authService.verifyOTP(phone, otp);
      if (!isValid) {
        return res.status(401).json({ error: 'Invalid or expired OTP' });
      }

      // Check if user exists
      const { data: users, error: userError } = await supabase
        .from('users')
        .select('*')
        .eq('phone', phone);

      let user;
      let isNewUser = false;

      if (!users || users.length === 0) {
        // Create new user
        isNewUser = true;
        const { data: newUser, error: createError } = await supabase
          .from('users')
          .insert({
            phone,
            role: 'user',
            created_at: new Date().toISOString()
          })
          .select()
          .single();

        if (createError) throw createError;
        user = newUser;
      } else {
        user = users[0];
      }

      // Create JWT token
      const accessToken = authService.createAccessToken(user.id, user.phone);

      res.json({
        access_token: accessToken,
        token_type: 'bearer',
        user_id: user.id,
        is_new_user: isNewUser
      });
    } catch (error) {
      console.error('Error in verify-otp:', error);
      res.status(500).json({ error: 'Failed to verify OTP' });
    }
  }
);

// Logout
router.post('/logout', (req, res) => {
  res.json({ message: 'Logged out successfully' });
});

module.exports = router;
