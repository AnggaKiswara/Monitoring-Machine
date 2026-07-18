const express = require("express");
const authenticate = require("../middleware/authenticate");
const authorize = require("../middleware/authorize");
const ctrl = require("../controllers/user.controller");

const router = express.Router();

router.use(authenticate);
router.use(authorize("admin")); // hanya admin yang kelola user

router.get("/", ctrl.getAll);
router.get("/:id", ctrl.getOne);
router.put("/:id", ctrl.update);
router.patch("/:id/active", ctrl.setActive);

module.exports = router;
