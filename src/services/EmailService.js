const emailAdapter = require('../adapters/EmailAdapter');
const BudgetAlertEmailTemplate = require('../templates/BudgetAlertEmailTemplate');
const BillReminderEmailTemplate = require('../templates/BillReminderEmailTemplate');
const ReportTemplate = require('../templates/ReportTemplate');
const logger = require('../utils/logger');

class EmailService {
  async sendBudgetAlert(data) {
    try {
      const template = new BudgetAlertEmailTemplate();
      const { subject, html } = template.generate(data);
      await emailAdapter.send({ to: data.email, subject, html });
    } catch (error) {
      logger.error('Budget alert email error:', error.message);
    }
  }

  async sendBillReminder(data) {
    try {
      const template = new BillReminderEmailTemplate();
      const { subject, html } = template.generate(data);
      await emailAdapter.send({ to: data.email, subject, html });
    } catch (error) {
      logger.error('Bill reminder email error:', error.message);
    }
  }

  async sendMonthlyReport(data) {
    try {
      const template = new ReportTemplate();
      const { subject, html } = template.generate(data);
      await emailAdapter.send({ to: data.email, subject, html });
    } catch (error) {
      logger.error('Monthly report email error:', error.message);
    }
  }

  async sendOtp(email, otp) {
    const html = `
      <h2>Your OTP Code</h2>
      <p>Your one-time password is: <strong style="font-size:24px">${otp}</strong></p>
      <p>This code expires in 10 minutes.</p>
    `;
    await emailAdapter.send({ to: email, subject: 'MoneyMate OTP Code', html });
  }

  async sendWelcome(name, email) {
    const html = `<h2>Welcome to MoneyMate, ${name}!</h2><p>Your account has been created successfully.</p>`;
    await emailAdapter.send({ to: email, subject: 'Welcome to MoneyMate!', html });
  }
}

module.exports = new EmailService();