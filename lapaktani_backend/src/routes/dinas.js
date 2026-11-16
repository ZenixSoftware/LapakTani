const express = require('express');
const router = express.Router();
const agro = require('../controllers/agroSupplyChainController');
const { verifyToken, requireRole } = require('../middlewares/authMiddleware');

router.use(verifyToken);

router.get('/gis-overview', requireRole('dinas', 'penyuluh'), agro.getDinasGisOverview);
router.get('/fertilizer-subsidies', requireRole('dinas', 'penyuluh'), agro.getFertilizerSubsidies);
router.post('/fertilizer-subsidies/confirm', requireRole('dinas'), agro.confirmFertilizerSubsidy);
router.put('/fertilizer-subsidies/:id/dispatch', requireRole('dinas'), agro.dispatchFertilizerSubsidy);

module.exports = router;
