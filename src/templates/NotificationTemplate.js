class NotificationTemplate {
  static budgetAlert(categoryName, percentUsed, amountSpent, limit, currency) {
    const exceeded = percentUsed >= 100;
    return {
      type: 'budget_alert',
      title: exceeded ? `Budget Exceeded: ${categoryName}` : `Budget Warning: ${categoryName}`,
      message: exceeded
        ? `You've exceeded your ${categoryName} budget (${percentUsed.toFixed(0)}% used)`
        : `You've used ${percentUsed.toFixed(0)}% of your ${categoryName} budget`,
    };
  }

  static billReminder(billName, daysUntilDue, amount, currency) {
    return {
      type: 'bill_reminder',
      title: `Bill Due: ${billName}`,
      message: daysUntilDue <= 0
        ? `${billName} is due today! Amount: ${amount} ${currency}`
        : `${billName} is due in ${daysUntilDue} day(s). Amount: ${amount} ${currency}`,
    };
  }

  static goalCompleted(goalTitle, targetAmount, currency) {
    return {
      type: 'goal_completed',
      title: `Goal Achieved: ${goalTitle}`,
      message: `Congratulations! You've reached your goal of ${targetAmount} ${currency} for "${goalTitle}"! 🎉`,
    };
  }
}

module.exports = NotificationTemplate;