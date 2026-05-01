const express = require('express');
const { body } = require('express-validator');
const goalController = require('../controllers/goalController');
const { authenticate } = require('../middleware/auth.middleware');
const { validate } = require('../middleware/validation.middleware');

const router = express.Router();

// All routes require authentication
router.use(authenticate);

/**
 * @route   GET /api/goals
 * @desc    Get all goals
 * @access  Private
 */
router.get('/', goalController.getGoals);

/**
 * @route   GET /api/goals/summary
 * @desc    Get goal summary
 * @access  Private
 */
router.get('/summary', goalController.getGoalSummary);

/**
 * @route   GET /api/goals/:id
 * @desc    Get goal by ID
 * @access  Private
 */
router.get('/:id', goalController.getGoalById);

/**
 * @route   POST /api/goals
 * @desc    Create goal
 * @access  Private
 */
router.post(
  '/',
  [
    body('title').trim().notEmpty().withMessage('Title is required'),
    body('targetAmount')
      .isFloat({ min: 0 })
      .withMessage('Target amount must be a positive number'),
    body('deadline').isISO8601().withMessage('Valid deadline is required'),
    body('savedAmount').optional().isFloat({ min: 0 }),
  ],
  validate,
  goalController.createGoal
);

/**
 * @route   PUT /api/goals/:id
 * @desc    Update goal
 * @access  Private
 */
router.put(
  '/:id',
  [
    body('title').optional().trim().notEmpty(),
    body('targetAmount').optional().isFloat({ min: 0 }),
    body('savedAmount').optional().isFloat({ min: 0 }),
    body('deadline').optional().isISO8601(),
    body('status').optional().isIn(['in progress', 'completed', 'failed']),
  ],
  validate,
  goalController.updateGoal
);

/**
 * @route   POST /api/goals/:id/contribute
 * @desc    Add contribution to goal
 * @access  Private
 */
router.post(
  '/:id/contribute',
  [body('amount').isFloat({ min: 0 }).withMessage('Amount must be a positive number')],
  validate,
  goalController.addContribution
);

/**
 * @route   DELETE /api/goals/:id
 * @desc    Delete goal
 * @access  Private
 */
router.delete('/:id', goalController.deleteGoal);

module.exports = router;