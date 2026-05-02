const cron = require('node-cron');
const RepositoryFactory = require('../factories/RepositoryFactory');
const eventEmitter = require('../observers/EventEmitter');
const logger = require('../utils/logger');

const budgetAlertJob = cron.schedule('0 9 * * *', async () => {
  logger.info('Running budget alert job...');
  try {
    const budgetRepo = RepositoryFactory.getBudgetRepository();
    const userRepo = RepositoryFactory.getUserRepository();

    // Get all active budgets with spending above 80%
    const result = await budgetRepo.query(
      `SELECT b.*, c.name as category_name, u.email, u.name as user_name, u.currency,
              COALESCE(SUM(e.amount), 0) as spent_amount
       FROM budgets b
       JOIN users u ON b.user_id = u.id
       LEFT JOIN categories c ON b.category_id = c.category_id
       LEFT JOIN expenses e ON e.category_id = b.category_id
         AND e.user_id = b.user_id
         AND e.date BETWEEN b.start_date AND b.end_date
       WHERE NOW() BETWEEN b.start_date AND b.end_date
       GROUP BY b.budget_id, c.name, u.email, u.name, u.currency
       HAVING COALESCE(SUM(e.amount), 0) / b.limit_amount >= 0.8`,
      []
    );

    for (const budget of result.rows) {
      const pct = (parseFloat(budget.spent_amount) / parseFloat(budget.limit_amount)) * 100;
      await eventEmitter.emit('budget.exceeded', {
        userId: budget.user_id,
        email: budget.email,
        userName: budget.user_name,
        categoryName: budget.category_name,
        percentUsed: pct,
        amountSpent: budget.spent_amount,
        limit: budget.limit_amount,
        currency: budget.currency,
      });
    }
    logger.info(`Budget alert job: processed ${result.rows.length} budgets`);
  } catch (error) {
    logger.error('Budget alert job error:', error.message);
  }
}, { scheduled: false });

module.exports = budgetAlertJob;