const router = require('express').Router();
const CategoryController = require('../controllers/CategoryController');
const { authMiddleware } = require('../middleware/auth.middleware');

router.use(authMiddleware);
router.get('/', CategoryController.getAll.bind(CategoryController));
router.get('/type/:type', CategoryController.getByType.bind(CategoryController));
router.post('/', CategoryController.create.bind(CategoryController));
router.put('/:id', CategoryController.update.bind(CategoryController));
router.delete('/:id', CategoryController.delete.bind(CategoryController));

module.exports = router;