const router = require("express").Router();
const ctrl = require("../controllers/parameter.controller");
const { authenticate, authorize } = require("../middleware/auth");

router.use(authenticate);
router.get("/", ctrl.getAll);
router.get("/:id", ctrl.getOne);
router.post("/", authorize("admin"), ctrl.create);
router.put("/:id", authorize("admin"), ctrl.update);
router.delete("/:id", authorize("admin"), ctrl.remove);

module.exports = router;