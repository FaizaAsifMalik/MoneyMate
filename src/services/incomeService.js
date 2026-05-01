const { query } = require('../config/database');
const { AppError } = require('../utils/errorHandler');
const { formatDate } = require('../utils/helpers');
const logger = require('../utils/logger');

class IncomeService {
  /**
   * Get all income records for user
   */
  async getIncomes(userId, filters = {}) {
    const { startDate, endDate, categoryId, limit = 50, offset = 0 } = filters;
    
    let queryText = `
      SELECT i.*, c.name as category_name, c.icon, c.colour
      FROM income i
      LEFT JOIN category c ON i.category_id = c.category_id
      WHERE i.user_id = $1
    `;
    const values = [userId];
    let paramCount = 2;

    if (startDate) {
      queryText += ` AND i.date >= $${paramCount++}`;
      values.push(startDate);
    }

    if (endDate) {
      queryText += ` AND i.date <= $${paramCount++}`;
      values.push(endDate);
    }

    if (categoryId) {
      queryText += ` AND i.category_id = $${paramCount++}`;
      values.push(categoryId);
    }

    queryText += ` ORDER BY i.date DESC LIMIT $${paramCount++} OFFSET $${paramCount}`;
    values.push(limit, offset);

    const result = await query(queryText, values);
    return result.rows;
  }

  /**
   * Get income by ID
   */
  async getIncomeById(incomeId, userId) {
    const result = await query(
      `SELECT i.*, c.name as category_name, c.icon, c.colour
       FROM income i
       LEFT JOIN category c ON i.category_id = c.category_id
       WHERE i.income_id = $1 AND i.user_id = $2`,
      [incomeId, userId]
    );

    if (result.rows.length === 0) {
      throw new AppError('Income record not found', 404);
    }

    return result.rows[0];
  }

  /**
   * Create income record
   */
  async createIncome(userId, incomeData) {
    const { categoryId, amount, source, date, note } = incomeData;

    // Verify category belongs to user and is income type
    const category = await query(
      `SELECT category_id FROM category 
       WHERE category_id = $1 AND user_id = $2 AND type = 'income'`,
      [categoryId, userId]
    );

    if (category.rows.length === 0) {
      throw new AppError('Invalid income category', 400);
    }

    const result = await query(
      `INSERT INTO income (user_id, category_id, amount, source, date, note)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [userId, categoryId, amount, source, formatDate(date), note]
    );

    logger.info(`Income record created for user ${userId}`);

    return result.rows[0];
  }

  /**
   * Update income record
   */
  async updateIncome(incomeId, userId, updateData) {
    const { categoryId, amount, source, date, note } = updateData;
    const updates = [];
    const values = [];
    let paramCount = 1;

    if (categoryId) {
      // Verify category
      const category = await query(
        `SELECT category_id FROM category 
         WHERE category_id = $1 AND user_id = $2 AND type = 'income'`,
        [categoryId, userId]
      );

      if (category.rows.length === 0) {
        throw new AppError('Invalid income category', 400);
      }

      updates.push(`category_id = $${paramCount++}`);
      values.push(categoryId);
    }

    if (amount !== undefined) {
      updates.push(`amount = $${paramCount++}`);
      values.push(amount);
    }

    if (source) {
      updates.push(`source = $${paramCount++}`);
      values.push(source);
    }

    if (date) {
      updates.push(`date = $${paramCount++}`);
      values.push(formatDate(date));
    }

    if (note !== undefined) {
      updates.push(`note = $${paramCount++}`);
      values.push(note);
    }

    if (updates.length === 0) {
      throw new AppError('No fields to update', 400);
    }

    values.push(incomeId, userId);

    const result = await query(
      `UPDATE income 
       SET ${updates.join(', ')}
       WHERE income_id = $${paramCount++} AND user_id = $${paramCount}
       RETURNING *`,
      values
    );

    if (result.rows.length === 0) {
      throw new AppError('Income record not found', 404);
    }

    logger.info(`Income record updated: ${incomeId}`);

    return result.rows[0];
  }

  /**
   * Delete income record
   */
  async deleteIncome(incomeId, userId) {
    const result = await query(
      'DELETE FROM income WHERE income_id = $1 AND user_id = $2 RETURNING *',
      [incomeId, userId]
    );

    if (result.rows.length === 0) {
      throw new AppError('Income record not found', 404);
    }

    logger.info(`Income record deleted: ${incomeId}`);

    return {
      message: 'Income record deleted successfully',
    };
  }

  /**
   * Get income summary
   */
  async getIncomeSummary(userId, startDate, endDate) {
    const result = await query(
      `SELECT 
        COALESCE(SUM(amount), 0) as total_income,
        COUNT(*) as total_records,
        c.name as category_name,
        c.category_id,
        SUM(amount) as category_total
       FROM income i
       LEFT JOIN category c ON i.category_id = c.category_id
       WHERE i.user_id = $1 
       AND i.date >= $2 
       AND i.date <= $3
       GROUP BY c.category_id, c.name`,
      [userId, startDate, endDate]
    );

    const totalIncome = await query(
      `SELECT COALESCE(SUM(amount), 0) as total
       FROM income
       WHERE user_id = $1 AND date >= $2 AND date <= $3`,
      [userId, startDate, endDate]
    );

    return {
      total_income: parseFloat(totalIncome.rows[0].total),
      by_category: result.rows,
    };
  }
}

module.exports = new IncomeService();