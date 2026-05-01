const UserRepository = require('../repositories/UserRepository');
const ExpenseRepository = require('../repositories/ExpenseRepository');
const IncomeRepository = require('../repositories/IncomeRepository');
const CategoryRepository = require('../repositories/CategoryRepository');
const BudgetRepository = require('../repositories/BudgetRepository');

/**
 * Repository Factory
 * Implements Factory Pattern
 */
class RepositoryFactory {
  static create(repositoryType) {
    switch (repositoryType) {
      case 'user':
        return UserRepository;
      case 'expense':
        return ExpenseRepository;
      case 'income':
        return IncomeRepository;
      case 'category':
        return CategoryRepository;
      case 'budget':
        return BudgetRepository;
      default:
        throw new Error(`Unknown repository type: ${repositoryType}`);
    }
  }

  static createAll() {
    return {
      user: UserRepository,
      expense: ExpenseRepository,
      income: IncomeRepository,
      category: CategoryRepository,
      budget: BudgetRepository,
    };
  }
}

module.exports = RepositoryFactory;