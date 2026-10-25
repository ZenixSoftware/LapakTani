const express = require('express');
const router = express.Router();
const orderController = require('../controllers/orderController');
const { verifyToken } = require('../middlewares/authMiddleware');

// ==============================================================================
// PUBLIC ENDPOINTS (Payment Gateway Webhook & Simulator Callback)
// Midtrans / Xendit / Tripay webhooks do not send user JWT tokens
// ==============================================================================
router.post('/webhook', orderController.handlePaymentWebhook);
router.post('/payment/webhook', orderController.handlePaymentWebhook);
router.post('/:id/simulate-payment', orderController.simulatePaymentWebhook);

// ==============================================================================
// AUTHENTICATED ENDPOINTS (User JWT required)
// ==============================================================================
router.use(verifyToken);

router.post('/checkout', orderController.checkoutOrder);
router.get('/farmer/orders', verifyToken, orderController.getFarmerOrders);
router.put('/:id/status', verifyToken, orderController.updateOrderStatus);
router.get('/my-orders', orderController.getMyOrders);
router.get('/', orderController.getMyOrders);
router.get('/:id', orderController.getOrderById);
router.get('/:id/payment', orderController.getPaymentStatus);

module.exports = router;
