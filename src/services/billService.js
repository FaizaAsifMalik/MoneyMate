const { query } = require('../config/database');
const { AppError } = require('../utils/errorHandler');
const { formatDate } = require('../utils/helpers');
const logger = require('../utils/logger');

class BillService {
  /**
   * Get all bills for user
   */
  async getBills(userId, filters = {}) {
    const { isPaid, upcoming } = filters;
    
    let queryText = `
      SELECT b.*, c.name as category_name, c.icon, c.colour
      FROM bills b
      LEFT JOIN category c ON b.category_id = c.category_id
      WHERE b.user_id = $1
    `;
    const values = [userId];
    let paramCount = 2;

    if (isPaid !== undefined) {
      queryText += ` AND b.is_paid = $${paramCount++}`;
      values.push(isPaid);
    }

    if (upcoming === true) {
      const today = formatDate(new Date());
      const nextMonth = formatDate(new Date(Date.now() + 30 * 24 * 60 * 60 * 1000));
      queryText += ` AND b.due_date >= $${paramCount++} AND b.due_date <= $${paramCount++}`;
      values.push(today, nextMonth);
    }

    queryText += ' ORDER BY b.due_date ASC';

    const result = await query(queryText, values);

    // Calculate days until due
    const billsWithDays = result.rows.map((bill) => {
      const dueDate = new Date(bill.due_date);
      const today = new Date();
      const daysUntilDue = Math.ceil((dueDate - today) / (1000 * 60 * 60 * 24));
      
      return {
        ...bill,
        days_until_due: daysUntilDue,
        is_overdue: daysUntilDue < 0 && !bill.is_paid,
      };
    });

    return billsWithDays;
  }

  /**
   * Get bill by ID
   */
  async getBillById(billId, userId) {
    const result = await query(
      `SELECT b.*, c.name as category_name, c.icon, c.colour
       FROM bills b
       LEFT JOIN category c ON b.category_id = c.category_id
       WHERE b.bill_id = $1 AND b.user_id = $2`,
      [billId, userId]
    );

    if (result.rows.length === 0) {
      throw new AppError('Bill not found', 404);
    }

    return result.rows[0];
  }

  /**
   * Create bill
   */
  async createBill(userId, billData) {
    const { name, amount, dueDate, recurrence = 'none', categoryId = null } = billData;

    // Validate category if provided
    if (categoryId) {
      const category = await query(
        `SELECT category_id FROM category 
         WHERE category_id = $1 AND user_id = $2 AND type = 'expense'`,
        [categoryId, userId]
      );

      if (category.rows.length === 0) {
        throw new AppError('Invalid expense category', 400);
      }
    }

    const result = await query(
      `INSERT INTO bills (user_id, name, amount, due_date, recurrence, is_paid, category_id)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [userId, name, amount, formatDate(dueDate), recurrence, false, categoryId]
    );

    logger.info(`Bill created for user ${userId}: ${name}`);

    return result.rows[0];
  }

  /**
   * Update bill
   */
  async updateBill(billId, userId, updateData) {
    const { name, amount, dueDate, recurrence, isPaid, categoryId } = updateData;
    const updates = [];
    const values = [];
    let paramCount = 1;

    if (name) {
      updates.push(`name = $${paramCount++}`);
      values.push(name);
    }

    if (amount !== undefined) {
      updates.push(`amount = $${paramCount++}`);
      values.push(amount);
    }

    if (dueDate) {
      updates.push(`due_date = $${paramCount++}`);
      values.push(formatDate(dueDate));
    }

    if (recurrence) {
      updates.push(`recurrence = $${paramCount++}`);
      values.push(recurrence);
    }

    if (isPaid !== undefined) {
      updates.push(`is_paid = $${paramCount++}`);
      values.push(isPaid);
    }

    if (categoryId !== undefined) {
      if (categoryId) {
        const category = await query(
          `SELECT category_id FROM category 
           WHERE category_id = $1 AND user_id = $2 AND type = 'expense'`,
          [categoryId, userId]
        );

        if (category.rows.length === 0) {
          throw new AppError('Invalid expense category', 400);
        }
      }
      updates.push(`category_id = $${paramCount++}`);
      values.push(categoryId);
    }

    if (updates.length === 0) {
      throw new AppError('No fields to update', 400);
    }

    values.push(billId, userId);

    const result = await query(
      `UPDATE bills 
       SET ${updates.join(', ')}
       WHERE bill_id = $${paramCount++} AND user_id = $${paramCount}
       RETURNING *`,
      values
    );

    if (result.rows.length === 0) {
      throw new AppError('Bill not found', 404);
    }

    logger.info(`Bill updated: ${billId}`);

    return result.rows[0];
  }

  /**
   * Mark bill as paid
   */
  async markAsPaid(billId, userId, createExpense = true) {
    const bill = await this.getBillById(billId, userId);

    if (bill.is_paid) {
      throw new AppError('Bill is already marked as paid', 400);
    }

    // Update bill status
    await query(
      'UPDATE bills SET is_paid = true WHERE bill_id = $1',
      [billId]
    );

    // Create expense record if requested and category exists
    if (createExpense && bill.category_id) {
      const expenseService = require('./expenseService');
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

    return {
      message: 'Bill marked as paid successfully',
    };
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

    await query(
      `INSERT INTO bills (user_id, name, amount, due_date, recurrence, is_paid, category_id)
       VALUES ($1, $2, $3, $4, $5, false, $6)`,
      [
        userId,
        originalBill.name,
        originalBill.amount,
        formatDate(nextDueDate),
        originalBill.recurrence,
        originalBill.category_id,
      ]
    );

    logger.info(`Recurring bill created: ${originalBill.name}`);
  }

  /**
   * Delete bill
   */
  async deleteBill(billId, userId) {
    const result = await query(
      'DELETE FROM bills WHERE bill_id = $1 AND user_id = $2 RETURNING *',
      [billId, userId]
    );

    if (result.rows.length === 0) {
      throw new AppError('Bill not found', 404);
    }

    logger.info(`Bill deleted: ${billId}`);

    return {
      message: 'Bill deleted successfully',
    };
  }

  /**
   * Get upcoming bills (next 7 days)
   */
  async getUpcomingBills(userId) {
    const today = formatDate(new Date());
    const nextWeek = formatDate(new Date(Date.now() + 7 * 24 * 60 * 60 * 1000));

    const result = await query(
      `SELECT * FROM bills 
       WHERE user_id = $1 
       AND is_paid = false 
       AND due_date >= $2 
       AND due_date <= $3
       ORDER BY due_date ASC`,
      [userId, today, nextWeek]
    );

    return result.rows;
  }

  /**
   * Get overdue bills
   */
  async getOverdueBills(userId) {
    const today = formatDate(new Date());

    const result = await query(
      `SELECT * FROM bills 
       WHERE user_id = $1 
       AND is_paid = false 
       AND due_date < $2
       ORDER BY due_date ASC`,
      [userId, today]
    );

    return result.rows;
  }
}

module.exports = new BillService();