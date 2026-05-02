const getStartOfMonth = (date = new Date()) => {
  return new Date(date.getFullYear(), date.getMonth(), 1).toISOString().split('T')[0];
};

const getEndOfMonth = (date = new Date()) => {
  return new Date(date.getFullYear(), date.getMonth() + 1, 0).toISOString().split('T')[0];
};

const getNextDueDate = (dayOfMonth, frequency = 'monthly') => {
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
};

const parseInputDate = (dateStr) => {
  if (!dateStr) return null;
  const parts = dateStr.split('-');
  // MM-DD-YYYY from frontend
  if (parts[2]?.length === 4) {
    const [month, day, year] = parts;
    return new Date(`${year}-${month}-${day}`);
  }
  // Already YYYY-MM-DD or ISO
  return new Date(dateStr);
};

const formatDate = (date) => {
  if (!date) return null;
  const d = typeof date === 'string' ? parseInputDate(date) : new Date(date);
  if (isNaN(d.getTime())) return null;
  return d.toISOString().split('T')[0];
};

const paginate = (page = 1, limit = 20) => ({
  limit: parseInt(limit),
  offset: (parseInt(page) - 1) * parseInt(limit),
});

module.exports = { getStartOfMonth, getEndOfMonth, getNextDueDate, parseInputDate, formatDate, paginate };