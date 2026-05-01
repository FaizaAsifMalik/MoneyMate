const express = require('express');
const { body } = require('express-validator');
const categoryController = require('../controllers/categoryController');
const { authenticate } = require('../middleware/auth.middleware');
const { validate } = require('../middleware/validation.middleware');

const router = express.Router();

// All routes require authentication
router.use(authenticate);

/**
 * @route   GET /api/categories
 * @desc    Get all categories
 * @access  Private
 */
router.get('/', categoryController.getCategories);

/**
 * @route   GET /api/categories/:id
 * @desc    Get category by ID
 * @access  Private
 */
router.get('/:id', categoryController.getCategoryById);

/**
 * @route   POST /api/categories
 * @desc    Create new category
 * @access  Private
 */
router.post(
  '/',
  [
    body('name').trim().notEmpty().withMessage('Category name is required'),
    body('type')
      .isIn(['income', 'expense'])
      .withMessage('Type must be either income or expense'),
    body('icon').optional().isString(),
    body('colour').optional().isString(),
  ],
  validate,
  categoryController.createCategory
);

/**
 * @route   PUT /api/categories/:id
 * @desc    Update category
 * @access  Private
 */
router.put(
  '/:id',
  [
    body('name').optional().trim().notEmpty(),
    body('icon').optional().isString(),
    body('colour').optional().isString(),
  ],
  validate,
  categoryController.updateCategory
);

/**
 * @route   DELETE /api/categories/:id
 * @desc    Delete category
 * @access  Private
 */
router.delete('/:id', categoryController.deleteCategory);

/**
 * @route   GET /api/categories/:id/stats
 * @desc    Get category statistics
 * @access  Private
 */
router.get('/:id/stats', categoryController.getCategoryStats);

module.exports = router;