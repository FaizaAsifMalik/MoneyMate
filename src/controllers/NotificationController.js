const notificationService = require('../services/NotificationService');
const { success, error } = require('../utils/responseFormatter');

class NotificationController {
  async getAll(req, res) {
    try {
      const onlyUnread = req.query.unread === 'true';
      const notifications = await notificationService.getAll(req.user.id, onlyUnread);
      return success(res, notifications);
    } catch (err) {
      return error(res, err.message, err.statusCode || 500);
    }
  }

  async markRead(req, res) {
    try {
      const notification = await notificationService.markRead(req.params.id, req.user.id);
      return success(res, notification, 'Notification marked as read');
    } catch (err) {
      return error(res, err.message, err.statusCode || 500);
    }
  }

  async markAllRead(req, res) {
    try {
      await notificationService.markAllRead(req.user.id);
      return success(res, null, 'All notifications marked as read');
    } catch (err) {
      return error(res, err.message, err.statusCode || 500);
    }
  }

  async delete(req, res) {
    try {
      await notificationService.delete(req.params.id, req.user.id);
      return success(res, null, 'Notification deleted');
    } catch (err) {
      return error(res, err.message, err.statusCode || 500);
    }
  }
}

module.exports = new NotificationController();