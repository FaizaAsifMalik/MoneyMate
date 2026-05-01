const axios = require("axios");
const { config } = require("./env");
const logger = require("../utils/logger");

/**
 * Convert currency
 * @param {string} from 
 * @param {string} to 
 * @param {number} amount 
 */
const convertCurrency = async (from, to, amount) => {
  try {
    const url = `${config.currencyApi.url}/${config.currencyApi.key}/pair/${from}/${to}/${amount}`;

    const response = await axios.get(url);

    logger.info("Currency converted successfully");

    return {
      from,
      to,
      amount,
      result: response.data.conversion_result
    };
  } catch (error) {
    logger.error("Currency conversion error:", error.message);
    throw error;
  }
};

module.exports = {
  convertCurrency
};
