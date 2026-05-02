const repos = require('../repositories');

class RepositoryFactory {
  static _instances = {};

  static getRepository(name) {
    if (!this._instances[name]) {
      const RepoClass = repos[name];
      if (!RepoClass) throw new Error(`Repository ${name} not found`);
      this._instances[name] = new RepoClass();
    }
    return this._instances[name];
  }

  static getUserRepository() { return this.getRepository('UserRepository'); }
  static getCategoryRepository() { return this.getRepository('CategoryRepository'); }
  static getIncomeRepository() { return this.getRepository('IncomeRepository'); }
  static getExpenseRepository() { return this.getRepository('ExpenseRepository'); }
  static getBudgetRepository() { return this.getRepository('BudgetRepository'); }
  static getGoalRepository() { return this.getRepository('GoalRepository'); }
  static getBillRepository() { return this.getRepository('BillRepository'); }
  static getNotificationRepository() { return this.getRepository('NotificationRepository'); }
}

module.exports = RepositoryFactory;