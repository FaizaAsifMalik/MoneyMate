class ServiceContainer {
  constructor() {
    this._services = {};
  }

  register(name, factory) {
    this._services[name] = { factory, instance: null };
  }

  get(name) {
    const service = this._services[name];
    if (!service) throw new Error(`Service ${name} not registered`);
    if (!service.instance) {
      service.instance = service.factory();
    }
    return service.instance;
  }
}

module.exports = new ServiceContainer();