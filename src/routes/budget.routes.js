const router = require('express').Router();
const BudgetController = require('../controllers/BudgetController');
const { authMiddleware } = require('../middleware/auth.middleware');
const { createBudgetValidator } = require('../validators/BudgetValidator');
const { validate } = require('../middleware/validation.middleware');

router.use(authMiddleware);
router.get('/', BudgetController.getAll.bind(BudgetController));
router.get('/active', BudgetController.getActive.bind(BudgetController));
router.post('/', createBudgetValidator, validate, BudgetController.create.bind(BudgetController));
router.put('/:id', BudgetController.update.bind(BudgetController));
router.delete('/:id', BudgetController.delete.bind(BudgetController));

module.exports = router;