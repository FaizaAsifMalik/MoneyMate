require('dotenv').config();

const app = require('./src/app');
const { config } = require('./src/config/env');
const logger = require('./src/utils/logger');
const { startJobs } = require('./src/jobs');
const { pool } = require('./src/config/database');

const PORT = config.port;

async function startServer() {
  try {
    const client = await pool.connect();
    await client.query('SELECT NOW()');
    client.release();
    logger.info('Database connection established successfully');

    startJobs();
    logger.info('Scheduled jobs initialized');

    app.listen(PORT, () => {
      logger.info(`MoneyMate server running on port ${PORT}`);
      logger.info(`Environment: ${config.nodeEnv}`);
      logger.info(`API URL: http://localhost:${PORT}/api`);
    });
  } catch (error) {
    logger.error('Failed to start server:', error);
    process.exit(1);
  }
}

process.on('unhandledRejection', (err) => {
  logger.error('Unhandled Rejection:', err);
  process.exit(1);
});

process.on('uncaughtException', (err) => {
  logger.error('Uncaught Exception:', err);
  process.exit(1);
});

startServer();