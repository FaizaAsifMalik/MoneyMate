const { query } = require('../config/database');
const { AppError } = require('../utils/errorHandler');
const { formatDate } = require('../utils/helpers');
const logger = require('../utils/logger');

class ExpenseService {
  /**
   * Get all expenses for user
   */
  async getExpenses(userId, filters = {}) {
    const { startDate, endDate, categoryId, limit = 50, offset = 0 } = filters;
    
    let queryText = `
      SELECT e.*, c.name as category_name, c.icon, c.colour, b.name as bill_name
      FROM expense e
      LEFT JOIN category c ON e.category_id = c.category_id
      LEFT JOIN bills b ON e.bill_id = b.bill_id
      WHERE e.user_id = $1
    `;
    const values = [userId];
    let paramCount = 2;

    if (startDate) {
      queryText += ` AND e.date >= $${paramCount++}`;
      values.push(startDate);
    }

    if (endDate) {
      queryText += ` AND e.date <= $${paramCount++}`;
      values.push(endDate);
    }

    if (categoryId) {
      queryText += ` AND e.category_id = $${paramCount++}`;
      values.push(categoryId);
    }

    queryText += ` ORDER BY e.date DESC LIMIT $${paramCount++} OFFSET $${paramCount}`;
    values.push(limit, offset);

    const result = await query(queryText, values);
    return result.rows;
  }

  /**
   * Get expense by ID
   */
  async getExpenseById(expenseId, userId) {
    const result = await query(
      `SELECT e.*, c.name as category_name, c.icon, c.colour
       FROM expense e
       LEFT JOIN category c ON e.category_id = c.category_id
       WHERE e.expense_id = $1 AND e.user_id = $2`,
      [expenseId, userId]
    );

    if (result.rows.length === 0) {
      throw new AppError('Expense record not found', 404);
    }

    return result.rows[0];
  }

  /**
   * Create expense record
   */
  async createExpense(userId, expenseData) {
    const { categoryId, amount, date, description, billId = null } = expenseData;

    // Verify category belongs to user and is expense type
    const category = await query(
      `SELECT category_id FROM category 
       WHERE category_id = $1 AND user_id = $2 AND type = 'expense'`,
      [categoryId, userId]
    );

    if (category.rows.length === 0) {
      throw new AppError('Invalid expense category', 400);
    }

    const result = await query(
      `INSERT INTO expense (user_id, category_id, amount, date, description, bill_id)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [userId, categoryId, amount, formatDate(date), description, billId]
    );

    logger.info(`Expense record created for user ${userId}`);

    // Check budget alerts
    await this.checkBudgetAlert(userId, categoryId, formatDate(date));

    return result.rows[0];
  }

  /**
   * Update expense record
   */
  async updateExpense(expenseId, userId, updateData) {
    const { categoryId, amount, date, description, billId } = updateData;
    const updates = [];
    const values = [];
    let paramCount = 1;

    if (categoryId) {
      const category = await query(
        `SELECT category_id FROM category 
         WHERE category_id = $1 AND user_id = $2 AND type = 'expense'`,
        [categoryId, userId]
      );

      if (category.rows.length === 0) {
        throw new AppError('Invalid expense category', 400);
      }

      updates.push(`category_id = $${paramCount++}`);
      values.push(categoryId);
    }

    if (amount !== undefined) {
      updates.push(`amount = $${paramCount++}`);
      values.push(amount);
    }

    if (date) {
      updates.push(`date = $${paramCount++}`);
      values.push(formatDate(date));
    }

    if (description !== undefined) {
      updates.push(`description = $${paramCount++}`);
      values.push(description);
    }

    if (billId !== undefined) {
      updates.push(`bill_id = $${paramCount++}`);
      values.push(billId);
    }

    if (updates.length === 0) {
      throw new AppError('No fields to update', 400);
    }

    values.push(expenseId, userId);

    const result = await query(
      `UPDATE expense 
       SET ${updates.join(', ')}
       WHERE expense_id = $${paramCount++} AND user_id = $${paramCount}
       RETURNING *`,
      values
    );

    if (result.rows.length === 0) {
      throw new AppError('Expense record not found', 404);
    }

    logger.info(`Expense record updated: ${expenseId}`);

    return result.rows[0];
  }

  /**
   * Delete expense record
   */
  async deleteExpense(expenseId, userId) {
    const result = await query(
      'DELETE FROM expense WHERE expense_id = $1 AND user_id = $2 RETURNING *',
      [expenseId, userId]
    );

    if (result.rows.length === 0) {
      throw new AppError('Expense record not found', 404);
    }

    logger.info(`Expense record deleted: ${expenseId}`);

    return {
      message: 'Expense record deleted successfully',
    };
  }

  /**
   * Get expense summary
   */
  async getExpenseSummary(userId, startDate, endDate) {
    const result = await query(
      `SELECT 
        c.name as category_name,
        c.category_id,
        c.icon,
        c.colour,
        SUM(e.amount) as category_total,
        COUNT(e.expense_id) as transaction_count
       FROM expense e
       LEFT JOIN category c ON e.category_id = c.category_id
       WHERE e.user_id = $1 
       AND e.date >= $2 
       AND e.date <= $3
       GROUP BY c.category_id, c.name, c.icon, c.colour
       ORDER BY category_total DESC`,
      [userId, startDate, endDate]
    );

    const totalExpenses = await query(
      `SELECT COALESCE(SUM(amount), 0) as total
       FROM expense
       WHERE user_id = $1 AND date >= $2 AND date <= $3`,
      [userId, startDate, endDate]
    );

    return {
      total_expenses: parseFloat(totalExpenses.rows[0].total),
      by_category: result.rows,
    };
  }

  /**
   * Check if expense exceeds budget
   */
  async checkBudgetAlert(userId, categoryId, date) {
    // Find active budgets for this category
    const budgets = await query(
      `SELECT * FROM budget 
       WHERE user_id = $1 
       AND category_id = $2 
       AND start_date <= $3 
       AND end_date >= $3`,
      [userId, categoryId, date]
    );

    for (const budget of budgets.rows) {
      // Calculate total expenses in budget period
      const expenses = await query(
        `SELECT COALESCE(SUM(amount), 0) as total
         FROM expense
         WHERE user_id = $1 
         AND category_id = $2 
         AND date >= $3 
         AND date <= $4`,
        [userId, categoryId, budget.start_date, budget.end_date]
      );

      const totalSpent = parseFloat(expenses.rows[0].total);
      const percentUsed = (totalSpent / budget.limit_amount) * 100;

      // Create notification if over 80% or exceeded
      if (percentUsed >= 80) {
        const notificationService = require('./notificationService');
        const message = percentUsed >= 100
          ? `You have exceeded your budget for this category by ${(percentUsed - 100).toFixed(1)}%`
          : `You have used ${percentUsed.toFixed(1)}% of your budget for this category`;

        await notificationService.createNotification(userId, {
          message,
          type: 'alert',
        });
      }
    }
  }
}

module.exports = new ExpenseService();