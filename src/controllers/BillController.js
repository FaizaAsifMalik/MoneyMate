const billService = require('../services/BillService');
const { success, error, created } = require('../utils/responseFormatter');

class BillController {
  async getAll(req, res) {
    try {
      const bills = await billService.getBills(req.user.id, req.query);
      return success(res, bills);
    } catch (err) {
      return error(res, err.message, err.statusCode || 500);
    }
  }

  async getUpcoming(req, res) {
    try {
      const bills = await billService.getUpcomingBills(
        req.user.id, 
        req.query.days
      );
      return success(res, bills);
    } catch (err) {
      return error(res, err.message, err.statusCode || 500);
    }
  }

  async getById(req, res) {
    try {
      const bill = await billService.getBillById(
        req.params.id, 
        req.user.id
      );
      return success(res, bill);
    } catch (err) {
      return error(res, err.message, err.statusCode || 500);
    }
  }

  async create(req, res) {
    try {
      const bill = await billService.createBill(req.user.id, req.body);
      return created(res, bill);
    } catch (err) {
      return error(res, err.message, err.statusCode || 500);
    }
  }

  async update(req, res) {
    try {
      const bill = await billService.updateBill(
        req.params.id, 
        req.user.id, 
        req.body
      );
      return success(res, bill, 'Bill updated');
    } catch (err) {
      return error(res, err.message, err.statusCode || 500);
    }
  }

  async markAsPaid(req, res) {
    try {
      const bill = await billService.markAsPaid(
        req.params.id, 
        req.user.id
      );
      return success(res, bill, 'Bill marked as paid');
    } catch (err) {
      return error(res, err.message, err.statusCode || 500);
    }
  }

  async getOverdue(req, res) {
    try {
      const bills = await billService.getOverdueBills(req.user.id);
      return success(res, bills);
    } catch (err) {
      return error(res, err.message, err.statusCode || 500);
    }
  }

  async delete(req, res) {
    try {
      const result = await billService.deleteBill(
        req.params.id, 
        req.user.id
      );
      return success(res, result, 'Bill deleted');
    } catch (err) {
      return error(res, err.message, err.statusCode || 500);
    }
  }
}

module.exports = new BillController();