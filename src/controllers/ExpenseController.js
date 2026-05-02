const expenseService = require('../services/ExpenseService');
const { success, error, created } = require('../utils/responseFormatter');

class ExpenseController {
  async getAll(req, res) {
    try {
      const expenses = await expenseService.getAll(req.user.id, req.query);
      return success(res, expenses);
    } catch (err) {
      return error(res, err.message, err.statusCode || 500);
    }
  }

  async getById(req, res) {
    try {
      const expense = await expenseService.getById(req.params.id, req.user.id);
      return success(res, expense);
    } catch (err) {
      return error(res, err.message, err.statusCode || 500);
    }
  }

  async create(req, res) {
    try {
      const expense = await expenseService.create(req.user.id, req.body);
      return created(res, expense);
    } catch (err) {
      return error(res, err.message, err.statusCode || 500);
    }
  }

  async update(req, res) {
    try {
      const expense = await expenseService.update(req.params.id, req.user.id, req.body);
      return success(res, expense, 'Expense updated');
    } catch (err) {
      return error(res, err.message, err.statusCode || 500);
    }
  }

  async delete(req, res) {
    try {
      await expenseService.delete(req.params.id, req.user.id);
      return success(res, null, 'Expense deleted');
    } catch (err) {
      return error(res, err.message, err.statusCode || 500);
    }
  }

  async getSummary(req, res) {
    try {
      const summary = await expenseService.getSummary(req.user.id, req.query.startDate, req.query.endDate);
      return success(res, summary);
    } catch (err) {
      return error(res, err.message, err.statusCode || 500);
    }
  }

  async getMonthlyTotals(req, res) {
    try {
      const totals = await expenseService.getMonthlyTotals(req.user.id);
      return success(res, totals);
    } catch (err) {
      return error(res, err.message, err.statusCode || 500);
    }
  }
}

module.exports = new ExpenseController();