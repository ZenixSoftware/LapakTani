const express = require('express');
const router = express.Router();
const agro = require('../controllers/agroSupplyChainController');
const { verifyToken, requireRole } = require('../middlewares/authMiddleware');

router.use(verifyToken);

router.get('/my-application', agro.getMyStoreApplication);
router.post('/apply', agro.applyForStore);
router.put('/settings', requireRole('admin'), agro.updateStoreSettings);
router.get('/nearby-harvests', requireRole('admin', 'penyuluh'), agro.getNearbyHarvests);
router.get('/purchase-offers', requireRole('admin'), agro.getStorePurchaseOffers);
router.post('/purchase-offers', requireRole('admin'), agro.createPurchaseOffer);
router.put('/purchase-offers/:id/weigh-and-pay', requireRole('admin'), agro.weighAndPayOffer);

module.exports = router;
