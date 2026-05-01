const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const morgan = require("morgan");

const { config } = require("./config/env");
const logger = require("./utils/logger");
const { checkDatabaseConnection } = require("./config/connection_check");

const app = express();

// Middlewares
app.use(cors());
app.use(helmet());
app.use(express.json());
app.use(morgan("dev"));

// Test route
app.get("/", (req, res) => {
  res.json({
    message: "MoneyMate API is running"
  });
});

// Health check
app.get("/health", async (req, res) => {
  try {
    await checkDatabaseConnection();
    res.json({ status: "OK", db: "Connected" });
  } catch (err) {
    res.status(500).json({ status: "ERROR", db: "Disconnected" });
  }
});

module.exports = app;
