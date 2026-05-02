const router = require('express').Router();
const NotificationController = require('../controllers/NotificationController');
const { authMiddleware } = require('../middleware/auth.middleware');

router.use(authMiddleware);
router.get('/', NotificationController.getAll.bind(NotificationController));
router.patch('/read-all', NotificationController.markAllRead.bind(NotificationController));
router.patch('/:id/read', NotificationController.markRead.bind(NotificationController));
router.delete('/:id', NotificationController.delete.bind(NotificationController));

module.exports = router;