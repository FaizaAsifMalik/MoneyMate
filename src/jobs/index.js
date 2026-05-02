const billReminderJob = require('./billReminder.job');
const budgetAlertJob = require('./budgetAlert.job');
const logger = require('../utils/logger');

const startJobs = () => {
  billReminderJob.start();
  budgetAlertJob.start();
  logger.info('Scheduled jobs started');
};

const stopJobs = () => {
  billReminderJob.stop();
  budgetAlertJob.stop();
  logger.info('Scheduled jobs stopped');
};

module.exports = { startJobs, stopJobs };