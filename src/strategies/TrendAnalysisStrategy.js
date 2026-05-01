const AIStrategy = require('./AIStrategy');

/**
 * Trend Analysis Strategy
 * Concrete implementation of AI Strategy
 */
class TrendAnalysisStrategy extends AIStrategy {
  async analyze(expenses) {
    const categoriesMap = {};

    // Group by category and month
    expenses.forEach(row => {
      const categoryId = row.category_id;
      if (!categoriesMap[categoryId]) {
        categoriesMap[categoryId] = {
          category_id: categoryId,
          category_name: row.name,
          monthly_data: [],
        };
      }
      categoriesMap[categoryId].monthly_data.push({
        month: row.month,
        total: parseFloat(row.total),
      });
    });

    // Calculate trends
    const trends = [];
    Object.values(categoriesMap).forEach(category => {
      if (category.monthly_data.length >= 2) {
        const sorted = category.monthly_data.sort(
          (a, b) => new Date(a.month) - new Date(b.month)
        );
        
        const oldest = sorted[0].total;
        const newest = sorted[sorted.length - 1].total;
        const percentageChange = ((newest - oldest) / oldest * 100).toFixed(2);
        const direction = newest > oldest ? 'up' : 'down';

        trends.push({
          category_id: category.category_id,
          category_name: category.category_name,
          direction,
          percentage_change: Math.abs(percentageChange),
          trend: direction === 'up' ? 'increasing' : 'decreasing',
        });
      }
    });

    return trends;
  }

  async predict(data) {
    // Simple moving average prediction
    const amounts = data.map(row => parseFloat(row.total));
    const average = amounts.reduce((sum, val) => sum + val, 0) / amounts.length;
    
    // Calculate trend
    const firstHalf = amounts.slice(0, Math.floor(amounts.length / 2));
    const secondHalf = amounts.slice(Math.floor(amounts.length / 2));
    const firstAvg = firstHalf.reduce((sum, val) => sum + val, 0) / firstHalf.length;
    const secondAvg = secondHalf.reduce((sum, val) => sum + val, 0) / secondHalf.length;
    const trendFactor = secondAvg / firstAvg;

    return {
      predicted_amount: (average * trendFactor).toFixed(2),
      average: average.toFixed(2),
      trend_factor: trendFactor.toFixed(2),
    };
  }
}

module.exports = TrendAnalysisStrategy;