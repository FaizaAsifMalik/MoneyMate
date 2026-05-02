const EmailTemplate = require('./EmailTemplate');

class ReportTemplate extends EmailTemplate {
  getSubject(data) {
    return `📊 Your Monthly Financial Report - ${data.month}`;
  }

  getHeader(data) {
    return `<h2>Monthly Financial Report</h2><p>${data.month}</p>`;
  }

  getBody(data) {
    const { userName, totalIncome, totalExpenses, netSavings, currency, topCategories } = data;
    const savingsColor = netSavings >= 0 ? '#4CAF50' : '#F44336';

    const categoryRows = (topCategories || []).map(c =>
      `<tr><td>${c.name}</td><td>${parseFloat(c.total).toFixed(2)} ${currency}</td></tr>`
    ).join('');

    return `
      <p>Hi ${userName}, here is your monthly financial summary:</p>
      <table style="width:100%; border-collapse:collapse; margin:20px 0;">
        <tr style="background:#f0f0f0"><td style="padding:8px"><strong>Total Income</strong></td><td style="padding:8px; color:#4CAF50">${totalIncome} ${currency}</td></tr>
        <tr><td style="padding:8px"><strong>Total Expenses</strong></td><td style="padding:8px; color:#F44336">${totalExpenses} ${currency}</td></tr>
        <tr style="background:#f0f0f0"><td style="padding:8px"><strong>Net Savings</strong></td><td style="padding:8px; color:${savingsColor}">${netSavings} ${currency}</td></tr>
      </table>
      ${categoryRows.length > 0 ? `
        <p><strong>Top Spending Categories:</strong></p>
        <table style="width:100%; border-collapse:collapse">${categoryRows}</table>
      ` : ''}
    `;
  }
}

module.exports = ReportTemplate;