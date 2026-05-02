const RepositoryFactory = require('../factories/RepositoryFactory');
const { AppError } = require('../utils/errorHandler');

class NotificationService {
  constructor() {
    this.repo = RepositoryFactory.getNotificationRepository();
  }

  async getAll(userId, onlyUnread = false) {
    return this.repo.findByUserId(userId, onlyUnread);
  }

  async create(data) {
    return this.repo.create(data);
  }

  async markRead(notificationId, userId) {
    const existing = await this.repo.findById(notificationId);
    if (!existing || existing.user_id !== userId) throw new AppError('Notification not found', 404);
    return this.repo.update(notificationId, { isRead: true });
  }

  async markAllRead(userId) {
    return this.repo.markAllRead(userId);
  }

  async delete(notificationId, userId) {
    const existing = await this.repo.findById(notificationId);
    if (!existing || existing.user_id !== userId) throw new AppError('Notification not found', 404);
    return this.repo.delete(notificationId);
  }
}

module.exports = new NotificationService();