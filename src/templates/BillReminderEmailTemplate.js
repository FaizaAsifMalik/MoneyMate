const EmailTemplate = require('./EmailTemplate');

/**
 * Bill Reminder Email Template
 */
class BillReminderEmailTemplate extends EmailTemplate {
  getSubject(data) {
    const { billName, daysUntilDue } = data;
    if (daysUntilDue <= 1) {
      return `🔴 URGENT: ${billName} Due ${daysUntilDue === 0 ? 'Today' : 'Tomorrow'}`;
    }
    return `📅 Bill Reminder: ${billName} Due in ${daysUntilDue} Days`;
  }

  getHeader(data) {
    return '<h2>Bill Reminder</h2>';
  }

  getBody(data) {
    const { userName, billName, amount, currency, dueDate, daysUntilDue } = data;
    const urgency = daysUntilDue <= 3 ? 'urgent' : 'normal';
    const color = urgency === 'urgent' ? '#F44336' : '#2196F3';

    return `
      <p>Hi ${userName},</p>
      <p>This is a reminder that your bill <strong>${billName}</strong> is due soon.</p>
      
      <div style="background-color: ${color}20; padding: 15px; border-left: 4px solid ${color}; margin: 20px 0;">
        <p style="margin: 5px 0;"><strong>Bill Name:</strong> ${billName}</p>
        <p style="margin: 5px 0;"><strong>Amount:</strong> ${amount} ${currency}</p>
        <p style="margin: 5px 0;"><strong>Due Date:</strong> ${dueDate}</p>
        <p style="margin: 5px 0;"><strong>Days Until Due:</strong> ${daysUntilDue}</p>
      </div>

      ${urgency === 'urgent' 
        ? '<p>⚠️ <strong>This bill is due very soon!</strong> Please make the payment as soon as possible.</p>'
        : '<p>Don\'t forget to make the payment on time to avoid late fees.</p>'
      }
      
      <p>You can mark this bill as paid in the MoneyMate app.</p>
    `;
  }
}

module.exports = BillReminderEmailTemplate;