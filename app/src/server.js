const express = require("express");
const mongoose = require("mongoose");

const app = express();

app.use(express.json());

const PORT = process.env.PORT || 3000;
const MONGO_URI = process.env.MONGO_URI;

app.get("/", (req, res) => {
  res.json({
    message: "Study Now DevOps Assessment App",
    status: "running"
  });
});

app.get("/health", async (req, res) => {
  try {
    if (mongoose.connection.readyState !== 1) {
      return res.status(503).json({
        status: "unhealthy",
        database: "disconnected"
      });
    }

    res.status(200).json({
      status: "healthy",
      database: "connected"
    });
} catch {
    res.status(503).json({
        status: "unhealthy"
    });
  }
});

app.get("/api/notes", async (req, res) => {
  res.json({
    message: "Notes API is working"
  });
});

async function startServer() {
  try {
    if (!MONGO_URI) {
      throw new Error("MONGO_URI environment variable is not set");
    }

    await mongoose.connect(MONGO_URI);

    console.log("Connected to MongoDB");

    app.listen(PORT, "0.0.0.0", () => {
      console.log(`Application listening on port ${PORT}`);
    });
  } catch (error) {
    console.error("Failed to start application:", error.message);
    process.exit(1);
  }
}

startServer();