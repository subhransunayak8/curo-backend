const express = require('express');
const { body, validationResult } = require('express-validator');
const authService = require('../services/authService');
const { supabase } = require('../config/supabase');

const router = express.Router();

// Send OTP to email
router.post('/send-otp',
  body('email').isEmail().withMessage('Invalid email format'),
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { email } = req.body;
      const result = await authService.sendOTP(email);
      res.json(result);
    } catch (error) {
      console.error('Error in send-otp:', error);
      res.status(500).json({ error: 'Failed to send OTP' });
    }
  }
);

// Verify OTP
router.post('/verify-otp',
  body('email').isEmail().withMessage('Invalid email format'),
  body('otp').isLength({ min: 6, max: 6 }).withMessage('OTP must be 6 digits'),
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { email, otp } = req.body;

      // Verify OTP with Supabase
      const authData = await authService.verifyOTP(email, otp);
      if (!authData || !authData.user) {
        return res.status(401).json({ error: 'Invalid or expired OTP' });
      }

      const supabaseUserId = authData.user.id;

      // Check if user exists in our users table
      const { data: users, error: userError } = await supabase
        .from('users')
        .select('*')
        .eq('email', email);

      let user;
      let isNewUser = false;

      if (!users || users.length === 0) {
        // Create new user
        isNewUser = true;
        const { data: newUser, error: createError } = await supabase
          .from('users')
          .insert({
            email,
            auth_user_id: supabaseUserId,
            role: 'user',
            created_at: new Date().toISOString()
          })
          .select()
          .single();

        if (createError) throw createError;
        user = newUser;
      } else {
        user = users[0];
        
        // Update auth_user_id if not set
        if (!user.auth_user_id) {
          await supabase
            .from('users')
            .update({ auth_user_id: supabaseUserId })
            .eq('id', user.id);
        }
      }

      // Create JWT token
      const accessToken = authService.createAccessToken(user.id, user.email);

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
router.post('/logout', async (req, res) => {
  try {
    // Sign out from Supabase
    await supabase.auth.signOut();
    res.json({ message: 'Logged out successfully' });
  } catch (error) {
    console.error('Error in logout:', error);
    res.status(500).json({ error: 'Failed to logout' });
  }
});

module.exports = router;
