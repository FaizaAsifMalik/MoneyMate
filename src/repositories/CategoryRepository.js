const BaseRepository = require('./BaseRepository');

class CategoryRepository extends BaseRepository {
  constructor() {
    super('categories', 'category_id');
  }

  async findByUserId(userId) {
    const result = await this.query(
      'SELECT * FROM categories WHERE user_id = $1 ORDER BY name',
      [userId]
    );
    return result.rows;
  }

  async findByUserIdAndType(userId, type) {
    const result = await this.query(
      'SELECT * FROM categories WHERE user_id = $1 AND type = $2 ORDER BY name',
      [userId, type]
    );
    return result.rows;
  }

  async create(data) {
    const result = await this.query(
      `INSERT INTO categories (user_id, name, type, icon, colour)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [data.userId, data.name, data.type, data.icon || '📁', data.colour || '#607D8B']
    );
    return result.rows[0];
  }

  async update(id, data) {
    const fields = [];
    const values = [];
    let i = 1;

    if (data.name !== undefined) { fields.push(`name = $${i++}`); values.push(data.name); }
    if (data.icon !== undefined) { fields.push(`icon = $${i++}`); values.push(data.icon); }
    if (data.colour !== undefined) { fields.push(`colour = $${i++}`); values.push(data.colour); }

    if (fields.length === 0) return null;
    values.push(id);

    const result = await this.query(
      `UPDATE categories SET ${fields.join(', ')} WHERE category_id = $${i} RETURNING *`,
      values
    );
    return result.rows[0] || null;
  }
}

module.exports = CategoryRepository;