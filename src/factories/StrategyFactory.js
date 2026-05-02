const TrendAnalysisStrategy = require('../strategies/TrendAnalysisStrategy');
const BudgetPredictionStrategy = require('../strategies/BudgetPredictionStrategy');
const SuggestionStrategy = require('../strategies/SuggestionStrategy');
const CurrencyConversionStrategy = require('../strategies/CurrencyConversionStrategy');

class StrategyFactory {
  static create(type) {
    switch (type) {
      case 'trend': return new TrendAnalysisStrategy();
      case 'budget_prediction': return new BudgetPredictionStrategy();
      case 'suggestion': return new SuggestionStrategy();
      case 'currency': return new CurrencyConversionStrategy();
      default: throw new Error(`Unknown strategy: ${type}`);
    }
  }
}

module.exports = StrategyFactory;