const express = require('express');
const router = express.Router();
const masterDataController = require('../controllers/masterDataController');

router.get('/commodities', masterDataController.getCommodities);
router.get('/grades', masterDataController.getProductGrades);

module.exports = router;
