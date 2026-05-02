const Entity = require('../core/Entity');
const Money = require('./Money');

/**
 * Budget Domain Model
 */
class Budget extends Entity {
  constructor(data) {
    super(data.id);
    this._userId = data.userId;
    this._categoryId = data.categoryId;
    this._limitAmount = data.limitAmount instanceof Money 
      ? data.limitAmount 
      : new Money(data.limitAmount, data.currency || 'USD');
    this._period = data.period; // 'weekly', 'monthly', 'custom'
    this._startDate = new Date(data.startDate);
    this._endDate = new Date(data.endDate);
    this._spentAmount = data.spentAmount instanceof Money
      ? data.spentAmount
      : new Money(data.spentAmount || 0, data.currency || 'USD');
  }

  // Getters
  get userId() {
    return this._userId;
  }

  get categoryId() {
    return this._categoryId;
  }

  get limitAmount() {
    return this._limitAmount;
  }

  get period() {
    return this._period;
  }

  get startDate() {
    return this._startDate;
  }

  get endDate() {
    return this._endDate;
  }

  get spentAmount() {
    return this._spentAmount;
  }

  // Business Methods
  updateLimit(newLimit) {
    if (!(newLimit instanceof Money)) {
      throw new Error('Limit must be a Money object');
    }
    this._limitAmount = newLimit;
    this.touch();
  }

  updateSpentAmount(amount) {
    if (!(amount instanceof Money)) {
      throw new Error('Amount must be a Money object');
    }
    this._spentAmount = amount;
    this.touch();
  }

  getRemainingAmount() {
    try {
      return this._limitAmount.subtract(this._spentAmount);
    } catch (error) {
      return Money.zero(this._limitAmount.currency);
    }
  }

  getPercentageUsed() {
    if (this._limitAmount.amount === 0) return 0;
    return (this._spentAmount.amount / this._limitAmount.amount) * 100;
  }

  isExceeded() {
    return this._spentAmount.amount > this._limitAmount.amount;
  }

  isWarning() {
    const percentage = this.getPercentageUsed();
    return percentage >= 80 && percentage < 100;
  }

  isActive() {
    const now = new Date();
    return now >= this._startDate && now <= this._endDate;
  }

  isInPeriod(date) {
    return date >= this._startDate && date <= this._endDate;
  }

  // Validation
  validate() {
    if (!this._userId) {
      throw new Error('User ID is required');
    }
    if (!this._categoryId) {
      throw new Error('Category ID is required');
    }
    if (this._limitAmount.amount <= 0) {
      throw new Error('Limit amount must be greater than zero');
    }
    if (!['weekly', 'monthly', 'custom'].includes(this._period)) {
      throw new Error('Invalid period');
    }
    if (this._startDate >= this._endDate) {
      throw new Error('Start date must be before end date');
    }
    return true;
  }

  // Serialization
  toJSON() {
    return {
      id: this._id,
      userId: this._userId,
      categoryId: this._categoryId,
      limitAmount: this._limitAmount.amount,
      currency: this._limitAmount.currency,
      formattedLimit: this._limitAmount.format(),
      period: this._period,
      startDate: this._startDate.toISOString().split('T')[0],
      endDate: this._endDate.toISOString().split('T')[0],
      spentAmount: this._spentAmount.amount,
      formattedSpent: this._spentAmount.format(),
      remainingAmount: this.getRemainingAmount().amount,
      formattedRemaining: this.getRemainingAmount().format(),
      percentageUsed: this.getPercentageUsed().toFixed(2),
      isExceeded: this.isExceeded(),
      isWarning: this.isWarning(),
      isActive: this.isActive(),
      createdAt: this._createdAt,
      updatedAt: this._updatedAt,
    };
  }

  // Factory
  static create(userId, categoryId, limitAmount, period, startDate, endDate) {
    const budget = new Budget({
      id: null,
      userId,
      categoryId,
      limitAmount,
      period,
      startDate,
      endDate,
      spentAmount: Money.zero(limitAmount.currency),
    });
    budget.validate();
    return budget;
  }

  // Reconstruct from database
  static fromDatabase(dbRow, currency = 'USD', spentAmount = 0) {
    return new Budget({
      id: dbRow.budget_id,
      userId: dbRow.user_id,
      categoryId: dbRow.category_id,
      limitAmount: dbRow.limit_amount,
      currency: currency,
      period: dbRow.period,
      startDate: dbRow.start_date,
      endDate: dbRow.end_date,
      spentAmount: spentAmount,
    });
  }
}

module.exports = Budget;