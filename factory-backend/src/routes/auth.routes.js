const router = require("express").Router();
const ctrl = require("../controllers/auth.controller");
const { authenticate, optionalAuthenticate } = require("../middleware/auth");

router.post("/register", optionalAuthenticate, ctrl.register);
router.post("/login", ctrl.login);
router.get("/me", authenticate, ctrl.me);

module.exports = router;