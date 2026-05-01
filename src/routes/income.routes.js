const express = require('express');
const { body } = require('express-validator');
const incomeController = require('../controllers/incomeController');
const { authenticate } = require('../middleware/auth.middleware');
const { validate } = require('../middleware/validation.middleware');

const router = express.Router();

// All routes require authentication
router.use(authenticate);

/**
 * @route   GET /api/income
 * @desc    Get all income records
 * @access  Private
 */
router.get('/', incomeController.getIncomes);

/**
 * @route   GET /api/income/summary
 * @desc    Get income summary
 * @access  Private
 */
router.get('/summary', incomeController.getIncomeSummary);

/**
 * @route   GET /api/income/:id
 * @desc    Get income by ID
 * @access  Private
 */
router.get('/:id', incomeController.getIncomeById);

/**
 * @route   POST /api/income
 * @desc    Create income record
 * @access  Private
 */
router.post(
  '/',
  [
    body('categoryId').isInt().withMessage('Valid category ID is required'),
    body('amount')
      .isFloat({ min: 0 })
      .withMessage('Amount must be a positive number'),
    body('source').trim().notEmpty().withMessage('Source is required'),
    body('date').isISO8601().withMessage('Valid date is required'),
    body('note').optional().isString(),
  ],
  validate,
  incomeController.createIncome
);

/**
 * @route   PUT /api/income/:id
 * @desc    Update income record
 * @access  Private
 */
router.put(
  '/:id',
  [
    body('categoryId').optional().isInt(),
    body('amount').optional().isFloat({ min: 0 }),
    body('source').optional().trim().notEmpty(),
    body('date').optional().isISO8601(),
    body('note').optional().isString(),
  ],
  validate,
  incomeController.updateIncome
);

/**
 * @route   DELETE /api/income/:id
 * @desc    Delete income record
 * @access  Private
 */
router.delete('/:id', incomeController.deleteIncome);

module.exports = router;