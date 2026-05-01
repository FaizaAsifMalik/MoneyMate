const { query } = require('../config/database');
const { AppError } = require('../utils/errorHandler');
const { formatDate } = require('../utils/helpers');
const logger = require('../utils/logger');

class GoalService {
  /**
   * Get all goals for user
   */
  async getGoals(userId, filters = {}) {
    const { status } = filters;
    
    let queryText = 'SELECT * FROM goal WHERE user_id = $1';
    const values = [userId];

    if (status) {
      queryText += ' AND status = $2';
      values.push(status);
    }

    queryText += ' ORDER BY deadline ASC';

    const result = await query(queryText, values);

    // Calculate progress for each goal
    const goalsWithProgress = result.rows.map((goal) => ({
      ...goal,
      progress_percentage: ((goal.saved_amount / goal.target_amount) * 100).toFixed(2),
      remaining_amount: goal.target_amount - goal.saved_amount,
    }));

    return goalsWithProgress;
  }

  /**
   * Get goal by ID
   */
  async getGoalById(goalId, userId) {
    const result = await query(
      'SELECT * FROM goal WHERE goal_id = $1 AND user_id = $2',
      [goalId, userId]
    );

    if (result.rows.length === 0) {
      throw new AppError('Goal not found', 404);
    }

    const goal = result.rows[0];

    return {
      ...goal,
      progress_percentage: ((goal.saved_amount / goal.target_amount) * 100).toFixed(2),
      remaining_amount: goal.target_amount - goal.saved_amount,
    };
  }

  /**
   * Create goal
   */
  async createGoal(userId, goalData) {
    const { title, targetAmount, deadline, savedAmount = 0 } = goalData;

    // Check if goal with same title exists
    const existing = await query(
      'SELECT goal_id FROM goal WHERE user_id = $1 AND title = $2',
      [userId, title]
    );

    if (existing.rows.length > 0) {
      throw new AppError('Goal with this title already exists', 400);
    }

    // Validate deadline is in future
    if (new Date(deadline) < new Date()) {
      throw new AppError('Deadline must be in the future', 400);
    }

    const result = await query(
      `INSERT INTO goal (user_id, title, target_amount, saved_amount, deadline, status)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [userId, title, targetAmount, savedAmount, formatDate(deadline), 'in progress']
    );

    logger.info(`Goal created for user ${userId}: ${title}`);

    return result.rows[0];
  }

  /**
   * Update goal
   */
  async updateGoal(goalId, userId, updateData) {
    const { title, targetAmount, savedAmount, deadline, status } = updateData;
    const updates = [];
    const values = [];
    let paramCount = 1;

    if (title) {
      updates.push(`title = $${paramCount++}`);
      values.push(title);
    }

    if (targetAmount !== undefined) {
      updates.push(`target_amount = $${paramCount++}`);
      values.push(targetAmount);
    }

    if (savedAmount !== undefined) {
      updates.push(`saved_amount = $${paramCount++}`);
      values.push(savedAmount);
    }

    if (deadline) {
      updates.push(`deadline = $${paramCount++}`);
      values.push(formatDate(deadline));
    }

    if (status) {
      updates.push(`status = $${paramCount++}`);
      values.push(status);
    }

    if (updates.length === 0) {
      throw new AppError('No fields to update', 400);
    }

    values.push(goalId, userId);

    const result = await query(
      `UPDATE goal 
       SET ${updates.join(', ')}
       WHERE goal_id = $${paramCount++} AND user_id = $${paramCount}
       RETURNING *`,
      values
    );

    if (result.rows.length === 0) {
      throw new AppError('Goal not found', 404);
    }

    // Auto-update status based on saved amount
    const goal = result.rows[0];
    if (goal.saved_amount >= goal.target_amount && goal.status !== 'completed') {
      await query(
        "UPDATE goal SET status = 'completed' WHERE goal_id = $1",
        [goalId]
      );
      goal.status = 'completed';
    }

    logger.info(`Goal updated: ${goalId}`);

    return goal;
  }

  /**
   * Add contribution to goal
   */
  async addContribution(goalId, userId, amount) {
    const goal = await this.getGoalById(goalId, userId);

    const newSavedAmount = parseFloat(goal.saved_amount) + parseFloat(amount);
    const newStatus = newSavedAmount >= goal.target_amount ? 'completed' : 'in progress';

    const result = await query(
      `UPDATE goal 
       SET saved_amount = $1, status = $2
       WHERE goal_id = $3 AND user_id = $4
       RETURNING *`,
      [newSavedAmount, newStatus, goalId, userId]
    );

    logger.info(`Contribution added to goal ${goalId}: ${amount}`);

    // Send notification if goal completed
    if (newStatus === 'completed') {
      const notificationService = require('./notificationService');
      await notificationService.createNotification(userId, {
        message: `Congratulations! You've completed your goal: ${goal.title}`,
        type: 'info',
      });
    }

    return result.rows[0];
  }

  /**
   * Delete goal
   */
  async deleteGoal(goalId, userId) {
    const result = await query(
      'DELETE FROM goal WHERE goal_id = $1 AND user_id = $2 RETURNING *',
      [goalId, userId]
    );

    if (result.rows.length === 0) {
      throw new AppError('Goal not found', 404);
    }

    logger.info(`Goal deleted: ${goalId}`);

    return {
      message: 'Goal deleted successfully',
    };
  }

  /**
   * Get goal summary
   */
  async getGoalSummary(userId) {
    const summary = await query(
      `SELECT 
        COUNT(*) as total_goals,
        COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_goals,
        COUNT(CASE WHEN status = 'in progress' THEN 1 END) as in_progress_goals,
        COUNT(CASE WHEN status = 'failed' THEN 1 END) as failed_goals,
        COALESCE(SUM(target_amount), 0) as total_target,
        COALESCE(SUM(saved_amount), 0) as total_saved
       FROM goal
       WHERE user_id = $1`,
      [userId]
    );

    return summary.rows[0];
  }
}

module.exports = new GoalService();