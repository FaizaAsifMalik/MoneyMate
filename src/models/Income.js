const Entity = require('../core/Entity');
const Money = require('./Money');

class Income extends Entity {
  constructor(data) {
    super(data.id);
    this._userId = data.userId;
    this._categoryId = data.categoryId;
    this._money = data.money instanceof Money ? data.money : new Money(data.amount, data.currency || 'USD');
    this._date = new Date(data.date);
    this._description = data.description || '';
  }

  get userId() { return this._userId; }
  get categoryId() { return this._categoryId; }
  get money() { return this._money; }
  get amount() { return this._money.amount; }
  get currency() { return this._money.currency; }
  get date() { return this._date; }
  get description() { return this._description; }

  updateAmount(newMoney) {
    if (!(newMoney instanceof Money)) throw new Error('Amount must be a Money object');
    this._money = newMoney;
    this.touch();
  }

  updateDescription(desc) { this._description = desc || ''; this.touch(); }

  validate() {
    if (!this._userId) throw new Error('User ID is required');
    if (!this._categoryId) throw new Error('Category ID is required');
    if (this._money.amount <= 0) throw new Error('Amount must be greater than zero');
    if (!(this._date instanceof Date) || isNaN(this._date)) throw new Error('Valid date is required');
    return true;
  }

  toJSON() {
    return {
      id: this._id,
      userId: this._userId,
      categoryId: this._categoryId,
      amount: this._money.amount,
      currency: this._money.currency,
      formattedAmount: this._money.format(),
      date: this._date.toISOString().split('T')[0],
      description: this._description,
      createdAt: this._createdAt,
      updatedAt: this._updatedAt,
    };
  }

  static create(userId, categoryId, money, date, description = '') {
    const income = new Income({ id: null, userId, categoryId, money, date, description });
    income.validate();
    return income;
  }

  static fromDatabase(dbRow, currency = 'USD') {
    return new Income({
      id: dbRow.income_id,
      userId: dbRow.user_id,
      categoryId: dbRow.category_id,
      amount: dbRow.amount,
      currency,
      date: dbRow.date,
      description: dbRow.description,
    });
  }
}

module.exports = Income;