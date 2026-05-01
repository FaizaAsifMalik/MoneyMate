const express = require('express');
const { body } = require('express-validator');
const aiController = require('../controllers/aiController');
const { authenticate } = require('../middleware/auth.middleware');
const { validate } = require('../middleware/validation.middleware');

const router = express.Router();

// All routes require authentication
router.use(authenticate);

/**
 * @route   GET /api/ai/trends
 * @desc    Analyze spending trends
 * @access  Private
 */
router.get('/trends', aiController.analyzeTrends);

/**
 * @route   POST /api/ai/predict-budget
 * @desc    Predict future budget
 * @access  Private
 */
router.post(
  '/predict-budget',
  [
    body('categoryId').isInt().withMessage('Valid category ID is required'),
    body('monthsAhead').optional().isInt({ min: 1, max: 12 }),
  ],
  validate,
  aiController.predictBudget
);

/**
 * @route   GET /api/ai/suggestions
 * @desc    Generate AI suggestions
 * @access  Private
 */
router.get('/suggestions/generate', aiController.generateSuggestions);

/**
 * @route   GET /api/ai/insights
 * @desc    Get AI insights
 * @access  Private
 */
router.get('/insights', aiController.getInsights);

/**
 * @route   GET /api/ai/suggestions
 * @desc    Get AI suggestions
 * @access  Private
 */
router.get('/suggestions', aiController.getSuggestions);

/**
 * @route   PUT /api/ai/suggestions/:id/read
 * @desc    Mark suggestion as read
 * @access  Private
 */
router.put('/suggestions/:id/read', aiController.markSuggestionAsRead);

/**
 * @route   POST /api/ai/convert-currency
 * @desc    Convert currency
 * @access  Private
 */
router.post(
  '/convert-currency',
  [
    body('amount').isFloat({ min: 0 }).withMessage('Amount must be a positive number'),
    body('from').isString().withMessage('Source currency is required'),
    body('to').isString().withMessage('Target currency is required'),
  ],
  validate,
  aiController.convertCurrency
);

/**
 * @route   GET /api/ai/currencies
 * @desc    Get supported currencies
 * @access  Private
 */
router.get('/currencies', aiController.getSupportedCurrencies);

module.exports = router;