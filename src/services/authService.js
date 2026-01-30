const { supabase } = require('../config/supabase');
const jwt = require('jsonwebtoken');
const config = require('../config/config');
const msg91Service = require('./msg91Service');

class AuthService {
  generateOTP() {
    return Math.floor(1000 + Math.random() * 9000).toString();
  }

  async sendOTP(phone) {
    try {
      const otp = this.generateOTP();
      const expiresAt = new Date(Date.now() + config.otp.expiryMinutes * 60 * 1000);

      // Delete existing OTPs for this phone
      await supabase
        .from('otp_verifications')
        .delete()
        .eq('phone', phone);

      // Store new OTP
      const { error } = await supabase
        .from('otp_verifications')
        .insert({
          phone,
          otp,
          expires_at: expiresAt.toISOString(),
          is_verified: false,
          created_at: new Date().toISOString()
        });

      if (error) throw error;

      // Send OTP via MSG91
      const smsSent = await msg91Service.sendOTP(phone, otp);

      if (!smsSent) {
        console.warn(`Failed to send OTP via MSG91 to ${phone}`);
      }

      const result = {
        message: 'OTP sent successfully',
        phone,
        expires_in_minutes: config.otp.expiryMinutes
      };

      // In development, include OTP in response
      if (config.nodeEnv === 'development') {
        result.otp = otp;
        console.log(`DEBUG MODE: OTP for ${phone} is ${otp}`);
      }

      return result;
    } catch (error) {
      console.error('Error sending OTP:', error);
      throw error;
    }
  }

  async verifyOTP(phone, otp) {
    try {
      const { data, error } = await supabase
        .from('otp_verifications')
        .select('*')
        .eq('phone', phone)
        .eq('otp', otp)
        .eq('is_verified', false)
        .single();

      if (error || !data) {
        console.warn(`Invalid OTP attempt for ${phone}`);
        return false;
      }

      // Check if expired
      const expiresAt = new Date(data.expires_at);
      if (new Date() > expiresAt) {
        console.warn(`Expired OTP attempt for ${phone}`);
        return false;
      }

      // Mark as verified
      await supabase
        .from('otp_verifications')
        .update({ is_verified: true })
        .eq('id', data.id);

      console.log(`OTP verified successfully for ${phone}`);
      return true;
    } catch (error) {
      console.error('Error verifying OTP:', error);
      return false;
    }
  }

  createAccessToken(userId, phone) {
    return jwt.sign(
      { sub: userId, phone },
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
