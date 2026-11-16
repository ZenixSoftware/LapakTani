const express = require('express');
const router = express.Router();
const penyuluhController = require('../controllers/penyuluhController');
const agroController = require('../controllers/agroSupplyChainController');
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

// Store approval, village store quota, scoped forums & village fertilizer coordination
router.get('/store-applications', requireRole('penyuluh', 'dinas'), agroController.getStoreApplicationsForPpl);
router.put('/store-applications/:id/verify', requireRole('penyuluh'), agroController.verifyStoreApplication);
router.put('/village-store-quota', requireRole('penyuluh'), agroController.updateVillageStoreQuota);

router.get('/inter-ppl-forum', requireRole('penyuluh', 'dinas'), agroController.getInterPplForum);
router.post('/inter-ppl-forum', requireRole('penyuluh'), agroController.createInterPplForumPost);

router.get('/village-forum', requireRole('penyuluh', 'petani', 'admin'), agroController.getVillageForum);
router.post('/village-forum', requireRole('penyuluh', 'petani', 'admin'), agroController.createVillageForumPost);

router.get('/fertilizer-subsidies', requireRole('penyuluh', 'dinas', 'petani'), agroController.getFertilizerSubsidies);
router.post('/fertilizer-request', requireRole('penyuluh'), agroController.proposeFertilizerSubsidy);
router.put('/fertilizer-subsidies/:id/receive', requireRole('penyuluh'), (req, res, next) => {
  req.body = { ...(req.body || {}), status: 'DITERIMA_DESA' };
  agroController.dispatchFertilizerSubsidy(req, res, next);
});

module.exports = router;
