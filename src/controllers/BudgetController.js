const budgetService = require('../services/BudgetService');
const { success, error, created } = require('../utils/responseFormatter');

class BudgetController {
  async getAll(req, res) {
    try {
      const budgets = await budgetService.getAll(req.user.id);
      return success(res, budgets);
    } catch (err) {
      return error(res, err.message, err.statusCode || 500);
    }
  }

  async getActive(req, res) {
    try {
      const budgets = await budgetService.getActive(req.user.id);
      return success(res, budgets);
    } catch (err) {
      return error(res, err.message, err.statusCode || 500);
    }
  }

  async create(req, res) {
    try {
      const budget = await budgetService.create(req.user.id, req.body);
      return created(res, budget);
    } catch (err) {
      return error(res, err.message, err.statusCode || 500);
    }
  }

  async update(req, res) {
    try {
      const budget = await budgetService.update(req.params.id, req.user.id, req.body);
      return success(res, budget, 'Budget updated');
    } catch (err) {
      return error(res, err.message, err.statusCode || 500);
    }
  }

  async delete(req, res) {
    try {
      await budgetService.delete(req.params.id, req.user.id);
      return success(res, null, 'Budget deleted');
    } catch (err) {
      return error(res, err.message, err.statusCode || 500);
    }
  }
}

module.exports = new BudgetController();