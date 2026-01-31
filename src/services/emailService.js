const nodemailer = require('nodemailer');
const config = require('../config/config');

class EmailService {
  constructor() {
    // Create transporter using Gmail SMTP
    this.transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: config.email.user,
        pass: config.email.password
      }
    });
  }

  async sendOTPEmail(email, otp) {
    try {
      const mailOptions = {
        from: `"CURA Healthcare" <${config.email.user}>`,
        to: email,
        subject: 'Your CURA Verification Code',
        html: `
          <!DOCTYPE html>
          <html>
          <head>
            <style>
              body {
                font-family: Arial, sans-serif;
                line-height: 1.6;
                color: #333;
                max-width: 600px;
                margin: 0 auto;
                padding: 20px;
              }
              .container {
                background-color: #f9f9f9;
                border-radius: 10px;
                padding: 30px;
                text-align: center;
              }
              .logo {
                font-size: 28px;
                font-weight: bold;
                color: #4F46E5;
                margin-bottom: 20px;
              }
              .otp-code {
                font-size: 42px;
                font-weight: bold;
                letter-spacing: 10px;
                color: #4F46E5;
                background-color: #EEF2FF;
                padding: 20px;
                border-radius: 8px;
                margin: 30px 0;
              }
              .message {
                font-size: 16px;
                color: #666;
                margin: 20px 0;
              }
              .warning {
                font-size: 14px;
                color: #999;
                margin-top: 30px;
              }
              .footer {
                margin-top: 40px;
                padding-top: 20px;
                border-top: 1px solid #ddd;
                font-size: 12px;
                color: #999;
              }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="logo">🏥 CURA</div>
              <h2>Email Verification</h2>
              <p class="message">Your verification code is:</p>
              <div class="otp-code">${otp}</div>
              <p class="message">Enter this code in the CURA app to verify your email address.</p>
              <p class="warning">⏱️ This code will expire in 5 minutes.</p>
              <p class="warning">If you didn't request this code, please ignore this email.</p>
              <div class="footer">
                <p>© 2024 CURA Healthcare. All rights reserved.</p>
                <p>This is an automated email, please do not reply.</p>
              </div>
            </div>
          </body>
          </html>
        `
      };

      const info = await this.transporter.sendMail(mailOptions);
      console.log('Email sent successfully:', info.messageId);
      return true;
    } catch (error) {
      console.error('Error sending email:', error);
      return false;
    }
  }

  async verifyConnection() {
    try {
      await this.transporter.verify();
      console.log('Email service is ready to send emails');
      return true;
    } catch (error) {
      console.error('Email service connection failed:', error);
      return false;
    }
  }
}

module.exports = new EmailService();
