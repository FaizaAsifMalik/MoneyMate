const nodemailer = require('nodemailer');
const { config } = require('./env');

const transporter = nodemailer.createTransport({
  host: config.email.host,
  port: config.email.port,
  secure: false,
  auth: {
    user: config.email.user,
    pass: config.email.pass,
  },
});

module.exports = { transporter };