const BaseRepository = require('./BaseRepository');

class UserRepository extends BaseRepository {
  constructor() {
    super('users', 'id');
  }

  async findByEmail(email) {
    const result = await this.query('SELECT * FROM users WHERE email = $1', [email]);
    return result.rows[0] || null;
  }

  async create(data) {
    const result = await this.query(
      `INSERT INTO users (name, email, passwordhash, currency)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [data.name, data.email, data.passwordHash, data.currency || 'USD']
    );
    return result.rows[0];
  }

  async update(id, data) {
    const fields = [];
    const values = [];
    let i = 1;

    if (data.name !== undefined) { fields.push(`name = $${i++}`); values.push(data.name); }
    if (data.email !== undefined) { fields.push(`email = $${i++}`); values.push(data.email); }
    if (data.currency !== undefined) { fields.push(`currency = $${i++}`); values.push(data.currency); }
    if (data.passwordHash !== undefined) { fields.push(`passwordhash = $${i++}`); values.push(data.passwordHash); }
    if (data.profilePicture !== undefined) { fields.push(`profile_picture = $${i++}`); values.push(data.profilePicture); }

    if (fields.length === 0) return null;
    values.push(id);

    const result = await this.query(
      `UPDATE users SET ${fields.join(', ')}, createdat = NOW() WHERE id = $${i} RETURNING *`,
      values
    );
    return result.rows[0] || null;
  }
}

module.exports = UserRepository;