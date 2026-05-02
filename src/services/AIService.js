const axios = require('axios');
const { config } = require('../config/env');
const RepositoryFactory = require('../factories/RepositoryFactory');
const StrategyFactory = require('../factories/StrategyFactory');
const { getStartOfMonth, getEndOfMonth } = require('../utils/helpers');
const logger = require('../utils/logger');

class AIService {
  constructor() {
    this.expenseRepo = RepositoryFactory.getExpenseRepository();
    this.incomeRepo = RepositoryFactory.getIncomeRepository();
    this.budgetRepo = RepositoryFactory.getBudgetRepository();
    this.goalRepo = RepositoryFactory.getGoalRepository();
  }

  async getInsights(userId, currency = 'USD') {
    const startDate = getStartOfMonth();
    const endDate = getEndOfMonth();

    const [expenseSummary, monthlyExpenses, monthlyIncomes, budgets, goals] = await Promise.all([
      this.expenseRepo.getSummaryByCategory(userId, startDate, endDate),
      this.expenseRepo.getMonthlyTotals(userId),
      this.incomeRepo.getMonthlyTotals(userId),
      this.budgetRepo.findByUserId(userId),
      this.goalRepo.findByUserId(userId),
    ]);

    const totalIncome = monthlyIncomes[0] ? parseFloat(monthlyIncomes[0].total) : 0;

    const [trends, budgetPredictions, suggestions] = await Promise.all([
      StrategyFactory.create('trend').analyze({ monthlyExpenses, monthlyIncomes }),
      StrategyFactory.create('budget_prediction').analyze({ budgets }),
      StrategyFactory.create('suggestion').analyze({ expenseSummary, budgets, goals, monthlyIncome: totalIncome }),
    ]);

    return { trends, budgetPredictions, suggestions, expenseSummary };
  }

  async convertCurrency(amount, fromCurrency, toCurrency) {
    return StrategyFactory.create('currency').analyze({ amount, fromCurrency, toCurrency });
  }

  async chat(userId, message, currency = 'USD') {
    try {
      const insights = await this.getInsights(userId, currency);

      const systemPrompt = `You are a helpful personal finance assistant for MoneyMate app. 
User's currency: ${currency}.
Current month summary:
- Top expense categories: ${insights.expenseSummary.map(e => `${e.name}: ${e.total}`).join(', ')}
- Financial trend: ${insights.trends.summary}
Provide concise, actionable financial advice.`;

      const response = await axios.post(
        'https://api.anthropic.com/v1/messages',
        {
          model: config.ai.model,
          max_tokens: 500,
          system: systemPrompt,
          messages: [{ role: 'user', content: message }],
        },
        {
          headers: {
            'x-api-key': config.ai.apiKey,
            'anthropic-version': '2023-06-01',
            'Content-Type': 'application/json',
          },
        }
      );

      return { reply: response.data.content[0].text };
    } catch (error) {
      logger.error('AI chat error:', error.message);
      throw new Error('AI service unavailable');
    }
  }
}

module.exports = new AIService();