const router = require('express').Router();
const UserController = require('../controllers/UserController');
const { authMiddleware } = require('../middleware/auth.middleware');
const upload = require('../middleware/upload.middleware');

router.use(authMiddleware);
router.get('/profile', UserController.getProfile.bind(UserController));
router.put('/profile', UserController.updateProfile.bind(UserController));
router.put('/currency', UserController.updateCurrency.bind(UserController));
router.put('/profile/picture', upload.single('profilePicture'), UserController.updateProfilePicture.bind(UserController));
router.delete('/account', UserController.deleteAccount.bind(UserController));

module.exports = router;