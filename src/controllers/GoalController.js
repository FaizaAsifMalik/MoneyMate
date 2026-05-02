const goalService = require('../services/GoalService');
const { success, error, created } = require('../utils/responseFormatter');

class GoalController {
  async getAll(req, res) {
    try {
      const goals = await goalService.getAll(req.user.id);
      return success(res, goals);
    } catch (err) {
      return error(res, err.message, err.statusCode || 500);
    }
  }

  async getById(req, res) {
    try {
      const goal = await goalService.getById(req.params.id, req.user.id);
      return success(res, goal);
    } catch (err) {
      return error(res, err.message, err.statusCode || 500);
    }
  }

  async create(req, res) {
    try {
      const goal = await goalService.create(req.user.id, req.body);
      return created(res, goal);
    } catch (err) {
      return error(res, err.message, err.statusCode || 500);
    }
  }

  async update(req, res) {
    try {
      const goal = await goalService.update(req.params.id, req.user.id, req.body);
      return success(res, goal, 'Goal updated');
    } catch (err) {
      return error(res, err.message, err.statusCode || 500);
    }
  }

  async addContribution(req, res) {
    try {
      const goal = await goalService.addContribution(req.params.id, req.user.id, req.body.amount);
      return success(res, goal, 'Contribution added');
    } catch (err) {
      return error(res, err.message, err.statusCode || 500);
    }
  }

  async delete(req, res) {
    try {
      await goalService.delete(req.params.id, req.user.id);
      return success(res, null, 'Goal deleted');
    } catch (err) {
      return error(res, err.message, err.statusCode || 500);
    }
  }
}

module.exports = new GoalController();