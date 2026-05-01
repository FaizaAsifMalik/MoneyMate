const TrendAnalysisStrategy = require('../strategies/TrendAnalysisStrategy');
const BudgetPredictionStrategy = require('../strategies/BudgetPredictionStrategy');

/**
 * AI Strategy Factory
 * Creates appropriate AI strategy based on type
 */
class AIStrategyFactory {
  static create(strategyType) {
    switch (strategyType) {
      case 'trend':
        return new TrendAnalysisStrategy();
      case 'prediction':
        return new BudgetPredictionStrategy();
      default:
        throw new Error(`Unknown AI strategy: ${strategyType}`);
    }
  }
}

module.exports = AIStrategyFactory;