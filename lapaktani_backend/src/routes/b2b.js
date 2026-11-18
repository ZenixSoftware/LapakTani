const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const { verifyToken } = require('../middlewares/authMiddleware');
const b2bPoolController = require('../controllers/b2bPoolController');
const b2bLotController = require('../controllers/b2bLotController');

const optionalToken = (req, res, next) => {
  const authHeader = req.headers.authorization || req.headers.Authorization;
  if (authHeader && authHeader.startsWith('Bearer ')) {
    const token = authHeader.split(' ')[1];
    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET || 'lapaktani_secret_2026');
      req.user = decoded;
    } catch (_) {}
  }
  next();
};

// 1. Browsing open pools (Public / Buyer & Guest accessible)
router.get('/pools', b2bPoolController.getHarvestPools);

// Two-Tier B2B Open-Bid Lots & Bids (HOTEL_B2B / RETAIL_MERCHANT <-> B2B_OFFTAKER)
router.get('/lots', b2bLotController.getB2BLots);
router.get('/lot-bids', verifyToken, b2bLotController.getB2BLotBids);
router.post('/lots/:productId/bid', verifyToken, b2bLotController.placeB2BLotBid);
router.put('/bids/:bidId/status', verifyToken, b2bLotController.updateB2BLotBidStatus);
router.post('/bids/:bidId/restock-to-retail', verifyToken, b2bLotController.restockB2BBidToRetail);
router.post('/bids/:bidId/cancel-with-refund', verifyToken, b2bLotController.cancelB2BBidWithRefund);

// US-22: B2B Contracts & Bids Aliases
router.get('/bids', (req, res, next) => {
  if (req.baseUrl === '/api/b2b') {
    return verifyToken(req, res, () => b2bLotController.getB2BLotBids(req, res, next));
  }
  return b2bPoolController.getHarvestPools(req, res, next);
});
router.get('/', b2bPoolController.getHarvestPools);
router.post('/', verifyToken, b2bPoolController.createHarvestPool);

// 2. Mitra Tani opens new forward harvest pool
router.post('/pools', verifyToken, b2bPoolController.createHarvestPool);

// 3. Zero-Waste Spillover: spill unsold quota to retail
router.post('/pools/:id/spillover-to-retail', verifyToken, b2bPoolController.spilloverToRetail);

// 4. Buyer takes quota
router.post('/take-quota', optionalToken, b2bPoolController.takeQuota);
router.post('/pools/:id/take-quota', optionalToken, b2bPoolController.takeQuota);

module.exports = router;
