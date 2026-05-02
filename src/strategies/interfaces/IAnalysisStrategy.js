class IAnalysisStrategy {
  async analyze(data) { throw new Error('analyze() must be implemented'); }
}
module.exports = IAnalysisStrategy;