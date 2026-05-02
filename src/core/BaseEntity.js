const Entity = require('./Entity');

class BaseEntity extends Entity {
  constructor(data) {
    super(data.id);
    if (data.createdAt) this._createdAt = new Date(data.createdAt);
    if (data.updatedAt) this._updatedAt = new Date(data.updatedAt);
  }

  toJSON() {
    return {
      id: this._id,
      createdAt: this._createdAt,
      updatedAt: this._updatedAt,
    };
  }

  validate() {
    return true;
  }
}

module.exports = BaseEntity;