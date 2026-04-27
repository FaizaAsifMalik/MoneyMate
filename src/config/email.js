const nodemailer = require("nodemailer");
const config = require("./app");

const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    type: "OAuth2",
    user: config.emailUser,
    clientId: config.gmailClientId,
    clientSecret: config.gmailClientSecret,
    refreshToken: config.gmailRefreshToken
  }
});

// optional test function
const verifyEmailConnection = async () => {
  try {
    await transporter.verify();
    console.log("Email service connected successfully");
  } catch (err) {
    console.error("Email service error:", err.message);
  }
};

module.exports = {
  transporter,
  verifyEmailConnection
};

