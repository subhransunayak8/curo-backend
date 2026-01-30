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

      console.log(`Attempting to send OTP to ${mobile} via MSG91`);
      console.log(`Using Auth Key: ${this.authKey ? 'Present' : 'Missing'}`);
      console.log(`Using Template ID: ${this.templateId || 'None'}`);

      // MSG91 Send OTP API v5
      const url = `${this.baseUrl}/otp`;
      
      const requestData = {
        template_id: this.templateId,
        mobile: mobile,
        authkey: this.authKey,
        otp: otp
      };

      // If no template, send as SMS
      if (!this.templateId) {
        console.log('No template ID, sending as direct SMS');
        const smsUrl = 'https://control.msg91.com/api/v5/flow/';
        const smsData = {
          flow_id: this.templateId || '',
          sender: this.senderId,
          mobiles: mobile,
          VAR1: otp,
          VAR2: config.otp.expiryMinutes
        };

        const smsResponse = await axios.post(smsUrl, smsData, {
          headers: {
            'authkey': this.authKey,
            'content-type': 'application/json'
          },
          timeout: 30000
        });

        console.log('MSG91 Response:', JSON.stringify(smsResponse.data));
        
        if (smsResponse.data.type === 'error') {
          console.error('MSG91 Error:', smsResponse.data.message);
          return false;
        }

        console.log(`OTP sent successfully to ${mobile} via MSG91`);
        return true;
      }

      const response = await axios.post(url, requestData, {
        headers: {
          'authkey': this.authKey,
          'content-type': 'application/json'
        },
        timeout: 30000
      });

      console.log('MSG91 Response:', JSON.stringify(response.data));
      
      if (response.data.type === 'error') {
        console.error('MSG91 Error:', response.data.message);
        return false;
      }

      console.log(`OTP sent successfully to ${mobile} via MSG91`);
      return true;
    } catch (error) {
      console.error(`Error sending OTP via MSG91:`, error.response?.data || error.message);
      if (error.response) {
        console.error('Response status:', error.response.status);
        console.error('Response data:', JSON.stringify(error.response.data));
      }
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
