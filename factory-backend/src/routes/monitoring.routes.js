const express = require("express");
const router = express.Router();
const { authenticate, authorize } = require("../middleware/auth");
const ctrl = require("../controllers/monitoring.controller");

router.use(authenticate);

// Read-only untuk teknisi/admin
router.get("/machines/:id_mesin/latest", ctrl.getLatestSession);
router.get("/machines/:id_mesin/history", ctrl.getHistory);

// Write untuk teknisi/admin
router.post("/machines/:id_mesin/sessions", authorize("admin", "teknisi"), ctrl.createSession);

module.exports = router;
