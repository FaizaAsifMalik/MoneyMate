const RepositoryFactory = require('../factories/RepositoryFactory');
const { AppError } = require('../utils/errorHandler');

class UserService {
  constructor() {
    this.userRepo = RepositoryFactory.getUserRepository();
  }

  async getProfile(userId) {
    const user = await this.userRepo.findById(userId);
    if (!user) throw new AppError('User not found', 404);
    const { passwordhash, ...safe } = user;
    return safe;
  }

  async updateProfile(userId, data) {
    const updated = await this.userRepo.update(userId, data);
    if (!updated) throw new AppError('User not found', 404);
    const { passwordhash, ...safe } = updated;
    return safe;
  }

  async updateCurrency(userId, currency) {
    return this.updateProfile(userId, { currency });
  }

  async updateProfilePicture(userId, imageUrl) {
    const updated = await this.userRepo.update(userId, { profilePicture: imageUrl });
    if (!updated) throw new AppError('User not found', 404);
    const { passwordhash, ...safe } = updated;
    return safe;
  }
}

module.exports = new UserService();
