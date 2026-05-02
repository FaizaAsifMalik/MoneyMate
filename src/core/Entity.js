class Entity {
  constructor(id) {
    if (new.target === Entity) {
      throw new TypeError('Cannot construct Entity instances directly');
    }
    this._id = id;
    this._createdAt = new Date();
    this._updatedAt = new Date();
  }

  get id() { return this._id; }
  get createdAt() { return this._createdAt; }
  get updatedAt() { return this._updatedAt; }

  touch() { this._updatedAt = new Date(); }

  toJSON() { throw new Error('toJSON() must be implemented by subclass'); }
  validate() { throw new Error('validate() must be implemented by subclass'); }

  equals(other) {
    if (!other || !(other instanceof Entity)) return false;
    return this._id === other._id;
  }
}

module.exports = Entity;