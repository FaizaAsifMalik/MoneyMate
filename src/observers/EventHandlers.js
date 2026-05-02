const eventEmitter = require('./EventEmitter');
const NotificationTemplate = require('../templates/NotificationTemplate');
const logger = require('../utils/logger');

// Register all event handlers
const registerHandlers = (notificationService, emailService) => {

  eventEmitter.on('budget.exceeded', async (data) => {
    logger.info(`Budget exceeded event for user ${data.userId}`);
    const tpl = NotificationTemplate.budgetAlert(data.categoryName, data.percentUsed, data.amountSpent, data.limit, data.currency);
    await notificationService.create({ ...tpl, userId: data.userId });
  });

  eventEmitter.on('bill.reminder', async (data) => {
    logger.info(`Bill reminder event for user ${data.userId}`);
    const tpl = NotificationTemplate.billReminder(data.billName, data.daysUntilDue, data.amount, data.currency);
    await notificationService.create({ ...tpl, userId: data.userId });
    if (data.email) {
      await emailService.sendBillReminder(data);
    }
  });

  eventEmitter.on('goal.completed', async (data) => {
    logger.info(`Goal completed event for user ${data.userId}`);
    const tpl = NotificationTemplate.goalCompleted(data.title, data.targetAmount, data.currency);
    await notificationService.create({ ...tpl, userId: data.userId });
  });
};

module.exports = { registerHandlers };