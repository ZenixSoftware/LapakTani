const express = require('express');
const router = express.Router();
const pestReportController = require('../controllers/pestReportController');
const { upload } = require('../middlewares/uploadMiddleware');
const { verifyToken } = require('../middlewares/authMiddleware');

// Optional auth middleware: sets req.user if token is present, continues if not
const optionalAuth = (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (authHeader && authHeader.startsWith('Bearer ')) {
    return verifyToken(req, res, next);
  }
  next();
};

// Optional multer upload: handles multipart if file sent, passes through if JSON
const optionalUpload = (req, res, next) => {
  upload.single('image')(req, res, (err) => {
    if (err) {
      // If error is related to file size or type
      return res.status(400).json({
        success: false,
        message: err.message || 'File gambar tidak valid.'
      });
    }
    next();
  });
};

// 1. Create Pest Attack Report & Dispatch Alerts
router.post('/', optionalAuth, optionalUpload, pestReportController.createPestReport);

// 2. Get list of reports (with filters)
router.get('/', pestReportController.getPestReports);

// 3. Get Active Pest Alert (for Dashboard Banner)
router.get('/active-alert', pestReportController.getActivePestAlert);
router.get('/active', pestReportController.getActivePestAlert);

// 4. Test / Inspect Notification Targets based on Poktan
router.get('/poktan-targets', pestReportController.getPoktanNotificationTargets);

// 5. Get detail of specific report
router.get('/:id', pestReportController.getPestReportById);

// 6. Update status / handling recommendations
router.patch('/:id/status', optionalAuth, pestReportController.updatePestReportStatus);
router.put('/:id/status', optionalAuth, pestReportController.updatePestReportStatus);

module.exports = router;

