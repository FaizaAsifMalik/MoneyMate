const ServiceContainer = require('../services/ServiceContainer');

class ServiceFactory {
  static get(name) {
    return ServiceContainer.get(name);
  }
}

module.exports = ServiceFactory;