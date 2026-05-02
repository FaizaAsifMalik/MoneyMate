const BaseRepository = require('./BaseRepository');

class IncomeRepository extends BaseRepository {
  constructor() {
    super('incomes', 'income_id');
  }

  async findByUserId(userId, filters = {}) {
    let sql = `
      SELECT i.*, c.name as category_name, c.icon as category_icon
      FROM incomes i
      LEFT JOIN categories c ON i.category_id = c.category_id
      WHERE i.user_id = $1
    `;
    const params = [userId];
    let idx = 2;

    if (filters.startDate) { sql += ` AND i.date >= $${idx++}`; params.push(filters.startDate); }
    if (filters.endDate) { sql += ` AND i.date <= $${idx++}`; params.push(filters.endDate); }
    if (filters.categoryId) { sql += ` AND i.category_id = $${idx++}`; params.push(filters.categoryId); }

    sql += ' ORDER BY i.date DESC';
    if (filters.limit) { sql += ` LIMIT $${idx++}`; params.push(filters.limit); }

    const result = await this.query(sql, params);
    return result.rows;
  }

  async getMonthlyTotals(userId, months = 6) {
    const result = await this.query(
      `SELECT DATE_TRUNC('month', date) as month, SUM(amount) as total
       FROM incomes
       WHERE user_id = $1 AND date >= NOW() - INTERVAL '${months} months'
       GROUP BY DATE_TRUNC('month', date)
       ORDER BY month DESC`,
      [userId]
    );
    return result.rows;
  }

  async create(data) {
    const result = await this.query(
      `INSERT INTO incomes (user_id, category_id, amount, date, description)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [data.userId, data.categoryId, data.amount, data.date, data.description || '']
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
      `UPDATE incomes SET ${fields.join(', ')} WHERE income_id = $${i} RETURNING *`,
      values
    );
    return result.rows[0] || null;
  }
}

module.exports = IncomeRepository;