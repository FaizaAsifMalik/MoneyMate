const { query } = require('../config/database');
const { AppError } = require('../utils/errorHandler');
const { formatDate } = require('../utils/helpers');
const logger = require('../utils/logger');

class BudgetService {
  /**
   * Get all budgets for user
   */
  async getBudgets(userId, filters = {}) {
    const { period, categoryId, active } = filters;
    
    let queryText = `
      SELECT b.*, c.name as category_name, c.icon, c.colour
      FROM budget b
      LEFT JOIN category c ON b.category_id = c.category_id
      WHERE b.user_id = $1
    `;
    const values = [userId];
    let paramCount = 2;

    if (period) {
      queryText += ` AND b.period = $${paramCount++}`;
      values.push(period);
    }

    if (categoryId) {
      queryText += ` AND b.category_id = $${paramCount++}`;
      values.push(categoryId);
    }

    if (active === true) {
      const today = formatDate(new Date());
      queryText += ` AND b.start_date <= $${paramCount} AND b.end_date >= $${paramCount}`;
      values.push(today);
      paramCount++;
    }

    queryText += ' ORDER BY b.start_date DESC';

    const result = await query(queryText, values);

    // Calculate spending for each budget
    const budgetsWithSpending = await Promise.all(
      result.rows.map(async (budget) => {
        const spending = await this.getBudgetSpending(
          userId,
          budget.category_id,
          budget.start_date,
          budget.end_date
        );
        return {
          ...budget,
          spent_amount: spending.total_spent,
          remaining_amount: budget.limit_amount - spending.total_spent,
          percent_used: ((spending.total_spent / budget.limit_amount) * 100).toFixed(2),
        };
      })
    );

    return budgetsWithSpending;
  }

  /**
   * Get budget by ID
   */
  async getBudgetById(budgetId, userId) {
    const result = await query(
      `SELECT b.*, c.name as category_name, c.icon, c.colour
       FROM budget b
       LEFT JOIN category c ON b.category_id = c.category_id
       WHERE b.budget_id = $1 AND b.user_id = $2`,
      [budgetId, userId]
    );

    if (result.rows.length === 0) {
      throw new AppError('Budget not found', 404);
    }

    const budget = result.rows[0];
    const spending = await this.getBudgetSpending(
      userId,
      budget.category_id,
      budget.start_date,
      budget.end_date
    );

    return {
      ...budget,
      spent_amount: spending.total_spent,
      remaining_amount: budget.limit_amount - spending.total_spent,
      percent_used: ((spending.total_spent / budget.limit_amount) * 100).toFixed(2),
    };
  }

  /**
   * Create budget
   */
  async createBudget(userId, budgetData) {
    const { categoryId, limitAmount, period, startDate, endDate } = budgetData;

    // Verify category belongs to user and is expense type
    const category = await query(
      `SELECT category_id FROM category 
       WHERE category_id = $1 AND user_id = $2 AND type = 'expense'`,
      [categoryId, userId]
    );

    if (category.rows.length === 0) {
      throw new AppError('Invalid expense category', 400);
    }

    // Validate dates
    if (new Date(startDate) > new Date(endDate)) {
      throw new AppError('Start date must be before end date', 400);
    }

    // Check for overlapping budgets
    const overlapping = await query(
      `SELECT budget_id FROM budget 
       WHERE user_id = $1 
       AND category_id = $2 
       AND period = $3
       AND (
         (start_date <= $4 AND end_date >= $4)
         OR (start_date <= $5 AND end_date >= $5)
         OR (start_date >= $4 AND end_date <= $5)
       )`,
      [userId, categoryId, period, startDate, endDate]
    );

    if (overlapping.rows.length > 0) {
      throw new AppError('A budget already exists for this category and period', 400);
    }

    const result = await query(
      `INSERT INTO budget (user_id, category_id, limit_amount, period, start_date, end_date)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [userId, categoryId, limitAmount, period, formatDate(startDate), formatDate(endDate)]
    );

    logger.info(`Budget created for user ${userId}`);

    return result.rows[0];
  }

  /**
   * Update budget
   */
  async updateBudget(budgetId, userId, updateData) {
    const { limitAmount, startDate, endDate } = updateData;
    const updates = [];
    const values = [];
    let paramCount = 1;

    if (limitAmount !== undefined) {
      updates.push(`limit_amount = $${paramCount++}`);
      values.push(limitAmount);
    }

    if (startDate) {
      updates.push(`start_date = $${paramCount++}`);
      values.push(formatDate(startDate));
    }

    if (endDate) {
      updates.push(`end_date = $${paramCount++}`);
      values.push(formatDate(endDate));
    }

    if (updates.length === 0) {
      throw new AppError('No fields to update', 400);
    }

    values.push(budgetId, userId);

    const result = await query(
      `UPDATE budget 
       SET ${updates.join(', ')}
       WHERE budget_id = $${paramCount++} AND user_id = $${paramCount}
       RETURNING *`,
      values
    );

    if (result.rows.length === 0) {
      throw new AppError('Budget not found', 404);
    }

    logger.info(`Budget updated: ${budgetId}`);

    return result.rows[0];
  }

  /**
   * Delete budget
   */
  async deleteBudget(budgetId, userId) {
    const result = await query(
      'DELETE FROM budget WHERE budget_id = $1 AND user_id = $2 RETURNING *',
      [budgetId, userId]
    );

    if (result.rows.length === 0) {
      throw new AppError('Budget not found', 404);
    }

    logger.info(`Budget deleted: ${budgetId}`);

    return {
      message: 'Budget deleted successfully',
    };
  }

  /**
   * Get spending for a budget period
   */
  async getBudgetSpending(userId, categoryId, startDate, endDate) {
    const result = await query(
      `SELECT COALESCE(SUM(amount), 0) as total_spent
       FROM expense
       WHERE user_id = $1 
       AND category_id = $2 
       AND date >= $3 
       AND date <= $4`,
      [userId, categoryId, startDate, endDate]
    );

    return {
      total_spent: parseFloat(result.rows[0].total_spent),
    };
  }

  /**
   * Get budget summary
   */
  async getBudgetSummary(userId) {
    const today = formatDate(new Date());

    const activeBudgets = await query(
      `SELECT COUNT(*) as count 
       FROM budget 
       WHERE user_id = $1 
       AND start_date <= $2 
       AND end_date >= $2`,
      [userId, today]
    );

    const exceededBudgets = await query(
      `SELECT COUNT(*) as count
       FROM budget b
       WHERE b.user_id = $1 
       AND b.start_date <= $2 
       AND b.end_date >= $2
       AND (
         SELECT COALESCE(SUM(amount), 0) 
         FROM expense e 
         WHERE e.user_id = b.user_id 
         AND e.category_id = b.category_id 
         AND e.date >= b.start_date 
         AND e.date <= b.end_date
       ) > b.limit_amount`,
      [userId, today]
    );

    return {
      active_budgets: parseInt(activeBudgets.rows[0].count),
      exceeded_budgets: parseInt(exceededBudgets.rows[0].count),
    };
  }
}

module.exports = new BudgetService();