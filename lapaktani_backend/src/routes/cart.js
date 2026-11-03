const express = require('express');
const router = express.Router();
const cartController = require('../controllers/cartController');
const { verifyToken } = require('../middlewares/authMiddleware');

router.get('/', verifyToken, cartController.getCart);
router.get('', verifyToken, cartController.getCart);
router.post('/', verifyToken, cartController.addToCart);
router.post('', verifyToken, cartController.addToCart);
router.delete('/:id', verifyToken, cartController.removeFromCart);
router.put('/:id', verifyToken, cartController.updateCartQuantity);
router.delete('/', verifyToken, cartController.clearCart);
router.delete('', verifyToken, cartController.clearCart);

module.exports = router;
