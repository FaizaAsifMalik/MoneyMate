const router = require('express').Router();
const GoalController = require('../controllers/GoalController');
const { authMiddleware } = require('../middleware/auth.middleware');

router.use(authMiddleware);
router.get('/', GoalController.getAll.bind(GoalController));
router.get('/:id', GoalController.getById.bind(GoalController));
router.post('/', GoalController.create.bind(GoalController));
router.put('/:id', GoalController.update.bind(GoalController));
router.post('/:id/contribute', GoalController.addContribution.bind(GoalController));
router.delete('/:id', GoalController.delete.bind(GoalController));

module.exports = router;