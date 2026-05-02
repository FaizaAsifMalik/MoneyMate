const Entity = require('../core/Entity');
const Money = require('./Money');
const InProgressState = require('../state/InProgressState');
const CompletedState = require('../state/CompletedState');
const FailedState = require('../state/FailedState');

/**
 * Goal Domain Model with State Pattern
 */
class Goal extends Entity {
  constructor(data) {
    super(data.id);
    this._userId = data.userId;
    this._title = data.title;
    this._targetAmount = data.targetAmount instanceof Money
      ? data.targetAmount
      : new Money(data.targetAmount, data.currency || 'USD');
    this._savedAmount = data.savedAmount instanceof Money
      ? data.savedAmount
      : new Money(data.savedAmount || 0, data.currency || 'USD');
    this._deadline = new Date(data.deadline);
    
    // Initialize state based on status
    this._state = this._initializeState(data.status || 'in progress');
  }

  // Getters
  get userId() {
    return this._userId;
  }

  get title() {
    return this._title;
  }

  get targetAmount() {
    return this._targetAmount;
  }

  get savedAmount() {
    return this._savedAmount;
  }

  get deadline() {
    return this._deadline;
  }

  get status() {
    return this._state.getStateName();
  }

  // State management
  _initializeState(status) {
    switch (status) {
      case 'completed':
        return new CompletedState(this);
      case 'failed':
        return new FailedState(this);
      case 'in progress':
      default:
        return new InProgressState(this);
    }
  }

  setState(newState) {
    this._state = newState;
    this.touch();
  }

  // Business Methods (delegated to state)
  addContribution(amount) {
    return this._state.addContribution(amount);
  }

  canEdit() {
    return this._state.canEdit();
  }

  canDelete() {
    return this._state.canDelete();
  }

  getStatusMessage() {
    return this._state.getStatusMessage();
  }

  // Direct business methods
  updateTitle(newTitle) {
    if (!this.canEdit()) {
      throw new Error('Cannot edit completed or failed goal');
    }
    if (!newTitle || newTitle.trim().length === 0) {
      throw new Error('Title cannot be empty');
    }
    this._title = newTitle.trim();
    this.touch();
  }

  updateTargetAmount(newAmount) {
    if (!this.canEdit()) {
      throw new Error('Cannot edit completed or failed goal');
    }
    if (!(newAmount instanceof Money)) {
      throw new Error('Amount must be a Money object');
    }
    this._targetAmount = newAmount;
    this.touch();
  }

  extendDeadline(newDeadline) {
    if (!this.canEdit()) {
      throw new Error('Cannot edit completed or failed goal');
    }
    if (new Date(newDeadline) <= this._deadline) {
      throw new Error('New deadline must be after current deadline');
    }
    this._deadline = new Date(newDeadline);
    this.touch();
  }

  getRemainingAmount() {
    try {
      return this._targetAmount.subtract(this._savedAmount);
    } catch (error) {
      return Money.zero(this._targetAmount.currency);
    }
  }

  getProgressPercentage() {
    if (this._targetAmount.amount === 0) return 0;
    return (this._savedAmount.amount / this._targetAmount.amount) * 100;
  }

  isDeadlinePassed() {
    return new Date() > this._deadline;
  }

  checkDeadlineAndUpdateState() {
    if (this.status === 'in progress' && this.isDeadlinePassed()) {
      this.setState(new FailedState(this));
    }
  }

  // Validation
  validate() {
    if (!this._userId) {
      throw new Error('User ID is required');
    }
    if (!this._title || this._title.trim().length === 0) {
      throw new Error('Title is required');
    }
    if (this._targetAmount.amount <= 0) {
      throw new Error('Target amount must be greater than zero');
    }
    if (!(this._deadline instanceof Date) || isNaN(this._deadline)) {
      throw new Error('Valid deadline is required');
    }
    return true;
  }

  // Serialization
  toJSON() {
    return {
      id: this._id,
      userId: this._userId,
      title: this._title,
      targetAmount: this._targetAmount.amount,
      currency: this._targetAmount.currency,
      formattedTarget: this._targetAmount.format(),
      savedAmount: this._savedAmount.amount,
      formattedSaved: this._savedAmount.format(),
      remainingAmount: this.getRemainingAmount().amount,
      formattedRemaining: this.getRemainingAmount().format(),
      deadline: this._deadline.toISOString().split('T')[0],
      status: this.status,
      statusMessage: this.getStatusMessage(),
      progressPercentage: this.getProgressPercentage().toFixed(2),
      canEdit: this.canEdit(),
      canDelete: this.canDelete(),
      createdAt: this._createdAt,
      updatedAt: this._updatedAt,
    };
  }

  // Factory
  static create(userId, title, targetAmount, deadline, savedAmount = null) {
    const currency = targetAmount.currency;
    const goal = new Goal({
      id: null,
      userId,
      title,
      targetAmount,
      savedAmount: savedAmount || Money.zero(currency),
      deadline,
      status: 'in progress',
    });
    goal.validate();
    return goal;
  }

  // Reconstruct from database
  static fromDatabase(dbRow, currency = 'USD') {
    return new Goal({
      id: dbRow.goal_id,
      userId: dbRow.user_id,
      title: dbRow.title,
      targetAmount: dbRow.target_amount,
      savedAmount: dbRow.saved_amount,
      currency: currency,
      deadline: dbRow.deadline,
      status: dbRow.status,
    });
  }
}

module.exports = Goal;