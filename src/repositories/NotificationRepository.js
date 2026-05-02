const BaseRepository = require('./BaseRepository');

class NotificationRepository extends BaseRepository {
  constructor() {
    super('notifications', 'notification_id');
  }

  async findByUserId(userId, onlyUnread = false) {
    let sql = 'SELECT * FROM notifications WHERE user_id = $1';
    if (onlyUnread) sql += ' AND is_read = false';
    sql += ' ORDER BY created_at DESC LIMIT 50';
    const result = await this.query(sql, [userId]);
    return result.rows;
  }

  async markAllRead(userId) {
    await this.query(
      'UPDATE notifications SET is_read = true WHERE user_id = $1',
      [userId]
    );
  }

  async create(data) {
    const result = await this.query(
      `INSERT INTO notifications (user_id, type, title, message, metadata)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [data.userId, data.type, data.title, data.message, JSON.stringify(data.metadata || {})]
    );
    return result.rows[0];
  }

  async update(id, data) {
    const result = await this.query(
      'UPDATE notifications SET is_read = $1 WHERE notification_id = $2 RETURNING *',
      [data.isRead, id]
    );
    return result.rows[0] || null;
  }
}

module.exports = NotificationRepository;