const express = require('express');
const router = express.Router();
const penyuluhController = require('../controllers/penyuluhController');
const agroController = require('../controllers/agroSupplyChainController');
const { verifyToken, requireRole } = require('../middlewares/authMiddleware');

router.use(verifyToken);

router.post('/daily-log', requireRole('petani', 'admin', 'penyuluh'), penyuluhController.createFarmerDailyLog);
router.get('/daily-log', requireRole('petani', 'admin', 'penyuluh', 'dinas'), penyuluhController.getFarmerDailyLogs);

router.get('/harvest-reports', requireRole('petani', 'penyuluh', 'admin'), agroController.getFarmerHarvestReports);
router.post('/harvest-reports', requireRole('petani', 'penyuluh', 'admin'), agroController.createFarmerHarvestReport);

router.get('/purchase-offers', requireRole('petani', 'admin', 'penyuluh'), agroController.getFarmerPurchaseOffers);
router.put('/purchase-offers/:id/respond', requireRole('petani'), agroController.respondToPurchaseOffer);

router.get('/village-forum', requireRole('petani', 'penyuluh', 'admin'), agroController.getVillageForum);
router.post('/village-forum', requireRole('petani', 'penyuluh', 'admin'), agroController.createVillageForumPost);

module.exports = router;
