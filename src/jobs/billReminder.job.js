const billService = require('../services/billService');
const emailService = require('../services/emailService');
const notificationService = require('../services/notificationService');
const { query } = require('../config/database');
const logger = require('../utils/logger');

/**
 * Send bill reminders for upcoming bills
 */
async function sendBillReminders() {
  try {
    logger.info('Starting bill reminder job...');

    // Get all users
    const users = await query('SELECT id FROM users');

    for (const user of users.rows) {
      const userId = user.id;

      // Get upcoming bills (next 7 days)
      const upcomingBills = await billService.getUpcomingBills(userId);

      for (const bill of upcomingBills) {
        const dueDate = new Date(bill.due_date);
        const today = new Date();
        const daysUntilDue = Math.ceil((dueDate - today) / (1000 * 60 * 60 * 24));

        // Send reminders at 7 days, 3 days, and 1 day before due
        if ([7, 3, 1].includes(daysUntilDue)) {
          // Create notification
          await notificationService.createNotification(userId, {
            message: `Bill reminder: ${bill.name} is due in ${daysUntilDue} day(s). Amount: $${bill.amount}`,
            type: 'reminder',
          });

          // Send email
          await emailService.sendBillReminderEmail(
            userId,
            bill.name,
            bill.amount,
            bill.due_date,
            daysUntilDue
          );

          logger.info(`Bill reminder sent for user ${userId}, bill ${bill.bill_id}`);
        }
      }

      // Check for overdue bills
      const overdueBills = await billService.getOverdueBills(userId);

      for (const bill of overdueBills) {
        // Create alert notification
        await notificationService.createNotification(userId, {
          message: `OVERDUE: ${bill.name} was due on ${bill.due_date}. Amount: $${bill.amount}`,
          type: 'alert',
        });

        logger.info(`Overdue bill alert sent for user ${userId}, bill ${bill.bill_id}`);
      }
    }

    logger.info('Bill reminder job completed successfully');
  } catch (error) {
    logger.error('Error in bill reminder job:', error);
  }
}

module.exports = sendBillReminders;