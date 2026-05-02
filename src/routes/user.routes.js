const router = require('express').Router();
const UserController = require('../controllers/UserController');
const { authMiddleware } = require('../middleware/auth.middleware');

router.use(authMiddleware);
router.get('/profile', UserController.getProfile.bind(UserController));
router.put('/profile', UserController.updateProfile.bind(UserController));
router.put('/currency', UserController.updateCurrency.bind(UserController));

module.exports = router;