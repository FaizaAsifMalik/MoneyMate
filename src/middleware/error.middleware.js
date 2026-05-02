const logger = require('../utils/logger');

const errorMiddleware = (err, req, res, next) => {
  const statusCode = err.statusCode || 500;
  const message = err.isOperational ? err.message : 'Internal server error';

  if (statusCode === 500) logger.error(err);

  res.status(statusCode).json({ success: false, message });
};

module.exports = { errorMiddleware };