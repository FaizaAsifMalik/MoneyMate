const { transporter } = require('../config/email');
const { config } = require('../config/env');
const logger = require('../utils/logger');

class EmailAdapter {
  async send({ to, subject, html }) {
    try {
      const info = await transporter.sendMail({
        from: config.email.from,
        to,
        subject,
        html,
      });
      logger.info(`Email sent to ${to}: ${info.messageId}`);
      return { success: true, messageId: info.messageId };
    } catch (error) {
      logger.error('Email send error:', error.message);
      throw new Error('Failed to send email');
    }
  }
}

module.exports = new EmailAdapter();