const { sendEmail } = require('../config/email');
const { query } = require('../config/database');
const logger = require('../utils/logger');

class EmailService {
  /**
   * Send welcome email
   */
  async sendWelcomeEmail(email, name) {
    const subject = 'Welcome to MoneyMate!';
    const html = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #4CAF50;">Welcome to MoneyMate, ${name}!</h2>
        <p>Thank you for joining MoneyMate. We're excited to help you manage your finances better.</p>
        <p>Here's what you can do with MoneyMate:</p>
        <ul>
          <li>Track your income and expenses</li>
          <li>Set budgets and financial goals</li>
          <li>Manage bills and recurring payments</li>
          <li>Get AI-powered insights and suggestions</li>
        </ul>
        <p>Get started by logging in and exploring the dashboard!</p>
        <p>Best regards,<br>The MoneyMate Team</p>
      </div>
    `;

    await sendEmail({ to: email, subject, html });
    
    logger.info(`Welcome email sent to ${email}`);
  }

  /**
   * Send password reset email
   */
  async sendPasswordResetEmail(email, name, otp) {
    const subject = 'Password Reset Request - MoneyMate';
    const html = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #F44336;">Password Reset Request</h2>
        <p>Hi ${name},</p>
        <p>We received a request to reset your password. Use the OTP below to reset your password:</p>
        <div style="background-color: #f5f5f5; padding: 20px; text-align: center; margin: 20px 0;">
          <h1 style="color: #333; letter-spacing: 5px; margin: 0;">${otp}</h1>
        </div>
        <p>This OTP is valid for 10 minutes.</p>
        <p>If you didn't request this, please ignore this email.</p>
        <p>Best regards,<br>The MoneyMate Team</p>
      </div>
    `;

    await sendEmail({ to: email, subject, html });

    logger.info(`Password reset email sent to ${email}`);
  }

  /**
   * Send budget alert email
   */
  async sendBudgetAlertEmail(userId, categoryName, percentUsed, amountSpent, budgetLimit) {
    const user = await query('SELECT email, name FROM users WHERE id = $1', [userId]);
    
    if (user.rows.length === 0) return;

    const { email, name } = user.rows[0];
    const subject = `Budget Alert: ${categoryName}`;
    const html = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #FF9800;">Budget Alert</h2>
        <p>Hi ${name},</p>
        <p>You have used <strong>${percentUsed}%</strong> of your budget for <strong>${categoryName}</strong>.</p>
        <div style="background-color: #fff3cd; padding: 15px; border-left: 4px solid #FF9800; margin: 20px 0;">
          <p style="margin: 5px 0;"><strong>Amount Spent:</strong> $${amountSpent}</p>
          <p style="margin: 5px 0;"><strong>Budget Limit:</strong> $${budgetLimit}</p>
          <p style="margin: 5px 0;"><strong>Remaining:</strong> $${(budgetLimit - amountSpent).toFixed(2)}</p>
        </div>
        <p>Consider reviewing your spending in this category.</p>
        <p>Best regards,<br>The MoneyMate Team</p>
      </div>
    `;

    await sendEmail({ to: email, subject, html });

    // Save to emails table
    await query(
      `INSERT INTO emails (user_id, subject, body, sent_at, status)
       VALUES ($1, $2, $3, NOW(), 'sent')`,
      [userId, subject, html]
    );

    logger.info(`Budget alert email sent to ${email}`);
  }

  /**
   * Send bill reminder email
   */
  async sendBillReminderEmail(userId, billName, amount, dueDate, daysUntilDue) {
    const user = await query('SELECT email, name FROM users WHERE id = $1', [userId]);
    
    if (user.rows.length === 0) return;

    const { email, name } = user.rows[0];
    const subject = `Bill Reminder: ${billName}`;
    const urgency = daysUntilDue <= 3 ? 'urgent' : 'normal';
    const color = urgency === 'urgent' ? '#F44336' : '#2196F3';

    const html = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: ${color};">Bill Reminder</h2>
        <p>Hi ${name},</p>
        <p>This is a reminder that your bill <strong>${billName}</strong> is due soon.</p>
        <div style="background-color: #f5f5f5; padding: 15px; border-left: 4px solid ${color}; margin: 20px 0;">
          <p style="margin: 5px 0;"><strong>Bill Name:</strong> ${billName}</p>
          <p style="margin: 5px 0;"><strong>Amount:</strong> $${amount}</p>
          <p style="margin: 5px 0;"><strong>Due Date:</strong> ${dueDate}</p>
          <p style="margin: 5px 0;"><strong>Days Until Due:</strong> ${daysUntilDue}</p>
        </div>
        <p>Don't forget to make the payment on time!</p>
        <p>Best regards,<br>The MoneyMate Team</p>
      </div>
    `;

    await sendEmail({ to: email, subject, html });

    // Save to emails table
    await query(
      `INSERT INTO emails (user_id, subject, body, sent_at, status)
       VALUES ($1, $2, $3, NOW(), 'sent')`,
      [userId, subject, html]
    );

    logger.info(`Bill reminder email sent to ${email}`);
  }

  /**
   * Send AI insight email
   */
  async sendAIInsightEmail(userId, insights) {
    const user = await query('SELECT email, name FROM users WHERE id = $1', [userId]);
    
    if (user.rows.length === 0) return;

    const { email, name } = user.rows[0];
    const subject = 'Your Weekly Financial Insights';
    
    const insightsList = insights.map(insight => 
      `<li style="margin-bottom: 10px;">${insight}</li>`
    ).join('');

    const html = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #9C27B0;">Your Weekly Financial Insights</h2>
        <p>Hi ${name},</p>
        <p>Here are your personalized financial insights for this week:</p>
        <ul style="line-height: 1.8;">
          ${insightsList}
        </ul>
        <p>Keep up the good work managing your finances!</p>
        <p>Best regards,<br>The MoneyMate Team</p>
      </div>
    `;

    await sendEmail({ to: email, subject, html });

    // Save to emails table
    await query(
      `INSERT INTO emails (user_id, subject, body, sent_at, status)
       VALUES ($1, $2, $3, NOW(), 'sent')`,
      [userId, subject, html]
    );

    logger.info(`AI insight email sent to ${email}`);
  }
}

module.exports = new EmailService();