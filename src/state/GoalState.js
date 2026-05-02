/**
 * Abstract Goal State
 * State Pattern implementation for Goal status
 */
class GoalState {
  constructor(goal) {
    if (new.target === GoalState) {
      throw new TypeError('Cannot construct GoalState instances directly');
    }
    this.goal = goal;
  }

  /**
   * Add contribution to goal
   */
  addContribution(amount) {
    throw new Error('addContribution() must be implemented by subclass');
  }

  /**
   * Check if goal can be edited
   */
  canEdit() {
    throw new Error('canEdit() must be implemented by subclass');
  }

  /**
   * Check if goal can be deleted
   */
  canDelete() {
    throw new Error('canDelete() must be implemented by subclass');
  }

  /**
   * Get state name
   */
  getStateName() {
    throw new Error('getStateName() must be implemented by subclass');
  }

  /**
   * Get status message
   */
  getStatusMessage() {
    throw new Error('getStatusMessage() must be implemented by subclass');
  }
}

module.exports = GoalState;