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

    // 1. Verify stock availability and lock product rows
    for (const item of items) {
      const productId = item.product_id || item.productId || item.id;
      const quantity = Math.max(1, parseInt(item.quantity || item.qty || 1, 10));

      if (!productId) {
        await connection.rollback();
        return res.status(400).json({
          success: false,
          message: 'Item pesanan memiliki ID produk yang tidak valid.'
        });
      }

      // Query product with FOR UPDATE to prevent race condition overbooking
      const [productRows] = await connection.query(
        'SELECT id, title, price_per_kg, stock_kg, image_url, farmer_id FROM products WHERE id = ? FOR UPDATE',
        [productId]
      );

      if (productRows.length === 0) {
        await connection.rollback();
        return res.status(404).json({
          success: false,
          message: `Produk pertanian dengan ID #${productId} tidak ditemukan dalam etalase.`
        });
      }

      const product = productRows[0];
      const availableStock = Number(product.stock_kg || 0);

      if (availableStock < quantity) {
        await connection.rollback();
        return res.status(400).json({
          success: false,
          message: `Stok produk "${product.title}" tidak mencukupi (Tersedia: ${availableStock} kg, diminta: ${quantity} kg).`
        });
      }

      const pricePerUnit = Number(item.price_per_unit || item.price || product.price_per_kg || 0);
      const subtotal = pricePerUnit * quantity;
      itemsSubtotal += subtotal;

      validatedOrderItems.push({
        product_id: productId,
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

    // 2. Deduct ordered quantity from products.stock_kg
    for (const item of validatedOrderItems) {
      await connection.query(
        'UPDATE products SET stock_kg = GREATEST(0, stock_kg - ?) WHERE id = ?',
        [item.quantity, item.product_id]
      );
    }

    // 3. Deduct total cost from buyer's internal wallet balance (or demo balance simulator)
    let userWalletBalance = 2500000; // Default simulator balance
    let hasWalletColumn = false;

    try {
      const [walletRows] = await connection.query(
        'SELECT wallet_balance FROM user_profiles WHERE user_id = ? LIMIT 1',
        [userId]
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
        'UPDATE user_profiles SET wallet_balance = ? WHERE user_id = ?',
        [remainingBalance, userId]
      );
    }

    // 4. Insert record into orders table
    await connection.query(
      `INSERT INTO orders 
       (id, user_id, invoice_number, total_amount, payment_method, payment_status, order_status, delivery_address, shipping_fee, created_at, updated_at) 
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())`,
      [
        orderId,
        userId,
        invoiceNumber,
        totalAmount,
        payment_method || 'LAPAKPAY_SIMULATOR',
        'PAID',
        'PROCESSING',
        cleanAddress,
        numericShippingFee
      ]
    );

    // 5. Insert detail records into order_items table
    for (const item of validatedOrderItems) {
      const orderItemId = `OI-${uuidv4()}`;
      await connection.query(
        `INSERT INTO order_items 
         (id, order_id, product_id, grade_id, quantity, price_per_unit, subtotal, created_at) 
         VALUES (?, ?, ?, ?, ?, ?, ?, NOW())`,
        [
          orderItemId,
          orderId,
          item.product_id,
          item.grade_id,
          item.quantity,
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
    if (connection) {
      try {
        await connection.rollback();
        console.log('[ORDER] Transaction rolled back due to error:', error.message);
      } catch (rollbackErr) {
        console.error('[ORDER] Error during rollback:', rollbackErr.message);
      }
    }

    console.error('[ORDER] Error during checkout transaction:', error.message);
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
      WHERE o.user_id = ?
      ORDER BY o.created_at DESC`,
      [userId]
    );

    // Fetch items for each order
    for (const order of orders) {
      const [items] = await pool.query(
        `SELECT 
          oi.id,
          oi.product_id,
          oi.grade_id,
          oi.quantity,
          oi.price_per_unit,
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
      WHERE o.id = ? AND o.user_id = ?
      LIMIT 1`,
      [id, userId]
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
        oi.quantity,
        oi.price_per_unit,
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
