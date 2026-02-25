const nodemailer = require('nodemailer');
const sgMail = require('@sendgrid/mail');

class SendGridEmailService {
  constructor() {
    this.sendgrid = sgMail.setApiKey(process.env.SENDGRID_API_KEY);
    this.fromName = process.env.FROM_NAME || 'Flownet Workspaces';
    this.fromEmail = process.env.FROM_EMAIL || 'dhlamininaomi1@gmail.com';
    this.replyTo = process.env.EMAIL_REPLY_TO || this.fromEmail;
    
    // Debug logging to see what email is being used
    console.log('📧 SendGrid Configuration:');
    console.log('  FROM_EMAIL env var:', process.env.FROM_EMAIL);
    console.log('  Final fromEmail:', this.fromEmail);
    console.log('  fromName:', this.fromName);
  }

  // Test SendGrid connection
  async testConnection() {
    try {
      if (!process.env.SENDGRID_API_KEY) {
        console.log('⚠️  SENDGRID_API_KEY not configured');
        return false;
      }
      console.log('✅ SendGrid initialized successfully');
      return true;
    } catch (error) {
      console.error('❌ SendGrid initialization failed:', error.message);
      return false;
    }
  }

  // Send verification email
  async sendVerificationEmail(toEmail, userName, verificationCode) {
    try {
      const mailOptions = {
        to: toEmail,
        from: {
          name: this.fromName,
          email: this.fromEmail
        },
        subject: 'Verify Your Email - Flownet Workspaces',
        html: this.buildVerificationEmailHtml(userName, verificationCode),
        replyTo: this.replyTo
      };

      const result = await this.sendgrid.send(mailOptions);
      console.log('✅ Verification email sent successfully via SendGrid:', result[0].messageId);
      return { success: true, messageId: result[0].messageId };
    } catch (error) {
      console.error('❌ Failed to send verification email via SendGrid:', error.message);
      
      // Better error debugging
      if (error.response) {
        console.error('📧 SendGrid API Response:', {
          status: error.response.status,
          body: error.response.body
        });
        
        // Specific error guidance
        if (error.response.status === 401) {
          console.error('🔑 SendGrid Error: Invalid API Key');
          console.error('💡 Fix: Check SENDGRID_API_KEY in Render environment variables');
        } else if (error.response.status === 403) {
          console.error('📧 SendGrid Error: Sender not verified');
          console.error('💡 Fix: Verify your sender email/domain in SendGrid dashboard');
        } else if (error.response.status === 400) {
          console.error('📧 SendGrid Error: Bad request - check FROM_EMAIL format');
          console.error('💡 Fix: Ensure FROM_EMAIL matches verified sender');
        }
      } else if (error.code === 'ENOTFOUND') {
        console.error('🌐 SendGrid Error: Network connection failed');
        console.error('💡 Fix: Check internet connection and firewall settings');
      }
      
      // Fallback to SMTP if SendGrid fails
      return await this.sendViaSmtpFallback(toEmail, userName, verificationCode);
    }
  }

  // Fallback to SMTP
  async sendViaSmtpFallback(toEmail, userName, verificationCode) {
    try {
      const transporter = nodemailer.createTransport({
        host: process.env.SMTP_HOST || 'smtp.gmail.com',
        port: parseInt(process.env.SMTP_PORT) || 587,
        secure: process.env.SMTP_SECURE === 'true' || false,
        auth: {
          user: process.env.SMTP_USER,
          pass: (process.env.SMTP_PASS || '').replace(/\s+/g, '')
        }
      });

      const mailOptions = {
        from: {
          name: this.fromName,
          address: process.env.SMTP_FROM_EMAIL || process.env.SMTP_USER
        },
        to: toEmail,
        subject: 'Verify Your Email - Flownet Workspaces',
        html: this.buildVerificationEmailHtml(userName, verificationCode),
        replyTo: this.replyTo
      };

      const result = await transporter.sendMail(mailOptions);
      console.log('✅ Verification email sent via SMTP fallback:', result.messageId);
      return { success: true, messageId: result.messageId };
    } catch (error) {
      console.error('❌ SMTP fallback also failed:', error.message);
      return { success: false, error: error.message };
    }
  }

  buildVerificationEmailHtml(userName, verificationCode) {
    return `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Email Verification</title>
        <style>
          body { font-family: 'Poppins', sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5; }
          .container { max-width: 600px; margin: 0 auto; background-color: white; border-radius: 8px; padding: 30px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
          .header { text-align: center; margin-bottom: 30px; }
          .logo { font-size: 24px; font-weight: bold; color: #C10D00; }
          .content { margin-bottom: 30px; }
          .code { background-color: #f8f9fa; border: 2px solid #e9ecef; border-radius: 8px; padding: 20px; text-align: center; font-size: 32px; font-weight: bold; letter-spacing: 4px; margin: 20px 0; color: #C10D00; }
          .footer { text-align: center; color: #6c757d; font-size: 14px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <div class="logo">Flownet Workspaces</div>
          </div>
          <div class="content">
            <h2>Hello ${userName},</h2>
            <p>Thank you for signing up! Please use the verification code below to activate your account:</p>
            <div class="code">${verificationCode}</div>
            <p>This code will expire in 24 hours.</p>
            <p>If you didn't request this verification, please ignore this email.</p>
          </div>
          <div class="footer">
            <p>&copy; 2026 Flownet Workspaces. All rights reserved.</p>
          </div>
        </div>
      </body>
      </html>
    `;
  }
}

module.exports = SendGridEmailService;
