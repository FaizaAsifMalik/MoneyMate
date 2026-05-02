const { body } = require('express-validator');

const createBudgetValidator = [
  body('categoryId').notEmpty().withMessage('Category ID is required'),
  body('limitAmount').isFloat({ gt: 0 }).withMessage('Limit must be a positive number'),
  body('period').isIn(['weekly', 'monthly', 'custom']).withMessage('Invalid period'),
  body('startDate').isDate().withMessage('Valid start date is required'),
  body('endDate').isDate().withMessage('Valid end date is required'),
];

module.exports = { createBudgetValidator };