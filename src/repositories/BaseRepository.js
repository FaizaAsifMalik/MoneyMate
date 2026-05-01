const { query, transaction } = require('../config/database');

/**
 * Base Repository with common CRUD operations
 * Implements Repository Pattern
 */
class BaseRepository {
  constructor(tableName) {
    this.tableName = tableName;
  }

  /**
   * Find all records with optional filters
   */
  async findAll(filters = {}, options = {}) {
    const { limit = 100, offset = 0, orderBy = 'id', order = 'ASC' } = options;
    
    let queryText = `SELECT * FROM ${this.tableName}`;
    const values = [];
    let paramCount = 1;

    // Build WHERE clause from filters
    if (Object.keys(filters).length > 0) {
      const conditions = Object.keys(filters).map(key => {
        values.push(filters[key]);
        return `${key} = $${paramCount++}`;
      });
      queryText += ` WHERE ${conditions.join(' AND ')}`;
    }

    queryText += ` ORDER BY ${orderBy} ${order} LIMIT $${paramCount++} OFFSET $${paramCount}`;
    values.push(limit, offset);

    const result = await query(queryText, values);
    return result.rows;
  }

  /**
   * Find one record by criteria
   */
  async findOne(criteria) {
    const keys = Object.keys(criteria);
    const values = Object.values(criteria);
    
    const conditions = keys.map((key, index) => `${key} = $${index + 1}`);
    const queryText = `SELECT * FROM ${this.tableName} WHERE ${conditions.join(' AND ')} LIMIT 1`;
    
    const result = await query(queryText, values);
    return result.rows[0] || null;
  }

  /**
   * Find by ID
   */
  async findById(id, idColumn = 'id') {
    const result = await query(
      `SELECT * FROM ${this.tableName} WHERE ${idColumn} = $1`,
      [id]
    );
    return result.rows[0] || null;
  }

  /**
   * Create new record
   */
  async create(data) {
    const keys = Object.keys(data);
    const values = Object.values(data);
    
    const columns = keys.join(', ');
    const placeholders = keys.map((_, index) => `$${index + 1}`).join(', ');
    
    const queryText = `
      INSERT INTO ${this.tableName} (${columns})
      VALUES (${placeholders})
      RETURNING *
    `;
    
    const result = await query(queryText, values);
    return result.rows[0];
  }

  /**
   * Update record
   */
  async update(id, data, idColumn = 'id') {
    const keys = Object.keys(data);
    const values = Object.values(data);
    
    const setClause = keys.map((key, index) => `${key} = $${index + 1}`).join(', ');
    values.push(id);
    
    const queryText = `
      UPDATE ${this.tableName}
      SET ${setClause}
      WHERE ${idColumn} = $${keys.length + 1}
      RETURNING *
    `;
    
    const result = await query(queryText, values);
    return result.rows[0] || null;
  }

  /**
   * Delete record
   */
  async delete(id, idColumn = 'id') {
    const result = await query(
      `DELETE FROM ${this.tableName} WHERE ${idColumn} = $1 RETURNING *`,
      [id]
    );
    return result.rows[0] || null;
  }

  /**
   * Count records
   */
  async count(filters = {}) {
    let queryText = `SELECT COUNT(*) as count FROM ${this.tableName}`;
    const values = [];
    
    if (Object.keys(filters).length > 0) {
      const conditions = Object.keys(filters).map((key, index) => {
        values.push(filters[key]);
        return `${key} = $${index + 1}`;
      });
      queryText += ` WHERE ${conditions.join(' AND ')}`;
    }
    
    const result = await query(queryText, values);
    return parseInt(result.rows[0].count);
  }

  /**
   * Execute raw query
   */
  async raw(queryText, values = []) {
    const result = await query(queryText, values);
    return result.rows;
  }

  /**
   * Execute in transaction
   */
  async executeInTransaction(callback) {
    return await transaction(callback);
  }
}

module.exports = BaseRepository;