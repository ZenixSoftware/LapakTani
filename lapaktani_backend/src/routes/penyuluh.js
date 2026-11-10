const express = require('express');
const router = express.Router();
const penyuluhController = require('../controllers/penyuluhController');
const { verifyToken, requireRole } = require('../middlewares/authMiddleware');

router.use(verifyToken);
router.use(requireRole('penyuluh'));

router.get('/pending-farmers', penyuluhController.getPendingFarmers);
router.get('/farmers', penyuluhController.getAllFarmers);
router.put('/verify-farmer/:id', penyuluhController.verifyFarmer);

// US-27: Spatial soil fertility map for PPL
router.get('/soil-map', penyuluhController.getSoilMap);

module.exports = router;
