const BaseRepository = require('./BaseRepository');

class BillRepository extends BaseRepository {
  constructor() {
    super('bills', 'bill_id');
  }

  // ✅ Service calls this - was missing
  async findWithCategory(userId, filters = {}) {
    const result = await this.query(
      `SELECT b.*, c.name as category_name, c.icon as category_icon
       FROM bills b
       LEFT JOIN categories c ON b.category_id = c.category_id
       WHERE b.user_id = $1
       ORDER BY b.due_date`,
      [userId]
    );
    return result.rows;
  }

  // ✅ Service calls this - was missing
  async findOne(conditions) {
    const fields = Object.keys(conditions);
    const values = Object.values(conditions);
    const where = fields.map((f, i) => `${f} = $${i + 1}`).join(' AND ');
    const result = await this.query(
      `SELECT * FROM bills WHERE ${where} LIMIT 1`,
      values
    );
    return result.rows[0] || null;
  }

  // ✅ Service calls this - was missing
  async markPaid(billId) {
    const result = await this.query(
      `UPDATE bills SET is_paid = true WHERE bill_id = $1 RETURNING *`,
      [billId]
    );
    return result.rows[0] || null;
  }

  // ✅ Service calls getUpcoming - was findUpcoming
  async getUpcoming(userId, days = 7) {
    const result = await this.query(
      `SELECT b.*, c.name as category_name
       FROM bills b
       LEFT JOIN categories c ON b.category_id = c.category_id
       WHERE b.user_id = $1
         AND b.is_paid = false
         AND b.due_date <= NOW() + INTERVAL '${parseInt(days)} days'
       ORDER BY b.due_date`,
      [userId]
    );
    return result.rows;
  }

  // ✅ Service calls getOverdue - was missing
  async getOverdue(userId) {
    const result = await this.query(
      `SELECT b.*, c.name as category_name
       FROM bills b
       LEFT JOIN categories c ON b.category_id = c.category_id
       WHERE b.user_id = $1
         AND b.is_paid = false
         AND b.due_date < NOW()
       ORDER BY b.due_date`,
      [userId]
    );
    return result.rows;
  }

  // ✅ Fixed - service passes snake_case keys
  async create(data) {
    const result = await this.query(
      `INSERT INTO bills (user_id, name, amount, due_date, recurrence, category_id, is_paid)
       VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *`,
      [
        data.user_id,
        data.name,
        data.amount,
        data.due_date,
        data.recurrence || 'none',
        data.category_id || null,
        data.is_paid || false,
      ]
    );
    return result.rows[0];
  }

  // ✅ Fixed - handles snake_case from service
  async update(id, data, primaryKey = 'bill_id') {
    const fields = [];
    const values = [];
    let i = 1;

    if (data.name !== undefined) { fields.push(`name = $${i++}`); values.push(data.name); }
    if (data.amount !== undefined) { fields.push(`amount = $${i++}`); values.push(data.amount); }
    if (data.due_date !== undefined) { fields.push(`due_date = $${i++}`); values.push(data.due_date); }
    if (data.is_paid !== undefined) { fields.push(`is_paid = $${i++}`); values.push(data.is_paid); }
    if (data.recurrence !== undefined) { fields.push(`recurrence = $${i++}`); values.push(data.recurrence); }
    if (data.category_id !== undefined) { fields.push(`category_id = $${i++}`); values.push(data.category_id); }

    if (fields.length === 0) return null;
    values.push(id);

    const result = await this.query(
      `UPDATE bills SET ${fields.join(', ')} WHERE ${primaryKey} = $${i} RETURNING *`,
      values
    );
    return result.rows[0] || null;
  }

  // ✅ For scheduled jobs
  async findAllUpcomingForReminders(days = 3) {
    const result = await this.query(
      `SELECT b.*, u.email, u.name as user_name, u.currency
       FROM bills b
       JOIN users u ON b.user_id = u.id
       WHERE b.is_paid = false
         AND b.due_date::date <= NOW()::date + INTERVAL '${parseInt(days)} days'`,
      []
    );
    return result.rows;
  }

  // ✅ Override delete to use bill_id
  async delete(id, primaryKey = 'bill_id') {
    const result = await this.query(
      `DELETE FROM bills WHERE ${primaryKey} = $1 RETURNING *`,
      [id]
    );
    return result.rows[0] || null;
  }
}

module.exports = BillRepository;