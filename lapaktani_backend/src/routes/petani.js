const express = require('express');
const router = express.Router();
const penyuluhController = require('../controllers/penyuluhController');
const { verifyToken, requireRole } = require('../middlewares/authMiddleware');

router.use(verifyToken);

router.post('/daily-log', requireRole('petani', 'admin', 'penyuluh'), penyuluhController.createFarmerDailyLog);
router.get('/daily-log', requireRole('petani', 'admin', 'penyuluh', 'dinas'), penyuluhController.getFarmerDailyLogs);

module.exports = router;
