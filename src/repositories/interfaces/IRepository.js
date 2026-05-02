class IRepository {
  async findById(id) { throw new Error('Not implemented'); }
  async findAll(filters) { throw new Error('Not implemented'); }
  async create(entity) { throw new Error('Not implemented'); }
  async update(id, data) { throw new Error('Not implemented'); }
  async delete(id) { throw new Error('Not implemented'); }
}

module.exports = IRepository;