const { query } = require('../config/database');

class BaseRepository {
  constructor(tableName, primaryKey) {
    this.tableName = tableName;
    this.primaryKey = primaryKey;
    this.query = query;
  }

  async findById(id) {
    const result = await this.query(
      `SELECT * FROM ${this.tableName} WHERE ${this.primaryKey} = $1`,
      [id]
    );
    return result.rows[0] || null;
  }

  async delete(id) {
    const result = await this.query(
      `DELETE FROM ${this.tableName} WHERE ${this.primaryKey} = $1 RETURNING *`,
      [id]
    );
    return result.rows[0] || null;
  }

  async count(whereClause = '', params = []) {
    const sql = `SELECT COUNT(*) FROM ${this.tableName} ${whereClause ? 'WHERE ' + whereClause : ''}`;
    const result = await this.query(sql, params);
    return parseInt(result.rows[0].count);
  }
}

module.exports = BaseRepository;