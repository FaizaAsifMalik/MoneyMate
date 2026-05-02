const { pool } = require('./database');
const logger = require('../utils/logger');

const checkConnection = async () => {
  try {
    const client = await pool.connect();
    await client.query('SELECT 1');
    client.release();
    logger.info('Database connection: OK');
    return true;
  } catch (error) {
    logger.error('Database connection failed:', error.message);
    return false;
  }
};

module.exports = { checkConnection };