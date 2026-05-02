const Entity = require('../core/Entity');
const Money = require('./Money');

class Bill extends Entity {
  constructor(data) {
    super(data.id);
    this._userId = data.userId;
    this._name = data.name;
    this._money = data.money instanceof Money ? data.money : new Money(data.amount, data.currency || 'USD');
    this._dueDate = parseInt(data.dueDate); // day of month 1-31
    this._frequency = data.frequency; // 'monthly', 'yearly'
    this._categoryId = data.categoryId || null;
    this._isPaid = data.isPaid || false;
    this._nextDueDate = data.nextDueDate ? new Date(data.nextDueDate) : null;
  }

  get userId() { return this._userId; }
  get name() { return this._name; }
  get money() { return this._money; }
  get amount() { return this._money.amount; }
  get currency() { return this._money.currency; }
  get dueDate() { return this._dueDate; }
  get frequency() { return this._frequency; }
  get categoryId() { return this._categoryId; }
  get isPaid() { return this._isPaid; }
  get nextDueDate() { return this._nextDueDate; }

  markAsPaid() { this._isPaid = true; this.touch(); }
  markAsUnpaid() { this._isPaid = false; this.touch(); }

  getDaysUntilDue() {
    if (!this._nextDueDate) return null;
    const now = new Date();
    const diff = this._nextDueDate - now;
    return Math.ceil(diff / (1000 * 60 * 60 * 24));
  }

  isOverdue() {
    if (!this._nextDueDate || this._isPaid) return false;
    return new Date() > this._nextDueDate;
  }

  validate() {
    if (!this._userId) throw new Error('User ID is required');
    if (!this._name || this._name.trim().length === 0) throw new Error('Bill name is required');
    if (this._money.amount <= 0) throw new Error('Amount must be greater than zero');
    if (this._dueDate < 1 || this._dueDate > 31) throw new Error('Due date must be between 1 and 31');
    if (!['monthly', 'yearly'].includes(this._frequency)) throw new Error('Invalid frequency');
    return true;
  }

  toJSON() {
    return {
      id: this._id,
      userId: this._userId,
      name: this._name,
      amount: this._money.amount,
      currency: this._money.currency,
      formattedAmount: this._money.format(),
      dueDate: this._dueDate,
      frequency: this._frequency,
      categoryId: this._categoryId,
      isPaid: this._isPaid,
      nextDueDate: this._nextDueDate ? this._nextDueDate.toISOString().split('T')[0] : null,
      daysUntilDue: this.getDaysUntilDue(),
      isOverdue: this.isOverdue(),
      createdAt: this._createdAt,
      updatedAt: this._updatedAt,
    };
  }

  static create(userId, name, money, dueDate, frequency, categoryId = null) {
    const bill = new Bill({ id: null, userId, name, money, dueDate, frequency, categoryId });
    bill.validate();
    return bill;
  }

  static fromDatabase(dbRow, currency = 'USD') {
    return new Bill({
      id: dbRow.bill_id,
      userId: dbRow.user_id,
      name: dbRow.name,
      amount: dbRow.amount,
      currency,
      dueDate: dbRow.due_date,
      frequency: dbRow.frequency,
      categoryId: dbRow.category_id,
      isPaid: dbRow.is_paid,
      nextDueDate: dbRow.next_due_date,
    });
  }
}

module.exports = Bill;