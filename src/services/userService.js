const { query } = require('../config/database');
const { AppError } = require('../utils/errorHandler');
const { hashPassword } = require('../utils/helpers');
const logger = require('../utils/logger');

class UserService {
  /**
   * Get user profile
   */
  async getProfile(userId) {
    const result = await query(
      `SELECT id, name, email, currency, createdat 
       FROM users WHERE id = $1`,
      [userId]
    );

    if (result.rows.length === 0) {
      throw new AppError('User not found', 404);
    }

    return result.rows[0];
  }

  /**
   * Update user profile
   */
  async updateProfile(userId, updateData) {
    const { name, email, currency } = updateData;
    const updates = [];
    const values = [];
    let paramCount = 1;

    if (name) {
      updates.push(`name = $${paramCount++}`);
      values.push(name);
    }

    if (email) {
      updates.push(`email = $${paramCount++}`);
      values.push(email);
    }

    if (currency) {
      updates.push(`currency = $${paramCount++}`);
      values.push(currency);
    }

    if (updates.length === 0) {
      throw new AppError('No fields to update', 400);
    }

    values.push(userId);

    const result = await query(
      `UPDATE users 
       SET ${updates.join(', ')}
       WHERE id = $${paramCount}
       RETURNING id, name, email, currency`,
      values
    );

    logger.info(`User profile updated: ${userId}`);

    return result.rows[0];
  }

  /**
   * Delete user account
   */
  async deleteAccount(userId) {
    // Delete user (cascade will handle related records)
    await query('DELETE FROM users WHERE id = $1', [userId]);

    logger.info(`User account deleted: ${userId}`);

    return {
      message: 'Account deleted successfully',
    };
  }

  /**
   * Get user statistics
   */
  async getStatistics(userId) {
    const stats = await query(
      `SELECT 
        (SELECT COUNT(*) FROM income WHERE user_id = $1) as total_income_records,
        (SELECT COUNT(*) FROM expense WHERE user_id = $1) as total_expense_records,
        (SELECT COUNT(*) FROM category WHERE user_id = $1) as total_categories,
        (SELECT COUNT(*) FROM budget WHERE user_id = $1) as total_budgets,
        (SELECT COUNT(*) FROM goal WHERE user_id = $1) as total_goals,
        (SELECT COUNT(*) FROM bills WHERE user_id = $1) as total_bills,
        (SELECT COALESCE(SUM(amount), 0) FROM income WHERE user_id = $1) as total_income,
        (SELECT COALESCE(SUM(amount), 0) FROM expense WHERE user_id = $1) as total_expenses`,
      [userId]
    );

    const data = stats.rows[0];
    
    return {
      total_income_records: parseInt(data.total_income_records),
      total_expense_records: parseInt(data.total_expense_records),
      total_categories: parseInt(data.total_categories),
      total_budgets: parseInt(data.total_budgets),
      total_goals: parseInt(data.total_goals),
      total_bills: parseInt(data.total_bills),
      total_income: parseFloat(data.total_income),
      total_expenses: parseFloat(data.total_expenses),
      net_balance: parseFloat(data.total_income) - parseFloat(data.total_expenses),
    };
  }
}

module.exports = new UserService();