class CategoryIterator {
  constructor(categories) {
    this.categories = categories;
    this.currentIndex = 0;
  }

  hasNext() { return this.currentIndex < this.categories.length; }

  next() {
    if (!this.hasNext()) throw new Error('No more categories');
    return this.categories[this.currentIndex++];
  }

  reset() { this.currentIndex = 0; }

  filterByType(type) { return this.categories.filter(c => c.type === type); }

  getIncomeCategories() { return this.filterByType('income'); }
  getExpenseCategories() { return this.filterByType('expense'); }

  count() { return this.categories.length; }
}

module.exports = CategoryIterator;