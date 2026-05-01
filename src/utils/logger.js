const { config } = require('../config/env');

const levels = {
  error: 0,
  warn: 1,
  info: 2,
  debug: 3,
};

const colors = {
  error: '\x1b[31m', // Red
  warn: '\x1b[33m',  // Yellow
  info: '\x1b[36m',  // Cyan
  debug: '\x1b[35m', // Magenta
  reset: '\x1b[0m',
};

/**
 * Simple logger utility
 */
class Logger {
  constructor() {
    this.level = config.nodeEnv === 'production' ? 'info' : 'debug';
  }

  log(level, message, meta = {}) {
    if (levels[level] <= levels[this.level]) {
      const timestamp = new Date().toISOString();
      const color = colors[level];
      const reset = colors.reset;
      
      const logMessage = `${color}[${timestamp}] [${level.toUpperCase()}]${reset} ${message}`;
      
      if (Object.keys(meta).length > 0) {
        console.log(logMessage, meta);
      } else {
        console.log(logMessage);
      }
    }
  }

  error(message, meta) {
    this.log('error', message, meta);
  }

  warn(message, meta) {
    this.log('warn', message, meta);
  }

  info(message, meta) {
    this.log('info', message, meta);
  }

  debug(message, meta) {
    this.log('debug', message, meta);
  }
}

module.exports = new Logger();