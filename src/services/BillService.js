const BillRepository = require('../repositories/BillRepository');
const CategoryRepository = require('../repositories/CategoryRepository');
const { AppError } = require('../utils/errorHandler');
const { formatDate } = require('../utils/helpers');
const logger = require('../utils/logger');

/**
 * Bill Service - Updated with Repository Pattern
 */
class BillService {
  constructor(
    billRepository = BillRepository,
    categoryRepository = CategoryRepository
  ) {
    this.billRepository = billRepository;
    this.categoryRepository = categoryRepository;
  }

  /**
   * Get all bills
   */
  async getBills(userId, filters = {}) {
    const bills = await this.billRepository.findWithCategory(userId, filters);

    // Calculate days until due
    return bills.map((bill) => {
      const dueDate = new Date(bill.due_date);
      const today = new Date();
      const daysUntilDue = Math.ceil((dueDate - today) / (1000 * 60 * 60 * 24));

      return {
        ...bill,
        days_until_due: daysUntilDue,
        is_overdue: daysUntilDue < 0 && !bill.is_paid,
      };
    });
  }

  /**
   * Get bill by ID
   */
  async getBillById(billId, userId) {
    const bill = await this.billRepository.findById(billId, 'bill_id');

    if (!bill || bill.user_id !== userId) {
      throw new AppError('Bill not found', 404);
    }

    return bill;
  }

  /**
   * Create bill
   */
  async createBill(userId, billData) {
    const { name, amount, dueDate, recurrence = 'none', categoryId = null } = billData;

    // Validate category if provided
    if (categoryId) {
      const category = await this.categoryRepository.findOne({
        category_id: categoryId,
        user_id: userId,
        type: 'expense',
      });

      if (!category) {
        throw new AppError('Invalid expense category', 400);
      }
    }

    const bill = await this.billRepository.create({
      user_id: userId,
      name,
      amount,
      due_date: formatDate(dueDate),
      recurrence,
      is_paid: false,
      category_id: categoryId,
    });

    logger.info(`Bill created for user ${userId}: ${name}`);

    return bill;
  }

  /**
   * Update bill
   */
  async updateBill(billId, userId, updateData) {
    // Verify ownership
    await this.getBillById(billId, userId);

    // Validate category if updating
    if (updateData.categoryId) {
      const category = await this.categoryRepository.findOne({
        category_id: updateData.categoryId,
        user_id: userId,
        type: 'expense',
      });

      if (!category) {
        throw new AppError('Invalid expense category', 400);
      }
      updateData.category_id = updateData.categoryId;
      delete updateData.categoryId;
    }

    // Format date if provided
    if (updateData.dueDate) {
      updateData.due_date = formatDate(updateData.dueDate);
      delete updateData.dueDate;
    }

    // Map camelCase to snake_case
    if (updateData.isPaid !== undefined) {
      updateData.is_paid = updateData.isPaid;
      delete updateData.isPaid;
    }

    const bill = await this.billRepository.update(billId, updateData, 'bill_id');

    logger.info(`Bill updated: ${billId}`);

    return bill;
  }

  /**
   * Mark bill as paid
   */
  async markAsPaid(billId, userId, createExpense = true) {
    const bill = await this.getBillById(billId, userId);

    if (bill.is_paid) {
      throw new AppError('Bill is already marked as paid', 400);
    }

    // Mark as paid
    await this.billRepository.markPaid(billId);

    // Create expense if requested and category exists
    if (createExpense && bill.category_id) {
      const expenseService = require('./ExpenseService');
      await expenseService.createExpense(userId, {
        categoryId: bill.category_id,
        amount: bill.amount,
        date: new Date(),
        description: `Payment for ${bill.name}`,
        billId: billId,
      });
    }

    // Handle recurring bills
    if (bill.recurrence !== 'none') {
      await this.createRecurringBill(userId, bill);
    }

    logger.info(`Bill marked as paid: ${billId}`);

    return { message: 'Bill marked as paid successfully' };
  }

  /**
   * Create next recurring bill
   */
  async createRecurringBill(userId, originalBill) {
    const dueDate = new Date(originalBill.due_date);
    let nextDueDate = new Date(dueDate);

    if (originalBill.recurrence === 'weekly') {
      nextDueDate.setDate(dueDate.getDate() + 7);
    } else if (originalBill.recurrence === 'monthly') {
      nextDueDate.setMonth(dueDate.getMonth() + 1);
    }

    await this.billRepository.create({
      user_id: userId,
      name: originalBill.name,
      amount: originalBill.amount,
      due_date: formatDate(nextDueDate),
      recurrence: originalBill.recurrence,
      is_paid: false,
      category_id: originalBill.category_id,
    });

    logger.info(`Recurring bill created: ${originalBill.name}`);
  }

  /**
   * Delete bill
   */
  async deleteBill(billId, userId) {
    // Verify ownership
    await this.getBillById(billId, userId);

    await this.billRepository.delete(billId, 'bill_id');

    logger.info(`Bill deleted: ${billId}`);

    return { message: 'Bill deleted successfully' };
  }

  /**
   * Get upcoming bills
   */
  async getUpcomingBills(userId, days = 7) {
    return await this.billRepository.getUpcoming(userId, days);
  }

  /**
   * Get overdue bills
   */
  async getOverdueBills(userId) {
    return await this.billRepository.getOverdue(userId);
  }
}

module.exports = new BillService();