const IAnalysisStrategy = require('./interfaces/IAnalysisStrategy');

class TrendAnalysisStrategy extends IAnalysisStrategy {
  async analyze(data) {
    const { monthlyExpenses, monthlyIncomes } = data;

    const expenseTrend = this._calculateTrend(monthlyExpenses);
    const incomeTrend = this._calculateTrend(monthlyIncomes);

    return {
      expenseTrend: expenseTrend.direction,
      expenseChangePercent: expenseTrend.changePercent,
      incomeTrend: incomeTrend.direction,
      incomeChangePercent: incomeTrend.changePercent,
      netTrend: incomeTrend.avg - expenseTrend.avg,
      summary: this._buildSummary(expenseTrend, incomeTrend),
    };
  }

  _calculateTrend(monthlyData) {
    if (!monthlyData || monthlyData.length < 2) {
      return { direction: 'stable', changePercent: 0, avg: 0 };
    }

    const totals = monthlyData.map(m => parseFloat(m.total) || 0);
    const avg = totals.reduce((a, b) => a + b, 0) / totals.length;
    const recent = totals[0];
    const previous = totals[1];

    const changePercent = previous > 0 ? ((recent - previous) / previous) * 100 : 0;
    const direction = changePercent > 5 ? 'increasing' : changePercent < -5 ? 'decreasing' : 'stable';

    return { direction, changePercent: parseFloat(changePercent.toFixed(2)), avg };
  }

  _buildSummary(expenseTrend, incomeTrend) {
    const parts = [];
    if (expenseTrend.direction === 'increasing') parts.push('Expenses are increasing');
    if (expenseTrend.direction === 'decreasing') parts.push('Expenses are decreasing');
    if (incomeTrend.direction === 'increasing') parts.push('income is growing');
    if (incomeTrend.direction === 'decreasing') parts.push('income is declining');
    return parts.length > 0 ? parts.join(', ') + '.' : 'Finances are stable.';
  }
}

module.exports = TrendAnalysisStrategy;