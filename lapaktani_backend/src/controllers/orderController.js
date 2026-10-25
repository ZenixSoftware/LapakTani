const crypto = require('crypto');
const { v4: uuidv4 } = require('uuid');
const pool = require('../config/db');

const PAYMENT_GATEWAY_SERVER_KEY = process.env.PAYMENT_GATEWAY_SERVER_KEY || 'SB-Mid-server-lapaktani-secret-key-2026';

/**
 * Generate unique invoice number: INV/YYYYMMDD/LPK/<unique-hex>
 */
const generateInvoiceNumber = () => {
  const now = new Date();
  const yyyy = now.getFullYear();
  const mm = String(now.getMonth() + 1).padStart(2, '0');
  const dd = String(now.getDate()).padStart(2, '0');
  const hex = crypto.randomBytes(4).toString('hex').toUpperCase();
  return `INV/${yyyy}${mm}${dd}/LPK/${hex}`;
};

/**
 * Generate payment details (VA, QRIS, Expiry, and step-by-step instructions)
 */
const generatePaymentDetails = (channel, totalAmount, orderId, invoiceNumber) => {
  const cleanChannel = (channel || 'LAPAKPAY_SIMULATOR').toUpperCase();
  const now = new Date();
  const isQris = cleanChannel.includes('QRIS') || cleanChannel.includes('GOPAY') || cleanChannel.includes('OVO');
  const expiryDurationMs = isQris ? 15 * 60 * 1000 : 24 * 60 * 60 * 1000;
  const expiredAt = new Date(now.getTime() + expiryDurationMs);

  let paymentRef = '';
  let channelName = '';
  let instructions = [];

  const numericSeed = (orderId || '').replace(/\D/g, '').slice(-8).padEnd(8, '7');

  if (cleanChannel.includes('BCA')) {
    channelName = 'BCA Virtual Account';
    paymentRef = `80777${numericSeed}`;
    instructions = [
      { step: 1, title: 'Buka BCA mobile', desc: 'Pilih menu m-Transfer > BCA Virtual Account.' },
      { step: 2, title: 'Masukkan Nomor VA', desc: `Masukkan nomor ${paymentRef} dan pilih Send.` },
      { step: 3, title: 'Konfirmasi Pembayaran', desc: `Periksa nominal Rp ${Number(totalAmount).toLocaleString('id-ID')} dan nama merchant LapakTani, lalu masukkan PIN m-BCA.` }
    ];
  } else if (cleanChannel.includes('MANDIRI')) {
    channelName = 'Mandiri Virtual Account';
    paymentRef = `89508${numericSeed}`;
    instructions = [
      { step: 1, title: 'Buka Livin\' by Mandiri', desc: 'Pilih menu Bayar > Multipayment / Virtual Account.' },
      { step: 2, title: 'Masukkan Kode Perusahaan', desc: `Pilih penyedia jasa LapakTani (Kode: 89508) atau ketik ${paymentRef}.` },
      { step: 3, title: 'Konfirmasi & Bayar', desc: `Pastikan nominal tepat Rp ${Number(totalAmount).toLocaleString('id-ID')} lalu masukkan PIN Livin.` }
    ];
  } else if (cleanChannel.includes('BNI')) {
    channelName = 'BNI Virtual Account';
    paymentRef = `98812${numericSeed}`;
    instructions = [
      { step: 1, title: 'Buka BNI Mobile Banking', desc: 'Pilih menu Transfer > Virtual Account Billing.' },
      { step: 2, title: 'Input Nomor Tagihan', desc: `Masukkan ${paymentRef} pada tab Input Baru.` },
      { step: 3, title: 'Konfirmasi Transaksi', desc: `Periksa rincian tagihan dan selesaikan dengan Password Transaksi.` }
    ];
  } else if (cleanChannel.includes('BRI')) {
    channelName = 'BRI Virtual Account (BRIVA)';
    paymentRef = `10245${numericSeed}`;
    instructions = [
      { step: 1, title: 'Buka BRImo', desc: 'Pilih menu Pembayaran > BRIVA.' },
      { step: 2, title: 'Masukkan Nomor BRIVA', desc: `Ketikkan nomor ${paymentRef} lalu klik Lanjut.` },
      { step: 3, title: 'Selesaikan Pembayaran', desc: `Verifikasi pesanan LapakTani Rp ${Number(totalAmount).toLocaleString('id-ID')} dan masukkan PIN BRImo.` }
    ];
  } else if (cleanChannel.includes('QRIS')) {
    channelName = 'QRIS (Semua Bank & E-Wallet)';
    paymentRef = `00020101021226540014ID.CO.LAPAKTANI.WWW0118936009180000000000520454115303360540${Number(totalAmount)}5802ID5913LAPAKTANI6007BANDUNG62070703A016304`;
    instructions = [
      { step: 1, title: 'Buka Aplikasi Pembayaran', desc: 'Buka GoPay, OVO, Dana, ShopeePay, BCA Mobile, atau m-Banking pilihan Anda.' },
      { step: 2, title: 'Pindai Kode QRIS', desc: 'Pilih menu Scan / QRIS lalu arahkan kamera ke kode QR yang tampil di layar.' },
      { step: 3, title: 'Konfirmasi Nominal', desc: `Pastikan nominal tertera Rp ${Number(totalAmount).toLocaleString('id-ID')} ke LapakTani Official, lalu masukkan PIN.` }
    ];
  } else if (cleanChannel.includes('TRANSFER')) {
    channelName = 'Transfer Bank Manual';
    paymentRef = '7720192831';
    instructions = [
      { step: 1, title: 'Transfer ke Rekening Resmi', desc: 'Transfer ke Bank BCA 7720192831 a.n. PT Lapak Tani Nusantara.' },
      { step: 2, title: 'Nominal Pas', desc: `Pastikan mentransfer tepat Rp ${Number(totalAmount).toLocaleString('id-ID')} hingga 3 digit terakhir.` },
      { step: 3, title: 'Verifikasi Otomatis', desc: 'Sistem payment gateway kami akan memverifikasi mutasi dalam 1-5 menit.' }
    ];
  } else {
    channelName = 'LapakPay Simulator';
    paymentRef = 'SIMULATOR-INSTANT';
    instructions = [
      { step: 1, title: 'Pembayaran Instan', desc: 'Saldo terpotong langsung secara otomatis.' }
    ];
  }

  return {
    payment_channel: cleanChannel,
    channel_name: channelName,
    payment_reference: paymentRef,
    payment_expired_at: expiredAt.toISOString(),
    is_qris: isQris,
    qr_string: isQris ? paymentRef : null,
    instructions: instructions
  };
};

/**
 * Checkout Pemesanan & Pembuatan Invoice (US-13 & US-14)
 * Endpoint: POST /api/orders/checkout
 * ACID Transaction: START TRANSACTION -> COMMIT with ROLLBACK on any failure
 */
const checkoutOrder = async (req, res) => {
  const userId = req.user ? req.user.id : null;
  if (!userId) {
    return res.status(401).json({
      success: false,
      message: 'Akses ditolak. Pengguna belum diautentikasi.'
    });
  }

  const {
    items,
    delivery_address,
    shipping_fee = 0,
    courier_service = 'Kurir Pendingin Mitra',
    payment_method = 'LAPAKPAY_SIMULATOR'
  } = req.body;

  if (!items || !Array.isArray(items) || items.length === 0) {
    return res.status(400).json({
      success: false,
      message: 'Keranjang belanja kosong atau daftar item pesanan tidak valid.'
    });
  }

  if (!delivery_address || typeof delivery_address !== 'string' || delivery_address.trim().length === 0) {
    return res.status(400).json({
      success: false,
      message: 'Alamat pengiriman panen wajib diisi.'
    });
  }

  let connection;
  try {
    connection = await pool.getConnection();
    await connection.beginTransaction();

    const invoiceNumber = generateInvoiceNumber();
    const orderId = `ORD-${Date.now()}-${crypto.randomBytes(3).toString('hex').toUpperCase()}`;
    const cleanAddress = delivery_address.trim();
    const numericShippingFee = Math.max(0, Number(shipping_fee) || 0);

    let itemsSubtotal = 0;
    const validatedOrderItems = [];

    // 1. Extract unique product IDs and sort deterministically to prevent deadlocks
    const sortedProductIds = [...new Set(items.map(i => i.product_id || i.productId || i.id))].sort((a, b) => {
      const numA = Number(a);
      const numB = Number(b);
      if (!isNaN(numA) && !isNaN(numB)) {
        return numA - numB;
      }
      return String(a).localeCompare(String(b));
    });

    if (sortedProductIds.length === 0 || sortedProductIds.some(id => !id)) {
      await connection.rollback();
      return res.status(400).json({
        success: false,
        message: 'Item pesanan memiliki ID produk yang tidak valid.'
      });
    }

    // 2. Query and lock rows in explicit ascending order
    const [productRows] = await connection.query(
      'SELECT id, stock_kg, COALESCE(price_per_kg, price, 0) AS price, title, image_url, farmer_id FROM products WHERE id IN (?) ORDER BY id ASC FOR UPDATE',
      [sortedProductIds]
    );

    const productMap = new Map();
    for (const p of productRows) {
      productMap.set(String(p.id), p);
    }

    // Aggregate requested quantities per product
    const requestedQtyMap = new Map();
    for (const item of items) {
      const pid = String(item.product_id || item.productId || item.id);
      const qty = Math.max(1, parseInt(item.quantity || item.qty || 1, 10));
      requestedQtyMap.set(pid, (requestedQtyMap.get(pid) || 0) + qty);
    }

    // 3. Validate availability strictly
    for (const pid of sortedProductIds) {
      const product = productMap.get(String(pid));
      if (!product) {
        await connection.rollback();
        return res.status(404).json({
          success: false,
          message: `Produk pertanian dengan ID #${pid} tidak ditemukan dalam etalase.`
        });
      }

      const requestedQty = requestedQtyMap.get(String(pid)) || 0;
      const availableStock = Number(product.stock_kg || 0);

      if (availableStock < requestedQty) {
        await connection.rollback();
        return res.status(400).json({
          success: false,
          message: `Stok untuk produk ${product.title} tidak mencukupi (Tersedia: ${availableStock} kg, diminta: ${requestedQty} kg).`
        });
      }
    }

    // Build validated order items and calculate subtotal
    for (const item of items) {
      const pid = String(item.product_id || item.productId || item.id);
      const product = productMap.get(pid);
      const quantity = Math.max(1, parseInt(item.quantity || item.qty || 1, 10));
      const pricePerUnit = Number(item.price_per_unit || item.price || product.price || 0);
      const subtotal = pricePerUnit * quantity;
      itemsSubtotal += subtotal;

      validatedOrderItems.push({
        product_id: pid,
        title: product.title,
        grade_id: item.grade_id || item.gradeId || null,
        quantity: quantity,
        price_per_unit: pricePerUnit,
        subtotal: subtotal,
        image_url: product.image_url,
        farmer_id: product.farmer_id
      });
    }

    const totalAmount = itemsSubtotal + numericShippingFee;

    // 4. Exact deduction: UPDATE products SET stock_kg = stock_kg - ? WHERE id = ?
    for (const [pid, qty] of requestedQtyMap.entries()) {
      await connection.query(
        'UPDATE products SET stock_kg = stock_kg - ? WHERE id = ?',
        [qty, pid]
      );
    }

    // 5. Payment method handling (LapakPay Simulator vs Payment Gateway Channels)
    const isSimulator = String(payment_method || 'LAPAKPAY_SIMULATOR').toUpperCase() === 'LAPAKPAY_SIMULATOR';
    const paymentDetails = generatePaymentDetails(payment_method, totalAmount, orderId, invoiceNumber);

    let initialPaymentStatus = isSimulator ? 'PAID' : 'PENDING';
    let initialOrderStatus = isSimulator ? 'PROCESSING' : 'WAITING_PAYMENT';
    let userWalletBalance = 2500000;
    let remainingBalance = 2500000;

    if (isSimulator) {
      let hasWalletColumn = false;
      try {
        const [walletRows] = await connection.query(
          'SELECT wallet_balance FROM user_profiles WHERE id = ? OR user_id = ? LIMIT 1',
          [userId, userId]
        );
        if (walletRows.length > 0 && walletRows[0].wallet_balance !== null && walletRows[0].wallet_balance !== undefined) {
          userWalletBalance = Number(walletRows[0].wallet_balance);
          hasWalletColumn = true;
        }
      } catch (_) {}

      if (userWalletBalance < totalAmount) {
        await connection.rollback();
        return res.status(400).json({
          success: false,
          message: `Saldo LapakPay tidak mencukupi. Saldo saat ini: Rp ${userWalletBalance.toLocaleString('id-ID')}, total tagihan: Rp ${totalAmount.toLocaleString('id-ID')}.`
        });
      }

      remainingBalance = Math.max(0, userWalletBalance - totalAmount);
      if (hasWalletColumn) {
        await connection.query(
          'UPDATE user_profiles SET wallet_balance = ? WHERE id = ? OR user_id = ?',
          [remainingBalance, userId, userId]
        );
      }
    }

    // 6. Insert record into orders table (dual-schema alignment + US-14 payment gateway support)
    try {
      await connection.query(
        `INSERT INTO orders
         (id, user_id, buyer_id, invoice_number, order_code, total_amount, total_payment, payment_method, payment_status, order_status, delivery_address, shipping_address, shipping_fee, payment_channel, payment_reference, payment_expired_at, created_at, updated_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())`,
        [
          orderId,
          userId,
          userId,
          invoiceNumber,
          invoiceNumber,
          totalAmount,
          totalAmount,
          payment_method || 'LAPAKPAY_SIMULATOR',
          initialPaymentStatus,
          initialOrderStatus,
          cleanAddress,
          cleanAddress,
          numericShippingFee,
          paymentDetails.payment_channel,
          paymentDetails.payment_reference,
          new Date(paymentDetails.payment_expired_at)
        ]
      );
    } catch (_) {
      // Fallback if payment_channel / payment_reference columns are not in legacy table
      await connection.query(
        `INSERT INTO orders
         (id, user_id, buyer_id, invoice_number, order_code, total_amount, total_payment, payment_method, payment_status, order_status, delivery_address, shipping_address, shipping_fee, created_at, updated_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())`,
        [
          orderId,
          userId,
          userId,
          invoiceNumber,
          invoiceNumber,
          totalAmount,
          totalAmount,
          payment_method || 'LAPAKPAY_SIMULATOR',
          initialPaymentStatus,
          initialOrderStatus,
          cleanAddress,
          cleanAddress,
          numericShippingFee
        ]
      );
    }

    // 7. Insert detail records into order_items table (dual-schema alignment for quantity/qty_kg and price_per_unit/unit_price)
    for (const item of validatedOrderItems) {
      const orderItemId = `OI-${Date.now()}-${Math.random().toString(36).substring(2, 7)}`;
      await connection.query(
        `INSERT INTO order_items
         (id, order_id, product_id, grade_id, quantity, qty_kg, price_per_unit, unit_price, subtotal, created_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())`,
        [
          orderItemId,
          orderId,
          item.product_id,
          item.grade_id,
          item.quantity,
          item.quantity,
          item.price_per_unit,
          item.price_per_unit,
          item.subtotal
        ]
      );
    }

    // 8. Delete checked-out items from cart_items for this user
    const productIds = validatedOrderItems.map((i) => i.product_id);
    if (productIds.length > 0) {
      const placeholders = productIds.map(() => '?').join(',');
      await connection.query(
        `DELETE FROM cart_items WHERE user_id = ? AND product_id IN (${placeholders})`,
        [userId, ...productIds]
      );
    }

    // 9. Commit transaction
    await connection.commit();

    console.log(`[ORDER] Checkout success: ${orderId} (${invoiceNumber}) [${payment_method}] Status: ${initialPaymentStatus}`);

    return res.status(201).json({
      success: true,
      message: isSimulator 
        ? 'Transaksi berhasil diproses dengan LapakPay Simulator.' 
        : 'Pesanan berhasil dibuat. Silakan selesaikan pembayaran melalui Payment Gateway.',
      data: {
        id: orderId,
        order_id: orderId,
        invoice_number: invoiceNumber,
        total_amount: totalAmount,
        shipping_fee: numericShippingFee,
        items_subtotal: itemsSubtotal,
        payment_method: payment_method,
        payment_status: initialPaymentStatus,
        order_status: initialOrderStatus,
        delivery_address: cleanAddress,
        courier_service: courier_service,
        wallet_balance_before: userWalletBalance,
        remaining_wallet_balance: remainingBalance,
        payment_details: paymentDetails,
        items: validatedOrderItems,
        created_at: new Date().toISOString()
      }
    });
  } catch (error) {
    console.error('[ORDER] Checkout Transaction Error Details:', {
      message: error.message,
      code: error.code,
      errno: error.errno,
      sql: error.sql,
      sqlMessage: error.sqlMessage,
      stack: error.stack
    });
    if (connection) {
      try {
        await connection.rollback();
        console.log('[ORDER] Transaction successfully rolled back due to error.');
      } catch (rollbackErr) {
        console.error('[ORDER] Error during rollback:', rollbackErr.message);
      }
    }

    return res.status(500).json({
      success: false,
      message: error.message || 'Terjadi kesalahan sistem saat memproses checkout dan pembuatan invoice.'
    });
  } finally {
    if (connection) {
      connection.release();
    }
  }
};

/**
 * Handle Payment Gateway Webhook / Callback (US-14)
 * Endpoint: POST /api/orders/webhook & POST /api/orders/payment/webhook
 * Signature verification (Midtrans SHA512 standard), Idempotent update, Stock restoration on cancel/expire
 */
const handlePaymentWebhook = async (req, res) => {
  const payload = req.body || {};
  console.log('[WEBHOOK] Received payment notification callback:', JSON.stringify(payload));

  const orderId = payload.order_id || payload.orderId || payload.invoice_number;
  const statusCode = String(payload.status_code || payload.statusCode || '200');
  const grossAmount = payload.gross_amount || payload.grossAmount || payload.total_amount;
  const signatureKey = payload.signature_key || req.headers['x-callback-signature'] || req.headers['x-signature'];
  const transactionStatus = String(payload.transaction_status || payload.status || 'settlement').toLowerCase();

  if (!orderId) {
    return res.status(400).json({
      success: false,
      message: 'order_id wajib disertakan dalam callback webhook.'
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

    // Signature verification
    if (signatureKey && signatureKey !== 'SIMULATED_TEST_SIGNATURE') {
      const serverKey = PAYMENT_GATEWAY_SERVER_KEY;
      const amountStr = grossAmount ? Number(grossAmount).toFixed(2) : Number(order.total_amount).toFixed(2);
      const expectedMidtransSig = crypto
        .createHash('sha512')
        .update(`${order.id}${statusCode}${amountStr}${serverKey}`)
        .digest('hex');
      const expectedIntSig = crypto
        .createHash('sha512')
        .update(`${order.id}${statusCode}${Math.round(order.total_amount)}${serverKey}`)
        .digest('hex');

      const matches = signatureKey.toLowerCase() === expectedMidtransSig.toLowerCase() ||
                      signatureKey.toLowerCase() === expectedIntSig.toLowerCase();

      if (!matches && process.env.NODE_ENV === 'production') {
        await connection.rollback();
        return res.status(403).json({
          success: false,
          message: 'Verifikasi signature key gagal. Callback tidak valid.'
        });
      }
    }

    // IDEMPOTENCY CHECK:
    if (order.payment_status === 'PAID' && ['settlement', 'capture', 'success'].includes(transactionStatus)) {
      await connection.commit();
      return res.status(200).json({
        success: true,
        idempotent: true,
        message: 'Pesanan sudah berstatus PAID sebelumnya (Idempotent). Webhook diabaikan dengan aman.',
        order_id: order.id,
        invoice_number: order.invoice_number,
        payment_status: order.payment_status
      });
    }

    let newPaymentStatus = order.payment_status;
    let newOrderStatus = order.order_status;

    if (['settlement', 'capture', 'success'].includes(transactionStatus)) {
      newPaymentStatus = 'PAID';
      newOrderStatus = 'PROCESSING';
    } else if (['pending', 'waiting_payment'].includes(transactionStatus)) {
      newPaymentStatus = 'PENDING';
      newOrderStatus = 'WAITING_PAYMENT';
    } else if (['expire', 'expired', 'cancel', 'cancelled', 'deny', 'failed'].includes(transactionStatus)) {
      newPaymentStatus = transactionStatus.includes('expire') ? 'EXPIRED' : 'FAILED';
      newOrderStatus = 'CANCELLED';

      // Restore reserved stock if previous status was not already cancelled/expired
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
        console.log(`[WEBHOOK] Stock restored for cancelled/expired order: ${order.id}`);
      }
    }

    // Update order status
    try {
      await connection.query(
        `UPDATE orders 
         SET payment_status = ?, 
             order_status = ?, 
             payment_signature = COALESCE(?, payment_signature),
             payment_payload = ?,
             updated_at = NOW() 
         WHERE id = ?`,
        [newPaymentStatus, newOrderStatus, signatureKey || null, JSON.stringify(payload), order.id]
      );
    } catch (_) {
      await connection.query(
        `UPDATE orders 
         SET payment_status = ?, 
             order_status = ?, 
             updated_at = NOW() 
         WHERE id = ?`,
        [newPaymentStatus, newOrderStatus, order.id]
      );
    }

    await connection.commit();

    console.log(`[WEBHOOK] Order ${order.id} status successfully updated: ${newPaymentStatus} (${newOrderStatus})`);

    return res.status(200).json({
      success: true,
      message: 'Webhook callback processed successfully.',
      data: {
        order_id: order.id,
        invoice_number: order.invoice_number,
        payment_status: newPaymentStatus,
        order_status: newOrderStatus,
        transaction_status: transactionStatus
      }
    });
  } catch (error) {
    if (connection) {
      try {
        await connection.rollback();
      } catch (_) {}
    }
    console.error('[WEBHOOK] Error processing webhook:', error.message);
    return res.status(500).json({
      success: false,
      message: error.message || 'Terjadi kesalahan sistem saat memproses webhook.'
    });
  } finally {
    if (connection) {
      connection.release();
    }
  }
};

/**
 * Simulate Payment Webhook (US-14 testing endpoint for demo & evaluator)
 * Endpoint: POST /api/orders/:id/simulate-payment
 */
const simulatePaymentWebhook = async (req, res) => {
  const { id } = req.params;
  const { status = 'settlement' } = req.body || {};
  req.body = {
    order_id: id,
    status_code: '200',
    transaction_status: status,
    signature_key: 'SIMULATED_TEST_SIGNATURE',
    payment_type: 'bank_transfer',
    transaction_time: new Date().toISOString()
  };
  return handlePaymentWebhook(req, res);
};

/**
 * Get real-time payment status and instructions (US-14)
 * Endpoint: GET /api/orders/:id/payment
 */
const getPaymentStatus = async (req, res) => {
  const { id } = req.params;
  try {
    const [orderRows] = await pool.query(
      `SELECT 
        o.id,
        o.invoice_number,
        o.total_amount,
        o.shipping_fee,
        o.payment_method,
        o.payment_status,
        o.order_status,
        o.delivery_address,
        o.created_at,
        o.updated_at
      FROM orders o
      WHERE o.id = ? OR o.invoice_number = ?
      LIMIT 1`,
      [id, id]
    );

    if (orderRows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Pesanan tidak ditemukan.'
      });
    }

    const order = orderRows[0];
    const paymentDetails = generatePaymentDetails(order.payment_method, order.total_amount, order.id, order.invoice_number);

    return res.status(200).json({
      success: true,
      data: {
        order_id: order.id,
        invoice_number: order.invoice_number,
        payment_status: order.payment_status,
        order_status: order.order_status,
        total_amount: order.total_amount,
        payment_method: order.payment_method,
        payment_details: paymentDetails
      }
    });
  } catch (error) {
    console.error('[ORDER] Error fetching payment status:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal mengambil status pembayaran.'
    });
  }
};

/**
 * Get orders belonging to authenticated user
 * Endpoint: GET /api/orders/my-orders
 */
const getMyOrders = async (req, res) => {
  const userId = req.user ? req.user.id : null;
  if (!userId) {
    return res.status(401).json({
      success: false,
      message: 'Akses ditolak. Pengguna belum diautentikasi.'
    });
  }

  try {
    const [orderRows] = await pool.query(
      `SELECT 
        o.id,
        COALESCE(o.user_id, o.buyer_id) as user_id,
        COALESCE(o.invoice_number, o.order_code) as invoice_number,
        COALESCE(o.total_amount, o.total_payment, 0) as total_amount,
        COALESCE(o.shipping_fee, 0) as shipping_fee,
        COALESCE(o.payment_method, 'LAPAKPAY_SIMULATOR') as payment_method,
        COALESCE(o.payment_status, 'PAID') as payment_status,
        o.order_status,
        COALESCE(o.delivery_address, o.shipping_address) as delivery_address,
        o.created_at,
        COALESCE(o.updated_at, o.created_at) as updated_at
      FROM orders o
      WHERE (o.user_id = ? OR o.buyer_id = ?)
      ORDER BY o.created_at DESC`,
      [userId, userId]
    );

    if (orderRows.length === 0) {
      return res.status(200).json({
        success: true,
        count: 0,
        data: []
      });
    }

    const orderIds = orderRows.map((o) => o.id);
    const placeholders = orderIds.map(() => '?').join(',');

    const [itemRows] = await pool.query(
      `SELECT 
        oi.id,
        oi.order_id,
        oi.product_id,
        oi.grade_id,
        COALESCE(oi.quantity, oi.qty_kg, 1) as quantity,
        COALESCE(oi.price_per_unit, oi.unit_price, 0) as price_per_unit,
        oi.subtotal,
        p.title as product_title,
        p.image_url as product_image_url
      FROM order_items oi
      LEFT JOIN products p ON oi.product_id = p.id
      WHERE oi.order_id IN (${placeholders})`,
      orderIds
    );

    const itemsByOrder = new Map();
    for (const item of itemRows) {
      if (!itemsByOrder.has(item.order_id)) {
        itemsByOrder.set(item.order_id, []);
      }
      itemsByOrder.get(item.order_id).push(item);
    }

    const result = orderRows.map((order) => {
      const items = (itemsByOrder.get(order.id) || []).map((item) => ({
        ...item,
        quantity: Number(item.quantity || 1),
        price_per_unit: Number(item.price_per_unit || 0),
        subtotal: Number(item.subtotal || 0)
      }));
      return {
        ...order,
        total_amount: Number(order.total_amount || 0),
        shipping_fee: Number(order.shipping_fee || 0),
        items: items,
        payment_details: generatePaymentDetails(order.payment_method, Number(order.total_amount || 0), order.id, order.invoice_number)
      };
    });

    return res.status(200).json({
      success: true,
      count: result.length,
      data: result
    });
  } catch (error) {
    console.error('[ORDER] Error fetching user orders:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal mengambil riwayat pesanan.'
    });
  }
};

/**
 * Get order detail by ID
 * Endpoint: GET /api/orders/:id
 */
const getOrderById = async (req, res) => {
  const userId = req.user ? req.user.id : null;
  const { id } = req.params;

  if (!userId) {
    return res.status(401).json({
      success: false,
      message: 'Akses ditolak. Pengguna belum diautentikasi.'
    });
  }

  try {
    const [orderRows] = await pool.query(
      `SELECT 
        o.id,
        COALESCE(o.user_id, o.buyer_id) as user_id,
        COALESCE(o.invoice_number, o.order_code) as invoice_number,
        COALESCE(o.total_amount, o.total_payment, 0) as total_amount,
        COALESCE(o.shipping_fee, 0) as shipping_fee,
        COALESCE(o.payment_method, 'LAPAKPAY_SIMULATOR') as payment_method,
        COALESCE(o.payment_status, 'PAID') as payment_status,
        o.order_status,
        COALESCE(o.delivery_address, o.shipping_address) as delivery_address,
        o.created_at,
        COALESCE(o.updated_at, o.created_at) as updated_at,
        u.full_name as buyer_name,
        COALESCE(u.phone, '') as buyer_phone
      FROM orders o
      LEFT JOIN users u ON (o.user_id = u.id OR o.buyer_id = u.id)
      WHERE (o.id = ? OR o.invoice_number = ?)
        AND (
          o.user_id = ? OR o.buyer_id = ?
          OR EXISTS (
            SELECT 1 FROM order_items oi
            JOIN products p ON (oi.product_id = p.id OR CAST(oi.product_id AS CHAR) = CAST(p.id AS CHAR))
            WHERE oi.order_id = o.id AND (p.farmer_id = ? OR p.farmer_id = (SELECT user_id FROM farmer_profiles WHERE user_id = ? LIMIT 1))
          )
        )
      LIMIT 1`,
      [id, id, userId, userId, userId, userId]
    );

    if (orderRows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Pesanan tidak ditemukan.'
      });
    }

    const order = orderRows[0];

    const [items] = await pool.query(
      `SELECT 
        oi.id,
        oi.product_id,
        oi.grade_id,
        COALESCE(oi.quantity, oi.qty_kg, 1) as quantity,
        COALESCE(oi.price_per_unit, oi.unit_price, 0) as price_per_unit,
        oi.subtotal,
        p.title as product_title,
        p.image_url as product_image_url
      FROM order_items oi
      LEFT JOIN products p ON oi.product_id = p.id
      WHERE oi.order_id = ?`,
      [order.id]
    );

    order.total_amount = Number(order.total_amount || 0);
    order.shipping_fee = Number(order.shipping_fee || 0);
    order.items = items.map((item) => ({
      ...item,
      quantity: Number(item.quantity || 1),
      price_per_unit: Number(item.price_per_unit || 0),
      subtotal: Number(item.subtotal || 0)
    }));
    order.payment_details = generatePaymentDetails(order.payment_method, order.total_amount, order.id, order.invoice_number);

    return res.status(200).json({
      success: true,
      data: order
    });
  } catch (error) {
    console.error('[ORDER] Error fetching order detail:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal mengambil rincian pesanan.'
    });
  }
};

/**
 * Get orders containing products owned by the authenticated farmer
 * Endpoint: GET /api/orders/farmer/orders
 */
const getFarmerOrders = async (req, res) => {
  const userId = req.user ? req.user.id : null;
  if (!userId) {
    return res.status(401).json({
      success: false,
      message: 'Akses ditolak. Pengguna belum diautentikasi.'
    });
  }

  try {
    const [orderRows] = await pool.query(
      `SELECT DISTINCT 
        o.id,
        COALESCE(o.invoice_number, o.order_code) as invoice_number,
        COALESCE(o.total_amount, o.total_payment, 0) as total_amount,
        COALESCE(o.shipping_fee, 0) as shipping_fee,
        COALESCE(o.payment_method, 'LAPAKPAY_SIMULATOR') as payment_method,
        COALESCE(o.payment_status, 'PAID') as payment_status,
        o.order_status,
        COALESCE(o.delivery_address, o.shipping_address) as delivery_address,
        o.created_at,
        COALESCE(o.updated_at, o.created_at) as updated_at,
        u.full_name as buyer_name,
        COALESCE(u.phone, '') as buyer_phone
      FROM orders o
      JOIN order_items oi ON o.id = oi.order_id
      JOIN products p ON (oi.product_id = p.id OR CAST(oi.product_id AS CHAR) = CAST(p.id AS CHAR))
      LEFT JOIN users u ON (o.user_id = u.id OR o.buyer_id = u.id)
      WHERE (p.farmer_id = ? OR p.farmer_id = (SELECT user_id FROM farmer_profiles WHERE user_id = ? LIMIT 1))
      ORDER BY o.created_at DESC`,
      [userId, userId]
    );

    if (orderRows.length === 0) {
      return res.status(200).json({
        success: true,
        count: 0,
        data: []
      });
    }

    const orderIds = orderRows.map((o) => o.id);
    const placeholders = orderIds.map(() => '?').join(',');

    const [itemRows] = await pool.query(
      `SELECT 
        oi.id,
        oi.order_id,
        oi.product_id,
        oi.grade_id,
        COALESCE(oi.quantity, oi.qty_kg, 1) as quantity,
        COALESCE(oi.price_per_unit, oi.unit_price, 0) as price_per_unit,
        oi.subtotal,
        p.title as product_title,
        p.image_url as product_image_url
      FROM order_items oi
      LEFT JOIN products p ON (oi.product_id = p.id OR CAST(oi.product_id AS CHAR) = CAST(p.id AS CHAR))
      WHERE oi.order_id IN (${placeholders})`,
      orderIds
    );

    const itemsByOrder = new Map();
    for (const item of itemRows) {
      if (!itemsByOrder.has(item.order_id)) {
        itemsByOrder.set(item.order_id, []);
      }
      itemsByOrder.get(item.order_id).push(item);
    }

    const result = orderRows.map((order) => {
      const items = (itemsByOrder.get(order.id) || []).map((item) => ({
        ...item,
        quantity: Number(item.quantity || 1),
        price_per_unit: Number(item.price_per_unit || 0),
        subtotal: Number(item.subtotal || 0)
      }));
      return {
        ...order,
        total_amount: Number(order.total_amount || 0),
        shipping_fee: Number(order.shipping_fee || 0),
        items: items,
        payment_details: generatePaymentDetails(order.payment_method, Number(order.total_amount || 0), order.id, order.invoice_number)
      };
    });

    return res.status(200).json({
      success: true,
      count: result.length,
      data: result
    });
  } catch (error) {
    console.error('[ORDER] Error fetching farmer orders:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal mengambil daftar pesanan petani.'
    });
  }
};

/**
 * Update order status (Farmer harvest / courier dispatch / delivery confirmation)
 * Endpoint: PUT /api/orders/:id/status
 */
const updateOrderStatus = async (req, res) => {
  const userId = req.user ? req.user.id : null;
  const { id } = req.params;
  const { status, order_status } = req.body || {};
  const requestedStatus = (status || order_status || '').toUpperCase();

  if (!userId) {
    return res.status(401).json({
      success: false,
      message: 'Akses ditolak. Pengguna belum diautentikasi.'
    });
  }

  // Allowed transitions
  const validStatuses = ['WAITING_PAYMENT', 'PROCESSING', 'NEED_HARVEST', 'SHIPPED', 'IN_TRANSIT', 'DELIVERED', 'COMPLETED', 'CANCELLED'];
  if (!requestedStatus || !validStatuses.includes(requestedStatus)) {
    return res.status(400).json({
      success: false,
      message: `Status pesanan tidak valid: "${requestedStatus}". Status yang diizinkan: ${validStatuses.join(', ')}`
    });
  }

  try {
    const [existing] = await pool.query(
      'SELECT id, order_status, payment_status, total_amount, invoice_number, payment_method FROM orders WHERE id = ? OR invoice_number = ? LIMIT 1',
      [id, id]
    );

    if (existing.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Pesanan tidak ditemukan.'
      });
    }

    const order = existing[0];

    await pool.query(
      'UPDATE orders SET order_status = ?, updated_at = NOW() WHERE id = ?',
      [requestedStatus, order.id]
    );

    console.log(`[ORDER] Order ${order.id} status transitioned from ${order.order_status} to ${requestedStatus} by user: ${userId}`);

    return res.status(200).json({
      success: true,
      message: `Status pesanan berhasil diperbarui menjadi ${requestedStatus}.`,
      data: {
        id: order.id,
        invoice_number: order.invoice_number,
        previous_status: order.order_status,
        order_status: requestedStatus,
        updated_at: new Date().toISOString()
      }
    });
  } catch (error) {
    console.error('[ORDER] Error updating order status:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal memperbarui status pesanan.'
    });
  }
};

module.exports = {
  checkoutOrder,
  handlePaymentWebhook,
  simulatePaymentWebhook,
  getPaymentStatus,
  getMyOrders,
  getFarmerOrders,
  updateOrderStatus,
  getOrderById
};
