const { query } = require('../config/database');
const { hashPassword, comparePassword, generateOTP } = require('../utils/helpers');
const { generateToken } = require('../config/jwt');
const { AppError } = require('../utils/errorHandler');
const otpStore = require('./otpStore');
const emailService = require('./emailService');
const logger = require('../utils/logger');

class AuthService {
  /**
   * Register new user
   */
  async register(userData) {
    const { name, email, password, currency = 'USD' } = userData;

    // Check if user already exists
    const existingUser = await query(
      'SELECT id FROM users WHERE email = $1',
      [email]
    );

    if (existingUser.rows.length > 0) {
      throw new AppError('User with this email already exists', 400);
    }

    // Hash password
    const passwordHash = await hashPassword(password);

    // Insert user
    const result = await query(
      `INSERT INTO users (name, email, passwordhash, savedpassword, currency, createdat)
       VALUES ($1, $2, $3, $4, $5, NOW())
       RETURNING id, name, email, currency, createdat`,
      [name, email, passwordHash, password, currency]
    );

    const user = result.rows[0];

    // Create default categories for new user
    await this.createDefaultCategories(user.id);

    // Generate token
    const token = generateToken({
      id: user.id,
      email: user.email,
      name: user.name,
    });

    logger.info(`New user registered: ${email}`);

    return {
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        currency: user.currency,
      },
      token,
    };
  }

  /**
   * Create default categories for new user
   */
  async createDefaultCategories(userId) {
    const defaultCategories = [
      // Income categories
      { name: 'Salary', type: 'income', icon: '💰', colour: '#4CAF50' },
      { name: 'Freelance', type: 'income', icon: '💼', colour: '#2196F3' },
      { name: 'Investments', type: 'income', icon: '📈', colour: '#9C27B0' },
      { name: 'Other Income', type: 'income', icon: '💵', colour: '#00BCD4' },
      
      // Expense categories
      { name: 'Food & Dining', type: 'expense', icon: '🍔', colour: '#FF5722' },
      { name: 'Transportation', type: 'expense', icon: '🚗', colour: '#FF9800' },
      { name: 'Shopping', type: 'expense', icon: '🛍️', colour: '#E91E63' },
      { name: 'Entertainment', type: 'expense', icon: '🎬', colour: '#9C27B0' },
      { name: 'Bills & Utilities', type: 'expense', icon: '📱', colour: '#F44336' },
      { name: 'Healthcare', type: 'expense', icon: '🏥', colour: '#009688' },
      { name: 'Education', type: 'expense', icon: '📚', colour: '#3F51B5' },
      { name: 'Other Expenses', type: 'expense', icon: '💳', colour: '#607D8B' },
    ];

    const values = defaultCategories.map(cat => 
      `(${userId}, '${cat.name}', '${cat.type}', '${cat.icon}', '${cat.colour}')`
    ).join(',');

    await query(
      `INSERT INTO category (user_id, name, type, icon, colour)
       VALUES ${values}`
    );
  }

  /**
   * Login user
   */
  async login(credentials) {
    const { email, password } = credentials;

    // Find user
    const result = await query(
      'SELECT id, name, email, passwordhash, currency FROM users WHERE email = $1',
      [email]
    );

    if (result.rows.length === 0) {
      throw new AppError('Invalid email or password', 401);
    }

    const user = result.rows[0];

    // Verify password
    const isPasswordValid = await comparePassword(password, user.passwordhash);
    if (!isPasswordValid) {
      throw new AppError('Invalid email or password', 401);
    }

    // Generate token
    const token = generateToken({
      id: user.id,
      email: user.email,
      name: user.name,
    });

    logger.info(`User logged in: ${email}`);

    return {
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        currency: user.currency,
      },
      token,
    };
  }

  /**
   * Send password reset OTP
   */
  async forgotPassword(email) {
    // Check if user exists
    const result = await query(
      'SELECT id, name FROM users WHERE email = $1',
      [email]
    );

    if (result.rows.length === 0) {
      throw new AppError('User with this email does not exist', 404);
    }

    const user = result.rows[0];

    // Generate OTP
    const otp = generateOTP(6);
    otpStore.store(email, otp);

    // Send email
    await emailService.sendPasswordResetEmail(email, user.name, otp);

    logger.info(`Password reset OTP sent to: ${email}`);

    return {
      message: 'Password reset OTP sent to your email',
    };
  }

  /**
   * Reset password with OTP
   */
  async resetPassword(email, otp, newPassword) {
    // Verify OTP
    const isValid = otpStore.verify(email, otp);
    if (!isValid) {
      throw new AppError('Invalid or expired OTP', 400);
    }

    // Hash new password
    const passwordHash = await hashPassword(newPassword);

    // Update password
    await query(
      'UPDATE users SET passwordhash = $1, savedpassword = $2 WHERE email = $3',
      [passwordHash, newPassword, email]
    );

    logger.info(`Password reset successful for: ${email}`);

    return {
      message: 'Password reset successful',
    };
  }

  /**
   * Change password (authenticated user)
   */
  async changePassword(userId, oldPassword, newPassword) {
    // Get user's current password hash
    const result = await query(
      'SELECT passwordhash FROM users WHERE id = $1',
      [userId]
    );

    if (result.rows.length === 0) {
      throw new AppError('User not found', 404);
    }

    // Verify old password
    const isValid = await comparePassword(oldPassword, result.rows[0].passwordhash);
    if (!isValid) {
      throw new AppError('Current password is incorrect', 400);
    }

    // Hash new password
    const passwordHash = await hashPassword(newPassword);

    // Update password
    await query(
      'UPDATE users SET passwordhash = $1, savedpassword = $2 WHERE id = $3',
      [passwordHash, newPassword, userId]
    );

    logger.info(`Password changed for user ID: ${userId}`);

    return {
      message: 'Password changed successfully',
    };
  }
}

module.exports = new AuthService();