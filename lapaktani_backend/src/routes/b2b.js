const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const { verifyToken } = require('../middlewares/authMiddleware');
const b2bPoolController = require('../controllers/b2bPoolController');

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

// 2. Mitra Tani opens new forward harvest pool
router.post('/pools', verifyToken, b2bPoolController.createHarvestPool);

// 3. Zero-Waste Spillover: spill unsold quota to retail
router.post('/pools/:id/spillover-to-retail', verifyToken, b2bPoolController.spilloverToRetail);

// 4. Buyer takes quota
router.post('/take-quota', optionalToken, b2bPoolController.takeQuota);
router.post('/pools/:id/take-quota', optionalToken, b2bPoolController.takeQuota);

module.exports = router;

