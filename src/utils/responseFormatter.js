/**
 * Format success response
 */
const formatSuccessResponse = (data, message = 'Success') => {
  return {
    success: true,
    message,
    data,
  };
};

/**
 * Format error response
 */
const formatErrorResponse = (error) => {
  const response = {
    success: false,
    message: error.message || 'An error occurred',
  };

  if (error.details) {
    response.details = error.details;
  }

  // Include stack trace in development
  if (process.env.NODE_ENV === 'development' && error.stack) {
    response.stack = error.stack;
  }

  return response;
};

/**
 * Format paginated response
 */
const formatPaginatedResponse = (data, page, limit, total) => {
  return {
    success: true,
    data,
    pagination: {
      currentPage: page,
      limit,
      totalItems: total,
      totalPages: Math.ceil(total / limit),
    },
  };
};

module.exports = {
  formatSuccessResponse,
  formatErrorResponse,
  formatPaginatedResponse,
};