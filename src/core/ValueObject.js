class ValueObject {
  equals(other) {
    if (!other || other.constructor !== this.constructor) return false;
    return JSON.stringify(this) === JSON.stringify(other);
  }
}

module.exports = ValueObject;