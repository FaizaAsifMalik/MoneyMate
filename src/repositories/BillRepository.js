const BaseRepository = require('./BaseRepository');

class BillRepository extends BaseRepository {
  constructor() {
    super('bills', 'bill_id');
  }

  async findByUserId(userId) {
    const result = await this.query(
      `SELECT b.*, c.name as category_name
       FROM bills b
       LEFT JOIN categories c ON b.category_id = c.category_id
       WHERE b.user_id = $1
       ORDER BY b.due_date`,
      [userId]
    );
    return result.rows;
  }

  async findUpcoming(userId, days = 7) {
    const result = await this.query(
      `SELECT * FROM bills
       WHERE user_id = $1
         AND is_paid = false
         AND next_due_date <= NOW() + INTERVAL '${days} days'
       ORDER BY next_due_date`,
      [userId]
    );
    return result.rows;
  }

  async findAllUpcomingForReminders(days = 3) {
    const result = await this.query(
      `SELECT b.*, u.email, u.name as user_name, u.currency
       FROM bills b
       JOIN users u ON b.user_id = u.id
       WHERE b.is_paid = false
         AND b.next_due_date::date <= NOW()::date + INTERVAL '${days} days'`,
      []
    );
    return result.rows;
  }

  async create(data) {
    const result = await this.query(
      `INSERT INTO bills (user_id, name, amount, due_date, frequency, category_id, next_due_date)
       VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *`,
      [data.userId, data.name, data.amount, data.dueDate, data.frequency, data.categoryId || null, data.nextDueDate]
    );
    return result.rows[0];
  }

  async update(id, data) {
    const fields = [];
    const values = [];
    let i = 1;

    if (data.name !== undefined) { fields.push(`name = $${i++}`); values.push(data.name); }
    if (data.amount !== undefined) { fields.push(`amount = $${i++}`); values.push(data.amount); }
    if (data.dueDate !== undefined) { fields.push(`due_date = $${i++}`); values.push(data.dueDate); }
    if (data.isPaid !== undefined) { fields.push(`is_paid = $${i++}`); values.push(data.isPaid); }
    if (data.nextDueDate !== undefined) { fields.push(`next_due_date = $${i++}`); values.push(data.nextDueDate); }

    if (fields.length === 0) return null;
    values.push(id);

    const result = await this.query(
      `UPDATE bills SET ${fields.join(', ')} WHERE bill_id = $${i} RETURNING *`,
      values
    );
    return result.rows[0] || null;
  }
}

module.exports = BillRepository;