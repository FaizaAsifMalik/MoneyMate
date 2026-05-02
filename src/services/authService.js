const bcrypt = require('bcryptjs');
const { generateToken } = require('../config/jwt');
const RepositoryFactory = require('../factories/RepositoryFactory');
const otpStore = require('./otpStore');
const emailService = require('./EmailService');
const { AppError } = require('../utils/errorHandler');

class AuthService {
  constructor() {
    this.userRepo = RepositoryFactory.getUserRepository();
  }

  async register(name, email, password, currency = 'USD') {
    const existing = await this.userRepo.findByEmail(email);
    if (existing) throw new AppError('Email already registered', 400);

    const passwordHash = await bcrypt.hash(password, 12);
    const user = await this.userRepo.create({ name, email, passwordHash, currency });

    const token = generateToken({ id: user.id, email: user.email });

    // Welcome email (non-blocking)
    emailService.sendWelcome(user.name, user.email).catch(() => {});

    return { user: this._sanitize(user), token };
  }

  async login(email, password) {
    const user = await this.userRepo.findByEmail(email);
    if (!user) throw new AppError('Invalid email or password', 401);

    const isMatch = await bcrypt.compare(password, user.passwordhash);
    if (!isMatch) throw new AppError('Invalid email or password', 401);

    const token = generateToken({ id: user.id, email: user.email });
    return { user: this._sanitize(user), token };
  }

  async sendOtp(email) {
    const user = await this.userRepo.findByEmail(email);
    if (!user) throw new AppError('Email not found', 404);

    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    otpStore.set(email, otp);
    await emailService.sendOtp(email, otp);
    return { message: 'OTP sent to your email' };
  }

  async verifyOtpAndResetPassword(email, otp, newPassword) {
    const stored = otpStore.get(email);
    if (!stored || stored !== otp) throw new AppError('Invalid or expired OTP', 400);

    const passwordHash = await bcrypt.hash(newPassword, 12);
    await this.userRepo.update(null, { email, passwordHash });
    otpStore.remove(email);

    // Get user by email for the update
    const user = await this.userRepo.findByEmail(email);
    await this.userRepo.update(user.id, { passwordHash });

    return { message: 'Password reset successful' };
  }

  _sanitize(user) {
    const { passwordhash, ...safe } = user;
    return safe;
  }
}

module.exports = new AuthService();