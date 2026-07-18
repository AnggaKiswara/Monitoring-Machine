const router = require("express").Router();
const ctrl = require("../controllers/serviceHistory.controller");
const { authenticate, authorize } = require("../middleware/auth");

router.use(authenticate);
router.get("/global", ctrl.getGlobal);
router.get("/", ctrl.getAll);
router.get("/:id", ctrl.getOne);
router.post("/", ctrl.create); // semua role login boleh nyatet histori service
router.put("/:id", authorize("admin", "staff"), ctrl.update);
router.delete("/:id", authorize("admin"), ctrl.remove);

module.exports = router;