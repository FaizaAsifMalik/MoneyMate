const userService = require('../services/UserService');
const { success, error } = require('../utils/responseFormatter');

class UserController {
  async getProfile(req, res) {
    try {
      const user = await userService.getProfile(req.user.id);
      return success(res, user);
    } catch (err) {
      return error(res, err.message, err.statusCode || 500);
    }
  }

  async updateProfile(req, res) {
    try {
      const user = await userService.updateProfile(req.user.id, req.body);
      return success(res, user, 'Profile updated');
    } catch (err) {
      return error(res, err.message, err.statusCode || 500);
    }
  }

  async updateCurrency(req, res) {
    try {
      const user = await userService.updateCurrency(req.user.id, req.body.currency);
      return success(res, user, 'Currency updated');
    } catch (err) {
      return error(res, err.message, err.statusCode || 500);
    }
  }

  async updateProfilePicture(req, res) {
    try {
      if (!req.file) throw new AppError('No image file provided', 400);
      const imageUrl = `/uploads/profiles/${req.file.filename}`;
      const user = await userService.updateProfilePicture(req.user.id, imageUrl);
      return success(res, user, 'Profile picture updated');
    } catch (err) {
      return error(res, err.message, err.statusCode || 500);
    }
  }
}

module.exports = new UserController();