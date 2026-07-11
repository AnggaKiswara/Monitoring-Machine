const express = require('express');
const router = express.Router();
const ctrl = require('../controllers/sensorReading.controller');
const { authenticate, authorize } = require('../middleware/auth');

router.use(authenticate);

router.get('/parameters/:id_komponen', ctrl.getParametersByKomponen);
router.get('/history/:id_komponen', ctrl.getHistory);
router.get('/latest/:id_komponen', ctrl.getLatest);
router.post('/', authorize('admin', 'teknisi'), ctrl.create);

module.exports = router;
