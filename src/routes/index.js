const express = require('express');
const authRoutes = require('./auth.routes');
const userRoutes = require('./user.routes');
const categoryRoutes = require('./category.routes');
const incomeRoutes = require('./income.routes');
const expenseRoutes = require('./expense.routes');
const budgetRoutes = require('./budget.routes');
const goalRoutes = require('./goal.routes');
const billRoutes = require('./bill.routes');
const notificationRoutes = require('./notification.routes');
const aiRoutes = require('./ai.routes');

const router = express.Router();

// Health check route
router.get('/health', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'MoneyMate API is running',
    timestamp: new Date().toISOString(),
  });
});

// Mount routes
router.use('/auth', authRoutes);
router.use('/users', userRoutes);
router.use('/categories', categoryRoutes);
router.use('/income', incomeRoutes);
router.use('/expenses', expenseRoutes);
router.use('/budgets', budgetRoutes);
router.use('/goals', goalRoutes);
router.use('/bills', billRoutes);
router.use('/notifications', notificationRoutes);
router.use('/ai', aiRoutes);

module.exports = router;