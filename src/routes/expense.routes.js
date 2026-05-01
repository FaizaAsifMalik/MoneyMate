const express = require('express');
const { body } = require('express-validator');
const expenseController = require('../controllers/expenseController');
const { authenticate } = require('../middleware/auth.middleware');
const { validate } = require('../middleware/validation.middleware');

const router = express.Router();

// All routes require authentication
router.use(authenticate);

/**
 * @route   GET /api/expenses
 * @desc    Get all expenses
 * @access  Private
 */
router.get('/', expenseController.getExpenses);

/**
 * @route   GET /api/expenses/summary
 * @desc    Get expense summary
 * @access  Private
 */
router.get('/summary', expenseController.getExpenseSummary);

/**
 * @route   GET /api/expenses/:id
 * @desc    Get expense by ID
 * @access  Private
 */
router.get('/:id', expenseController.getExpenseById);

/**
 * @route   POST /api/expenses
 * @desc    Create expense record
 * @access  Private
 */
router.post(
  '/',
  [
    body('categoryId').isInt().withMessage('Valid category ID is required'),
    body('amount')
      .isFloat({ min: 0 })
      .withMessage('Amount must be a positive number'),
    body('date').isISO8601().withMessage('Valid date is required'),
    body('description').optional().isString(),
    body('billId').optional().isInt(),
  ],
  validate,
  expenseController.createExpense
);

/**
 * @route   PUT /api/expenses/:id
 * @desc    Update expense record
 * @access  Private
 */
router.put(
  '/:id',
  [
    body('categoryId').optional().isInt(),
    body('amount').optional().isFloat({ min: 0 }),
    body('date').optional().isISO8601(),
    body('description').optional().isString(),
    body('billId').optional().isInt(),
  ],
  validate,
  expenseController.updateExpense
);

/**
 * @route   DELETE /api/expenses/:id
 * @desc    Delete expense record
 * @access  Private
 */
router.delete('/:id', expenseController.deleteExpense);

module.exports = router;