const express = require('express');
const router = express.Router();
const {
  upload,
  uploadProductImage,
  uploadKtpDocument,
  uploadStoreSkDocument,
  uploadFieldPhoto,
  validateUploadMagicBytes
} = require('../middlewares/uploadMiddleware');
const uploadController = require('../controllers/uploadController');
const { verifyToken, optionalVerifyToken } = require('../middlewares/authMiddleware');

const createUploadFieldHandler = (multerInstance) => (req, res, next) => {
  multerInstance.single('image')(req, res, (err) => {
    if (err) {
      return res.status(400).json({
        success: false,
        message: err.message || 'Gagal mengunggah file.'
      });
    }
    if (req.file) {
      return next();
    }
    multerInstance.single('file')(req, res, (err2) => {
      if (err2) {
        return res.status(400).json({
          success: false,
          message: err2.message || 'Gagal mengunggah file.'
        });
      }
      if (req.file) {
        return next();
      }
      multerInstance.single('document')(req, res, (err3) => {
        if (err3) {
          return res.status(400).json({
            success: false,
            message: err3.message || 'Gagal mengunggah dokumen.'
          });
        }
        next();
      });
    });
  });
};

router.post(
  '/product-image',
  verifyToken,
  createUploadFieldHandler(uploadProductImage || upload),
  validateUploadMagicBytes,
  uploadController.uploadProductImage
);

router.post(
  '/ktp',
  optionalVerifyToken,
  createUploadFieldHandler(uploadKtpDocument),
  validateUploadMagicBytes,
  uploadController.uploadCategorizedFile('ktp')
);

router.post(
  '/store-sk',
  optionalVerifyToken,
  createUploadFieldHandler(uploadStoreSkDocument),
  validateUploadMagicBytes,
  uploadController.uploadCategorizedFile('docs')
);

router.post(
  '/field-photo',
  optionalVerifyToken,
  createUploadFieldHandler(uploadFieldPhoto),
  validateUploadMagicBytes,
  uploadController.uploadCategorizedFile('soil')
);

module.exports = router;
