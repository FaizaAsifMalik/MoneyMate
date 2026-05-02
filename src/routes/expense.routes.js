const router = require('express').Router();
const ExpenseController = require('../controllers/ExpenseController');
const { authMiddleware } = require('../middleware/auth.middleware');
const { createExpenseValidator, updateExpenseValidator } = require('../validators/ExpenseValidator');
const { validate } = require('../middleware/validation.middleware');

router.use(authMiddleware);
router.get('/', ExpenseController.getAll.bind(ExpenseController));
router.get('/summary', ExpenseController.getSummary.bind(ExpenseController));
router.get('/monthly', ExpenseController.getMonthlyTotals.bind(ExpenseController));
router.get('/:id', ExpenseController.getById.bind(ExpenseController));
router.post('/', createExpenseValidator, validate, ExpenseController.create.bind(ExpenseController));
router.put('/:id', updateExpenseValidator, validate, ExpenseController.update.bind(ExpenseController));
router.delete('/:id', ExpenseController.delete.bind(ExpenseController));

module.exports = router;