require('dotenv').config();

const config = {
  // Server
  port: process.env.PORT || 3000,
  nodeEnv: process.env.NODE_ENV || 'development',

  // Database
  database: {
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT) || 5432,
    database: process.env.DB_NAME || 'moneymate_db',
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || '',
    max: 20, // Maximum number of connections in pool
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 2000,
  },

  // JWT
  jwt: {
    secret: process.env.JWT_SECRET || 'fallback_secret_key_change_this',
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  },

  // Email
  email: {
    host: process.env.EMAIL_HOST || 'smtp.gmail.com',
    port: parseInt(process.env.EMAIL_PORT) || 587,
    secure: false,
    auth: {
      user: process.env.EMAIL_USER || '',
      pass: process.env.EMAIL_PASSWORD || '',
    },
    from: process.env.EMAIL_FROM || 'MoneyMate <noreply@moneymate.com>',
  },

  // Currency API
  currencyApi: {
    key: process.env.CURRENCY_API_KEY || '',
    url: process.env.CURRENCY_API_URL || 'https://v6.exchangerate-api.com/v6',
  },

  // Rate Limiting
  rateLimit: {
    windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 900000, // 15 minutes
    max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,
  },

  // AI Settings
  ai: {
    enabled: process.env.AI_SERVICE_ENABLED === 'true',
    thresholdMonths: parseInt(process.env.AI_ANALYSIS_THRESHOLD_MONTHS) || 3,
  },
};

module.exports = { config };