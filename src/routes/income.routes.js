const router = require('express').Router();
const IncomeController = require('../controllers/IncomeController');
const { authMiddleware } = require('../middleware/auth.middleware');

router.use(authMiddleware);
router.get('/', IncomeController.getAll.bind(IncomeController));
router.get('/monthly', IncomeController.getMonthlyTotals.bind(IncomeController));
router.get('/:id', IncomeController.getById.bind(IncomeController));
router.post('/', IncomeController.create.bind(IncomeController));
router.put('/:id', IncomeController.update.bind(IncomeController));
router.delete('/:id', IncomeController.delete.bind(IncomeController));

module.exports = router;