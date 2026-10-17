const express = require('express');
const router = express.Router();
const productController = require('../controllers/productController');
const { verifyToken } = require('../middlewares/authMiddleware');

router.get('/', productController.getProducts);
router.get('/me', verifyToken, productController.getFarmerProducts);
router.post('/', verifyToken, productController.createProduct);
router.post('/:id/deduct-stock', productController.deductStock);
router.post('/:id/restore-stock', productController.restoreStock);
router.put('/:id', verifyToken, productController.updateProduct);
router.delete('/:id', verifyToken, productController.deleteProduct);

module.exports = router;
