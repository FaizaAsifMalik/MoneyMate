const nodemailer = require('nodemailer');
const { config } = require('./env');
const logger = require('../utils/logger');

// Create transporter
const transporter = nodemailer.createTransport(config.email);

// Verify connection configuration
transporter.verify((error) => {
  if (error) {
    logger.error('Email configuration error:', error);
  } else {
    logger.info('✅ Email service is ready');
  }
});

/**
 * Send email
 * @param {Object} mailOptions - Email options
 * @returns {Promise}
 */
const sendEmail = async (mailOptions) => {
  try {
    const info = await transporter.sendMail({
      from: config.email.from,
      ...mailOptions,
    });
    logger.info(`Email sent: ${info.messageId}`);
    return info;
  } catch (error) {
    logger.error('Error sending email:', error);
    throw error;
  }
};

module.exports = {
  transporter,
  sendEmail,
};