const express = require("express");
const router = express.Router();
const ctrl = require("../controllers/sensorReading.controller");
const { authenticate, authorize } = require("../middleware/auth");

// Semua route memerlukan autentikasi
router.use(authenticate);

// GET - Ambil parameter untuk komponen tertentu
router.get("/parameters/:id_komponen", ctrl.getParametersByKomponen);

// GET - Ambil history sensor reading
router.get("/history/:id_komponen", ctrl.getHistory);

// GET - Ambil sensor reading terbaru
router.get("/latest/:id_komponen", ctrl.getLatest);

// POST - Insert sensor reading baru (hanya admin/teknisi)
router.post("/", authorize("admin", "teknisi"), ctrl.create);

module.exports = router;
