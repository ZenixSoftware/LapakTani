const express = require('express');
const router = express.Router();
const penyuluhController = require('../controllers/penyuluhController');
const soilRouter = require('./soil');
const { verifyToken, requireRole } = require('../middlewares/authMiddleware');

router.use(verifyToken);

// Strict PPL-only validation & decision endpoints
router.get('/pending-farmers', requireRole('penyuluh'), penyuluhController.getPendingFarmers);
router.get('/farmers', requireRole('penyuluh', 'dinas', 'admin'), penyuluhController.getAllFarmers);
router.put('/verify-farmer/:id', requireRole('penyuluh'), penyuluhController.verifyFarmer);
router.put('/monitoring-lahan/:id/recommend', requireRole('penyuluh'), penyuluhController.updateMonitoringRecommendation);

// Dual-Target RAG Decision & Dispatch
router.post('/rag-decision', requireRole('penyuluh'), penyuluhController.generateRagDecision);
router.post('/dispatch-decision', requireRole('penyuluh'), penyuluhController.dispatchRagDecision);
router.get(
  '/decision-reports',
  requireRole('penyuluh', 'dinas', 'petani', 'admin'),
  penyuluhController.getDecisionReports
);
router.put(
  '/decision-reports/:id/status',
  requireRole('penyuluh', 'dinas', 'petani', 'admin'),
  penyuluhController.updateDecisionReportStatus
);

// Shared monitoring & telemetry read/write endpoints
router.get('/soil-map', requireRole('penyuluh', 'dinas', 'admin'), penyuluhController.getSoilMap);
router.get(
  '/monitoring-lahan',
  requireRole('penyuluh', 'dinas', 'admin', 'petani'),
  penyuluhController.getMonitoringLahan
);
router.get(
  '/monitoring-summary',
  requireRole('penyuluh', 'dinas', 'admin', 'petani'),
  penyuluhController.getMonitoringSummary
);
router.post(
  '/monitoring-lahan',
  requireRole('penyuluh', 'petani', 'admin'),
  soilRouter.uploadSoilPhotos,
  penyuluhController.saveMonitoringLahan
);

module.exports = router;
