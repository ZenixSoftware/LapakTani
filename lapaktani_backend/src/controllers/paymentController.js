const crypto = require('crypto');
const midtransClient = require('midtrans-client');
const pool = require('../config/db');

// Initialize Midtrans CoreApi Client
const coreApi = new midtransClient.CoreApi({
  isProduction: false,
  serverKey: (process.env.MIDTRANS_SERVER_KEY || '').trim(),
  clientKey: (process.env.MIDTRANS_CLIENT_KEY || '').trim()
});

/**
 * Charge transaction using Midtrans Core API (US-14 & US-15)
 * Endpoint: POST /api/payments/charge
 */
const chargeMidtrans = async (req, res) => {
  const { order_id, gross_amount, payment_type = 'bank_transfer', bank = 'bca' } = req.body;

  if (!order_id) {
    return res.status(400).json({
      success: false,
      message: 'order_id wajib disertakan.'
    });
  }

  const numericAmount = Math.round(Number(gross_amount) || 0);
  if (numericAmount <= 0) {
    return res.status(400).json({
      success: false,
      message: 'gross_amount harus lebih besar dari 0.'
    });
  }

  const cleanType = String(payment_type).toLowerCase();
  const cleanBank = String(bank || 'bca').toLowerCase();

  let parameter = {
    payment_type: cleanType,
    transaction_details: {
      order_id: String(order_id),
      gross_amount: numericAmount
    }
  };

  if (cleanType === 'bank_transfer') {
    if (cleanBank === 'permata') {
      parameter.payment_type = 'permata';
    } else if (cleanBank === 'mandiri' || cleanBank === 'echannel') {
      parameter.payment_type = 'echannel';
      parameter.echannel = {
        bill_info1: 'Pembayaran',
        bill_info2: 'LapakTani'
      };
    } else {
      parameter.bank_transfer = {
        bank: cleanBank
      };
    }
  } else if (cleanType === 'qris' || cleanType === 'gopay') {
    parameter.payment_type = 'qris';
    parameter.qris = {
      acquirer: 'gopay'
    };
  }

  try {
    console.log('[MIDTRANS] Charging core API with parameter:', JSON.stringify(parameter));
    const chargeResponse = await coreApi.charge(parameter);
    console.log('[MIDTRANS] Charge response received:', JSON.stringify(chargeResponse));

    // Extract relevant payment references
    const vaNumber =
      chargeResponse.va_numbers?.[0]?.va_number ||
      chargeResponse.permata_va_number ||
      chargeResponse.bill_key ||
      null;

    const billCode = chargeResponse.biller_code || null;
    const qrUrl =
      chargeResponse.actions?.find((a) => a.name === 'generate-qr-code')?.url ||
      chargeResponse.qr_string ||
      null;
    const deepLink =
      chargeResponse.actions?.find((a) => a.name === 'deeplink-redirect')?.url || null;
    const expiryTime = chargeResponse.expiry_time || null;

    // Update order in database with payment references
    try {
      const channelLabel = cleanType === 'qris' ? 'QRIS' : `${cleanBank.toUpperCase()} Virtual Account`;
      const refString = vaNumber || qrUrl || chargeResponse.transaction_id || '';
      const expDate = expiryTime ? new Date(expiryTime) : null;

      await pool.query(
        `UPDATE orders 
         SET payment_channel = ?, 
             payment_reference = ?, 
             payment_expired_at = ?, 
             midtrans_transaction_id = ?, 
             updated_at = NOW() 
         WHERE id = ? OR invoice_number = ?`,
        [channelLabel, refString, expDate, chargeResponse.transaction_id, order_id, order_id]
      );
    } catch (dbErr) {
      console.warn('[MIDTRANS] Notice: Could not update orders table with metadata:', dbErr.message);
    }

    return res.status(200).json({
      success: true,
      message: 'Charge Midtrans berhasil diinisialisasi.',
      data: {
        order_id: String(order_id),
        transaction_id: chargeResponse.transaction_id,
        payment_type: cleanType,
        gross_amount: Number(chargeResponse.gross_amount || numericAmount),
        transaction_status: chargeResponse.transaction_status,
        va_number: vaNumber,
        bill_code: billCode,
        qr_url: qrUrl,
        deep_link: deepLink,
        expiry_time: expiryTime,
        raw_response: chargeResponse
      }
    });
  } catch (error) {
    console.error('MIDTRANS CHARGE ERROR:', error.ApiResponse || error.message);
    return res.status(500).json({
      success: false,
      message: error.message || 'Gagal memproses transaksi melalui Midtrans Core API.',
      error: error.ApiResponse || null
    });
  }
};

/**
 * Handle Midtrans Webhook Notification Callback
 * Endpoint: POST /api/payments/midtrans-callback
 */
const handleMidtransWebhook = async (req, res) => {
  const payload = req.body || {};
  console.log('[MIDTRANS-WEBHOOK] Received callback payload:', JSON.stringify(payload));

  const orderId = payload.order_id;
  const statusCode = String(payload.status_code || '200');
  const grossAmount = payload.gross_amount;
  const signatureKey = payload.signature_key;
  const transactionStatus = String(payload.transaction_status || '').toLowerCase();
  const fraudStatus = String(payload.fraud_status || '').toLowerCase();

  if (!orderId) {
    return res.status(400).json({
      success: false,
      message: 'order_id wajib disertakan.'
    });
  }

  // Verify SHA-512 Signature
  const serverKey = process.env.MIDTRANS_SERVER_KEY || '';
  const expectedSignature = crypto
    .createHash('sha512')
    .update(`${orderId}${statusCode}${grossAmount}${serverKey}`)
    .digest('hex');

  if (signatureKey && signatureKey.toLowerCase() !== expectedSignature.toLowerCase()) {
    console.warn(`[MIDTRANS-WEBHOOK] Signature mismatch for order ${orderId}. Expected ${expectedSignature}, got ${signatureKey}`);
    return res.status(403).json({
      success: false,
      message: 'Signature key tidak valid.'
    });
  }

  let connection;
  try {
    connection = await pool.getConnection();
    await connection.beginTransaction();

    const [orderRows] = await connection.query(
      'SELECT id, invoice_number, total_amount, payment_status, order_status FROM orders WHERE id = ? OR invoice_number = ? LIMIT 1 FOR UPDATE',
      [orderId, orderId]
    );

    if (orderRows.length === 0) {
      await connection.rollback();
      return res.status(404).json({
        success: false,
        message: `Pesanan dengan ID #${orderId} tidak ditemukan.`
      });
    }

    const order = orderRows[0];

    // Idempotency: If already marked as PAID, skip updating status
    if (order.payment_status === 'PAID' && (transactionStatus === 'settlement' || transactionStatus === 'capture')) {
      await connection.commit();
      return res.status(200).json({
        success: true,
        idempotent: true,
        message: 'Pesanan sudah berstatus PAID sebelumnya (Idempotent).'
      });
    }

    let newPaymentStatus = order.payment_status;
    let newOrderStatus = order.order_status;

    if (transactionStatus === 'capture') {
      if (fraudStatus === 'accept') {
        newPaymentStatus = 'PAID';
        newOrderStatus = 'PROCESSING';
      } else if (fraudStatus === 'challenge') {
        newPaymentStatus = 'CHALLENGE';
        newOrderStatus = 'WAITING_PAYMENT';
      }
    } else if (transactionStatus === 'settlement') {
      newPaymentStatus = 'PAID';
      newOrderStatus = 'PROCESSING';
    } else if (transactionStatus === 'pending') {
      newPaymentStatus = 'PENDING';
      newOrderStatus = 'WAITING_PAYMENT';
    } else if (['deny', 'cancel', 'expire'].includes(transactionStatus)) {
      newPaymentStatus = transactionStatus === 'expire' ? 'EXPIRED' : 'FAILED';
      newOrderStatus = 'CANCELLED';

      // Restore product stock if not previously cancelled/expired
      if (order.payment_status !== 'EXPIRED' && order.payment_status !== 'CANCELLED') {
        const [items] = await connection.query(
          'SELECT product_id, quantity FROM order_items WHERE order_id = ?',
          [order.id]
        );
        for (const item of items) {
          await connection.query(
            'UPDATE products SET stock_kg = stock_kg + ? WHERE id = ?',
            [item.quantity, item.product_id]
          );
        }
        console.log(`[MIDTRANS-WEBHOOK] Stock restored for cancelled/expired order: ${order.id}`);
      }
    }

    // Update order status in MySQL
    await connection.query(
      `UPDATE orders 
       SET payment_status = ?, 
           order_status = ?, 
           updated_at = NOW() 
       WHERE id = ? OR invoice_number = ?`,
      [newPaymentStatus, newOrderStatus, orderId, orderId]
    );

    // Synchronize payments table if present
    try {
      const paymentStatusEnum = newPaymentStatus === 'PAID' ? 'paid' : (newPaymentStatus === 'EXPIRED' || newPaymentStatus === 'FAILED' ? 'failed' : 'unpaid');
      await connection.query(
        `UPDATE payments 
         SET payment_status = ?, 
             paid_at = ${newPaymentStatus === 'PAID' ? 'NOW()' : 'paid_at'} 
         WHERE order_id = ?`,
        [paymentStatusEnum, order.id]
      );
    } catch (_) {}

    await connection.commit();
    console.log(`[MIDTRANS-WEBHOOK] Order ${order.id} updated successfully: Payment=${newPaymentStatus}, Order=${newOrderStatus}`);

    return res.status(200).json({
      success: true,
      message: 'Status pesanan berhasil diperbarui via webhook Midtrans.',
      data: {
        order_id: order.id,
        invoice_number: order.invoice_number,
        payment_status: newPaymentStatus,
        order_status: newOrderStatus
      }
    });
  } catch (error) {
    if (connection) await connection.rollback();
    console.error('[MIDTRANS-WEBHOOK] Error handling webhook:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan sistem saat memproses webhook Midtrans.'
    });
  } finally {
    if (connection) connection.release();
  }
};

/**
 * Check payment status against Midtrans and local database
 * Endpoint: GET /api/payments/status/:orderId
 */
const checkPaymentStatus = async (req, res) => {
  const orderId = req.params.orderId;

  if (!orderId) {
    return res.status(400).json({
      success: false,
      message: 'Parameter orderId wajib disertakan.'
    });
  }

  let midtransData = null;
  try {
    midtransData = await coreApi.transaction.status(orderId);
  } catch (midErr) {
    console.log(`[MIDTRANS] Status check note for ${orderId}:`, midErr.message);
  }

  try {
    const [orderRows] = await pool.query(
      `SELECT id, invoice_number, total_amount, shipping_fee, payment_method, 
              payment_status, order_status, payment_channel, payment_reference, 
              payment_expired_at, midtrans_transaction_id, created_at, updated_at 
       FROM orders 
       WHERE id = ? OR invoice_number = ? 
       LIMIT 1`,
      [orderId, orderId]
    );

    if (orderRows.length === 0) {
      return res.status(404).json({
        success: false,
        message: `Pesanan #${orderId} tidak ditemukan.`
      });
    }

    const order = orderRows[0];

    // If Midtrans reports settlement/capture and local DB is still PENDING, synchronize
    if (midtransData && midtransData.transaction_status) {
      const transStatus = String(midtransData.transaction_status).toLowerCase();
      if ((transStatus === 'settlement' || transStatus === 'capture') && order.payment_status !== 'PAID') {
        await pool.query(
          `UPDATE orders SET payment_status = 'PAID', order_status = 'PROCESSING', updated_at = NOW() WHERE id = ?`,
          [order.id]
        );
        order.payment_status = 'PAID';
        order.order_status = 'PROCESSING';
      }
    }

    return res.status(200).json({
      success: true,
      data: {
        order_id: order.id,
        invoice_number: order.invoice_number,
        payment_status: order.payment_status,
        order_status: order.order_status,
        payment_method: order.payment_method,
        payment_channel: order.payment_channel,
        payment_reference: order.payment_reference,
        payment_expired_at: order.payment_expired_at,
        total_amount: Number(order.total_amount || 0),
        midtrans_status: midtransData ? midtransData.transaction_status : null,
        midtrans_raw: midtransData
      }
    });
  } catch (error) {
    console.error('[PAYMENT] Error checking payment status:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal memeriksa status pembayaran pesanan.'
    });
  }
};

module.exports = {
  chargeMidtrans,
  handleMidtransWebhook,
  checkPaymentStatus
};
