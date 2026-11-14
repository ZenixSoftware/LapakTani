const path = require('path');
const fs = require('fs');
const express = require('express');
const multer = require('multer');
const { v4: uuidv4 } = require('uuid');
const router = express.Router();
const productController = require('../controllers/productController');
const penyuluhController = require('../controllers/penyuluhController');
const { validateImageMagicBytes } = require('../middlewares/uploadMiddleware');
const { optionalVerifyToken } = require('../middlewares/authMiddleware');

const soilUploadDir = path.resolve(__dirname, '../../public/uploads/soil');
const ALLOWED_EXT = new Set(['.jpg', '.jpeg', '.png', '.webp']);

const soilStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    if (!fs.existsSync(soilUploadDir)) {
      fs.mkdirSync(soilUploadDir, { recursive: true });
    }
    cb(null, soilUploadDir);
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname || '').toLowerCase();
    const safeExt = ALLOWED_EXT.has(ext) ? ext : '.jpg';
    cb(null, `soil-${file.fieldname}-${uuidv4().slice(0, 8)}${safeExt}`);
  }
});

const soilUpload = multer({
  storage: soilStorage,
  limits: { fileSize: 8 * 1024 * 1024, files: 3 },
  fileFilter: (req, file, cb) => {
    const ext = path.extname(file.originalname || '').toLowerCase();
    if (file.mimetype.startsWith('image/') && ALLOWED_EXT.has(ext)) {
      return cb(null, true);
    }
    return cb(new Error('Hanya file gambar (jpg/png/webp) yang diperbolehkan untuk foto lahan.'));
  }
});

const uploadSoilPhotos = (req, res, next) => {
  if (!req.is('multipart/form-data')) {
    return next();
  }
  const uploader = soilUpload.fields([
    { name: 'foto_daun', maxCount: 1 },
    { name: 'foto_pohon', maxCount: 1 },
    { name: 'foto_tanah', maxCount: 1 }
  ]);
  uploader(req, res, (err) => {
    if (err) {
      return res.status(400).json({ success: false, message: err.message || 'Gagal mengunggah foto lahan.' });
    }
    const files = req.files || {};
    for (const key of Object.keys(files)) {
      for (const file of files[key]) {
        if (!validateImageMagicBytes(file.path)) {
          try { fs.unlinkSync(file.path); } catch (_) {}
          return res.status(400).json({ success: false, message: `File ${key} tidak valid.` });
        }
      }
    }
    return next();
  });
};

// Static/named Sumenep monitoring routes MUST appear before /:farm_id
router.get('/monitoring-lahan', penyuluhController.getMonitoringLahan);
router.get('/monitoring-summary', penyuluhController.getMonitoringSummary);
router.post('/monitoring-lahan', optionalVerifyToken, uploadSoilPhotos, penyuluhController.saveMonitoringLahan);
router.post('/save', optionalVerifyToken, uploadSoilPhotos, penyuluhController.saveMonitoringLahan);

// GET /api/soil/telemetry/:productId
router.get('/telemetry/:productId', productController.getSoilTelemetry);

// US-26: GET /api/soil/:farm_id and POST /api/soil/telemetry
router.get('/:farm_id', productController.getSoilTelemetry);
router.post('/telemetry', productController.saveSoilTelemetry);

router.uploadSoilPhotos = uploadSoilPhotos;

module.exports = router;
