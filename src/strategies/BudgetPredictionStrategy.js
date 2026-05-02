const IAnalysisStrategy = require('./interfaces/IAnalysisStrategy');

class BudgetPredictionStrategy extends IAnalysisStrategy {
  async analyze(data) {
    const { budgets, currentExpenses } = data;
    const predictions = [];

    for (const budget of budgets) {
      const spent = parseFloat(budget.spent_amount) || 0;
      const limit = parseFloat(budget.limit_amount);
      const daysInPeriod = this._getDaysBetween(budget.start_date, budget.end_date);
      const daysPassed = this._getDaysBetween(budget.start_date, new Date());
      const daysRemaining = daysInPeriod - daysPassed;

      if (daysPassed <= 0) continue;

      const dailyRate = spent / daysPassed;
      const projectedTotal = dailyRate * daysInPeriod;
      const projectedOverrun = projectedTotal - limit;

      predictions.push({
        categoryName: budget.category_name,
        budgetId: budget.budget_id,
        spent,
        limit,
        projectedTotal: parseFloat(projectedTotal.toFixed(2)),
        projectedOverrun: parseFloat(projectedOverrun.toFixed(2)),
        willExceed: projectedTotal > limit,
        daysRemaining,
        dailyAllowance: daysRemaining > 0 ? parseFloat(((limit - spent) / daysRemaining).toFixed(2)) : 0,
      });
    }

    return predictions;
  }

  _getDaysBetween(start, end) {
    const a = new Date(start);
    const b = new Date(end);
    return Math.max(1, Math.ceil((b - a) / (1000 * 60 * 60 * 24)));
  }
}

module.exports = BudgetPredictionStrategy;