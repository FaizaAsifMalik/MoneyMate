const router = require('express').Router();
const AuthController = require('../controllers/AuthController');
const { registerValidator, loginValidator } = require('../validators/AuthValidator');
const { validate } = require('../middleware/validation.middleware');
const { authLimiter } = require('../middleware/rateLimiter.middleware');

router.post('/register', authLimiter, registerValidator, validate, AuthController.register.bind(AuthController));
router.post('/login', authLimiter, loginValidator, validate, AuthController.login.bind(AuthController));
router.post('/send-otp', AuthController.sendOtp.bind(AuthController));
router.post('/reset-password', AuthController.resetPassword.bind(AuthController));

module.exports = router;