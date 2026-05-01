/**
 * In-memory OTP storage
 * For production, use Redis or database
 */
class OTPStore {
  constructor() {
    this.otps = new Map();
    this.OTP_EXPIRY = 10 * 60 * 1000; // 10 minutes
  }

  /**
   * Store OTP for email
   */
  store(email, otp) {
    this.otps.set(email, {
      otp,
      expiresAt: Date.now() + this.OTP_EXPIRY,
    });
  }

  /**
   * Verify OTP for email
   */
  verify(email, otp) {
    const stored = this.otps.get(email);
    
    if (!stored) {
      return false;
    }

    if (Date.now() > stored.expiresAt) {
      this.otps.delete(email);
      return false;
    }

    if (stored.otp === otp) {
      this.otps.delete(email);
      return true;
    }

    return false;
  }

  /**
   * Clean expired OTPs
   */
  cleanup() {
    const now = Date.now();
    for (const [email, data] of this.otps.entries()) {
      if (now > data.expiresAt) {
        this.otps.delete(email);
      }
    }
  }
}

// Cleanup every 5 minutes
const otpStore = new OTPStore();
setInterval(() => otpStore.cleanup(), 5 * 60 * 1000);

module.exports = otpStore;