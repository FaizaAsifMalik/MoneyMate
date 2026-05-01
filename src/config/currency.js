const axios = require("axios");
const config = require("./app");

class CurrencyService {
  async convert(from, to, amount) {
    try {
      const res = await axios.get(
        `https://v6.exchangerate-api.com/v6/${config.currencyApiKey}/latest/${from}`
      );

      const rate = res.data.conversion_rates[to];

      if (!rate) {
        throw new Error("Invalid currency type");
      }

      return {
        from,
        to,
        amount,
        converted: amount * rate,
        rate
      };
    } catch (err) {
      throw new Error("Currency conversion failed: " + err.message);
    }
  }
}

module.exports = new CurrencyService();

