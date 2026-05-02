const EmailTemplate = require('./EmailTemplate');

/**
 * Budget Alert Email Template
 * Concrete implementation of EmailTemplate
 */
class BudgetAlertEmailTemplate extends EmailTemplate {
  getSubject(data) {
    const { categoryName, percentUsed } = data;
    if (percentUsed >= 100) {
      return `⚠️ Budget Exceeded: ${categoryName}`;
    }
    return `⚠️ Budget Alert: ${categoryName}`;
  }

  getHeader(data) {
    return '<h2>Budget Alert</h2>';
  }

  getBody(data) {
    const { userName, categoryName, percentUsed, amountSpent, budgetLimit, currency } = data;
    
    const status = percentUsed >= 100 ? 'exceeded' : 'approaching limit for';
    const colorClass = percentUsed >= 100 ? '#F44336' : '#FF9800';

    return `
      <p>Hi ${userName},</p>
      <p>You have <strong>${status}</strong> your budget for <strong>${categoryName}</strong>.</p>
      
      <div style="background-color: ${colorClass}20; padding: 15px; border-left: 4px solid ${colorClass}; margin: 20px 0;">
        <p style="margin: 5px 0;"><strong>Amount Spent:</strong> ${amountSpent} ${currency}</p>
        <p style="margin: 5px 0;"><strong>Budget Limit:</strong> ${budgetLimit} ${currency}</p>
        <p style="margin: 5px 0;"><strong>Percentage Used:</strong> ${percentUsed.toFixed(1)}%</p>
        <p style="margin: 5px 0;"><strong>Remaining:</strong> ${Math.max(0, budgetLimit - amountSpent).toFixed(2)} ${currency}</p>
      </div>

      ${percentUsed >= 100 
        ? '<p>⚠️ <strong>You have exceeded your budget!</strong> Consider reviewing your spending in this category.</p>'
        : '<p>⚠️ <strong>You are approaching your budget limit.</strong> Please monitor your spending carefully.</p>'
      }
      
      <p>Log in to MoneyMate to view detailed insights and adjust your budget if needed.</p>
    `;
  }
}

module.exports = BudgetAlertEmailTemplate;