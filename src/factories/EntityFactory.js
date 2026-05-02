const User = require('../models/User');
const Category = require('../models/Category');
const Income = require('../models/Income');
const Expense = require('../models/Expense');
const Budget = require('../models/Budget');
const Goal = require('../models/Goal');
const Bill = require('../models/Bill');
const Notification = require('../models/Notification');
const Money = require('../models/Money');

class EntityFactory {
  static createUser(data) { return User.create(data.name, data.email, data.passwordHash, data.currency); }
  static createCategory(data) { return Category.create(data.userId, data.name, data.type, data.icon, data.colour); }
  static createIncome(data) {
    const money = new Money(data.amount, data.currency);
    return Income.create(data.userId, data.categoryId, money, data.date, data.description);
  }
  static createExpense(data) {
    const money = new Money(data.amount, data.currency);
    return Expense.create(data.userId, data.categoryId, money, data.date, data.description, data.billId);
  }
  static createBudget(data) {
    const money = new Money(data.limitAmount, data.currency);
    return Budget.create(data.userId, data.categoryId, money, data.period, data.startDate, data.endDate);
  }
  static createGoal(data) {
    const target = new Money(data.targetAmount, data.currency);
    const saved = data.savedAmount ? new Money(data.savedAmount, data.currency) : null;
    return Goal.create(data.userId, data.title, target, data.deadline, saved);
  }
  static createBill(data) {
    const money = new Money(data.amount, data.currency);
    return Bill.create(data.userId, data.name, money, data.dueDate, data.frequency, data.categoryId);
  }
  static createNotification(data) {
    return Notification.create(data.userId, data.type, data.title, data.message, data.metadata);
  }
}

module.exports = EntityFactory;