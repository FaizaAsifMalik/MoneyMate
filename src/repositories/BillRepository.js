const BaseRepository = require('./BaseRepository');

class BillRepository extends BaseRepository {
  constructor() {
    super('bills', 'bill_id');
  }

  // Service calls findWithCategory
  async findWithCategory(userId, filters = {}) {
    const result = await this.query(
      `SELECT b.*, c.name as category_name, c.icon as category_icon
       FROM bills b
       LEFT JOIN categories c ON b.category_id = c.category_id
       WHERE b.user_id = $1
       ORDER BY b.next_due_date ASC NULLS LAST`,
      [userId]
    );
    return result.rows;
  }

  // Service calls findOne on categoryRepository
  // CategoryRepository needs this too - shown below
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

  // Service calls getUpcoming
  async getUpcoming(userId, days = 7) {
    const result = await this.query(
      `SELECT b.*, c.name as category_name
       FROM bills b
       LEFT JOIN categories c ON b.category_id = c.category_id
       WHERE b.user_id = $1
         AND b.is_paid = false
         AND b.next_due_date <= NOW() + INTERVAL '${parseInt(days)} days'
       ORDER BY b.next_due_date ASC`,
      [userId]
    );
    return result.rows;
  }

  // Service calls getOverdue
  async getOverdue(userId) {
    const result = await this.query(
      `SELECT b.*, c.name as category_name
       FROM bills b
       LEFT JOIN categories c ON b.category_id = c.category_id
       WHERE b.user_id = $1
         AND b.is_paid = false
         AND b.next_due_date < NOW()
       ORDER BY b.next_due_date ASC`,
      [userId]
    );
    return result.rows;
  }

  // Service calls markPaid with next due date
  async markPaid(billId, nextDueDate) {
    const result = await this.query(
      `UPDATE bills 
       SET is_paid = true, next_due_date = $2 
       WHERE bill_id = $1 
       RETURNING *`,
      [billId, nextDueDate]
    );
    return result.rows[0] || null;
  }

  // Service passes snake_case keys
  async create(data) {
    const result = await this.query(
      `INSERT INTO bills 
        (user_id, name, amount, due_date, frequency, category_id, is_paid, next_due_date)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8) 
       RETURNING *`,
      [
        data.user_id,
        data.name,
        data.amount,
        data.due_date,           // INTEGER day of month
        data.frequency || 'monthly',
        data.category_id || null,
        data.is_paid || false,
        data.next_due_date,      // DATE
      ]
    );
    return result.rows[0];
  }

  // Handles snake_case update fields
  async update(id, data) {
    const fields = [];
    const values = [];
    let i = 1;

    if (data.name !== undefined) { fields.push(`name = $${i++}`); values.push(data.name); }
    if (data.amount !== undefined) { fields.push(`amount = $${i++}`); values.push(data.amount); }
    if (data.due_date !== undefined) { fields.push(`due_date = $${i++}`); values.push(data.due_date); }
    if (data.frequency !== undefined) { fields.push(`frequency = $${i++}`); values.push(data.frequency); }
    if (data.is_paid !== undefined) { fields.push(`is_paid = $${i++}`); values.push(data.is_paid); }
    if (data.category_id !== undefined) { fields.push(`category_id = $${i++}`); values.push(data.category_id); }
    if (data.next_due_date !== undefined) { fields.push(`next_due_date = $${i++}`); values.push(data.next_due_date); }

    if (fields.length === 0) return null;
    values.push(id);

    const result = await this.query(
      `UPDATE bills SET ${fields.join(', ')} WHERE bill_id = $${i} RETURNING *`,
      values
    );
    return result.rows[0] || null;
  }

  // For scheduled reminder jobs
  async findAllUpcomingForReminders(days = 3) {
    const result = await this.query(
      `SELECT b.*, u.email, u.name as user_name, u.currency
       FROM bills b
       JOIN users u ON b.user_id = u.id
       WHERE b.is_paid = false
         AND b.next_due_date::date <= NOW()::date + INTERVAL '${parseInt(days)} days'`,
      []
    );
    return result.rows;
  }
}

module.exports = BillRepository;