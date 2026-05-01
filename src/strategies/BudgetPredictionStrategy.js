const AIStrategy = require('./AIStrategy');

/**
 * Budget Prediction Strategy
 * Uses linear regression for prediction
 */
class BudgetPredictionStrategy extends AIStrategy {
  async predict(historicalData) {
    if (historicalData.length < 3) {
      throw new Error('Insufficient data for prediction');
    }

    const amounts = historicalData.map(row => parseFloat(row.total));
    
    // Simple linear regression
    const n = amounts.length;
    const sumX = (n * (n + 1)) / 2; // Sum of 1, 2, 3, ..., n
    const sumY = amounts.reduce((sum, val) => sum + val, 0);
    const sumXY = amounts.reduce((sum, val, index) => sum + val * (index + 1), 0);
    const sumX2 = (n * (n + 1) * (2 * n + 1)) / 6; // Sum of 1², 2², 3², ..., n²

    const slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    const intercept = (sumY - slope * sumX) / n;

    // Predict next value
    const predictedAmount = slope * (n + 1) + intercept;

    // Calculate confidence based on R²
    const average = sumY / n;
    const ssTotal = amounts.reduce((sum, val) => sum + Math.pow(val - average, 2), 0);
    const ssRes = amounts.reduce(
      (sum, val, index) => sum + Math.pow(val - (slope * (index + 1) + intercept), 2),
      0
    );
    const rSquared = 1 - (ssRes / ssTotal);
    const confidence = (rSquared * 100).toFixed(2);

    return {
      predicted_amount: Math.max(0, predictedAmount).toFixed(2),
      confidence: parseFloat(confidence),
      trend: slope > 0 ? 'increasing' : 'decreasing',
      slope: slope.toFixed(2),
    };
  }
}

module.exports = BudgetPredictionStrategy;