const { validationResult } = require('express-validator');
const { AppError } = require('../utils/errorHandler');

/**
 * Validate request using express-validator
 */
const validate = (req, res, next) => {
  const errors = validationResult(req);
  
  if (!errors.isEmpty()) {
    const errorMessages = errors.array().map(err => ({
      field: err.path,
      message: err.msg,
    }));
    
    throw new AppError('Validation failed', 400, errorMessages);
  }
  
  next();
};

module.exports = { validate };