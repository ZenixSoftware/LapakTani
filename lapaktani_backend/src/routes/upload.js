const express = require('express');
const router = express.Router();
const { upload, validateUploadMagicBytes } = require('../middlewares/uploadMiddleware');
const uploadController = require('../controllers/uploadController');
const { verifyToken } = require('../middlewares/authMiddleware');

const handleUploadField = (req, res, next) => {
  upload.single('image')(req, res, (err) => {
    if (err) {
      return res.status(400).json({
        success: false,
        message: err.message || 'Gagal mengunggah file.'
      });
    }
    if (req.file) {
      return next();
    }
    upload.single('file')(req, res, (err2) => {
      if (err2) {
        return res.status(400).json({
          success: false,
          message: err2.message || 'Gagal mengunggah file.'
        });
      }
      next();
    });
  });
};

router.post(
  '/product-image',
  verifyToken,
  handleUploadField,
  validateUploadMagicBytes,
  uploadController.uploadProductImage
);

module.exports = router;
