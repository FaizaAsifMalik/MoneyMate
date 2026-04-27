require("dotenv").config();

const app = require("./src/config/app");
const sequelize = require("./src/config/database");
const connectDB = require("./src/config/connection-check");

// Routes
const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const morgan = require("morgan");

const appInstance = express();

//middleware
appInstance.use(cors());
appInstance.use(helmet());
appInstance.use(express.json());
appInstance.use(express.urlencoded({ extended: true }));
appInstance.use(morgan("dev"));

//test route
appInstance.get("/", (req, res) => {
  res.json({
    message: "MoneyMate Backend is Running 🚀"
  });
});

const startServer = async () => {
  try {
    await connectDB(); // check DB connection

    await sequelize.sync(); // sync models with DB (development)

    const PORT = process.env.PORT || app.port || 5000;

    appInstance.listen(PORT, () => {
      console.log(`Server running on port ${PORT}`);
    });
  } catch (err) {
    console.error("Server failed to start:", err.message);
  }
};

startServer();