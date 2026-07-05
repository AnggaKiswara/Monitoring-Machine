const router = require("express").Router();
const ctrl = require("../controllers/serviceAlert.controller");
const { authenticate } = require("../middleware/auth");

router.use(authenticate);
router.get("/", ctrl.getAll);
router.get("/:id", ctrl.getOne);
router.post("/", ctrl.create);
router.put("/:id", ctrl.update);
router.delete("/:id", ctrl.remove);
router.patch("/:id/acknowledge", ctrl.acknowledge);
router.patch("/:id/resolve", ctrl.resolve);

module.exports = router;
