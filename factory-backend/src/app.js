const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const morgan = require("morgan");
const path = require("path");

const errorHandler = require("./middleware/errorHandler");
const db = require("./config/db"); // Tambahkan ini (sesuaikan path jika berbeda)

const authRoutes = require("./routes/auth.routes");
const stationRoutes = require("./routes/station.routes");
const machineRoutes = require("./routes/machine.routes");
const komponenRoutes = require("./routes/komponen.routes");
const parameterRoutes = require("./routes/parameter.routes");
const komponenParameterRoutes = require("./routes/komponenParameter.routes");
const sensorReadingRoutes = require("./routes/sensorReading.routes");
const alertRuleRoutes = require("./routes/alertRule.routes");
const serviceAlertRoutes = require("./routes/serviceAlert.routes");
const serviceHistoryRoutes = require("./routes/serviceHistory.routes");
const factoryRoutes = require("./routes/factory.routes");

const app = express();

// Middleware global
app.use(helmet({ crossOriginResourcePolicy: { policy: "cross-origin" } }));
app.use(cors());
app.use(express.json());
app.use(morgan(process.env.NODE_ENV === "production" ? "combined" : "dev"));

// Serve static files (foto inspeksi)
app.use("/uploads", express.static(path.join(__dirname, "..", "uploads")));

// Health check
app.get("/health", (req, res) => res.json({ success: true, message: "API is running" }));

// Test koneksi database
app.get("/test-db", (req, res) => {
  db.query("SELECT 1 + 1 AS result", (err, results) => {
    if (err) {
      return res.status(500).json({
        success: false,
        message: "Gagal koneksi database",
        error: err.message,
      });
    }
    res.json({
      success: true,
      message: "Berhasil koneksi database",
      result: results[0],
    });
  });
});

// Routes
app.use("/api/auth", authRoutes);
app.use("/api/factories", factoryRoutes);
app.use("/api/stations", stationRoutes);
app.use("/api/machines", machineRoutes);
app.use("/api/komponen", komponenRoutes);
app.use("/api/parameters", parameterRoutes);
app.use("/api/komponen-parameters", komponenParameterRoutes);
app.use("/api/sensor-readings", sensorReadingRoutes);
app.use("/api/alert-rules", alertRuleRoutes);
app.use("/api/service-alerts", serviceAlertRoutes);
app.use("/api/service-history", serviceHistoryRoutes);

// 404 handler
app.use((req, res) => {
  res.status(404).json({ success: false, message: "Endpoint not found :)" });
});

// Error handler (harus paling bawah)
app.use(errorHandler);

module.exports = app;
