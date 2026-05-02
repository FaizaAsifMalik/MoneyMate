const GoalState = require('./GoalState');

/**
 * Completed State
 * Goal has been achieved
 */
class CompletedState extends GoalState {
  addContribution(amount) {
    throw new Error('Cannot add contribution to completed goal');
  }

  canEdit() {
    return false;
  }

  canDelete() {
    return true;
  }

  getStateName() {
    return 'completed';
  }

  getStatusMessage() {
    return 'Goal completed! Congratulations! 🎉';
  }
}

module.exports = CompletedState;