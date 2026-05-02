const Entity = require('../core/Entity');

class Notification extends Entity {
  constructor(data) {
    super(data.id);
    this._userId = data.userId;
    this._type = data.type; // 'budget_alert', 'bill_reminder', 'goal_completed'
    this._title = data.title;
    this._message = data.message;
    this._isRead = data.isRead || false;
    this._metadata = data.metadata || {};
  }

  get userId() { return this._userId; }
  get type() { return this._type; }
  get title() { return this._title; }
  get message() { return this._message; }
  get isRead() { return this._isRead; }
  get metadata() { return this._metadata; }

  markAsRead() { this._isRead = true; this.touch(); }

  validate() {
    if (!this._userId) throw new Error('User ID is required');
    if (!this._title) throw new Error('Title is required');
    if (!this._message) throw new Error('Message is required');
    return true;
  }

  toJSON() {
    return {
      id: this._id,
      userId: this._userId,
      type: this._type,
      title: this._title,
      message: this._message,
      isRead: this._isRead,
      metadata: this._metadata,
      createdAt: this._createdAt,
      updatedAt: this._updatedAt,
    };
  }

  static create(userId, type, title, message, metadata = {}) {
    const n = new Notification({ id: null, userId, type, title, message, metadata });
    n.validate();
    return n;
  }

  static fromDatabase(dbRow) {
    return new Notification({
      id: dbRow.notification_id,
      userId: dbRow.user_id,
      type: dbRow.type,
      title: dbRow.title,
      message: dbRow.message,
      isRead: dbRow.is_read,
      metadata: dbRow.metadata || {},
    });
  }
}

module.exports = Notification;