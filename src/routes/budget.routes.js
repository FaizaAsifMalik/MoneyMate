const express = require('express');
const { body } = require('express-validator');
const budgetController = require('../controllers/budgetController');
const { authenticate } = require('../middleware/auth.middleware');
const { validate } = require('../middleware/validation.middleware');

const router = express.Router();

// All routes require authentication
router.use(authenticate);

/**
 * @route   GET /api/budgets
 * @desc    Get all budgets
 * @access  Private
 */
router.get('/', budgetController.getBudgets);

/**
 * @route   GET /api/budgets/summary
 * @desc    Get budget summary
 * @access  Private
 */
router.get('/summary', budgetController.getBudgetSummary);

/**
 * @route   GET /api/budgets/:id
 * @desc    Get budget by ID
 * @access  Private
 */
router.get('/:id', budgetController.getBudgetById);

/**
 * @route   POST /api/budgets
 * @desc    Create budget
 * @access  Private
 */
router.post(
  '/',
  [
    body('categoryId').isInt().withMessage('Valid category ID is required'),
    body('limitAmount')
      .isFloat({ min: 0 })
      .withMessage('Limit amount must be a positive number'),
    body('period')
      .isIn(['weekly', 'monthly', 'custom'])
      .withMessage('Period must be weekly, monthly, or custom'),
    body('startDate').isISO8601().withMessage('Valid start date is required'),
    body('endDate').isISO8601().withMessage('Valid end date is required'),
  ],
  validate,
  budgetController.createBudget
);

/**
 * @route   PUT /api/budgets/:id
 * @desc    Update budget
 * @access  Private
 */
router.put(
  '/:id',
  [
    body('limitAmount').optional().isFloat({ min: 0 }),
    body('startDate').optional().isISO8601(),
    body('endDate').optional().isISO8601(),
  ],
  validate,
  budgetController.updateBudget
);

/**
 * @route   DELETE /api/budgets/:id
 * @desc    Delete budget
 * @access  Private
 */
router.delete('/:id', budgetController.deleteBudget);

module.exports = router;