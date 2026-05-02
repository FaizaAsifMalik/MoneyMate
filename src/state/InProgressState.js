const GoalState = require('./GoalState');
const CompletedState = require('./CompletedState');
const Money = require('../models/Money');

/**
 * In Progress State
 * Goal is actively being pursued
 */
class InProgressState extends GoalState {
  addContribution(amount) {
    if (!(amount instanceof Money)) {
      throw new Error('Amount must be a Money object');
    }

    // Add contribution
    this.goal._savedAmount = this.goal._savedAmount.add(amount);
    this.goal.touch();

    // Check if goal is completed
    if (this.goal._savedAmount.amount >= this.goal._targetAmount.amount) {
      this.goal.setState(new CompletedState(this.goal));
    }

    return this.goal;
  }

  canEdit() {
    return true;
  }

  canDelete() {
    return true;
  }

  getStateName() {
    return 'in progress';
  }

  getStatusMessage() {
    const remaining = this.goal._targetAmount.subtract(this.goal._savedAmount);
    const percentage = ((this.goal._savedAmount.amount / this.goal._targetAmount.amount) * 100).toFixed(1);
    return `${percentage}% completed. ${remaining.format()} remaining.`;
  }
}

module.exports = InProgressState;