/**
 * Base AI Strategy Interface
 * Implements Strategy Pattern
 */
class AIStrategy {
  async analyze(data) {
    throw new Error('Method analyze() must be implemented');
  }

  async predict(data) {
    throw new Error('Method predict() must be implemented');
  }
}

module.exports = AIStrategy;