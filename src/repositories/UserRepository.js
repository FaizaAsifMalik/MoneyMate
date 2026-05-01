const BaseRepository = require('./BaseRepository');
const { query } = require('../config/database');

/**
 * User Repository - Extends BaseRepository
 * Implements specific user-related data access
 */
class UserRepository extends BaseRepository {
  constructor() {
    super('users');
  }

  /**
   * Find user by email
   */
  async findByEmail(email) {
    return await this.findOne({ email });
  }

  /**
   * Check if email exists
   */
  async emailExists(email) {
    const result = await query(
      'SELECT EXISTS(SELECT 1 FROM users WHERE email = $1) as exists',
      [email]
    );
    return result.rows[0].exists;
  }

  /**
   * Get user with statistics
   */
  async getUserWithStats(userId) {
    const result = await query(
      `SELECT 
        u.*,
        (SELECT COUNT(*) FROM income WHERE user_id = u.id) as income_count,
        (SELECT COUNT(*) FROM expense WHERE user_id = u.id) as expense_count,
        (SELECT COUNT(*) FROM budget WHERE user_id = u.id) as budget_count,
        (SELECT COUNT(*) FROM goal WHERE user_id = u.id) as goal_count
       FROM users u
       WHERE u.id = $1`,
      [userId]
    );
    return result.rows[0] || null;
  }

  /**
   * Update last login
   */
  async updateLastLogin(userId) {
    await query(
      'UPDATE users SET last_login = NOW() WHERE id = $1',
      [userId]
    );
  }
}

module.exports = new UserRepository();