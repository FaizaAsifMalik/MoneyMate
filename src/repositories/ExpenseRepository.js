const BaseRepository = require('./BaseRepository');
const { query } = require('../config/database');

/**
 * Expense Repository
 */
class ExpenseRepository extends BaseRepository {
  constructor() {
    super('expense');
  }

  /**
   * Find expenses with category details
   */
  async findWithCategory(userId, filters = {}) {
    const { startDate, endDate, categoryId, limit = 50, offset = 0 } = filters;
    
    let queryText = `
      SELECT e.*, c.name as category_name, c.icon, c.colour
      FROM expense e
      LEFT JOIN category c ON e.category_id = c.category_id
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
   * Get expenses by date range
   */
  async findByDateRange(userId, startDate, endDate) {
    const result = await query(
      `SELECT * FROM expense 
       WHERE user_id = $1 AND date >= $2 AND date <= $3
       ORDER BY date DESC`,
      [userId, startDate, endDate]
    );
    return result.rows;
  }

  /**
   * Get total by category
   */
  async getTotalByCategory(userId, categoryId, startDate, endDate) {
    const result = await query(
      `SELECT COALESCE(SUM(amount), 0) as total
       FROM expense
       WHERE user_id = $1 AND category_id = $2 AND date >= $3 AND date <= $4`,
      [userId, categoryId, startDate, endDate]
    );
    return parseFloat(result.rows[0].total);
  }

  /**
   * Get summary by category
   */
  async getSummaryByCategory(userId, startDate, endDate) {
    const result = await query(
      `SELECT 
        c.category_id,
        c.name as category_name,
        c.icon,
        c.colour,
        COALESCE(SUM(e.amount), 0) as total,
        COUNT(e.expense_id) as count
       FROM category c
       LEFT JOIN expense e ON c.category_id = e.category_id 
         AND e.user_id = $1 
         AND e.date >= $2 
         AND e.date <= $3
       WHERE c.user_id = $1 AND c.type = 'expense'
       GROUP BY c.category_id, c.name, c.icon, c.colour
       ORDER BY total DESC`,
      [userId, startDate, endDate]
    );
    return result.rows;
  }
}

module.exports = new ExpenseRepository();