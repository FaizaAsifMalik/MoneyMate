require("dotenv").config();

module.exports = {
  port: process.env.PORT || 5000,

  jwtSecret: process.env.JWT_SECRET,
  jwtExpire: "7d",

  bcryptSaltRounds: 10,

  currencyApiKey: process.env.CURRENCY_API_KEY,

  emailUser: process.env.EMAIL_USER,
  gmailClientId: process.env.GMAIL_CLIENT_ID,
  gmailClientSecret: process.env.GMAIL_CLIENT_SECRET,
  gmailRefreshToken: process.env.GMAIL_REFRESH_TOKEN
};
