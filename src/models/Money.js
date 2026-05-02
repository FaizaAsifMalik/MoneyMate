class Money {
  constructor(amount, currency = 'USD') {
    if (amount < 0) throw new Error('Money amount cannot be negative');
    this._amount = parseFloat(amount);
    this._currency = currency.toUpperCase();
    Object.freeze(this);
  }

  get amount() { return this._amount; }
  get currency() { return this._currency; }

  add(money) {
    if (money.currency !== this._currency) throw new Error('Cannot add money with different currencies');
    return new Money(this._amount + money.amount, this._currency);
  }

  subtract(money) {
    if (money.currency !== this._currency) throw new Error('Cannot subtract money with different currencies');
    const result = this._amount - money.amount;
    if (result < 0) throw new Error('Result cannot be negative');
    return new Money(result, this._currency);
  }

  multiply(multiplier) {
    return new Money(this._amount * multiplier, this._currency);
  }

  format() {
    const symbols = {
      USD: '$', EUR: '€', GBP: '£', PKR: 'Rs.', INR: '₹',
      JPY: '¥', CNY: '¥', AUD: 'A$', CAD: 'C$', CHF: 'CHF',
      AED: 'AED', SAR: 'SAR',
    };
    const symbol = symbols[this._currency] || this._currency;
    const formatted = this._amount.toLocaleString('en-US', {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    });
    if (['PKR', 'INR'].includes(this._currency)) return `${formatted} ${symbol}`;
    return `${symbol}${formatted}`;
  }

  toString() { return this.format(); }

  toJSON() {
    return { amount: this._amount, currency: this._currency, formatted: this.format() };
  }

  equals(other) {
    if (!(other instanceof Money)) return false;
    return this._amount === other.amount && this._currency === other.currency;
  }

  static fromDatabase(amount, currency) { return new Money(amount, currency); }
  static zero(currency = 'USD') { return new Money(0, currency); }
}

module.exports = Money;