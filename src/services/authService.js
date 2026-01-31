const { supabase } = require('../config/supabase');
const jwt = require('jsonwebtoken');
const config = require('../config/config');

class AuthService {
  async sendOTP(email) {
    try {
      console.log(`Sending OTP to email: ${email}`);

      // Use Supabase Auth to send OTP via email
      // Setting shouldCreateUser to false and using email type forces OTP
      const { data, error } = await supabase.auth.signInWithOtp({
        email: email,
        options: {
          shouldCreateUser: true,
          data: {
            // Additional metadata if needed
          }
        }
      });

      if (error) {
        console.error('Error sending OTP via Supabase:', error);
        throw error;
      }

      console.log(`OTP sent successfully to ${email} via Supabase`);
      console.log('Supabase response:', data);

      return {
        message: 'A 6-digit verification code has been sent to your email. Please check your inbox.',
        email: email
      };
    } catch (error) {
      console.error('Error sending OTP:', error);
      throw error;
    }
  }

  async verifyOTP(email, otp) {
    try {
      console.log(`Verifying OTP for email: ${email}`);

      // Verify OTP with Supabase Auth
      const { data, error } = await supabase.auth.verifyOtp({
        email: email,
        token: otp,
        type: 'email'
      });

      if (error) {
        console.error('Error verifying OTP:', error);
        return null;
      }

      console.log(`OTP verified successfully for ${email}`);
      return data;
    } catch (error) {
      console.error('Error verifying OTP:', error);
      return null;
    }
  }

  createAccessToken(userId, email) {
    return jwt.sign(
      { sub: userId, email },
      config.jwt.secret,
      { expiresIn: config.jwt.expiresIn }
    );
  }

  verifyToken(token) {
    try {
      return jwt.verify(token, config.jwt.secret);
    } catch (error) {
      return null;
    }
  }
}

module.exports = new AuthService();
