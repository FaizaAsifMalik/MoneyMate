const currencyAdapter = require('../adapters/CurrencyApiAdapter');

class CurrencyService {
  async convert(amount, fromCurrency, toCurrency) {
    return currencyAdapter.convert(amount, fromCurrency, toCurrency);
  }

  async getRate(fromCurrency, toCurrency) {
    return currencyAdapter.getExchangeRate(fromCurrency, toCurrency);
  }

  getSupportedCurrencies() {
    return currencyAdapter.getSupportedCurrencies();
  }
}

module.exports = new CurrencyService();