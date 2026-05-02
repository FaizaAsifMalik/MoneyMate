const express = require('express');
const cors = require('cors');
const { errorMiddleware } = require('./middleware/error.middleware');
const { rateLimiter } = require('./middleware/rateLimiter.middleware');
const routes = require('./routes');
const logger = require('./utils/logger');

const app = express();

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(rateLimiter);

// Health check
app.get('/health', (req, res) => {
  res.json({ success: true, message: 'MoneyMate API is running', timestamp: new Date() });
});

// API Routes
app.use('/api', routes);

// 404 handler
app.use((req, res) => {
  res.status(404).json({ success: false, message: 'Route not found' });
});

// Error handler
app.use(errorMiddleware);

module.exports = app;