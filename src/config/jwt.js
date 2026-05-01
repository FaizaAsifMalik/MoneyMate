const jwt = require('jsonwebtoken');
const { config } = require('./env');

/**
 * Generate JWT token for user
 * @param {Object} payload - User data to encode
 * @returns {string} JWT token
 */
const generateToken = (payload) => {
  return jwt.sign(payload, config.jwt.secret, {
    expiresIn: config.jwt.expiresIn,
  });
};

/**
 * Verify JWT token
 * @param {string} token - JWT token to verify
 * @returns {Object} Decoded payload
 */
const verifyToken = (token) => {
  try {
    return jwt.verify(token, config.jwt.secret);
  } catch (error) {
    throw new Error('Invalid or expired token');
  }
};

/**
 * Decode JWT token without verification
 * @param {string} token - JWT token to decode
 * @returns {Object} Decoded payload
 */
const decodeToken = (token) => {
  return jwt.decode(token);
};

module.exports = {
  generateToken,
  verifyToken,
  decodeToken,
};