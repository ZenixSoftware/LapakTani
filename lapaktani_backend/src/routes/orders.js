const express = require('express');
const router = express.Router();
const orderController = require('../controllers/orderController');
const { verifyToken } = require('../middlewares/authMiddleware');

router.use(verifyToken);

router.post('/checkout', orderController.checkoutOrder);
router.get('/my-orders', orderController.getMyOrders);
router.get('/', orderController.getMyOrders);
router.get('/:id', orderController.getOrderById);

module.exports = router;
