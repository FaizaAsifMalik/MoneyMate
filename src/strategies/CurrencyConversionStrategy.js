const IAnalysisStrategy = require('./interfaces/IAnalysisStrategy');
const currencyAdapter = require('../adapters/CurrencyApiAdapter');

class CurrencyConversionStrategy extends IAnalysisStrategy {
  async analyze(data) {
    const { amount, fromCurrency, toCurrency } = data;
    return await currencyAdapter.convert(amount, fromCurrency, toCurrency);
  }
}

module.exports = CurrencyConversionStrategy;