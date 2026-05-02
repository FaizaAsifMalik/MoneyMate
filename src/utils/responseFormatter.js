const success = (res, data, message = 'Success', statusCode = 200) => {
  return res.status(statusCode).json({ success: true, message, data });
};

const error = (res, message = 'An error occurred', statusCode = 500, details = null) => {
  const response = { success: false, message };
  if (details) response.details = details;
  return res.status(statusCode).json(response);
};

const created = (res, data, message = 'Created successfully') => {
  return success(res, data, message, 201);
};

const notFound = (res, message = 'Not found') => {
  return error(res, message, 404);
};

const unauthorized = (res, message = 'Unauthorized') => {
  return error(res, message, 401);
};

const forbidden = (res, message = 'Forbidden') => {
  return error(res, message, 403);
};

const validationError = (res, details) => {
  return error(res, 'Validation failed', 422, details);
};

module.exports = { success, error, created, notFound, unauthorized, forbidden, validationError };