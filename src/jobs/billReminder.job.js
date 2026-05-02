const cron = require('node-cron');
const RepositoryFactory = require('../factories/RepositoryFactory');
const eventEmitter = require('../observers/EventEmitter');
const logger = require('../utils/logger');

const billReminderJob = cron.schedule('0 8 * * *', async () => {
  logger.info('Running bill reminder job...');
  try {
    const billRepo = RepositoryFactory.getBillRepository();
    const bills = await billRepo.findAllUpcomingForReminders(3);

    for (const bill of bills) {
      const daysUntilDue = Math.ceil((new Date(bill.next_due_date) - new Date()) / (1000 * 60 * 60 * 24));
      await eventEmitter.emit('bill.reminder', {
        userId: bill.user_id,
        email: bill.email,
        userName: bill.user_name,
        billName: bill.name,
        amount: bill.amount,
        currency: bill.currency,
        dueDate: new Date(bill.next_due_date).toISOString().split('T')[0],
        daysUntilDue,
      });
    }
    logger.info(`Bill reminder job: processed ${bills.length} bills`);
  } catch (error) {
    logger.error('Bill reminder job error:', error.message);
  }
}, { scheduled: false });

module.exports = billReminderJob;