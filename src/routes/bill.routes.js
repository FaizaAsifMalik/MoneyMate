const router = require('express').Router();
const BillController = require('../controllers/BillController');
const { authMiddleware } = require('../middleware/auth.middleware');

router.use(authMiddleware);
router.get('/', BillController.getAll.bind(BillController));
router.get('/upcoming', BillController.getUpcoming.bind(BillController));
router.post('/', BillController.create.bind(BillController));
router.put('/:id', BillController.update.bind(BillController));
router.patch('/:id/pay', BillController.markAsPaid.bind(BillController));
router.delete('/:id', BillController.delete.bind(BillController));

module.exports = router;