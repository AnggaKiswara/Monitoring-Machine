const router = require("express").Router();
const ctrl = require("../controllers/sensorReading.controller");
const { authenticate } = require("../middleware/auth");

router.use(authenticate);
router.post("/", ctrl.create);                    // insert reading baru (dari ESP32/Pi bridge)
router.get("/history", ctrl.getHistory);           // ?id_komponen=&id_parameter=&from=&to=
router.get("/latest/:id_komponen", ctrl.getLatest); // nilai terkini semua parameter di 1 komponen

module.exports = router;
