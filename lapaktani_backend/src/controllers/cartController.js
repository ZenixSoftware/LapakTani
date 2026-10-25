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
        COALESCE(p.title, 'Komoditas Panen') AS title,
        COALESCE(p.title, 'Komoditas Panen') AS product_title,
        COALESCE(p.price_per_kg, p.price, 0) AS price_per_kg,
        COALESCE(p.price_per_kg, p.price, 0) AS price,
        COALESCE(p.image_url, 'uploads/products/tomat.jpg') AS image_url,
        COALESCE(p.stock_kg, p.stock, 10) AS stock_kg,
        COALESCE(p.farmer_id, 'farmer-1') AS farmer_id,
        COALESCE(fg.group_name, u.full_name, 'Petani LapakTani') AS poktan_name,
        COALESCE(fg.group_name, u.full_name, 'Petani LapakTani') AS farmer_name,
        COALESCE(v.name, 'Lembang, Jawa Barat') AS village_name,
        COALESCE(v.name, 'Lembang, Jawa Barat') AS origin_location,
        COALESCE(c.specific_name, 'Sayuran Segar') AS category_name,
        COALESCE(pg.grade_label, 'Grade A') AS grade_label,
        COALESCE(cu.unit_name, 'kg') AS unit_name
      FROM cart_items ci
      LEFT JOIN products p ON (ci.product_id = p.id OR CAST(ci.product_id AS CHAR) = CAST(p.id AS CHAR))
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
      grade_id: row.grade_id,
      quantity: Number(row.quantity || 1),
      title: row.title,
      product_title: row.product_title,
      price_per_kg: Number(row.price_per_kg || 0),
      price: Number(row.price || 0),
      image_url: row.image_url,
      stock_kg: Number(row.stock_kg || 10),
      farmer_id: row.farmer_id,
      poktan_name: row.poktan_name,
      farmer_name: row.farmer_name,
      village_name: row.village_name,
      origin_location: row.origin_location,
      category_name: row.category_name,
      grade_label: row.grade_label,
      unit_name: row.unit_name,
      created_at: row.created_at
    }));

    console.log(`[GET_CART] Found ${rows.length} items for user: ${userId}`);

    return res.status(200).json({
      success: true,
      count: formatted.length,
      data: formatted,
      items: formatted,
      cart: formatted
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
  updateCartQuantity: updateCartItem,
  deleteCartItem,
  removeFromCart: deleteCartItem,
  clearCart
};
