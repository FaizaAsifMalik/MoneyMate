class Subject {
  constructor() {
    this._observers = [];
  }

  subscribe(observer) { this._observers.push(observer); }
  unsubscribe(observer) { this._observers = this._observers.filter(o => o !== observer); }

  async notify(event, data) {
    for (const observer of this._observers) {
      if (typeof observer.update === 'function') {
        await observer.update(event, data);
      }
    }
  }
}

module.exports = Subject;