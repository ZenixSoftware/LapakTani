const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/paymentController');
const { verifyToken } = require('../middlewares/authMiddleware');

// ==============================================================================
// PUBLIC ENDPOINT (Midtrans Webhook Callback)
// Midtrans callbacks arrive directly from Midtrans servers without user JWT
// ==============================================================================
router.post('/midtrans-callback', paymentController.handleMidtransWebhook);

// ==============================================================================
// AUTHENTICATED ENDPOINTS (User JWT required)
// ==============================================================================
router.post('/charge', verifyToken, paymentController.chargeMidtrans);
router.get('/status/:orderId', verifyToken, paymentController.checkPaymentStatus);

module.exports = router;
