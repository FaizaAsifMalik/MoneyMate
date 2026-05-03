const RepositoryFactory = require('../factories/RepositoryFactory');
const { AppError } = require('../utils/errorHandler');
const logger = require('../utils/logger');

class BillService {
  constructor() {
    this.billRepository = RepositoryFactory.getBillRepository();
    this.categoryRepository = RepositoryFactory.getCategoryRepository();
  }

  async getBills(userId, filters = {}) {
    const bills = await this.billRepository.findWithCategory(userId, filters);

    return bills.map((bill) => {
      const nextDueDate = bill.next_due_date ? new Date(bill.next_due_date) : null;
      const today = new Date();
      const daysUntilDue = nextDueDate
        ? Math.ceil((nextDueDate - today) / (1000 * 60 * 60 * 24))
        : null;

      return {
        ...bill,
        days_until_due: daysUntilDue,
        is_overdue: daysUntilDue !== null && daysUntilDue < 0 && !bill.is_paid,
      };
    });
  }

  async getBillById(billId, userId) {
    const bill = await this.billRepository.findById(billId);
    if (!bill || bill.user_id !== userId) {
      throw new AppError('Bill not found', 404);
    }
    return bill;
  }

  async createBill(userId, billData) {
    const {
      name,
      amount,
      dueDate,
      frequency = 'monthly',
      categoryId = null,
    } = billData;

    if (!dueDate || dueDate < 1 || dueDate > 31) {
      throw new AppError('Due date must be a day of month between 1 and 31', 400);
    }

    if (!['monthly', 'yearly'].includes(frequency)) {
      throw new AppError('Frequency must be monthly or yearly', 400);
    }

    if (categoryId) {
      const category = await this.categoryRepository.findOne({
        category_id: categoryId,
        user_id: userId,
      });
      if (!category) {
        throw new AppError('Invalid expense category', 400);
      }
    }

    const nextDueDate = this._calculateNextDueDate(dueDate, frequency);

    const bill = await this.billRepository.create({
      user_id: userId,
      name,
      amount,
      due_date: dueDate,
      frequency,
      category_id: categoryId,
      is_paid: false,
      next_due_date: nextDueDate,
    });

    logger.info(`Bill created for user ${userId}: ${name}`);
    return bill;
  }

  async updateBill(billId, userId, updateData) {
    await this.getBillById(billId, userId);

    const updateFields = {};

    if (updateData.name !== undefined) updateFields.name = updateData.name;
    if (updateData.amount !== undefined) updateFields.amount = updateData.amount;

    if (updateData.dueDate !== undefined) {
      if (updateData.dueDate < 1 || updateData.dueDate > 31) {
        throw new AppError('Due date must be between 1 and 31', 400);
      }
      updateFields.due_date = updateData.dueDate;
    }

    if (updateData.frequency !== undefined) {
      if (!['monthly', 'yearly'].includes(updateData.frequency)) {
        throw new AppError('Frequency must be monthly or yearly', 400);
      }
      updateFields.frequency = updateData.frequency;
    }

    if (updateData.categoryId !== undefined) {
      if (updateData.categoryId) {
        const category = await this.categoryRepository.findOne({
          category_id: updateData.categoryId,
          user_id: userId,
        });
        if (!category) {
          throw new AppError('Invalid expense category', 400);
        }
      }
      updateFields.category_id = updateData.categoryId;
    }

    if (updateData.isPaid !== undefined) updateFields.is_paid = updateData.isPaid;

    if (updateData.dueDate || updateData.frequency) {
      const bill = await this.getBillById(billId, userId);
      const dueDay = updateData.dueDate || bill.due_date;
      const freq = updateData.frequency || bill.frequency;
      updateFields.next_due_date = this._calculateNextDueDate(dueDay, freq);
    }

    const bill = await this.billRepository.update(billId, updateFields);
    logger.info(`Bill updated: ${billId}`);
    return bill;
  }

  async markAsPaid(billId, userId) {
    const bill = await this.getBillById(billId, userId);

    if (bill.is_paid) {
      throw new AppError('Bill is already marked as paid', 400);
    }

    const nextDueDate = this._calculateNextDueDate(bill.due_date, bill.frequency);
    await this.billRepository.markPaid(billId, nextDueDate);

    // Use expenseRepo directly to avoid circular dependency with ExpenseService
    if (bill.category_id) {
      const expenseRepo = RepositoryFactory.getExpenseRepository();
      await expenseRepo.create({
        user_id: userId,
        category_id: bill.category_id,
        amount: bill.amount,
        date: new Date().toISOString().split('T')[0],
        description: `Payment for ${bill.name}`,
        bill_id: billId,
      });
    }

    logger.info(`Bill marked as paid: ${billId}`);
    return { message: 'Bill marked as paid successfully' };
  }

  async deleteBill(billId, userId) {
    await this.getBillById(billId, userId);
    await this.billRepository.delete(billId);
    logger.info(`Bill deleted: ${billId}`);
    return { message: 'Bill deleted successfully' };
  }

  async getUpcomingBills(userId, days = 7) {
    return await this.billRepository.getUpcoming(userId, days);
  }

  async getOverdueBills(userId) {
    return await this.billRepository.getOverdue(userId);
  }

  _calculateNextDueDate(dayOfMonth, frequency) {
    const now = new Date();
    let next = new Date(now.getFullYear(), now.getMonth(), dayOfMonth);

    if (next <= now) {
      if (frequency === 'monthly') {
        next = new Date(now.getFullYear(), now.getMonth() + 1, dayOfMonth);
      } else if (frequency === 'yearly') {
        next = new Date(now.getFullYear() + 1, now.getMonth(), dayOfMonth);
      }
    }

    return next.toISOString().split('T')[0];
  }
}

module.exports = new BillService();