const RepositoryFactory = require('../factories/RepositoryFactory');
const eventEmitter = require('../observers/EventEmitter');
const { AppError } = require('../utils/errorHandler');
const { getStartOfMonth, getEndOfMonth, parseInputDate, formatDate } = require('../utils/helpers');

class ExpenseService {
  constructor() {
    this.repo = RepositoryFactory.getExpenseRepository();
    this.budgetRepo = RepositoryFactory.getBudgetRepository();
    this.userRepo = RepositoryFactory.getUserRepository();
  }

  async getAll(userId, filters = {}) {
    return this.repo.findByUserId(userId, filters);
  }

  async getById(expenseId, userId) {
    const expense = await this.repo.findById(expenseId);
    if (!expense || expense.user_id !== userId) throw new AppError('Expense not found', 404);
    return expense;
  }

  async create(userId, data) {
    const user = await this.userRepo.findById(userId);

    const expense = await this.repo.create({
      ...data,
      userId,
      amount: parseFloat(data.amount),
      date: data.date ? formatDate(parseInputDate(data.date)) : formatDate(new Date()),
    });

    await this._checkBudgetAlert(userId, data.categoryId, user);

    return expense;
  }

  async update(expenseId, userId, data) {
    const existing = await this.repo.findById(expenseId);
    if (!existing || existing.user_id !== userId) throw new AppError('Expense not found', 404);

    return this.repo.update(expenseId, {
      ...data,
      ...(data.date && { date: formatDate(parseInputDate(data.date)) }),
    });
  }

  async delete(expenseId, userId) {
    const existing = await this.repo.findById(expenseId);
    if (!existing || existing.user_id !== userId) throw new AppError('Expense not found', 404);
    return this.repo.delete(expenseId);
  }

  async getSummary(userId, startDate, endDate) {
    const start = startDate ? formatDate(parseInputDate(startDate)) : getStartOfMonth();
    const end = endDate ? formatDate(parseInputDate(endDate)) : getEndOfMonth();
    return this.repo.getSummaryByCategory(userId, start, end);
  }

  async getMonthlyTotals(userId) {
    return this.repo.getMonthlyTotals(userId);
  }

  async _checkBudgetAlert(userId, categoryId, user) {
    try {
      const budgets = await this.budgetRepo.findActiveBudgets(userId);
      for (const budget of budgets) {
        if (budget.category_id !== categoryId) continue;
        const pct = (parseFloat(budget.spent_amount) / parseFloat(budget.limit_amount)) * 100;
        if (pct >= 80) {
          await eventEmitter.emit('budget.exceeded', {
            userId,
            email: user.email,
            userName: user.name,
            categoryName: budget.category_name,
            percentUsed: pct,
            amountSpent: budget.spent_amount,
            limit: budget.limit_amount,
            currency: user.currency,
          });
        }
      }
    } catch (e) { /* non-blocking */ }
  }
}

module.exports = new ExpenseService();