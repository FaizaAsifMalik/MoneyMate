const { verifyToken } = require('../config/jwt');
const { unauthorized } = require('../utils/responseFormatter');

const authMiddleware = (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return unauthorized(res, 'No token provided');
    }

    const token = authHeader.split(' ')[1];
    const decoded = verifyToken(token);
    req.user = decoded;
    next();
  } catch (error) {
    return unauthorized(res, 'Invalid or expired token');
  }
};

module.exports = { authMiddleware };