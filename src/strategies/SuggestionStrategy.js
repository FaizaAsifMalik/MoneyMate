const IAnalysisStrategy = require('./interfaces/IAnalysisStrategy');

class SuggestionStrategy extends IAnalysisStrategy {
  async analyze(data) {
    const { expenseSummary, budgets, goals, monthlyIncome } = data;
    const suggestions = [];

    // High spending categories
    if (expenseSummary && expenseSummary.length > 0) {
      const topExpense = expenseSummary[0];
      if (parseFloat(topExpense.total) > monthlyIncome * 0.3) {
        suggestions.push({
          type: 'spending',
          priority: 'high',
          message: `You're spending a lot on ${topExpense.name}. Consider setting a budget for this category.`,
        });
      }
    }

    // Exceeded budgets
    if (budgets) {
      for (const b of budgets) {
        const pct = (parseFloat(b.spent_amount) / parseFloat(b.limit_amount)) * 100;
        if (pct >= 100) {
          suggestions.push({
            type: 'budget',
            priority: 'high',
            message: `Budget exceeded for ${b.category_name}. Review your spending.`,
          });
        } else if (pct >= 80) {
          suggestions.push({
            type: 'budget',
            priority: 'medium',
            message: `You've used ${pct.toFixed(0)}% of your ${b.category_name} budget.`,
          });
        }
      }
    }

    // Goal suggestions
    if (goals) {
      for (const g of goals) {
        if (g.status === 'in progress') {
          const pct = (parseFloat(g.saved_amount) / parseFloat(g.target_amount)) * 100;
          if (pct < 20) {
            suggestions.push({
              type: 'goal',
              priority: 'medium',
              message: `Your goal "${g.title}" is only ${pct.toFixed(0)}% funded. Consider contributing more.`,
            });
          }
        }
      }
    }

    return suggestions.slice(0, 5);
  }
}

module.exports = SuggestionStrategy;