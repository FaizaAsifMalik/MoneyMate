const BaseRepository = require('./BaseRepository');

class BudgetRepository extends BaseRepository {
  constructor() {
    super('budgets', 'budget_id');
  }

  async findByUserId(userId) {
    const result = await this.query(
      `SELECT b.*, c.name as category_name, c.icon as category_icon, c.colour as category_colour,
              COALESCE(SUM(e.amount), 0) as spent_amount
       FROM budgets b
       LEFT JOIN categories c ON b.category_id = c.category_id
       LEFT JOIN expenses e ON e.category_id = b.category_id
         AND e.user_id = b.user_id
         AND e.date BETWEEN b.start_date AND b.end_date
       WHERE b.user_id = $1
       GROUP BY b.budget_id, c.name, c.icon, c.colour
       ORDER BY b.start_date DESC`,
      [userId]
    );
    return result.rows;
  }

  async findActiveBudgets(userId) {
    const result = await this.query(
      `SELECT b.*, c.name as category_name,
              COALESCE(SUM(e.amount), 0) as spent_amount
       FROM budgets b
       LEFT JOIN categories c ON b.category_id = c.category_id
       LEFT JOIN expenses e ON e.category_id = b.category_id
         AND e.user_id = b.user_id
         AND e.date BETWEEN b.start_date AND b.end_date
       WHERE b.user_id = $1 AND NOW() BETWEEN b.start_date AND b.end_date
       GROUP BY b.budget_id, c.name`,
      [userId]
    );
    return result.rows;
  }

  async create(data) {
    const result = await this.query(
      `INSERT INTO budgets (user_id, category_id, limit_amount, period, start_date, end_date)
       VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
      [data.userId, data.categoryId, data.limitAmount, data.period, data.startDate, data.endDate]
    );
    return result.rows[0];
  }

  async update(id, data) {
    const fields = [];
    const values = [];
    let i = 1;

    if (data.limitAmount !== undefined) { fields.push(`limit_amount = $${i++}`); values.push(data.limitAmount); }
    if (data.startDate !== undefined) { fields.push(`start_date = $${i++}`); values.push(data.startDate); }
    if (data.endDate !== undefined) { fields.push(`end_date = $${i++}`); values.push(data.endDate); }

    if (fields.length === 0) return null;
    values.push(id);

    const result = await this.query(
      `UPDATE budgets SET ${fields.join(', ')} WHERE budget_id = $${i} RETURNING *`,
      values
    );
    return result.rows[0] || null;
  }
}

module.exports = BudgetRepository;