const cron = require('node-cron');
const sendBillReminders = require('./billReminder.job');
const checkBudgetAlerts = require('./budgetAlert.job');
const logger = require('../utils/logger');

/**
 * Initialize all scheduled jobs
 */
function initializeJobs() {
  // Run bill reminders every day at 9:00 AM
  cron.schedule('0 9 * * *', async () => {
    logger.info('Running scheduled bill reminder job');
    await sendBillReminders();
  });

  // Run budget alerts every day at 8:00 PM
  cron.schedule('0 20 * * *', async () => {
    logger.info('Running scheduled budget alert job');
    await checkBudgetAlerts();
  });

  logger.info('✅ Scheduled jobs initialized');
}

module.exports = {
  initializeJobs,
  sendBillReminders,
  checkBudgetAlerts,
};