const axios = require('axios');
const { config } = require('../config/env');
const logger = require('../utils/logger');

/**
 * Currency API Adapter
 * Adapts external currency API to internal interface
 * Implements Adapter Pattern
 */
class CurrencyApiAdapter {
  constructor() {
    this.baseUrl = config.currencyApi.url;
    this.apiKey = config.currencyApi.key;
    this.cache = new Map();
    this.cacheDuration = 60 * 60 * 1000; // 1 hour
  }

  /**
   * Get exchange rate between two currencies
   * Adapts external API response to internal format
   */
  async getExchangeRate(fromCurrency, toCurrency) {
    // Check cache first
    const cacheKey = `${fromCurrency}_${toCurrency}`;
    const cached = this._getFromCache(cacheKey);
    
    if (cached) {
      return cached;
    }

    try {
      const rate = await this._fetchFromExternalApi(fromCurrency, toCurrency);
      this._saveToCache(cacheKey, rate);
      return rate;
    } catch (error) {
      logger.error('Currency API error:', error);
      throw new Error('Currency conversion service unavailable');
    }
  }

  /**
   * Convert amount from one currency to another
   */
  async convert(amount, fromCurrency, toCurrency) {
    if (fromCurrency === toCurrency) {
      return {
        originalAmount: amount,
        originalCurrency: fromCurrency,
        convertedAmount: amount,
        convertedCurrency: toCurrency,
        exchangeRate: 1,
        timestamp: new Date().toISOString(),
      };
    }

    const rate = await this.getExchangeRate(fromCurrency, toCurrency);
    const convertedAmount = amount * rate;

    return {
      originalAmount: parseFloat(amount),
      originalCurrency: fromCurrency,
      convertedAmount: parseFloat(convertedAmount.toFixed(2)),
      convertedCurrency: toCurrency,
      exchangeRate: rate,
      timestamp: new Date().toISOString(),
    };
  }

  /**
   * Get all supported currencies
   */
  getSupportedCurrencies() {
    return [
      { code: 'USD', name: 'US Dollar', symbol: '$', flag: '🇺🇸' },
      { code: 'EUR', name: 'Euro', symbol: '€', flag: '🇪🇺' },
      { code: 'GBP', name: 'British Pound', symbol: '£', flag: '🇬🇧' },
      { code: 'PKR', name: 'Pakistani Rupee', symbol: 'Rs.', flag: '🇵🇰' },
      { code: 'INR', name: 'Indian Rupee', symbol: '₹', flag: '🇮🇳' },
      { code: 'JPY', name: 'Japanese Yen', symbol: '¥', flag: '🇯🇵' },
      { code: 'CNY', name: 'Chinese Yuan', symbol: '¥', flag: '🇨🇳' },
      { code: 'AUD', name: 'Australian Dollar', symbol: 'A$', flag: '🇦🇺' },
      { code: 'CAD', name: 'Canadian Dollar', symbol: 'C$', flag: '🇨🇦' },
      { code: 'CHF', name: 'Swiss Franc', symbol: 'CHF', flag: '🇨🇭' },
      { code: 'AED', name: 'UAE Dirham', symbol: 'AED', flag: '🇦🇪' },
      { code: 'SAR', name: 'Saudi Riyal', symbol: 'SAR', flag: '🇸🇦' },
    ];
  }

  /**
   * Private: Fetch from external API
   */
  async _fetchFromExternalApi(fromCurrency, toCurrency) {
    const url = `${this.baseUrl}/${this.apiKey}/pair/${fromCurrency}/${toCurrency}`;
    const response = await axios.get(url, { timeout: 5000 });

    if (response.data.result !== 'success') {
      throw new Error('Failed to fetch exchange rate');
    }

    return response.data.conversion_rate;
  }

  /**
   * Private: Get from cache
   */
  _getFromCache(key) {
    const cached = this.cache.get(key);
    
    if (!cached) {
      return null;
    }

    const isExpired = Date.now() - cached.timestamp > this.cacheDuration;
    
    if (isExpired) {
      this.cache.delete(key);
      return null;
    }

    return cached.rate;
  }

  /**
   * Private: Save to cache
   */
  _saveToCache(key, rate) {
    this.cache.set(key, {
      rate,
      timestamp: Date.now(),
    });
  }

  /**
   * Clear cache
   */
  clearCache() {
    this.cache.clear();
    logger.info('Currency cache cleared');
  }
}

// Singleton instance
module.exports = new CurrencyApiAdapter();