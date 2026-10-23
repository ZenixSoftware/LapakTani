const express = require('express');
const router = express.Router();
const cartController = require('../controllers/cartController');
const { verifyToken } = require('../middlewares/authMiddleware');

router.use(verifyToken);

router.get('/', cartController.getCart);
router.post('/', verifyToken, cartController.addToCart);
router.post('', verifyToken, cartController.addToCart);
router.put('/:id', cartController.updateCartItem);
router.delete('/:id', cartController.deleteCartItem);
router.delete('/', cartController.clearCart);
router.delete('', cartController.clearCart);

module.exports = router;
