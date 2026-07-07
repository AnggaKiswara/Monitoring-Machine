const router = require("express").Router();
const ctrl = require("../controllers/sensorReading.controller");
const { authenticate } = require("../middleware/auth");

router.use(authenticate);
router.post("/", ctrl.create);
router.get("/history", ctrl.getHistory);
router.get("/latest/:id_komponen", ctrl.getLatest);

module.exports = router;