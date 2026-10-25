const crypto = require('crypto');
const { v4: uuidv4 } = require('uuid');
const pool = require('../config/db');

/**
 * Generate unique invoice number: INV/YYYYMMDD/TANI/<unique-hex>
 */
const generateInvoiceNumber = () => {
  const now = new Date();
  const yyyy = now.getFullYear();
  const mm = String(now.getMonth() + 1).padStart(2, '0');
  const dd = String(now.getDate()).padStart(2, '0');
  const hex = crypto.randomBytes(4).toString('hex').toUpperCase();
  return `INV/${yyyy}${mm}${dd}/TANI/${hex}`;
};

/**
 * Checkout Pemesanan & Pembuatan Invoice (US-13)
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

    // 3. Deduct total cost from buyer's internal wallet balance (or demo balance simulator)
    let userWalletBalance = 2500000; // Default simulator balance
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
    } catch (_) {
      // Column may not exist yet, fallback to simulator balance
    }

    if (userWalletBalance < totalAmount) {
      await connection.rollback();
      return res.status(400).json({
        success: false,
        message: `Saldo LapakPay tidak mencukupi. Saldo saat ini: Rp ${userWalletBalance.toLocaleString('id-ID')}, total tagihan: Rp ${totalAmount.toLocaleString('id-ID')}.`
      });
    }

    const remainingBalance = Math.max(0, userWalletBalance - totalAmount);

    if (hasWalletColumn) {
      await connection.query(
        'UPDATE user_profiles SET wallet_balance = ? WHERE id = ? OR user_id = ?',
        [remainingBalance, userId, userId]
      );
    }

    // 4. Insert record into orders table (dual-schema alignment for user_id/buyer_id and invoice_number/order_code)
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
        'PAID',
        'PROCESSING',
        cleanAddress,
        cleanAddress,
        numericShippingFee
      ]
    );

    // 5. Insert detail records into order_items table (dual-schema alignment for quantity/qty_kg and price_per_unit/unit_price)
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

    // 6. Delete checked-out items from cart_items for this user
    const productIds = validatedOrderItems.map((i) => i.product_id);
    if (productIds.length > 0) {
      const placeholders = productIds.map(() => '?').join(',');
      await connection.query(
        `DELETE FROM cart_items WHERE user_id = ? AND product_id IN (${placeholders})`,
        [userId, ...productIds]
      );
    }

    // 7. Commit transaction
    await connection.commit();

    console.log(`[ORDER] Checkout success: ${orderId} (${invoiceNumber}) for user: ${userId}, total: Rp ${totalAmount}`);

    return res.status(201).json({
      success: true,
      message: 'Transaksi berhasil diproses dengan LapakPay Simulator.',
      data: {
        id: orderId,
        order_id: orderId,
        invoice_number: invoiceNumber,
        total_amount: totalAmount,
        shipping_fee: numericShippingFee,
        items_subtotal: itemsSubtotal,
        payment_method: payment_method || 'LAPAKPAY_SIMULATOR',
        payment_status: 'PAID',
        order_status: 'PROCESSING',
        delivery_address: cleanAddress,
        courier_service: courier_service,
        wallet_balance_before: userWalletBalance,
        remaining_wallet_balance: remainingBalance,
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
 * Get buyer's orders list
 * Endpoint: GET /api/orders
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
    const [orders] = await pool.query(
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

    // Fetch items for each order
    for (const order of orders) {
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
      order.items = items;
    }

    return res.status(200).json({
      success: true,
      count: orders.length,
      data: orders
    });
  } catch (error) {
    console.error('[ORDER] Error fetching orders:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal mengambil riwayat transaksi pesanan.'
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
        COALESCE(o.updated_at, o.created_at) as updated_at
      FROM orders o
      WHERE o.id = ? AND (o.user_id = ? OR o.buyer_id = ?)
      LIMIT 1`,
      [id, userId, userId]
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

    order.items = items;

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

module.exports = {
  checkoutOrder,
  getMyOrders,
  getOrderById
};
