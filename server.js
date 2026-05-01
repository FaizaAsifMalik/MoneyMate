const app = require('./src/app');
const { config } = require('./src/config/env');
const { checkDatabaseConnection } = require('./src/config/connection_check');
const logger = require('./src/utils/logger');
const { initializeJobs } = require('./src/jobs');

const PORT = config.port;

// Check database connection before starting server
async function startServer() {
  try {
    // Test database connection
    await checkDatabaseConnection();
    logger.info('✅ Database connection established successfully');

    // Initialize scheduled jobs
    initializeJobs();
    logger.info('✅ Scheduled jobs initialized');

    // Start the server
    app.listen(PORT, () => {
      logger.info(`🚀 MoneyMate server running on port ${PORT}`);
      logger.info(`📊 Environment: ${config.nodeEnv}`);
      logger.info(`🔗 API URL: http://localhost:${PORT}/api`);
    });
  } catch (error) {
    logger.error('❌ Failed to start server:', error);
    process.exit(1);
  }
}

// Handle unhandled rejections
process.on('unhandledRejection', (err) => {
  logger.error('Unhandled Rejection:', err);
  process.exit(1);
});

// Handle uncaught exceptions
process.on('uncaughtException', (err) => {
  logger.error('Uncaught Exception:', err);
  process.exit(1);
});

// Start the server
startServer();