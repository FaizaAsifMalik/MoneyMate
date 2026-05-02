const router = require('express').Router();
const AIController = require('../controllers/AIController');
const { authMiddleware } = require('../middleware/auth.middleware');

router.use(authMiddleware);
router.get('/insights', AIController.getInsights.bind(AIController));
router.post('/chat', AIController.chat.bind(AIController));
router.post('/convert-currency', AIController.convertCurrency.bind(AIController));
router.get('/currencies', AIController.getSupportedCurrencies.bind(AIController));

module.exports = router;