const { query } = require('../config/database');
const { AppError } = require('../utils/errorHandler');
const logger = require('../utils/logger');

class CategoryService {
  /**
   * Get all categories for user
   */
  async getCategories(userId, type = null) {
    let queryText = 'SELECT * FROM category WHERE user_id = $1';
    const values = [userId];

    if (type) {
      queryText += ' AND type = $2';
      values.push(type);
    }

    queryText += ' ORDER BY name ASC';

    const result = await query(queryText, values);
    return result.rows;
  }

  /**
   * Get category by ID
   */
  async getCategoryById(categoryId, userId) {
    const result = await query(
      'SELECT * FROM category WHERE category_id = $1 AND user_id = $2',
      [categoryId, userId]
    );

    if (result.rows.length === 0) {
      throw new AppError('Category not found', 404);
    }

    return result.rows[0];
  }

  /**
   * Create new category
   */
  async createCategory(userId, categoryData) {
    const { name, type, icon = '📁', colour = '#607D8B' } = categoryData;

    // Check if category name already exists for this user
    const existing = await query(
      'SELECT category_id FROM category WHERE user_id = $1 AND name = $2',
      [userId, name]
    );

    if (existing.rows.length > 0) {
      throw new AppError('Category with this name already exists', 400);
    }

    const result = await query(
      `INSERT INTO category (user_id, name, type, icon, colour)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [userId, name, type, icon, colour]
    );

    logger.info(`Category created: ${name} for user ${userId}`);

    return result.rows[0];
  }

  /**
   * Update category
   */
  async updateCategory(categoryId, userId, updateData) {
    const { name, icon, colour } = updateData;
    const updates = [];
    const values = [];
    let paramCount = 1;

    if (name) {
      updates.push(`name = $${paramCount++}`);
      values.push(name);
    }

    if (icon) {
      updates.push(`icon = $${paramCount++}`);
      values.push(icon);
    }

    if (colour) {
      updates.push(`colour = $${paramCount++}`);
      values.push(colour);
    }

    if (updates.length === 0) {
      throw new AppError('No fields to update', 400);
    }

    values.push(categoryId, userId);

    const result = await query(
      `UPDATE category 
       SET ${updates.join(', ')}
       WHERE category_id = $${paramCount++} AND user_id = $${paramCount}
       RETURNING *`,
      values
    );

    if (result.rows.length === 0) {
      throw new AppError('Category not found', 404);
    }

    logger.info(`Category updated: ${categoryId}`);

    return result.rows[0];
  }

  /**
   * Delete category
   */
  async deleteCategory(categoryId, userId) {
    // Check if category has associated records
    const hasIncome = await query(
      'SELECT COUNT(*) as count FROM income WHERE category_id = $1',
      [categoryId]
    );

    const hasExpense = await query(
      'SELECT COUNT(*) as count FROM expense WHERE category_id = $1',
      [categoryId]
    );

    if (parseInt(hasIncome.rows[0].count) > 0 || parseInt(hasExpense.rows[0].count) > 0) {
      throw new AppError(
        'Cannot delete category with associated income or expense records',
        400
      );
    }

    const result = await query(
      'DELETE FROM category WHERE category_id = $1 AND user_id = $2 RETURNING *',
      [categoryId, userId]
    );

    if (result.rows.length === 0) {
      throw new AppError('Category not found', 404);
    }

    logger.info(`Category deleted: ${categoryId}`);

    return {
      message: 'Category deleted successfully',
    };
  }

  /**
   * Get category statistics
   */
  async getCategoryStats(userId, categoryId) {
    const stats = await query(
      `SELECT 
        c.category_id,
        c.name,
        c.type,
        COALESCE(SUM(CASE WHEN c.type = 'income' THEN i.amount ELSE 0 END), 0) as total_income,
        COALESCE(SUM(CASE WHEN c.type = 'expense' THEN e.amount ELSE 0 END), 0) as total_expenses,
        COUNT(DISTINCT i.income_id) as income_count,
        COUNT(DISTINCT e.expense_id) as expense_count
       FROM category c
       LEFT JOIN income i ON c.category_id = i.category_id
       LEFT JOIN expense e ON c.category_id = e.category_id
       WHERE c.user_id = $1 AND c.category_id = $2
       GROUP BY c.category_id, c.name, c.type`,
      [userId, categoryId]
    );

    if (stats.rows.length === 0) {
      throw new AppError('Category not found', 404);
    }

    return stats.rows[0];
  }
}

module.exports = new CategoryService();