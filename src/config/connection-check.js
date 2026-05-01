const sequelize = require("./database");

const connectDB = async () => {
  try {
    await sequelize.authenticate();
    console.log("PostgreSQL connected successfully");
  } catch (err) {
    console.error("Database connection failed:", err.message);
    process.exit(1);
  }
};

module.exports = connectDB;
