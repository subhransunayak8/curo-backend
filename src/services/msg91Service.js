const axios = require('axios');
const config = require('../config/config');

class MSG91Service {
  constructor() {
    this.baseUrl = 'https://control.msg91.com/api/v5';
    this.authKey = config.msg91.authKey;
    this.senderId = config.msg91.senderId;
    this.templateId = config.msg91.templateId;
  }

  async sendOTP(phone, otp) {
    try {
      // Remove '+' and format phone number
      const mobile = phone.replace(/[^0-9]/g, '');

      const params = {
        template_id: this.templateId,
        mobile: mobile,
        authkey: this.authKey,
        otp: otp,
        otp_expiry: config.otp.expiryMinutes
      };

      // If no template, use direct message
      if (!this.templateId) {
        params.sender = this.senderId;
        params.otp_length = 4;
      }

      const response = await axios.post(`${this.baseUrl}/otp`, null, {
        params,
        headers: {
          'accept': 'application/json',
          'content-type': 'application/json',
          'authkey': this.authKey
        },
        timeout: 30000
      });

      console.log(`OTP sent successfully to ${mobile} via MSG91`);
      return true;
    } catch (error) {
      console.error(`Error sending OTP via MSG91:`, error.message);
      return false;
    }
  }

  async verifyOTP(phone, otp) {
    try {
      const mobile = phone.replace(/[^0-9]/g, '');

      const response = await axios.get(`${this.baseUrl}/otp/verify`, {
        params: {
          authkey: this.authKey,
          mobile: mobile,
          otp: otp
        },
        headers: {
          'accept': 'application/json',
          'authkey': this.authKey
        },
        timeout: 30000
      });

      return response.data.type === 'success';
    } catch (error) {
      console.error(`Error verifying OTP with MSG91:`, error.message);
      return false;
    }
  }

  async resendOTP(phone, retryType = 'text') {
    try {
      const mobile = phone.replace(/[^0-9]/g, '');

      const response = await axios.get(`${this.baseUrl}/otp/retry`, {
        params: {
          authkey: this.authKey,
          mobile: mobile,
          retrytype: retryType
        },
        headers: {
          'accept': 'application/json',
          'authkey': this.authKey
        },
        timeout: 30000
      });

      console.log(`OTP resent successfully to ${mobile} via MSG91`);
      return true;
    } catch (error) {
      console.error(`Error resending OTP via MSG91:`, error.message);
      return false;
    }
  }
}

module.exports = new MSG91Service();
