const RepositoryFactory = require('../factories/RepositoryFactory');
const { AppError } = require('../utils/errorHandler');
const { parseInputDate, formatDate } = require('../utils/helpers');

class BudgetService {
  constructor() {
    this.repo = RepositoryFactory.getBudgetRepository();
  }

  async getAll(userId) {
    return this.repo.findByUserId(userId);
  }

  async getActive(userId) {
    return this.repo.findActiveBudgets(userId);
  }

  async getById(budgetId, userId) {
    const budget = await this.repo.findById(budgetId);
    if (!budget || budget.user_id !== userId) throw new AppError('Budget not found', 404);
    return budget;
  }

  async create(userId, data) {
    return this.repo.create({
      ...data,
      userId,
      limitAmount: parseFloat(data.limitAmount),
      ...(data.startDate && { startDate: formatDate(parseInputDate(data.startDate)) }),
      ...(data.endDate && { endDate: formatDate(parseInputDate(data.endDate)) }),
    });
  }

  async update(budgetId, userId, data) {
    const existing = await this.repo.findById(budgetId);
    if (!existing || existing.user_id !== userId) throw new AppError('Budget not found', 404);
    return this.repo.update(budgetId, {
      ...data,
      ...(data.startDate && { startDate: formatDate(parseInputDate(data.startDate)) }),
      ...(data.endDate && { endDate: formatDate(parseInputDate(data.endDate)) }),
    });
  }

  async delete(budgetId, userId) {
    const existing = await this.repo.findById(budgetId);
    if (!existing || existing.user_id !== userId) throw new AppError('Budget not found', 404);
    return this.repo.delete(budgetId);
  }
}

module.exports = new BudgetService();