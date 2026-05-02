const BaseRepository = require('./BaseRepository');

class ExpenseRepository extends BaseRepository {
  constructor() {
    super('expenses', 'expense_id');
  }

  async findByUserId(userId, filters = {}) {
    let sql = `
      SELECT e.*, c.name as category_name, c.icon as category_icon, c.colour as category_colour
      FROM expenses e
      LEFT JOIN categories c ON e.category_id = c.category_id
      WHERE e.user_id = $1
    `;
    const params = [userId];
    let i = 2;

    if (filters.startDate) { sql += ` AND e.date >= $${i++}`; params.push(filters.startDate); }
    if (filters.endDate) { sql += ` AND e.date <= $${i++}`; params.push(filters.endDate); }
    if (filters.categoryId) { sql += ` AND e.category_id = $${i++}`; params.push(filters.categoryId); }

    sql += ' ORDER BY e.date DESC';

    if (filters.limit) { sql += ` LIMIT $${i++}`; params.push(filters.limit); }
    if (filters.offset) { sql += ` OFFSET $${i++}`; params.push(filters.offset); }

    const result = await this.query(sql, params);
    return result.rows;
  }

  async getSummaryByCategory(userId, startDate, endDate) {
    const result = await this.query(
      `SELECT c.category_id, c.name, c.icon, c.colour,
              SUM(e.amount) as total, COUNT(*) as count
       FROM expenses e
       JOIN categories c ON e.category_id = c.category_id
       WHERE e.user_id = $1 AND e.date BETWEEN $2 AND $3
       GROUP BY c.category_id, c.name, c.icon, c.colour
       ORDER BY total DESC`,
      [userId, startDate, endDate]
    );
    return result.rows;
  }

  async getMonthlyTotals(userId, months = 6) {
    const result = await this.query(
      `SELECT DATE_TRUNC('month', date) as month, SUM(amount) as total
       FROM expenses
       WHERE user_id = $1 AND date >= NOW() - INTERVAL '${months} months'
       GROUP BY DATE_TRUNC('month', date)
       ORDER BY month DESC`,
      [userId]
    );
    return result.rows;
  }

  async create(data) {
    const result = await this.query(
      `INSERT INTO expenses (user_id, category_id, amount, date, description, bill_id)
       VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
      [data.userId, data.categoryId, data.amount, data.date, data.description || '', data.billId || null]
    );
    return result.rows[0];
  }

  async update(id, data) {
    const fields = [];
    const values = [];
    let i = 1;

    if (data.amount !== undefined) { fields.push(`amount = $${i++}`); values.push(data.amount); }
    if (data.categoryId !== undefined) { fields.push(`category_id = $${i++}`); values.push(data.categoryId); }
    if (data.date !== undefined) { fields.push(`date = $${i++}`); values.push(data.date); }
    if (data.description !== undefined) { fields.push(`description = $${i++}`); values.push(data.description); }

    if (fields.length === 0) return null;
    values.push(id);

    const result = await this.query(
      `UPDATE expenses SET ${fields.join(', ')} WHERE expense_id = $${i} RETURNING *`,
      values
    );
    return result.rows[0] || null;
  }
}

module.exports = ExpenseRepository;