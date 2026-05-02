const authService = require('../services/AuthService');
const { success, error } = require('../utils/responseFormatter');

class AuthController {
  async register(req, res) {
    try {
      const { name, email, password, currency } = req.body;
      const result = await authService.register(name, email, password, currency);
      return res.status(201).json({ success: true, message: 'Registration successful', data: result });
    } catch (err) {
      return error(res, err.message, err.statusCode || 500);
    }
  }

  async login(req, res) {
    try {
      const { email, password } = req.body;
      const result = await authService.login(email, password);
      return success(res, result, 'Login successful');
    } catch (err) {
      return error(res, err.message, err.statusCode || 500);
    }
  }

  async sendOtp(req, res) {
    try {
      const result = await authService.sendOtp(req.body.email);
      return success(res, result, 'OTP sent');
    } catch (err) {
      return error(res, err.message, err.statusCode || 500);
    }
  }

  async resetPassword(req, res) {
    try {
      const { email, otp, newPassword } = req.body;
      const result = await authService.verifyOtpAndResetPassword(email, otp, newPassword);
      return success(res, result, 'Password reset successful');
    } catch (err) {
      return error(res, err.message, err.statusCode || 500);
    }
  }
}

module.exports = new AuthController();