const logger = require('../utils/logger');
const { formatErrorResponse } = require('../utils/responseFormatter');

/**
 * Global error handling middleware
 */
const errorHandler = (err, req, res, next) => {
  // Log error
  logger.error('Error occurred:', {
    message: err.message,
    stack: err.stack,
    url: req.originalUrl,
    method: req.method,
  });

  // Set default values
  err.statusCode = err.statusCode || 500;
  err.status = err.status || 'error';

  // Send error response
  res.status(err.statusCode).json(formatErrorResponse(err));
};

/**
 * Handle 404 routes
 */
const notFound = (req, res, next) => {
  const error = new Error(`Route not found: ${req.originalUrl}`);
  error.statusCode = 404;
  next(error);
};

module.exports = {
  errorHandler,
  notFound,
};