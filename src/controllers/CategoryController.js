const categoryService = require('../services/CategoryService');
const { success, error, created } = require('../utils/responseFormatter');

class CategoryController {
  async getAll(req, res) {
    try {
      const categories = await categoryService.getAll(req.user.id);
      return success(res, categories);
    } catch (err) {
      return error(res, err.message, err.statusCode || 500);
    }
  }

  async getByType(req, res) {
    try {
      const categories = await categoryService.getByType(req.user.id, req.params.type);
      return success(res, categories);
    } catch (err) {
      return error(res, err.message, err.statusCode || 500);
    }
  }

  async create(req, res) {
    try {
      const category = await categoryService.create(req.user.id, req.body);
      return created(res, category);
    } catch (err) {
      return error(res, err.message, err.statusCode || 500);
    }
  }

  async update(req, res) {
    try {
      const category = await categoryService.update(req.params.id, req.user.id, req.body);
      return success(res, category, 'Category updated');
    } catch (err) {
      return error(res, err.message, err.statusCode || 500);
    }
  }

  async delete(req, res) {
    try {
      await categoryService.delete(req.params.id, req.user.id);
      return success(res, null, 'Category deleted');
    } catch (err) {
      return error(res, err.message, err.statusCode || 500);
    }
  }
}

module.exports = new CategoryController();