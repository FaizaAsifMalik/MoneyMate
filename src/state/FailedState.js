const GoalState = require('./GoalState');

/**
 * Failed State
 * Goal was not achieved by deadline
 */
class FailedState extends GoalState {
  addContribution(amount) {
    throw new Error('Cannot add contribution to failed goal');
  }

  canEdit() {
    return false;
  }

  canDelete() {
    return true;
  }

  getStateName() {
    return 'failed';
  }

  getStatusMessage() {
    return 'Goal deadline passed without completion.';
  }
}

module.exports = FailedState;