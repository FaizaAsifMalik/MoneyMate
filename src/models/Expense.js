const Entity = require('../core/Entity');
const Money = require('./Money');

/**
 * Expense Domain Model
 */
class Expense extends Entity {
  constructor(data) {
    super(data.id);
    this._userId = data.userId;
    this._categoryId = data.categoryId;
    this._money = data.money instanceof Money ? data.money : new Money(data.amount, data.currency || 'USD');
    this._date = new Date(data.date);
    this._description = data.description || '';
    this._billId = data.billId || null;
  }

  // Getters
  get userId() {
    return this._userId;
  }

  get categoryId() {
    return this._categoryId;
  }

  get money() {
    return this._money;
  }

  get amount() {
    return this._money.amount;
  }

  get currency() {
    return this._money.currency;
  }

  get date() {
    return this._date;
  }

  get description() {
    return this._description;
  }

  get billId() {
    return this._billId;
  }

  // Business Methods
  updateAmount(newMoney) {
    if (!(newMoney instanceof Money)) {
      throw new Error('Amount must be a Money object');
    }
    this._money = newMoney;
    this.touch();
  }

  updateDescription(newDescription) {
    this._description = newDescription || '';
    this.touch();
  }

  changeCategory(newCategoryId) {
    if (!newCategoryId) {
      throw new Error('Category ID is required');
    }
    this._categoryId = newCategoryId;
    this.touch();
  }

  isFromBill() {
    return this._billId !== null;
  }

  isSameMonth(date) {
    return (
      this._date.getMonth() === date.getMonth() &&
      this._date.getFullYear() === date.getFullYear()
    );
  }

  // Validation
  validate() {
    if (!this._userId) {
      throw new Error('User ID is required');
    }
    if (!this._categoryId) {
      throw new Error('Category ID is required');
    }
    if (this._money.amount <= 0) {
      throw new Error('Amount must be greater than zero');
    }
    if (!(this._date instanceof Date) || isNaN(this._date)) {
      throw new Error('Valid date is required');
    }
    return true;
  }

  // Serialization
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
      billId: this._billId,
      createdAt: this._createdAt,
      updatedAt: this._updatedAt,
    };
  }

  // Factory
  static create(userId, categoryId, money, date, description = '', billId = null) {
    const expense = new Expense({
      id: null,
      userId,
      categoryId,
      money,
      date,
      description,
      billId,
    });
    expense.validate();
    return expense;
  }

  // Reconstruct from database
  static fromDatabase(dbRow, currency = 'USD') {
    return new Expense({
      id: dbRow.expense_id,
      userId: dbRow.user_id,
      categoryId: dbRow.category_id,
      amount: dbRow.amount,
      currency: currency,
      date: dbRow.date,
      description: dbRow.description,
      billId: dbRow.bill_id,
    });
  }
}

module.exports = Expense;