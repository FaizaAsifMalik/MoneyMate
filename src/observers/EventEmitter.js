const Subject = require('./Subject');

class AppEventEmitter extends Subject {
  constructor() {
    super();
    this._handlers = {};
  }

  on(event, handler) {
    if (!this._handlers[event]) this._handlers[event] = [];
    this._handlers[event].push(handler);
  }

  async emit(event, data) {
    const handlers = this._handlers[event] || [];
    for (const handler of handlers) {
      await handler(data);
    }
  }
}

module.exports = new AppEventEmitter();