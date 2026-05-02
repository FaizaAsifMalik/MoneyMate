const BaseRepository = require('./BaseRepository');

class GoalRepository extends BaseRepository {
  constructor() {
    super('goals', 'goal_id');
  }

  async findByUserId(userId) {
    const result = await this.query(
      'SELECT * FROM goals WHERE user_id = $1 ORDER BY created_at DESC',
      [userId]
    );
    return result.rows;
  }

  async create(data) {
    const result = await this.query(
      `INSERT INTO goals (user_id, title, target_amount, saved_amount, deadline, status)
       VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
      [data.userId, data.title, data.targetAmount, data.savedAmount || 0, data.deadline, data.status || 'in progress']
    );
    return result.rows[0];
  }

  async update(id, data) {
    const fields = [];
    const values = [];
    let i = 1;

    if (data.title !== undefined) { fields.push(`title = $${i++}`); values.push(data.title); }
    if (data.targetAmount !== undefined) { fields.push(`target_amount = $${i++}`); values.push(data.targetAmount); }
    if (data.savedAmount !== undefined) { fields.push(`saved_amount = $${i++}`); values.push(data.savedAmount); }
    if (data.deadline !== undefined) { fields.push(`deadline = $${i++}`); values.push(data.deadline); }
    if (data.status !== undefined) { fields.push(`status = $${i++}`); values.push(data.status); }

    if (fields.length === 0) return null;
    values.push(id);

    const result = await this.query(
      `UPDATE goals SET ${fields.join(', ')} WHERE goal_id = $${i} RETURNING *`,
      values
    );
    return result.rows[0] || null;
  }
}

module.exports = GoalRepository;