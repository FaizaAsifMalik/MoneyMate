const RepositoryFactory = require('../factories/RepositoryFactory');
const { AppError } = require('../utils/errorHandler');

class CategoryService {
  constructor() {
    this.repo = RepositoryFactory.getCategoryRepository();
  }

  async getAll(userId) {
    return this.repo.findByUserId(userId);
  }

  async getByType(userId, type) {
    return this.repo.findByUserIdAndType(userId, type);
  }

  async create(userId, data) {
    return this.repo.create({ ...data, userId });
  }

  async update(categoryId, userId, data) {
    const existing = await this.repo.findById(categoryId);
    if (!existing || existing.user_id !== userId) throw new AppError('Category not found', 404);
    return this.repo.update(categoryId, data);
  }

  async delete(categoryId, userId) {
    const existing = await this.repo.findById(categoryId);
    if (!existing || existing.user_id !== userId) throw new AppError('Category not found', 404);
    return this.repo.delete(categoryId);
  }
}

module.exports = new CategoryService();