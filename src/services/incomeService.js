const RepositoryFactory = require('../factories/RepositoryFactory');
const { AppError } = require('../utils/errorHandler');
const { parseInputDate, formatDate } = require('../utils/helpers');

class IncomeService {
  constructor() {
    this.repo = RepositoryFactory.getIncomeRepository();
  }

  async getAll(userId, filters = {}) {
    return this.repo.findByUserId(userId, filters);
  }

  async getById(incomeId, userId) {
    const income = await this.repo.findById(incomeId);
    if (!income || income.user_id !== userId) throw new AppError('Income not found', 404);
    return income;
  }

  async create(userId, data) {
    return this.repo.create({
      ...data,
      userId,
      amount: parseFloat(data.amount),
      date: data.date ? formatDate(parseInputDate(data.date)) : formatDate(new Date()),
    });
  }

  async update(incomeId, userId, data) {
    const existing = await this.repo.findById(incomeId);
    if (!existing || existing.user_id !== userId) throw new AppError('Income not found', 404);
    return this.repo.update(incomeId, {
      ...data,
      ...(data.date && { date: formatDate(parseInputDate(data.date)) }),
    });
  }

  async delete(incomeId, userId) {
    const existing = await this.repo.findById(incomeId);
    if (!existing || existing.user_id !== userId) throw new AppError('Income not found', 404);
    return this.repo.delete(incomeId);
  }

  async getMonthlyTotals(userId) {
    return this.repo.getMonthlyTotals(userId);
  }
}

module.exports = new IncomeService();