const eventEmitter = require('../observers/EventEmitter');
const budgetService = require('../services/BudgetService');
const emailService = require('../services/emailService');
const notificationService = require('../services/notificationService');
const { query } = require('../config/database');
const logger = require('../utils/logger');

/**
 * Check budgets and send alerts
 */
async function checkBudgetAlerts() {
  try {
    logger.info('Starting budget alert job...');

    // Get all users
    const users = await query('SELECT id FROM users');

    for (const user of users.rows) {
      const userId = user.id;

      // Get active budgets
      const budgets = await budgetService.getBudgets(userId, { active: true });

      for (const budget of budgets) {
        const percentUsed = parseFloat(budget.percent_used);

        // Send alerts at 80%, 90%, and 100%
        if (percentUsed >= 80 && percentUsed < 90) {
  eventEmitter.emit('budget.exceeded', {
    userId,
    categoryName: budget.category_name,
    percentUsed,
    amount: budget.spent_amount,
    limit: budget.limit_amount,
  });
        } else if (percentUsed >= 90 && percentUsed < 100) {
  eventEmitter.emit('budget.exceeded', {
    userId,
    categoryName: budget.category_name,
    percentUsed,
    amount: budget.spent_amount,
    limit: budget.limit_amount,
  });

        } else if (percentUsed >= 100) {
  eventEmitter.emit('budget.exceeded', {
    userId,
    categoryName: budget.category_name,
    percentUsed,
    amount: budget.spent_amount,
    limit: budget.limit_amount,
  });
        }

        logger.info(`Budget check completed for user ${userId}, budget ${budget.budget_id}`);
      }
    }

    logger.info('Budget alert job completed successfully');
  } catch (error) {
    logger.error('Error in budget alert job:', error);
  }
}

module.exports = checkBudgetAlerts;