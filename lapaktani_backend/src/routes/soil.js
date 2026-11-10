const express = require('express');
const router = express.Router();
const productController = require('../controllers/productController');

// GET /api/soil/telemetry/:productId
router.get('/telemetry/:productId', productController.getSoilTelemetry);

// US-26: GET /api/soil/:farm_id and POST /api/soil/telemetry
router.get('/:farm_id', productController.getSoilTelemetry);
router.post('/telemetry', productController.saveSoilTelemetry);

module.exports = router;
