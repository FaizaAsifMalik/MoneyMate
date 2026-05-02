const { query, getClient } = require('../config/database');

class DatabaseAdapter {
  async executeQuery(sql, params) {
    return query(sql, params);
  }

  async executeTransaction(operations) {
    const client = await getClient();
    try {
      await client.query('BEGIN');
      const results = [];
      for (const op of operations) {
        const result = await client.query(op.sql, op.params);
        results.push(result);
      }
      await client.query('COMMIT');
      return results;
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }
}

module.exports = new DatabaseAdapter();