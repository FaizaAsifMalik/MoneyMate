const incomeService = require('../services/IncomeService');
const { success, error, created } = require('../utils/responseFormatter');

class IncomeController {
  async getAll(req, res) {
    try {
      const incomes = await incomeService.getAll(req.user.id, req.query);
      return success(res, incomes);
    } catch (err) {
      return error(res, err.message, err.statusCode || 500);
    }
  }

  async getById(req, res) {
    try {
      const income = await incomeService.getById(req.params.id, req.user.id);
      return success(res, income);
    } catch (err) {
      return error(res, err.message, err.statusCode || 500);
    }
  }

  async create(req, res) {
    try {
      const income = await incomeService.create(req.user.id, req.body);
      return created(res, income);
    } catch (err) {
      return error(res, err.message, err.statusCode || 500);
    }
  }

  async update(req, res) {
    try {
      const income = await incomeService.update(req.params.id, req.user.id, req.body);
      return success(res, income, 'Income updated');
    } catch (err) {
      return error(res, err.message, err.statusCode || 500);
    }
  }

  async delete(req, res) {
    try {
      await incomeService.delete(req.params.id, req.user.id);
      return success(res, null, 'Income deleted');
    } catch (err) {
      return error(res, err.message, err.statusCode || 500);
    }
  }

  async getMonthlyTotals(req, res) {
    try {
      const totals = await incomeService.getMonthlyTotals(req.user.id);
      return success(res, totals);
    } catch (err) {
      return error(res, err.message, err.statusCode || 500);
    }
  }
}

module.exports = new IncomeController();