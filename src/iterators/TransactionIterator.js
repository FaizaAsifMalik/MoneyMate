/**
 * Transaction Iterator
 * Iterates through income and expense transactions
 * Implements Iterator Pattern
 */
class TransactionIterator {
  constructor(incomes, expenses) {
    this.transactions = this._mergeAndSort(incomes, expenses);
    this.currentIndex = 0;
  }

  /**
   * Merge incomes and expenses, sort by date
   */
  _mergeAndSort(incomes, expenses) {
    const allTransactions = [
      ...incomes.map(income => ({ ...income, type: 'income' })),
      ...expenses.map(expense => ({ ...expense, type: 'expense' })),
    ];

    return allTransactions.sort((a, b) => {
      const dateA = new Date(a.date);
      const dateB = new Date(b.date);
      return dateB - dateA; // Descending order (newest first)
    });
  }

  /**
   * Check if there are more items
   */
  hasNext() {
    return this.currentIndex < this.transactions.length;
  }

  /**
   * Get next transaction
   */
  next() {
    if (!this.hasNext()) {
      throw new Error('No more transactions');
    }
    return this.transactions[this.currentIndex++];
  }

  /**
   * Get current transaction without advancing
   */
  current() {
    if (this.currentIndex === 0) {
      throw new Error('Iterator not started');
    }
    return this.transactions[this.currentIndex - 1];
  }

  /**
   * Reset iterator to beginning
   */
  reset() {
    this.currentIndex = 0;
  }

  /**
   * Get all remaining transactions
   */
  getRemaining() {
    return this.transactions.slice(this.currentIndex);
  }

  /**
   * Get total count
   */
  count() {
    return this.transactions.length;
  }

  /**
   * Filter transactions
   */
  filter(predicate) {
    return this.transactions.filter(predicate);
  }

  /**
   * Get transactions for a specific month
   */
  getForMonth(year, month) {
    return this.transactions.filter(transaction => {
      const date = new Date(transaction.date);
      return date.getFullYear() === year && date.getMonth() === month - 1;
    });
  }

  /**
   * Get income transactions only
   */
  getIncomes() {
    return this.transactions.filter(t => t.type === 'income');
  }

  /**
   * Get expense transactions only
   */
  getExpenses() {
    return this.transactions.filter(t => t.type === 'expense');
  }

  /**
   * Calculate net for a period
   */
  calculateNet() {
    const totalIncome = this.getIncomes().reduce((sum, t) => sum + parseFloat(t.amount), 0);
    const totalExpense = this.getExpenses().reduce((sum, t) => sum + parseFloat(t.amount), 0);
    return totalIncome - totalExpense;
  }
}

module.exports = TransactionIterator;