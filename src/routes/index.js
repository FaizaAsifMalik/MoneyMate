const router = require('express').Router();

router.use('/auth', require('./auth.routes'));
router.use('/users', require('./user.routes'));
router.use('/categories', require('./category.routes'));
router.use('/expenses', require('./expense.routes'));
router.use('/incomes', require('./income.routes'));
router.use('/budgets', require('./budget.routes'));
router.use('/goals', require('./goal.routes'));
router.use('/bills', require('./bill.routes'));
router.use('/notifications', require('./notification.routes'));
router.use('/ai', require('./ai.routes'));

module.exports = router;