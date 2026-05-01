const { pool } = require('./database');
const logger = require('../utils/logger');

/**
 * Check database connection
 * @returns {Promise<boolean>}
 */
const checkDatabaseConnection = async () => {
  try {
    const client = await pool.connect();
    const result = await client.query('SELECT NOW()');
    client.release();
    
    logger.info('Database connection test successful:', result.rows[0].now);
    return true;
  } catch (error) {
    logger.error('Database connection test failed:', error.message);
    throw error;
  }
};

/**
 * Check if all required tables exist
 * @returns {Promise<boolean>}
 */
const checkTablesExist = async () => {
  const requiredTables = [
    'users',
    'category',
    'income',
    'expense',
    'budget',
    'goal',
    'bills',
    'notifications',
    'ai_insights',
    'budgetprediction',
    'ai_suggestion',
    'budgetstrategy',
    'trendanalysis',
    'chart',
    'emails'
  ];

  try {
    const result = await pool.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public'
    `);
    
    const existingTables = result.rows.map(row => row.table_name.toLowerCase());
    const missingTables = requiredTables.filter(
      table => !existingTables.includes(table)
    );

    if (missingTables.length > 0) {
      logger.warn('Missing tables:', missingTables);
      return false;
    }

    logger.info('✅ All required tables exist');
    return true;
  } catch (error) {
    logger.error('Error checking tables:', error.message);
    throw error;
  }
};

module.exports = {
  checkDatabaseConnection,
  checkTablesExist,
};