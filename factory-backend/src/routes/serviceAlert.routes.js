const router = require("express").Router();
const ctrl = require("../controllers/serviceAlert.controller");
const { authenticate, authorize } = require("../middleware/auth");

router.use(authenticate);
router.get("/", ctrl.getAll);
router.get("/:id", ctrl.getOne);
router.post("/", authorize("admin", "staff"), ctrl.create);
router.put("/:id", authorize("admin", "staff"), ctrl.update);
router.delete("/:id", authorize("admin"), ctrl.remove);
router.patch("/:id/acknowledge", ctrl.acknowledge); // semua role login boleh
router.patch("/:id/resolve", ctrl.resolve);          // semua role login boleh

module.exports = router;