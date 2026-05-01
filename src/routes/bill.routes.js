const express = require('express');
const { body } = require('express-validator');
const billController = require('../controllers/billController');
const { authenticate } = require('../middleware/auth.middleware');
const { validate } = require('../middleware/validation.middleware');

const router = express.Router();

// All routes require authentication
router.use(authenticate);

/**
 * @route   GET /api/bills
 * @desc    Get all bills
 * @access  Private
 */
router.get('/', billController.getBills);

/**
 * @route   GET /api/bills/upcoming
 * @desc    Get upcoming bills
 * @access  Private
 */
router.get('/upcoming', billController.getUpcomingBills);

/**
 * @route   GET /api/bills/overdue
 * @desc    Get overdue bills
 * @access  Private
 */
router.get('/overdue', billController.getOverdueBills);

/**
 * @route   GET /api/bills/:id
 * @desc    Get bill by ID
 * @access  Private
 */
router.get('/:id', billController.getBillById);

/**
 * @route   POST /api/bills
 * @desc    Create bill
 * @access  Private
 */
router.post(
  '/',
  [
    body('name').trim().notEmpty().withMessage('Bill name is required'),
    body('amount')
      .isFloat({ min: 0 })
      .withMessage('Amount must be a positive number'),
    body('dueDate').isISO8601().withMessage('Valid due date is required'),
    body('recurrence')
      .optional()
      .isIn(['none', 'weekly', 'monthly'])
      .withMessage('Recurrence must be none, weekly, or monthly'),
    body('categoryId').optional().isInt(),
  ],
  validate,
  billController.createBill
);

/**
 * @route   PUT /api/bills/:id
 * @desc    Update bill
 * @access  Private
 */
router.put(
  '/:id',
  [
    body('name').optional().trim().notEmpty(),
    body('amount').optional().isFloat({ min: 0 }),
    body('dueDate').optional().isISO8601(),
    body('recurrence').optional().isIn(['none', 'weekly', 'monthly']),
    body('isPaid').optional().isBoolean(),
    body('categoryId').optional().isInt(),
  ],
  validate,
  billController.updateBill
);

/**
 * @route   POST /api/bills/:id/pay
 * @desc    Mark bill as paid
 * @access  Private
 */
router.post(
  '/:id/pay',
  [body('createExpense').optional().isBoolean()],
  validate,
  billController.markAsPaid
);

/**
 * @route   DELETE /api/bills/:id
 * @desc    Delete bill
 * @access  Private
 */
router.delete('/:id', billController.deleteBill);

module.exports = router;