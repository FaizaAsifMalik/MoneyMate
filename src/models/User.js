const Entity = require('../core/Entity');
const Money = require('./Money');

/**
 * User Domain Model
 * Encapsulates user business logic
 */
class User extends Entity {
  constructor(data) {
    super(data.id);
    this._name = data.name;
    this._email = data.email;
    this._passwordHash = data.passwordHash;
    this._currency = data.currency || 'USD';
    
    if (data.createdAt) {
      this._createdAt = new Date(data.createdAt);
    }
  }

  // Getters
  get name() {
    return this._name;
  }

  get email() {
    return this._email;
  }

  get currency() {
    return this._currency;
  }

  // Business Methods
  updateName(newName) {
    if (!newName || newName.trim().length === 0) {
      throw new Error('Name cannot be empty');
    }
    this._name = newName.trim();
    this.touch();
  }

  updateEmail(newEmail) {
    if (!this.isValidEmail(newEmail)) {
      throw new Error('Invalid email format');
    }
    this._email = newEmail.toLowerCase();
    this.touch();
  }

  changeCurrency(newCurrency) {
    const validCurrencies = ['USD', 'EUR', 'GBP', 'PKR', 'INR', 'JPY', 'CNY', 'AUD', 'CAD', 'CHF', 'AED', 'SAR'];
    if (!validCurrencies.includes(newCurrency)) {
      throw new Error('Invalid currency');
    }
    this._currency = newCurrency;
    this.touch();
  }

  createMoney(amount) {
    return new Money(amount, this._currency);
  }

  // Validation
  validate() {
    if (!this._name || this._name.trim().length === 0) {
      throw new Error('Name is required');
    }
    if (!this.isValidEmail(this._email)) {
      throw new Error('Valid email is required');
    }
    return true;
  }

  isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  }

  // Serialization
  toJSON() {
    return {
      id: this._id,
      name: this._name,
      email: this._email,
      currency: this._currency,
      createdAt: this._createdAt,
      updatedAt: this._updatedAt,
    };
  }

  // Factory method
  static create(name, email, passwordHash, currency = 'USD') {
    const user = new User({
      id: null,
      name,
      email: email.toLowerCase(),
      passwordHash,
      currency,
    });
    user.validate();
    return user;
  }

  // Reconstruct from database
  static fromDatabase(dbRow) {
    return new User({
      id: dbRow.id,
      name: dbRow.name,
      email: dbRow.email,
      passwordHash: dbRow.passwordhash,
      currency: dbRow.currency,
      createdAt: dbRow.createdat,
    });
  }
}

module.exports = User;