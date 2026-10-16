const { v4: uuidv4 } = require('uuid');
const pool = require('../config/db');
const redisClient = require('../config/redis');

/**
 * Public catalog
 */
const getProducts = async (req, res) => {
  try {
    const search = req.query.search || req.query.query || req.query.q;

    let sanitizedSearch = '';
    if (search && typeof search === 'string') {
      const trimmed = search.trim();
      if (trimmed.length > 0) {
        const capped = trimmed.slice(0, 100);
        sanitizedSearch = capped.replace(/([%_\\])/g, '\\$1');
      }
    }

    if (!sanitizedSearch && redisClient.isOpen) {
      try {
        const cachedCatalog = await redisClient.get('lapaktani_catalog');
        if (cachedCatalog) {
          const parsedData = JSON.parse(cachedCatalog);
          return res.status(200).json({
            success: true,
            source: 'redis_cache',
            count: parsedData.length,
            data: parsedData
          });
        }
      } catch (redisErr) {
        console.warn('[REDIS] Cache get warning:', redisErr.message);
      }
    }

    let query = `
      SELECT 
        p.id, 
        p.title, 
        p.price_per_kg, 
        p.stock_kg, 
        p.image_url, 
        p.unit_id,
        cu.unit_name,
        cu.description as unit_description,
        c.specific_name as category, 
        pg.grade_label as grade, 
        fg.group_name as poktan_name, 
        v.name as village_name,
        COALESCE(cart_stats.in_cart_count, 0) AS in_cart_count,
        COALESCE(cart_stats.in_cart_count, 0) AS in_cart_users_count,
        COALESCE(cart_stats.in_cart_qty, 0) AS in_cart_qty,
        COALESCE(cart_stats.in_cart_qty, 0) AS in_cart_total_qty
      FROM products p 
      JOIN commodities c ON p.commodity_id = c.id 
      JOIN product_grades pg ON p.grade_id = pg.id 
      LEFT JOIN commodity_units cu ON p.unit_id = cu.id
      JOIN farmer_profiles fp ON p.farmer_id = fp.user_id 
      JOIN farmer_groups fg ON fp.farmer_group_id = fg.id 
      JOIN villages v ON fg.village_id = v.id
      LEFT JOIN (
        SELECT 
          product_id,
          COUNT(DISTINCT user_id) AS in_cart_count,
          COALESCE(SUM(quantity), 0) AS in_cart_qty
        FROM cart_items
        GROUP BY product_id
      ) cart_stats ON p.id = cart_stats.product_id
    `;
    const params = [];

    if (sanitizedSearch.length > 0) {
      query += ` WHERE (p.title LIKE ? OR c.specific_name LIKE ? OR pg.grade_label LIKE ? OR fg.group_name LIKE ? OR v.name LIKE ?)`;
      const searchPattern = `%${sanitizedSearch}%`;
      params.push(searchPattern, searchPattern, searchPattern, searchPattern, searchPattern);
    }

    query += ` ORDER BY p.id DESC LIMIT 50`;

    const [rows] = await pool.query(query, params);

    const formattedRows = rows.map(row => ({
      ...row,
      in_cart_count: Number(row.in_cart_count || 0),
      in_cart_users_count: Number(row.in_cart_users_count || 0),
      in_cart_qty: Number(row.in_cart_qty || 0),
      in_cart_total_qty: Number(row.in_cart_total_qty || 0)
    }));

    if (!sanitizedSearch && redisClient.isOpen) {
      try {
        await redisClient.setEx('lapaktani_catalog', 3600, JSON.stringify(formattedRows));
      } catch (redisErr) {
        console.warn('[REDIS] Cache set warning:', redisErr.message);
      }
    }

    return res.status(200).json({
      success: true,
      source: 'mysql_db',
      count: formattedRows.length,
      data: formattedRows
    });
  } catch (error) {
    console.error('[PRODUCTS] Error fetching catalog:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal mengambil katalog produk.'
    });
  }
};

/**
 * Farmer Products (GET /api/products/me)
 */
const getFarmerProducts = async (req, res) => {
  try {
    const farmerId = req.user ? req.user.id : null;

    if (!farmerId) {
      return res.status(401).json({
        success: false,
        message: 'Akses tidak sah. ID petani tidak ditemukan dalam token.'
      });
    }

    const query = `
      SELECT 
        p.id, 
        p.title, 
        p.price_per_kg, 
        p.stock_kg, 
        p.image_url, 
        p.description,
        p.commodity_id,
        p.grade_id,
        p.unit_id,
        cu.unit_name,
        cu.description as unit_description,
        c.specific_name as category, 
        c.specific_name as commodity_name,
        pg.grade_label as grade, 
        p.created_at,
        COALESCE(cart_stats.in_cart_count, 0) AS in_cart_count,
        COALESCE(cart_stats.in_cart_count, 0) AS in_cart_users_count,
        COALESCE(cart_stats.in_cart_qty, 0) AS in_cart_qty,
        COALESCE(cart_stats.in_cart_qty, 0) AS in_cart_total_qty
      FROM products p 
      LEFT JOIN commodities c ON p.commodity_id = c.id 
      LEFT JOIN product_grades pg ON p.grade_id = pg.id 
      LEFT JOIN commodity_units cu ON p.unit_id = cu.id
      LEFT JOIN (
        SELECT 
          product_id,
          COUNT(DISTINCT user_id) AS in_cart_count,
          COALESCE(SUM(quantity), 0) AS in_cart_qty
        FROM cart_items
        GROUP BY product_id
      ) cart_stats ON p.id = cart_stats.product_id
      WHERE p.farmer_id = ?
      ORDER BY p.created_at DESC
      LIMIT 100
    `;

    const [rows] = await pool.query(query, [farmerId]);

    const formattedRows = rows.map(row => ({
      ...row,
      in_cart_count: Number(row.in_cart_count || 0),
      in_cart_users_count: Number(row.in_cart_users_count || 0),
      in_cart_qty: Number(row.in_cart_qty || 0),
      in_cart_total_qty: Number(row.in_cart_total_qty || 0)
    }));

    return res.status(200).json({
      success: true,
      count: formattedRows.length,
      data: formattedRows
    });
  } catch (error) {
    console.error('[PRODUCTS] Error fetching farmer products:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal mengambil produk petani.'
    });
  }
};

/**
 * Create Product (POST /api/products)
 */
const createProduct = async (req, res) => {
  try {
    const farmerId = req.user ? req.user.id : null;

    if (!farmerId) {
      return res.status(401).json({
        success: false,
        message: 'Akses tidak sah. ID petani tidak ditemukan dalam token.'
      });
    }

    const { title, price_per_kg, stock_kg, commodity_id, grade_id, unit_id, description, image_url, image_urls } = req.body;

    if (
      !title ||
      price_per_kg === undefined ||
      price_per_kg === null ||
      stock_kg === undefined ||
      stock_kg === null ||
      !commodity_id ||
      !grade_id
    ) {
      return res.status(400).json({
        success: false,
        message: 'Field title, price_per_kg, stock_kg, commodity_id, dan grade_id wajib diisi.'
      });
    }

    const numericPrice = parseFloat(price_per_kg);
    const numericStock = parseFloat(stock_kg);

    if (isNaN(numericPrice) || numericPrice < 0 || isNaN(numericStock) || numericStock < 0) {
      return res.status(400).json({
        success: false,
        message: 'Harga per kg dan stok kg harus berupa angka positif.'
      });
    }

    const [farmerProfiles] = await pool.query(
      'SELECT user_id, farmer_group_id FROM farmer_profiles WHERE user_id = ? LIMIT 1',
      [farmerId]
    );

    if (farmerProfiles.length === 0) {
      return res.status(403).json({
        success: false,
        message: 'Profil petani tidak ditemukan. Silakan lengkapi profil petani terlebih dahulu.'
      });
    }

    const productId = uuidv4();
    const selectedUnitId = unit_id || 'unit-kg';

    let formattedImageUrls = [];
    if (Array.isArray(image_urls)) {
      formattedImageUrls = image_urls.filter(url => typeof url === 'string' && url.trim().length > 0);
    } else if (typeof image_urls === 'string' && image_urls.trim().length > 0) {
      formattedImageUrls = [image_urls.trim()];
    }

    if (image_url && typeof image_url === 'string' && image_url.trim().length > 0 && !formattedImageUrls.includes(image_url.trim())) {
      formattedImageUrls.unshift(image_url.trim());
    }

    const primaryImageUrl = formattedImageUrls.length > 0 ? formattedImageUrls[0] : (image_url || null);

    await pool.query(
      `INSERT INTO products (id, farmer_id, commodity_id, grade_id, unit_id, title, price_per_kg, stock_kg, description, image_url)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        productId,
        farmerId,
        commodity_id,
        grade_id,
        selectedUnitId,
        title.trim(),
        numericPrice,
        numericStock,
        description || null,
        primaryImageUrl
      ]
    );

    if (formattedImageUrls.length > 0) {
      for (let i = 0; i < formattedImageUrls.length; i++) {
        const imgId = uuidv4();
        const imgUrl = formattedImageUrls[i];
        const isPrimary = i === 0;
        await pool.query(
          `INSERT INTO product_images (id, product_id, image_url, is_primary) VALUES (?, ?, ?, ?)`,
          [imgId, productId, imgUrl, isPrimary]
        );
      }
    }

    if (redisClient.isOpen) {
      try {
        await redisClient.del('lapaktani_catalog');
      } catch (redisErr) {
        console.warn('[REDIS] Invalidation warning:', redisErr.message);
      }
    }

    return res.status(201).json({
      success: true,
      message: 'Produk berhasil ditambahkan ke katalog.',
      data: {
        id: productId,
        farmer_id: farmerId,
        commodity_id,
        grade_id,
        title: title.trim(),
        price_per_kg: numericPrice,
        stock_kg: numericStock,
        image_url: primaryImageUrl,
        image_urls: formattedImageUrls
      }
    });

  } catch (error) {
    console.error('[PRODUCTS] Error creating product:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal menambahkan produk ke katalog.'
    });
  }
};

/**
 * Delete Product (DELETE /api/products/:id)
 */
const deleteProduct = async (req, res) => {
  try {
    const farmerId = req.user ? req.user.id : null;
    const { id } = req.params;

    if (!farmerId) {
      return res.status(401).json({
        success: false,
        message: 'Akses tidak sah. ID pengguna tidak ditemukan dalam token.'
      });
    }

    const [existing] = await pool.query(
      'SELECT id FROM products WHERE id = ? AND farmer_id = ? LIMIT 1',
      [id, farmerId]
    );

    if (existing.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Produk tidak ditemukan atau bukan milik Anda.'
      });
    }

    await pool.query('DELETE FROM products WHERE id = ? AND farmer_id = ?', [id, farmerId]);

    if (redisClient.isOpen) {
      try {
        await redisClient.del('lapaktani_catalog');
      } catch (redisErr) {
        console.warn('[REDIS] Invalidation warning:', redisErr.message);
      }
    }

    return res.status(200).json({
      success: true,
      message: 'Produk berhasil dihapus.'
    });
  } catch (error) {
    console.error('[PRODUCTS] Error deleting product:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal menghapus produk.'
    });
  }
};

/**
 * Update Product (PUT /api/products/:id)
 */
const updateProduct = async (req, res) => {
  try {
    const farmerId = req.user ? req.user.id : null;
    const { id } = req.params;

    if (!farmerId) {
      return res.status(401).json({
        success: false,
        message: 'Akses tidak sah. ID pengguna tidak ditemukan dalam token.'
      });
    }

    const { title, price_per_kg, stock_kg, commodity_id, grade_id, unit_id, description, image_url, image_urls } = req.body;

    const [existing] = await pool.query(
      'SELECT id FROM products WHERE id = ? AND farmer_id = ? LIMIT 1',
      [id, farmerId]
    );

    if (existing.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Produk tidak ditemukan atau bukan milik Anda.'
      });
    }

    const updates = [];
    const params = [];

    if (image_urls !== undefined && Array.isArray(image_urls)) {
      await pool.query('DELETE FROM product_images WHERE product_id = ?', [id]);
      for (let i = 0; i < image_urls.length; i++) {
        const imgId = uuidv4();
        const isPrimary = i === 0;
        await pool.query(
          'INSERT INTO product_images (id, product_id, image_url, is_primary) VALUES (?, ?, ?, ?)',
          [imgId, id, image_urls[i], isPrimary]
        );
      }
      if (image_urls.length > 0 && image_url === undefined) {
        updates.push('image_url = ?');
        params.push(image_urls[0]);
      }
    }

    if (title !== undefined && title !== null) {
      updates.push('title = ?');
      params.push(String(title).trim());
    }
    if (price_per_kg !== undefined && price_per_kg !== null) {
      const numPrice = parseFloat(price_per_kg);
      if (isNaN(numPrice) || numPrice < 0) {
        return res.status(400).json({ success: false, message: 'Harga per kg harus angka positif.' });
      }
      updates.push('price_per_kg = ?');
      params.push(numPrice);
    }
    if (stock_kg !== undefined && stock_kg !== null) {
      const numStock = parseFloat(stock_kg);
      if (isNaN(numStock) || numStock < 0) {
        return res.status(400).json({ success: false, message: 'Stok kg harus angka positif.' });
      }
      updates.push('stock_kg = ?');
      params.push(numStock);
    }
    if (commodity_id !== undefined && commodity_id !== null) {
      updates.push('commodity_id = ?');
      params.push(commodity_id);
    }
    if (grade_id !== undefined && grade_id !== null) {
      updates.push('grade_id = ?');
      params.push(grade_id);
    }
    if (unit_id !== undefined && unit_id !== null) {
      updates.push('unit_id = ?');
      params.push(unit_id);
    }
    if (description !== undefined) {
      updates.push('description = ?');
      params.push(description);
    }
    if (image_url !== undefined) {
      updates.push('image_url = ?');
      params.push(image_url);
    }

    if (updates.length > 0) {
      params.push(id, farmerId);
      await pool.query(`UPDATE products SET ${updates.join(', ')} WHERE id = ? AND farmer_id = ?`, params);
    }

    if (redisClient.isOpen) {
      try {
        await redisClient.del('lapaktani_catalog');
      } catch (redisErr) {
        console.warn('[REDIS] Invalidation warning:', redisErr.message);
      }
    }

    return res.status(200).json({
      success: true,
      message: 'Produk berhasil diperbarui.'
    });
  } catch (error) {
    console.error('[PRODUCTS] Error updating product:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal memperbarui produk.'
    });
  }
};

module.exports = {
  getProducts,
  getFarmerProducts,
  createProduct,
  deleteProduct,
  updateProduct
};
