const { v4: uuidv4 } = require('uuid');
const pool = require('../config/db');

/**
 * Get all cart items for authenticated user
 * GET /api/cart
 */
const getCart = async (req, res) => {
  try {
    const userId = req.user ? req.user.id : null;
    if (!userId) {
      return res.status(401).json({
        success: false,
        message: 'Akses tidak sah. Token otentikasi diperlukan.'
      });
    }

    const query = `
      SELECT 
        ci.id,
        ci.user_id,
        ci.product_id,
        ci.grade_id,
        ci.quantity,
        ci.created_at,
        p.title as product_title,
        p.price_per_kg,
        p.stock_kg,
        p.image_url,
        p.farmer_id,
        c.specific_name as category_name,
        COALESCE(pg.grade_label, 'Grade A') as grade_label,
        COALESCE(cu.unit_name, 'kg') as unit_name,
        COALESCE(fg.group_name, u.full_name, 'Petani Mitra LapakTani') as farmer_name,
        COALESCE(v.name, 'Lembang, Bandung Barat') as origin_location
      FROM cart_items ci
      JOIN products p ON ci.product_id = p.id
      LEFT JOIN commodities c ON p.commodity_id = c.id
      LEFT JOIN product_grades pg ON ci.grade_id = pg.id OR (ci.grade_id IS NULL AND p.grade_id = pg.id)
      LEFT JOIN commodity_units cu ON p.unit_id = cu.id
      LEFT JOIN farmer_profiles fp ON p.farmer_id = fp.user_id
      LEFT JOIN farmer_groups fg ON fp.farmer_group_id = fg.id
      LEFT JOIN villages v ON fg.village_id = v.id
      LEFT JOIN users u ON p.farmer_id = u.id
      WHERE ci.user_id = ?
      ORDER BY ci.created_at DESC
    `;

    const [rows] = await pool.query(query, [userId]);

    const formatted = rows.map((row) => ({
      id: row.id,
      user_id: row.user_id,
      product_id: row.product_id,
      product_title: row.product_title,
      price_per_kg: Number(row.price_per_kg || 0),
      stock_kg: Number(row.stock_kg || 0),
      quantity: Number(row.quantity || 1),
      image_url: row.image_url,
      farmer_id: row.farmer_id,
      farmer_name: row.farmer_name,
      origin_location: row.origin_location,
      category_name: row.category_name,
      grade_label: row.grade_label,
      unit_name: row.unit_name,
      created_at: row.created_at
    }));

    return res.status(200).json({
      success: true,
      count: formatted.length,
      data: formatted
    });
  } catch (error) {
    console.error('[CART] Error fetching cart items:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal mengambil data keranjang belanja.'
    });
  }
};

/**
 * Add product to cart or increment quantity
 * POST /api/cart
 */
const addToCart = async (req, res) => {
  try {
    const userId = req.user ? req.user.id : null;
    if (!userId) {
      return res.status(401).json({
        success: false,
        message: 'Akses tidak sah. Token otentikasi diperlukan.'
      });
    }

    const rawProductId = req.body.product_id || req.body.productId || req.body.id;
    const rawQty = req.body.quantity !== undefined ? req.body.quantity : (req.body.qty !== undefined ? req.body.qty : 1);
    const gradeId = req.body.grade_id || req.body.gradeId;

    if (!rawProductId) {
      return res.status(400).json({
        success: false,
        message: 'Product ID wajib disertakan.'
      });
    }

    const productId = String(rawProductId).trim();
    if (productId.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Product ID tidak boleh kosong.'
      });
    }

    const numericQty = parseInt(rawQty, 10);
    if (isNaN(numericQty) || numericQty <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Kuantitas harus berupa angka positif.'
      });
    }

    // Verify product exists and check stock (handling string or integer coercion)
    const [products] = await pool.query(
      'SELECT id, title, stock_kg, grade_id FROM products WHERE id = ? OR CAST(id AS CHAR) = ? LIMIT 1',
      [productId, productId]
    );

    if (products.length === 0) {
      console.warn(`[CART] Product lookup failed for product_id: "${productId}" (user_id: "${userId}"). Product not found in database.`);
      return res.status(404).json({
        success: false,
        message: 'Produk tidak ditemukan.'
      });
    }

    const product = products[0];
    const resolvedProductId = product.id;
    const resolvedGradeId = gradeId || product.grade_id || null;

    // Check if already in cart for this user
    const [existing] = await pool.query(
      'SELECT id, quantity FROM cart_items WHERE user_id = ? AND product_id = ? LIMIT 1',
      [userId, resolvedProductId]
    );

    if (existing.length > 0) {
      const newQty = Number(existing[0].quantity) + numericQty;
      await pool.query(
        'UPDATE cart_items SET quantity = ?, grade_id = ? WHERE id = ?',
        [newQty, resolvedGradeId, existing[0].id]
      );

      return res.status(200).json({
        success: true,
        message: 'Kuantitas produk di keranjang berhasil diperbarui.',
        data: {
          id: existing[0].id,
          product_id: resolvedProductId,
          quantity: newQty
        }
      });
    }

    const cartItemId = uuidv4();
    await pool.query(
      `INSERT INTO cart_items (id, user_id, product_id, grade_id, quantity)
       VALUES (?, ?, ?, ?, ?)`,
      [cartItemId, userId, resolvedProductId, resolvedGradeId, numericQty]
    );

    return res.status(201).json({
      success: true,
      message: 'Produk berhasil ditambahkan ke keranjang belanja.',
      data: {
        id: cartItemId,
        product_id: resolvedProductId,
        quantity: numericQty
      }
    });
  } catch (error) {
    console.error('[CART] Error adding to cart:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal menambahkan produk ke keranjang.'
    });
  }
};

/**
 * Update cart item quantity
 * PUT /api/cart/:id
 */
const updateCartItem = async (req, res) => {
  try {
    const userId = req.user ? req.user.id : null;
    if (!userId) {
      return res.status(401).json({
        success: false,
        message: 'Akses tidak sah.'
      });
    }

    const { id } = req.params;
    const { quantity } = req.body;

    const numericQty = parseInt(quantity, 10);
    if (isNaN(numericQty) || numericQty < 0) {
      return res.status(400).json({
        success: false,
        message: 'Kuantitas tidak valid.'
      });
    }

    if (numericQty === 0) {
      await pool.query('DELETE FROM cart_items WHERE id = ? AND user_id = ?', [id, userId]);
      return res.status(200).json({
        success: true,
        message: 'Item berhasil dihapus dari keranjang.'
      });
    }

    const [result] = await pool.query(
      'UPDATE cart_items SET quantity = ? WHERE id = ? AND user_id = ?',
      [numericQty, id, userId]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({
        success: false,
        message: 'Item keranjang tidak ditemukan.'
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Kuantitas keranjang berhasil diubah.',
      data: { id, quantity: numericQty }
    });
  } catch (error) {
    console.error('[CART] Error updating cart item:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal mengubah kuantitas item keranjang.'
    });
  }
};

/**
 * Delete a specific cart item
 * DELETE /api/cart/:id
 */
const deleteCartItem = async (req, res) => {
  try {
    const userId = req.user ? req.user.id : null;
    if (!userId) {
      return res.status(401).json({
        success: false,
        message: 'Akses tidak sah.'
      });
    }

    const { id } = req.params;

    const [result] = await pool.query(
      'DELETE FROM cart_items WHERE id = ? AND user_id = ?',
      [id, userId]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({
        success: false,
        message: 'Item keranjang tidak ditemukan.'
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Item berhasil dihapus dari keranjang belanja.'
    });
  } catch (error) {
    console.error('[CART] Error deleting cart item:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal menghapus item dari keranjang.'
    });
  }
};

/**
 * Clear all cart items for authenticated user
 * DELETE /api/cart
 */
const clearCart = async (req, res) => {
  try {
    const userId = req.user ? req.user.id : null;
    if (!userId) {
      return res.status(401).json({
        success: false,
        message: 'Akses tidak sah.'
      });
    }

    await pool.query('DELETE FROM cart_items WHERE user_id = ?', [userId]);

    return res.status(200).json({
      success: true,
      message: 'Keranjang belanja berhasil dikosongkan.'
    });
  } catch (error) {
    console.error('[CART] Error clearing cart:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal mengosongkan keranjang.'
    });
  }
};

module.exports = {
  getCart,
  addToCart,
  updateCartItem,
  deleteCartItem,
  clearCart
};
