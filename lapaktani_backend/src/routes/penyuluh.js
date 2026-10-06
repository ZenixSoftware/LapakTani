const express = require('express');
const router = express.Router();
const penyuluhController = require('../controllers/penyuluhController');

router.get('/pending-farmers', penyuluhController.getPendingFarmers);
router.get('/farmers', penyuluhController.getAllFarmers);
router.put('/verify-farmer/:id', penyuluhController.verifyFarmer);

module.exports = router;
