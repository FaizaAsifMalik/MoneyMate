const Entity = require('../core/Entity');

/**
 * Category Domain Model
 */
class Category extends Entity {
  constructor(data) {
    super(data.id);
    this._userId = data.userId;
    this._name = data.name;
    this._type = data.type; // 'income' or 'expense'
    this._icon = data.icon || '📁';
    this._colour = data.colour || '#607D8B';
  }

  // Getters
  get userId() {
    return this._userId;
  }

  get name() {
    return this._name;
  }

  get type() {
    return this._type;
  }

  get icon() {
    return this._icon;
  }

  get colour() {
    return this._colour;
  }

  // Business Methods
  updateName(newName) {
    if (!newName || newName.trim().length === 0) {
      throw new Error('Category name cannot be empty');
    }
    this._name = newName.trim();
    this.touch();
  }

  updateIcon(newIcon) {
    this._icon = newIcon || '📁';
    this.touch();
  }

  updateColour(newColour) {
    if (newColour && !this.isValidHexColor(newColour)) {
      throw new Error('Invalid color format');
    }
    this._colour = newColour || '#607D8B';
    this.touch();
  }

  isIncome() {
    return this._type === 'income';
  }

  isExpense() {
    return this._type === 'expense';
  }

  // Validation
  validate() {
    if (!this._userId) {
      throw new Error('User ID is required');
    }
    if (!this._name || this._name.trim().length === 0) {
      throw new Error('Category name is required');
    }
    if (!['income', 'expense'].includes(this._type)) {
      throw new Error('Type must be either income or expense');
    }
    return true;
  }

  isValidHexColor(color) {
    return /^#[0-9A-F]{6}$/i.test(color);
  }

  // Serialization
  toJSON() {
    return {
      id: this._id,
      userId: this._userId,
      name: this._name,
      type: this._type,
      icon: this._icon,
      colour: this._colour,
      createdAt: this._createdAt,
      updatedAt: this._updatedAt,
    };
  }

  // Factory
  static create(userId, name, type, icon = '📁', colour = '#607D8B') {
    const category = new Category({
      id: null,
      userId,
      name,
      type,
      icon,
      colour,
    });
    category.validate();
    return category;
  }

  // Reconstruct from database
  static fromDatabase(dbRow) {
    return new Category({
      id: dbRow.category_id,
      userId: dbRow.user_id,
      name: dbRow.name,
      type: dbRow.type,
      icon: dbRow.icon,
      colour: dbRow.colour,
    });
  }
}

module.exports = Category;