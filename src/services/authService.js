const { supabase } = require('../config/supabase');
const jwt = require('jsonwebtoken');
const config = require('../config/config');
const emailService = require('./emailService');

class AuthService {
  generateOTP() {
    // Generate 6-digit OTP
    return Math.floor(100000 + Math.random() * 900000).toString();
  }

  async sendOTP(email) {
    try {
      console.log(`Sending OTP to email: ${email}`);

      const otp = this.generateOTP();
      const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // 5 minutes

      // Delete existing OTPs for this email
      await supabase
        .from('email_otps')
        .delete()
        .eq('email', email);

      // Store new OTP in database
      const { error: insertError } = await supabase
        .from('email_otps')
        .insert({
          email,
          otp,
          expires_at: expiresAt.toISOString(),
          is_verified: false,
          created_at: new Date().toISOString()
        });

      if (insertError) {
        console.error('Error storing OTP:', insertError);
        throw insertError;
      }

      console.log(`OTP stored in database for ${email}`);

      // Send OTP via email using Nodemailer
      const emailSent = await emailService.sendOTPEmail(email, otp);

      if (!emailSent) {
        console.warn(`Failed to send OTP email to ${email}, but OTP is stored in DB`);
      } else {
        console.log(`OTP email sent successfully to ${email}`);
      }

      const result = {
        message: 'A 6-digit verification code has been sent to your email. Please check your inbox.',
        email: email
      };

      // In development, include OTP in response for testing
      if (config.nodeEnv === 'development') {
        result.otp = otp;
        console.log(`DEBUG MODE: OTP for ${email} is ${otp}`);
      }

      return result;
    } catch (error) {
      console.error('Error sending OTP:', error);
      throw error;
    }
  }

  async verifyOTP(email, otp) {
    try {
      console.log(`Verifying OTP for email: ${email}`);

      // Get OTP from database
      const { data, error } = await supabase
        .from('email_otps')
        .select('*')
        .eq('email', email)
        .eq('otp', otp)
        .eq('is_verified', false)
        .single();

      if (error || !data) {
        console.warn(`Invalid OTP attempt for ${email}`);
        return null;
      }

      // Check if expired
      const expiresAt = new Date(data.expires_at);
      if (new Date() > expiresAt) {
        console.warn(`Expired OTP attempt for ${email}`);
        return null;
      }

      // Mark as verified
      await supabase
        .from('email_otps')
        .update({ is_verified: true })
        .eq('id', data.id);

      console.log(`OTP verified successfully for ${email}`);

      // Return user data in format expected by routes
      return {
        user: {
          id: data.id,
          email: email
        }
      };
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
