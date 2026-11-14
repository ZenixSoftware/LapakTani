const express = require('express');
const router = express.Router();
const penyuluhController = require('../controllers/penyuluhController');
const soilRouter = require('./soil');
const { verifyToken, requireRole } = require('../middlewares/authMiddleware');

router.use(verifyToken);
router.use(requireRole('penyuluh'));

router.get('/pending-farmers', penyuluhController.getPendingFarmers);
router.get('/farmers', penyuluhController.getAllFarmers);
router.put('/verify-farmer/:id', penyuluhController.verifyFarmer);

// US-27: Spatial soil fertility map & Sumenep land monitoring for PPL
router.get('/soil-map', penyuluhController.getSoilMap);
router.get('/monitoring-lahan', penyuluhController.getMonitoringLahan);
router.get('/monitoring-summary', penyuluhController.getMonitoringSummary);
router.post('/monitoring-lahan', soilRouter.uploadSoilPhotos, penyuluhController.saveMonitoringLahan);
router.put('/monitoring-lahan/:id/recommend', penyuluhController.updateMonitoringRecommendation);

module.exports = router;
