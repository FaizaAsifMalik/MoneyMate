const { query } = require('../config/database');
const { AppError } = require('../utils/errorHandler');
const logger = require('../utils/logger');

class NotificationService {
  /**
   * Get all notifications for user
   */
  async getNotifications(userId, filters = {}) {
    const { isRead, type, limit = 50 } = filters;
    
    let queryText = 'SELECT * FROM notifications WHERE user_id = $1';
    const values = [userId];
    let paramCount = 2;

    if (isRead !== undefined) {
      queryText += ` AND is_read = $${paramCount++}`;
      values.push(isRead);
    }

    if (type) {
      queryText += ` AND type = $${paramCount++}`;
      values.push(type);
    }

    queryText += ` ORDER BY created_at DESC LIMIT $${paramCount}`;
    values.push(limit);

    const result = await query(queryText, values);
    return result.rows;
  }

  /**
   * Create notification
   */
  async createNotification(userId, notificationData) {
    const { message, type } = notificationData;

    const result = await query(
      `INSERT INTO notifications (user_id, message, type, is_read, created_at)
       VALUES ($1, $2, $3, false, NOW())
       RETURNING *`,
      [userId, message, type]
    );

    logger.info(`Notification created for user ${userId}`);

    return result.rows[0];
  }

  /**
   * Mark notification as read
   */
  async markAsRead(notificationId, userId) {
    const result = await query(
      `UPDATE notifications 
       SET is_read = true 
       WHERE notification_id = $1 AND user_id = $2
       RETURNING *`,
      [notificationId, userId]
    );

    if (result.rows.length === 0) {
      throw new AppError('Notification not found', 404);
    }

    return result.rows[0];
  }

  /**
   * Mark all notifications as read
   */
  async markAllAsRead(userId) {
    await query(
      'UPDATE notifications SET is_read = true WHERE user_id = $1 AND is_read = false',
      [userId]
    );

    return {
      message: 'All notifications marked as read',
    };
  }

  /**
   * Delete notification
   */
  async deleteNotification(notificationId, userId) {
    const result = await query(
      'DELETE FROM notifications WHERE notification_id = $1 AND user_id = $2 RETURNING *',
      [notificationId, userId]
    );

    if (result.rows.length === 0) {
      throw new AppError('Notification not found', 404);
    }

    return {
      message: 'Notification deleted successfully',
    };
  }

  /**
   * Get unread count
   */
  async getUnreadCount(userId) {
    const result = await query(
      'SELECT COUNT(*) as count FROM notifications WHERE user_id = $1 AND is_read = false',
      [userId]
    );

    return {
      unread_count: parseInt(result.rows[0].count),
    };
  }
}

module.exports = new NotificationService();