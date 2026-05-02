const RepositoryFactory = require('../factories/RepositoryFactory');
const eventEmitter = require('../observers/EventEmitter');
const { AppError } = require('../utils/errorHandler');
const { parseInputDate, formatDate } = require('../utils/helpers');

class GoalService {
  constructor() {
    this.repo = RepositoryFactory.getGoalRepository();
    this.userRepo = RepositoryFactory.getUserRepository();
  }

  async getAll(userId) {
    return this.repo.findByUserId(userId);
  }

  async getById(goalId, userId) {
    const goal = await this.repo.findById(goalId);
    if (!goal || goal.user_id !== userId) throw new AppError('Goal not found', 404);
    return goal;
  }

  async create(userId, data) {
    return this.repo.create({
      ...data,
      userId,
      ...(data.targetDate && { targetDate: formatDate(parseInputDate(data.targetDate)) }),
    });
  }

  async update(goalId, userId, data) {
    const existing = await this.repo.findById(goalId);
    if (!existing || existing.user_id !== userId) throw new AppError('Goal not found', 404);
    return this.repo.update(goalId, {
      ...data,
      ...(data.targetDate && { targetDate: formatDate(parseInputDate(data.targetDate)) }),
    });
  }

  async addContribution(goalId, userId, amount) {
    const goal = await this.getById(goalId, userId);
    if (goal.status === 'completed') throw new AppError('Goal is already completed', 400);
    if (goal.status === 'failed') throw new AppError('Cannot contribute to a failed goal', 400);

    const newSaved = parseFloat(goal.saved_amount) + parseFloat(amount);
    let newStatus = goal.status;

    if (newSaved >= parseFloat(goal.target_amount)) {
      newStatus = 'completed';
      const user = await this.userRepo.findById(userId);
      await eventEmitter.emit('goal.completed', {
        userId,
        title: goal.title,
        targetAmount: goal.target_amount,
        currency: user.currency,
      });
    }

    return this.repo.update(goalId, { savedAmount: newSaved, status: newStatus });
  }

  async delete(goalId, userId) {
    const existing = await this.repo.findById(goalId);
    if (!existing || existing.user_id !== userId) throw new AppError('Goal not found', 404);
    return this.repo.delete(goalId);
  }
}

module.exports = new GoalService();