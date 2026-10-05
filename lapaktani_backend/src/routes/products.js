const express = require('express');
const router = express.Router();
const productController = require('../controllers/productController');
const { verifyToken } = require('../middlewares/authMiddleware');

router.get('/', productController.getProducts);
router.post('/', verifyToken, productController.createProduct);

module.exports = router;
