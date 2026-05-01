const { query } = require('../config/database');
const { AppError } = require('../utils/errorHandler');
const { formatDate } = require('../utils/helpers');
const logger = require('../utils/logger');

class AIService {
  /**
   * Analyze spending trends
   */
  async analyzeTrends(userId) {
    const endDate = new Date();
    const startDate = new Date();
    startDate.setMonth(endDate.getMonth() - 3); // Last 3 months

    // Get expenses by category for trend analysis
    const expenses = await query(
      `SELECT 
        c.category_id,
        c.name,
        DATE_TRUNC('month', e.date) as month,
        SUM(e.amount) as total
       FROM expense e
       JOIN category c ON e.category_id = c.category_id
       WHERE e.user_id = $1 
       AND e.date >= $2 
       AND e.date <= $3
       GROUP BY c.category_id, c.name, DATE_TRUNC('month', e.date)
       ORDER BY month, total DESC`,
      [userId, formatDate(startDate), formatDate(endDate)]
    );

    if (expenses.rows.length === 0) {
      return {
        message: 'Not enough data for trend analysis',
        trends: [],
      };
    }

    // Analyze trends by category
    const trends = [];
    const categoriesMap = {};

    expenses.rows.forEach(row => {
      const categoryId = row.category_id;
      if (!categoriesMap[categoryId]) {
        categoriesMap[categoryId] = {
          category_id: categoryId,
          category_name: row.name,
          monthly_data: [],
        };
      }
      categoriesMap[categoryId].monthly_data.push({
        month: row.month,
        total: parseFloat(row.total),
      });
    });

    // Calculate trend direction and percentage change
    Object.values(categoriesMap).forEach(category => {
      if (category.monthly_data.length >= 2) {
        const sorted = category.monthly_data.sort((a, b) => new Date(a.month) - new Date(b.month));
        const oldest = sorted[0].total;
        const newest = sorted[sorted.length - 1].total;
        const percentageChange = ((newest - oldest) / oldest * 100).toFixed(2);
        const direction = newest > oldest ? 'up' : 'down';

        trends.push({
          category_id: category.category_id,
          category_name: category.category_name,
          direction,
          percentage_change: Math.abs(percentageChange),
          trend: direction === 'up' ? 'increasing' : 'decreasing',
        });

        // Save to TrendAnalysis table
        query(
          `INSERT INTO trendanalysis (user_id, category_id, period, percentage_change, direction, compared, generated_at)
           VALUES ($1, $2, 'monthly', $3, $4, 'last 3 months', NOW())`,
          [userId, category.category_id, percentageChange, direction]
        ).catch(err => logger.error('Error saving trend analysis:', err));
      }
    });

    logger.info(`Trend analysis completed for user ${userId}`);

    return {
      period: 'last_3_months',
      trends,
    };
  }

  /**
   * Predict future budget
   */
  async predictBudget(userId, categoryId, monthsAhead = 1) {
    // Get historical expenses for the category
    const endDate = new Date();
    const startDate = new Date();
    startDate.setMonth(endDate.getMonth() - 6); // Last 6 months

    const expenses = await query(
      `SELECT 
        DATE_TRUNC('month', date) as month,
        SUM(amount) as total
       FROM expense
       WHERE user_id = $1 
       AND category_id = $2 
       AND date >= $3 
       AND date <= $4
       GROUP BY DATE_TRUNC('month', date)
       ORDER BY month`,
      [userId, categoryId, formatDate(startDate), formatDate(endDate)]
    );

    if (expenses.rows.length < 3) {
      throw new AppError('Not enough data for budget prediction (minimum 3 months required)', 400);
    }

    // Simple moving average prediction
    const amounts = expenses.rows.map(row => parseFloat(row.total));
    const average = amounts.reduce((sum, val) => sum + val, 0) / amounts.length;
    
    // Calculate trend
    const firstHalf = amounts.slice(0, Math.floor(amounts.length / 2));
    const secondHalf = amounts.slice(Math.floor(amounts.length / 2));
    const firstAvg = firstHalf.reduce((sum, val) => sum + val, 0) / firstHalf.length;
    const secondAvg = secondHalf.reduce((sum, val) => sum + val, 0) / secondHalf.length;
    const trendFactor = secondAvg / firstAvg;

    // Predicted amount with trend
    const predictedAmount = (average * trendFactor).toFixed(2);
    
    // Calculate confidence based on variance
    const variance = amounts.reduce((sum, val) => sum + Math.pow(val - average, 2), 0) / amounts.length;
    const stdDev = Math.sqrt(variance);
    const coefficientOfVariation = (stdDev / average) * 100;
    const confidence = Math.max(50, 100 - coefficientOfVariation).toFixed(2);

    // Predict for date
    const predictedFor = new Date();
    predictedFor.setMonth(predictedFor.getMonth() + monthsAhead);

    // Save prediction
    await query(
      `INSERT INTO budgetprediction (user_id, category_id, predicted_amount, confidence, based_on_months, predicted_for, generated_at)
       VALUES ($1, $2, $3, $4, $5, $6, NOW())
       RETURNING *`,
      [userId, categoryId, predictedAmount, confidence, expenses.rows.length, formatDate(predictedFor)]
    );

    logger.info(`Budget prediction generated for user ${userId}, category ${categoryId}`);

    return {
      category_id: categoryId,
      predicted_amount: parseFloat(predictedAmount),
      confidence: parseFloat(confidence),
      based_on_months: expenses.rows.length,
      predicted_for: formatDate(predictedFor),
      historical_average: parseFloat(average.toFixed(2)),
      trend: trendFactor > 1 ? 'increasing' : 'decreasing',
    };
  }

  /**
   * Generate budget suggestions
   */
  async generateSuggestions(userId) {
    const suggestions = [];

    // Get user's financial data
    const endDate = new Date();
    const startDate = new Date();
    startDate.setMonth(endDate.getMonth() - 3);

    const financialData = await query(
      `SELECT 
        COALESCE(SUM(i.amount), 0) as total_income,
        COALESCE(SUM(e.amount), 0) as total_expenses
       FROM users u
       LEFT JOIN income i ON u.id = i.user_id AND i.date >= $2 AND i.date <= $3
       LEFT JOIN expense e ON u.id = e.user_id AND e.date >= $2 AND e.date <= $3
       WHERE u.id = $1
       GROUP BY u.id`,
      [userId, formatDate(startDate), formatDate(endDate)]
    );

    if (financialData.rows.length === 0) {
      return {
        message: 'Not enough data for suggestions',
        suggestions: [],
      };
    }

    const income = parseFloat(financialData.rows[0].total_income);
    const expenses = parseFloat(financialData.rows[0].total_expenses);
    const savingsRate = income > 0 ? ((income - expenses) / income * 100) : 0;

    // Suggestion 1: Savings rate
    if (savingsRate < 20) {
      suggestions.push({
        type: 'saving',
        priority: 1,
        content: `Your savings rate is ${savingsRate.toFixed(1)}%. Try to save at least 20% of your income for better financial health.`,
      });
    } else if (savingsRate >= 20 && savingsRate < 30) {
      suggestions.push({
        type: 'saving',
        priority: 2,
        content: `Great! You're saving ${savingsRate.toFixed(1)}% of your income. Consider increasing it to 30% for long-term goals.`,
      });
    } else {
      suggestions.push({
        type: 'saving',
        priority: 3,
        content: `Excellent! You're saving ${savingsRate.toFixed(1)}% of your income. Keep up the good work!`,
      });
    }

    // Suggestion 2: Category analysis
    const categoryExpenses = await query(
      `SELECT c.name, SUM(e.amount) as total
       FROM expense e
       JOIN category c ON e.category_id = c.category_id
       WHERE e.user_id = $1 AND e.date >= $2 AND e.date <= $3
       GROUP BY c.name
       ORDER BY total DESC
       LIMIT 3`,
      [userId, formatDate(startDate), formatDate(endDate)]
    );

    if (categoryExpenses.rows.length > 0) {
      const topCategory = categoryExpenses.rows[0];
      const categoryPercent = expenses > 0 ? (topCategory.total / expenses * 100) : 0;
      
      if (categoryPercent > 40) {
        suggestions.push({
          type: 'budgeting',
          priority: 1,
          content: `${topCategory.name} accounts for ${categoryPercent.toFixed(1)}% of your expenses. Consider setting a budget limit for this category.`,
        });
      }
    }

    // Suggestion 3: Bill payment patterns
    const overdueBills = await query(
      `SELECT COUNT(*) as count
       FROM bills
       WHERE user_id = $1 AND is_paid = false AND due_date < $2`,
      [userId, formatDate(new Date())]
    );

    if (parseInt(overdueBills.rows[0].count) > 0) {
      suggestions.push({
        type: 'budgeting',
        priority: 1,
        content: `You have ${overdueBills.rows[0].count} overdue bill(s). Set up automatic payments to avoid late fees.`,
      });
    }

    // Suggestion 4: Goal progress
    const goals = await query(
      `SELECT COUNT(*) as total,
        COUNT(CASE WHEN status = 'in progress' THEN 1 END) as in_progress
       FROM goal
       WHERE user_id = $1`,
      [userId]
    );

    const totalGoals = parseInt(goals.rows[0].total);
    const inProgressGoals = parseInt(goals.rows[0].in_progress);

    if (totalGoals === 0) {
      suggestions.push({
        type: 'saving',
        priority: 2,
        content: 'Set financial goals to stay motivated. Start with a short-term goal like building an emergency fund.',
      });
    } else if (inProgressGoals > 0) {
      suggestions.push({
        type: 'saving',
        priority: 2,
        content: `You have ${inProgressGoals} active goal(s). Stay consistent with your contributions to achieve them faster.`,
      });
    }

    // Save suggestions to database
    for (const suggestion of suggestions) {
      await query(
        `INSERT INTO ai_suggestion (user_id, type, content, priority, is_read, based_on_history_from, generated_at)
         VALUES ($1, $2, $3, $4, false, $5, NOW())`,
        [userId, suggestion.type, suggestion.content, suggestion.priority, formatDate(startDate)]
      ).catch(err => logger.error('Error saving AI suggestion:', err));
    }

    logger.info(`AI suggestions generated for user ${userId}`);

    return {
      suggestions,
      generated_at: new Date().toISOString(),
    };
  }

  /**
   * Get all AI insights for user
   */
  async getInsights(userId, filters = {}) {
    const { type, limit = 10 } = filters;
    
    let queryText = 'SELECT * FROM ai_insights WHERE user_id = $1';
    const values = [userId];

    if (type) {
      queryText += ' AND type = $2';
      values.push(type);
    }

    queryText += ` ORDER BY generated_at DESC LIMIT ${limit}`;

    const result = await query(queryText, values);
    return result.rows;
  }

  /**
   * Get AI suggestions for user
   */
  async getSuggestions(userId, filters = {}) {
    const { isRead, type, limit = 10 } = filters;
    
    let queryText = 'SELECT * FROM ai_suggestion WHERE user_id = $1';
    const values = [userId];
    let paramCount = 2;

    if (isRead !== undefined) {
      queryText += ` AND is_read = $${paramCount++}`;
      values.push(isRead);
    }

    if (type) {
      queryText += ` AND type = $${paramCount++}`;
      values.push(type);
    }

    queryText += ` ORDER BY priority ASC, generated_at DESC LIMIT ${limit}`;

    const result = await query(queryText, values);
    return result.rows;
  }

  /**
   * Mark suggestion as read
   */
  async markSuggestionAsRead(suggestionId, userId) {
    const result = await query(
      `UPDATE ai_suggestion 
       SET is_read = true 
       WHERE suggestion_id = $1 AND user_id = $2
       RETURNING *`,
      [suggestionId, userId]
    );

    if (result.rows.length === 0) {
      throw new AppError('Suggestion not found', 404);
    }

    return result.rows[0];
  }
}

module.exports = new AIService();