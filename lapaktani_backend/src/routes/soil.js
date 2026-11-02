const express = require('express');
const router = express.Router();
const productController = require('../controllers/productController');

// GET /api/soil/telemetry/:productId
router.get('/telemetry/:productId', productController.getSoilTelemetry);

module.exports = router;
