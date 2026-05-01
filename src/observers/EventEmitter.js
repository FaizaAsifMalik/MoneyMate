const EventEmitter = require('events');

/**
 * Application Event Emitter
 * Implements Observer Pattern
 */
class AppEventEmitter extends EventEmitter {
  constructor() {
    super();
    this.setupListeners();
  }

  setupListeners() {
    // Budget exceeded event
    this.on('budget.exceeded', async (data) => {
      const { userId, categoryName, percentUsed, amount, limit } = data;
      const notificationService = require('../services/notificationService');
      const emailService = require('../services/emailService');

      await notificationService.createNotification(userId, {
        message: `Budget exceeded for ${categoryName} by ${(percentUsed - 100).toFixed(1)}%`,
        type: 'alert',
      });

      await emailService.sendBudgetAlertEmail(
        userId,
        categoryName,
        percentUsed,
        amount,
        limit
      );
    });

    // Goal completed event
    this.on('goal.completed', async (data) => {
      const { userId, goalTitle } = data;
      const notificationService = require('../services/notificationService');

      await notificationService.createNotification(userId, {
        message: `Congratulations! You've completed your goal: ${goalTitle}`,
        type: 'info',
      });
    });

    // Bill overdue event
    this.on('bill.overdue', async (data) => {
      const { userId, billName, amount, dueDate } = data;
      const notificationService = require('../services/notificationService');

      await notificationService.createNotification(userId, {
        message: `OVERDUE: ${billName} was due on ${dueDate}. Amount: $${amount}`,
        type: 'alert',
      });
    });
  }
}

module.exports = new AppEventEmitter();