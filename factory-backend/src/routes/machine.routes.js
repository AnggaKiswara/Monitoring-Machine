const router = require("express").Router();
const ctrl = require("../controllers/machine.controller");
const { authenticate, authorize } = require("../middleware/auth");

router.use(authenticate);
router.get("/", ctrl.getAll);
router.get("/:id", ctrl.getOne);
router.post("/", authorize("admin"), ctrl.create);
router.put("/:id", authorize("admin"), ctrl.update);
router.delete("/:id", authorize("admin"), ctrl.remove);
router.post("/:id/hm", authenticate, ctrl.updateHM);
router.post("/:id/pm", authenticate, ctrl.recordPM);
router.post("/:id/inspection", authenticate, ctrl.submitInspection);
router.get("/:id/inspection/:serviceId", authenticate, ctrl.getInspectionDetail);
router.post("/:id/inspection/:serviceId/photos", authenticate, ctrl.uploadMiddleware, ctrl.uploadInspectionPhotos);
router.get("/:id/history", authenticate, ctrl.getServiceHistory);
router.get("/:id/pm-status", authenticate, ctrl.getPMStatus);

module.exports = router;
