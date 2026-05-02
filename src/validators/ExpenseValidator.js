const { body } = require('express-validator');

const createExpenseValidator = [
  body('categoryId').notEmpty().withMessage('Category ID is required'),
  body('amount').isFloat({ gt: 0 }).withMessage('Amount must be a positive number'),
  body('date').isDate().withMessage('Valid date is required'),
  body('description').optional().trim(),
];

const updateExpenseValidator = [
  body('amount').optional().isFloat({ gt: 0 }),
  body('date').optional().isDate(),
  body('description').optional().trim(),
];

module.exports = { createExpenseValidator, updateExpenseValidator };