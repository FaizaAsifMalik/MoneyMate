const aiService = require('../services/AIService');
const currencyService = require('../services/CurrencyService');
const { success, error } = require('../utils/responseFormatter');

class AIController {
  async getInsights(req, res) {
    try {
      const user = req.user;
      const insights = await aiService.getInsights(user.id);
      return success(res, insights);
    } catch (err) {
      return error(res, err.message, err.statusCode || 500);
    }
  }

  async chat(req, res) {
    try {
      const { message } = req.body;
      if (!message) return error(res, 'Message is required', 400);
      const result = await aiService.chat(req.user.id, message);
      return success(res, result);
    } catch (err) {
      return error(res, err.message, err.statusCode || 500);
    }
  }

  async convertCurrency(req, res) {
    try {
      const { amount, fromCurrency, toCurrency } = req.body;
      const result = await aiService.convertCurrency(amount, fromCurrency, toCurrency);
      return success(res, result);
    } catch (err) {
      return error(res, err.message, err.statusCode || 500);
    }
  }

  async getSupportedCurrencies(req, res) {
    try {
      const currencies = currencyService.getSupportedCurrencies();
      return success(res, currencies);
    } catch (err) {
      return error(res, err.message, err.statusCode || 500);
    }
  }
}

module.exports = new AIController();