const express = require('express');
const router = express.Router();
const productController = require('../controllers/productController');
const b2bPoolController = require('../controllers/b2bPoolController');
const { verifyToken } = require('../middlewares/authMiddleware');
const { upload } = require('../middlewares/uploadMiddleware');

const handleUploadField = (req, res, next) => {
  upload.single('image')(req, res, (err) => {
    if (err) {
      return res.status(400).json({
        success: false,
        message: err.message || 'Gagal mengunggah file gambar produk.'
      });
    }
    next();
  });
};

router.get('/', productController.getProducts);
router.get('/me', verifyToken, productController.getFarmerProducts);
router.post('/', verifyToken, handleUploadField, productController.createProduct);
router.post('/:id/deduct-stock', productController.deductStock);
router.post('/:id/restore-stock', productController.restoreStock);
router.put('/:id', verifyToken, productController.updateProduct);
router.delete('/:id', verifyToken, productController.deleteProduct);

// US-25: Spot Market / Surplus Panen Penyaluran
router.post('/spot-surplus', verifyToken, (req, res, next) => {
  if (req.body && req.body.pool_id) {
    req.params.id = req.body.pool_id;
  }
  b2bPoolController.spilloverToRetail(req, res, next);
});

module.exports = router;
