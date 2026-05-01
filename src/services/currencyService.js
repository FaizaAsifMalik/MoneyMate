const axios = require('axios');
const { config } = require('../config/env');
const { AppError } = require('../utils/errorHandler');
const logger = require('../utils/logger');

class CurrencyService {
  constructor() {
    this.baseUrl = config.currencyApi.url;
    this.apiKey = config.currencyApi.key;
    this.cache = new Map();
    this.CACHE_DURATION = 60 * 60 * 1000; // 1 hour
  }

  /**
   * Get exchange rate between two currencies
   */
  async getExchangeRate(from, to) {
    const cacheKey = `${from}_${to}`;
    const cached = this.cache.get(cacheKey);

    // Return cached rate if still valid
    if (cached && Date.now() - cached.timestamp < this.CACHE_DURATION) {
      return cached.rate;
    }

    try {
      const url = `${this.baseUrl}/${this.apiKey}/pair/${from}/${to}`;
      const response = await axios.get(url);

      if (response.data.result === 'success') {
        const rate = response.data.conversion_rate;
        
        // Cache the rate
        this.cache.set(cacheKey, {
          rate,
          timestamp: Date.now(),
        });

        logger.info(`Exchange rate fetched: ${from} to ${to} = ${rate}`);
        return rate;
      } else {
        throw new AppError('Failed to fetch exchange rate', 500);
      }
    } catch (error) {
      logger.error('Currency conversion error:', error.message);
      throw new AppError('Currency conversion service unavailable', 503);
    }
  }

  /**
   * Convert amount from one currency to another
   */
  async convertCurrency(amount, from, to) {
    if (from === to) {
      return amount;
    }

    const rate = await this.getExchangeRate(from, to);
    const convertedAmount = amount * rate;

    return {
      original_amount: parseFloat(amount),
      original_currency: from,
      converted_amount: parseFloat(convertedAmount.toFixed(2)),
      converted_currency: to,
      exchange_rate: rate,
      timestamp: new Date().toISOString(),
    };
  }

  /**
   * Get supported currencies
   */
  getSupportedCurrencies() {
    return [
      { code: 'USD', name: 'US Dollar', symbol: '$' },
      { code: 'EUR', name: 'Euro', symbol: '€' },
      { code: 'GBP', name: 'British Pound', symbol: '£' },
      { code: 'PKR', name: 'Pakistani Rupee', symbol: '₨' },
      { code: 'INR', name: 'Indian Rupee', symbol: '₹' },
      { code: 'JPY', name: 'Japanese Yen', symbol: '¥' },
      { code: 'CNY', name: 'Chinese Yuan', symbol: '¥' },
      { code: 'AUD', name: 'Australian Dollar', symbol: 'A$' },
      { code: 'CAD', name: 'Canadian Dollar', symbol: 'C$' },
      { code: 'CHF', name: 'Swiss Franc', symbol: 'CHF' },
      { code: 'AED', name: 'UAE Dirham', symbol: 'AED' },
      { code: 'SAR', name: 'Saudi Riyal', symbol: 'SAR' },
    ];
  }

  /**
   * Clear cache
   */
  clearCache() {
    this.cache.clear();
    logger.info('Currency cache cleared');
  }
}

module.exports = new CurrencyService();