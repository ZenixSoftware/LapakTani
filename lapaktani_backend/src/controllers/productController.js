/**
 * ============================================================================
 * LAPAKTANI BACKEND - [US-07, US-08, US-09] PRODUCT & QUALITY GRADING ENGINE
 * ============================================================================
 * Module       : Controllers / Product & Mitra Catalog
 * User Stories : [US-07] Penambahan Komoditas & Varietas Pertanian
 *                [US-08] Multi-Tier Quality Grading (Grade A, B, Standard)
 *                [US-09] CRUD Stok/Harga Toko (Retail, Diskon, Partai/Grosir)
 * Author       : Moch. Ilham Abdul Aziz (MochIlham05 - 3125522014)
 * Architecture : Express.js 5.x, MySQL2 Connection Pool, Redis L2 Catalog Cache
 * ============================================================================
 */

const { v4: uuidv4 } = require('uuid');
const pool = require('../config/db');
const redisClient = require('../config/redis');

function formatProductPricing(row) {
  const basePrice = Number(row.price_per_kg || row.price || 0);
  const discountPercent = Number(row.discount_percent || 0);
  const rawDiscountPrice = row.discount_price !== null && row.discount_price !== undefined ? Number(row.discount_price) : null;
  const effectiveDiscountPrice =
    discountPercent > 0
      ? (rawDiscountPrice && rawDiscountPrice > 0 && rawDiscountPrice < basePrice
          ? rawDiscountPrice
          : Math.round(basePrice * (1 - discountPercent / 100)))
      : (rawDiscountPrice && rawDiscountPrice > 0 && rawDiscountPrice < basePrice ? rawDiscountPrice : null);
  const minWholesaleQty = Math.max(2, parseInt(row.min_wholesale_qty || 30, 10));
  const isWholesaleEnabled =
    row.is_wholesale_enabled === undefined || row.is_wholesale_enabled === null
      ? true
      : Boolean(Number(row.is_wholesale_enabled));
  const wholesalePrice =
    row.wholesale_price !== null && row.wholesale_price !== undefined && Number(row.wholesale_price) > 0
      ? Number(row.wholesale_price)
      : Math.round(basePrice * 0.85);

  return {
    ...row,
    price: basePrice,
    price_per_kg: basePrice,
    base_price: basePrice,
    discount_percent: discountPercent,
    discount_price: effectiveDiscountPrice,
    effective_retail_price: effectiveDiscountPrice || basePrice,
    is_wholesale_enabled: isWholesaleEnabled,
    min_wholesale_qty: minWholesaleQty,
    wholesale_price: wholesalePrice,
    store_village_id: row.store_village_id ? Number(row.store_village_id) : 101,
    processing_state: row.processing_state || 'SIAP_PAKAI',
    catalog_channel: row.catalog_channel || 'BOTH',
    fulfillment_options: row.fulfillment_options || 'BOTH',
    source_farmer_id: row.source_farmer_id || row.farmer_id || null,
    source_farmer_name: row.source_farmer_name || 'Pak Supardi (Poktan Harapan Sumenep)',
    in_cart_count: Number(row.in_cart_count || 0),
    in_cart_users_count: Number(row.in_cart_users_count || 0),
    in_cart_qty: Number(row.in_cart_qty || 0),
    in_cart_total_qty: Number(row.in_cart_total_qty || 0),
  };
}

function normalizePricingInput(basePrice, body = {}) {
  const rawDiscPct = body.discount_percent !== undefined ? parseFloat(body.discount_percent) : 0;
  const rawDiscPrice =
    body.discount_price !== undefined && body.discount_price !== null && String(body.discount_price).trim() !== ''
      ? parseFloat(body.discount_price)
      : null;

  let discountPercent = !isNaN(rawDiscPct) && rawDiscPct > 0 && rawDiscPct < 95 ? Number(rawDiscPct.toFixed(2)) : 0;
  let discountPrice = rawDiscPrice && !isNaN(rawDiscPrice) && rawDiscPrice > 0 && rawDiscPrice < basePrice ? rawDiscPrice : null;

  if (discountPercent > 0 && discountPrice === null) {
    discountPrice = Math.round(basePrice * (1 - discountPercent / 100));
  } else if (discountPrice !== null && discountPercent === 0 && basePrice > 0) {
    discountPercent = Number((((basePrice - discountPrice) / basePrice) * 100).toFixed(2));
  }

  const rawEnabled = body.is_wholesale_enabled;
  const isWholesaleEnabled =
    rawEnabled === false || rawEnabled === 0 || String(rawEnabled).toLowerCase() === 'false' || String(rawEnabled) === '0'
      ? 0
      : 1;

  const parsedMinQty = parseInt(body.min_wholesale_qty || 30, 10);
  const minWholesaleQty = !isNaN(parsedMinQty) && parsedMinQty >= 2 ? parsedMinQty : 30;

  const parsedWholesale =
    body.wholesale_price !== undefined && body.wholesale_price !== null && String(body.wholesale_price).trim() !== ''
      ? parseFloat(body.wholesale_price)
      : Math.round(basePrice * 0.85);
  const wholesalePrice = !isNaN(parsedWholesale) && parsedWholesale > 0 ? parsedWholesale : Math.round(basePrice * 0.85);

  return {
    discount_percent: discountPercent,
    discount_price: discountPrice,
    is_wholesale_enabled: isWholesaleEnabled,
    min_wholesale_qty: minWholesaleQty,
    wholesale_price: wholesalePrice,
  };
}

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

    if (!sanitizedSearch) {
      try {
        const cached = await redisClient.getCache('lapaktani_catalog');
        if (cached && cached.hit && Array.isArray(cached.value)) {
          res.setHeader('X-Redis-Cache', 'HIT');
          return res.status(200).json({
            success: true,
            source: 'redis_cache',
            cache_backend: cached.backend,
            count: cached.value.length,
            data: cached.value
          });
        }
      } catch (redisErr) {
        console.warn('[REDIS] Cache get warning:', redisErr.message);
      }
    }

    const whereClause = sanitizedSearch.length > 0
      ? ` WHERE (p.title LIKE ? OR c.specific_name LIKE ? OR pg.grade_label LIKE ? OR fg.group_name LIKE ? OR v.name LIKE ?)`
      : '';
    const params = sanitizedSearch.length > 0
      ? Array(5).fill(`%${sanitizedSearch}%`)
      : [];

    const primaryQuery = `
      SELECT 
        p.id, 
        p.farmer_id,
        p.title, 
        p.price_per_kg, 
        p.price,
        p.discount_percent,
        p.discount_price,
        p.is_wholesale_enabled,
        p.min_wholesale_qty,
        p.wholesale_price,
        p.store_village_id,
        p.processing_state,
        p.catalog_channel,
        p.fulfillment_options,
        p.source_farmer_id,
        p.source_farmer_name,
        p.stock_kg, 
        p.image_url, 
        p.unit_id,
        COALESCE(cu.unit_name, 'Kg') AS unit_name,
        cu.description AS unit_description,
        COALESCE(c.specific_name, 'Komoditas') AS category, 
        COALESCE(pg.grade_label, 'Reguler') AS grade, 
        COALESCE(fg.group_name, 'Mitra Tani') AS poktan_name, 
        COALESCE(v.name, 'Sumenep') AS village_name,
        COALESCE(cart_stats.in_cart_count, 0) AS in_cart_count,
        COALESCE(cart_stats.in_cart_count, 0) AS in_cart_users_count,
        COALESCE(cart_stats.in_cart_qty, 0) AS in_cart_qty,
        COALESCE(cart_stats.in_cart_qty, 0) AS in_cart_total_qty
      FROM products p 
      LEFT JOIN commodities c ON p.commodity_id = c.id 
      LEFT JOIN product_grades pg ON p.grade_id = pg.id 
      LEFT JOIN commodity_units cu ON p.unit_id = cu.id
      LEFT JOIN farmer_profiles fp ON p.farmer_id = fp.user_id 
      LEFT JOIN farmer_groups fg ON fp.farmer_group_id = fg.id 
      LEFT JOIN villages v ON fg.village_id = v.id
      LEFT JOIN (
        SELECT 
          product_id,
          COUNT(DISTINCT user_id) AS in_cart_count,
          COALESCE(SUM(quantity), 0) AS in_cart_qty
        FROM cart_items
        GROUP BY product_id
      ) cart_stats ON p.id = cart_stats.product_id
      ${whereClause}
      ORDER BY p.id DESC LIMIT 50
    `;

    let rows;
    try {
      [rows] = await pool.query(primaryQuery, params);
    } catch (queryErr) {
      if (queryErr.code === 'ER_BAD_FIELD_ERROR' || queryErr.code === 'ER_NO_SUCH_TABLE') {
        console.warn('[PRODUCTS] Primary query schema mismatch, using fallback:', queryErr.code, queryErr.sqlMessage || queryErr.message);
        const fallbackQuery = `
          SELECT 
            p.id, 
            p.title, 
            p.price_per_kg, 
            p.stock_kg, 
            p.image_url, 
            'Kg' AS unit_name,
            COALESCE(c.specific_name, 'Komoditas') AS category, 
            COALESCE(pg.grade_label, 'Reguler') AS grade, 
            COALESCE(fg.group_name, 'Mitra Tani') AS poktan_name, 
            COALESCE(v.name, 'Sumenep') AS village_name,
            0 AS in_cart_count,
            0 AS in_cart_users_count,
            0 AS in_cart_qty,
            0 AS in_cart_total_qty
          FROM products p 
          LEFT JOIN commodities c ON p.commodity_id = c.id 
          LEFT JOIN product_grades pg ON p.grade_id = pg.id 
          LEFT JOIN farmer_profiles fp ON p.farmer_id = fp.user_id 
          LEFT JOIN farmer_groups fg ON fp.farmer_group_id = fg.id 
          LEFT JOIN villages v ON fg.village_id = v.id
          ${whereClause}
          ORDER BY p.id DESC LIMIT 50
        `;
        [rows] = await pool.query(fallbackQuery, params);
      } else {
        throw queryErr;
      }
    }

    const formattedRows = rows.map(formatProductPricing);

    if (!sanitizedSearch) {
      try {
        await redisClient.setCache('lapaktani_catalog', formattedRows, 3600);
        res.setHeader('X-Redis-Cache', 'MISS');
      } catch (redisErr) {
        console.warn('[REDIS] Cache set warning:', redisErr.message);
      }
    } else {
      res.setHeader('X-Redis-Cache', 'BYPASS');
    }

    return res.status(200).json({
      success: true,
      source: 'mysql_db',
      count: formattedRows.length,
      data: formattedRows
    });
  } catch (error) {
    console.error('[getProducts Error]', error.code, error.message, error.sqlMessage || '');
    return res.status(500).json({
      success: false,
      message: 'Gagal mengambil katalog produk.',
      error_code: error.code || 'DB_ERROR'
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
        p.farmer_id,
        p.title, 
        p.price_per_kg, 
        p.price,
        p.discount_percent,
        p.discount_price,
        p.is_wholesale_enabled,
        p.min_wholesale_qty,
        p.wholesale_price,
        p.store_village_id,
        p.processing_state,
        p.catalog_channel,
        p.fulfillment_options,
        p.source_farmer_id,
        p.source_farmer_name,
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

    const formattedRows = rows.map(formatProductPricing);

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

    const {
      title,
      price_per_kg,
      price,
      stock_kg,
      commodity_id,
      grade_id,
      unit_id,
      description,
      image_url,
      image_urls,
      store_village_id,
      processing_state,
      catalog_channel,
      fulfillment_options,
      source_farmer_id,
      source_farmer_name,
      source_farmer_phone
    } = req.body;

    // Check B2B seller verification before allowing B2B_BID_LOT publishing
    let sellerIsB2bVerified = false;
    try {
      const [uTierRows] = await pool.query(
        'SELECT admin_tier, is_b2b_verified FROM users WHERE id = ? LIMIT 1',
        [farmerId]
      );
      sellerIsB2bVerified =
        Boolean(uTierRows[0]?.is_b2b_verified) ||
        uTierRows[0]?.admin_tier === 'B2B_OFFTAKER' ||
        String(req.user?.role || '').toLowerCase() !== 'admin';
    } catch (_) {
      sellerIsB2bVerified = Boolean(req.user?.is_b2b_verified);
    }

    const requestedChannel = String(catalog_channel || '').toUpperCase();
    if (requestedChannel === 'B2B_BID_LOT' && !sellerIsB2bVerified) {
      return res.status(403).json({
        success: false,
        code: 'B2B_VERIFICATION_REQUIRED',
        message: 'Penjualan lot B2B khusus untuk Penjual B2B Terverifikasi. Ajukan upgrade B2B terlebih dahulu.',
      });
    }

    const cleanProcessingState = ['MENTAH', 'SIAP_PAKAI'].includes(String(processing_state || '').toUpperCase())
      ? String(processing_state).toUpperCase()
      : 'SIAP_PAKAI';
    const cleanCatalogChannel = ['B2B_BID_LOT', 'RETAIL_CATALOG', 'BOTH'].includes(requestedChannel)
      ? (sellerIsB2bVerified ? requestedChannel : 'RETAIL_CATALOG')
      : (sellerIsB2bVerified ? 'BOTH' : 'RETAIL_CATALOG');
    const cleanFulfillmentOpts = ['DELIVERY_ONLY', 'PICKUP_ONLY', 'BOTH'].includes(String(fulfillment_options || '').toUpperCase())
      ? String(fulfillment_options).toUpperCase()
      : 'BOTH';

    const effectiveRawPrice = price_per_kg !== undefined && price_per_kg !== null ? price_per_kg : price;

    if (!title || String(title).trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Judul komoditas wajib diisi.'
      });
    }

    if (effectiveRawPrice === undefined || effectiveRawPrice === null || String(effectiveRawPrice).trim() === '') {
      return res.status(400).json({
        success: false,
        message: 'Harga per kg wajib diisi.'
      });
    }

    if (stock_kg === undefined || stock_kg === null || String(stock_kg).trim() === '') {
      return res.status(400).json({
        success: false,
        message: 'Stok komoditas wajib diisi.'
      });
    }

    const numericPrice = parseFloat(effectiveRawPrice);
    const numericStock = parseFloat(stock_kg);
    const pricing = normalizePricingInput(numericPrice, req.body);
    const villageId = store_village_id ? parseInt(store_village_id, 10) : 101;

    if (isNaN(numericPrice) || numericPrice < 0 || isNaN(numericStock) || numericStock < 0) {
      return res.status(400).json({
        success: false,
        message: 'Harga per kg dan stok kg harus berupa angka positif.'
      });
    }

    // Automatically associate farmer_id from req.user.id or farmer_profiles
    let [farmerProfiles] = await pool.query(
      'SELECT user_id, farmer_group_id FROM farmer_profiles WHERE user_id = ? LIMIT 1',
      [farmerId]
    );

    if (farmerProfiles.length === 0) {
      const [groups] = await pool.query('SELECT id FROM farmer_groups LIMIT 1');
      const fallbackGroupId = groups.length > 0 ? groups[0].id : '3be588df-b4b6-496b-aeac-efa43e3a7735';
      await pool.query(
        'INSERT INTO farmer_profiles (user_id, farmer_group_id) VALUES (?, ?) ON DUPLICATE KEY UPDATE farmer_group_id = VALUES(farmer_group_id)',
        [farmerId, fallbackGroupId]
      );
    }

    // Resolve commodity_id (fallback to first commodity if missing)
    let resolvedCommodityId = commodity_id;
    if (!resolvedCommodityId) {
      const [comms] = await pool.query('SELECT id FROM commodities LIMIT 1');
      resolvedCommodityId = comms.length > 0 ? comms[0].id : 'com-tomat';
    }

    // Resolve grade_id (fallback to grade-1 if missing)
    let resolvedGradeId = grade_id;
    if (!resolvedGradeId) {
      const [grds] = await pool.query('SELECT id FROM product_grades LIMIT 1');
      resolvedGradeId = grds.length > 0 ? grds[0].id : 'grade-1';
    }

    const productId = uuidv4();
    const selectedUnitId = unit_id || 'unit-kg';

    // Handle image path saving cleanly with default fallback placeholder if no file uploaded
    const DEFAULT_PLACEHOLDER = 'uploads/products/tomat.jpg';
    let fileUploadedPath = null;
    if (req.file) {
      fileUploadedPath = `uploads/products/${req.file.filename}`;
    }

    let formattedImageUrls = [];
    if (Array.isArray(image_urls)) {
      formattedImageUrls = image_urls.filter(url => typeof url === 'string' && url.trim().length > 0);
    } else if (typeof image_urls === 'string' && image_urls.trim().length > 0) {
      formattedImageUrls = [image_urls.trim()];
    }

    if (fileUploadedPath) {
      formattedImageUrls.unshift(fileUploadedPath);
    } else if (image_url && typeof image_url === 'string' && image_url.trim().length > 0 && !formattedImageUrls.includes(image_url.trim())) {
      formattedImageUrls.unshift(image_url.trim());
    }

    const primaryImageUrl = formattedImageUrls.length > 0 ? formattedImageUrls[0] : DEFAULT_PLACEHOLDER;
    if (formattedImageUrls.length === 0) {
      formattedImageUrls.push(DEFAULT_PLACEHOLDER);
    }

    await pool.query(
      `INSERT INTO products 
       (id, farmer_id, commodity_id, grade_id, unit_id, title, description, price_per_kg, stock_kg, price, stock, image_url, discount_percent, discount_price, is_wholesale_enabled, min_wholesale_qty, wholesale_price, store_village_id, processing_state, catalog_channel, fulfillment_options, source_farmer_id, source_farmer_name, source_farmer_phone, created_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())`,
      [
        productId,
        farmerId,
        resolvedCommodityId,
        resolvedGradeId,
        selectedUnitId,
        title.trim(),
        description ? String(description).trim() : null,
        numericPrice,
        numericStock,
        numericPrice,
        Math.floor(numericStock),
        primaryImageUrl,
        pricing.discount_percent,
        pricing.discount_price,
        pricing.is_wholesale_enabled,
        pricing.min_wholesale_qty,
        pricing.wholesale_price,
        villageId,
        cleanProcessingState,
        cleanCatalogChannel,
        cleanFulfillmentOpts,
        source_farmer_id || farmerId,
        source_farmer_name || req.user.full_name || 'Mitra Tani Sumenep',
        source_farmer_phone || '081234567890'
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

    await redisClient.delCache('lapaktani_catalog');

    return res.status(201).json({
      success: true,
      message: 'Produk berhasil ditambahkan ke katalog.',
      data: formatProductPricing({
        id: productId,
        farmer_id: farmerId,
        commodity_id: resolvedCommodityId,
        grade_id: resolvedGradeId,
        unit_id: selectedUnitId,
        title: title.trim(),
        price_per_kg: numericPrice,
        price: numericPrice,
        stock_kg: numericStock,
        image_url: primaryImageUrl,
        image_urls: formattedImageUrls,
        ...pricing,
        store_village_id: villageId,
        processing_state: cleanProcessingState,
        catalog_channel: cleanCatalogChannel,
        fulfillment_options: cleanFulfillmentOpts
      })
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

    await redisClient.delCache('lapaktani_catalog');

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
    const userRole = String(req.user?.role || '').toLowerCase();
    const { id } = req.params;

    if (!farmerId) {
      return res.status(401).json({
        success: false,
        message: 'Akses tidak sah. ID pengguna tidak ditemukan dalam token.'
      });
    }

    const {
      title,
      price_per_kg,
      price,
      stock_kg,
      commodity_id,
      grade_id,
      unit_id,
      description,
      image_url,
      image_urls,
      discount_percent,
      discount_price,
      is_wholesale_enabled,
      min_wholesale_qty,
      wholesale_price
    } = req.body;

    const isAdminStore = userRole === 'admin' || Number(req.user?.role_id) === 3;
    const [existing] = await pool.query(
      isAdminStore
        ? 'SELECT * FROM products WHERE id = ? LIMIT 1'
        : 'SELECT * FROM products WHERE id = ? AND farmer_id = ? LIMIT 1',
      isAdminStore ? [id] : [id, farmerId]
    );

    if (existing.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Produk tidak ditemukan atau bukan milik Anda.'
      });
    }
    const currentProduct = existing[0];

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

    const effectiveRawPrice = price_per_kg !== undefined && price_per_kg !== null ? price_per_kg : price;
    let resolvedBasePrice = Number(currentProduct.price_per_kg || currentProduct.price || 0);
    if (effectiveRawPrice !== undefined && effectiveRawPrice !== null) {
      const numPrice = parseFloat(effectiveRawPrice);
      if (isNaN(numPrice) || numPrice < 0) {
        return res.status(400).json({ success: false, message: 'Harga per kg harus angka positif.' });
      }
      resolvedBasePrice = numPrice;
      updates.push('price_per_kg = ?', 'price = ?');
      params.push(numPrice, numPrice);
    }

    const hasPricingChange =
      discount_percent !== undefined ||
      discount_price !== undefined ||
      is_wholesale_enabled !== undefined ||
      min_wholesale_qty !== undefined ||
      wholesale_price !== undefined;

    if (hasPricingChange) {
      const pricing = normalizePricingInput(resolvedBasePrice, {
        discount_percent: discount_percent !== undefined ? discount_percent : currentProduct.discount_percent,
        discount_price: discount_price !== undefined ? discount_price : (discount_percent !== undefined ? null : currentProduct.discount_price),
        is_wholesale_enabled: is_wholesale_enabled !== undefined ? is_wholesale_enabled : currentProduct.is_wholesale_enabled,
        min_wholesale_qty: min_wholesale_qty !== undefined ? min_wholesale_qty : currentProduct.min_wholesale_qty,
        wholesale_price: wholesale_price !== undefined ? wholesale_price : currentProduct.wholesale_price
      });
      updates.push(
        'discount_percent = ?',
        'discount_price = ?',
        'is_wholesale_enabled = ?',
        'min_wholesale_qty = ?',
        'wholesale_price = ?'
      );
      params.push(
        pricing.discount_percent,
        pricing.discount_price,
        pricing.is_wholesale_enabled,
        pricing.min_wholesale_qty,
        pricing.wholesale_price
      );
    }

    if (stock_kg !== undefined && stock_kg !== null) {
      const numStock = parseFloat(stock_kg);
      if (isNaN(numStock) || numStock < 0) {
        return res.status(400).json({ success: false, message: 'Stok kg harus angka positif.' });
      }
      updates.push('stock_kg = ?', 'stock = ?');
      params.push(numStock, Math.floor(numStock));
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
      params.push(id);
      await pool.query(`UPDATE products SET ${updates.join(', ')} WHERE id = ?`, params);
    }

    const [reloaded] = await pool.query('SELECT * FROM products WHERE id = ? LIMIT 1', [id]);

    await redisClient.delCache('lapaktani_catalog');

    return res.status(200).json({
      success: true,
      message: 'Produk dan pengaturan harga berhasil diperbarui.',
      data: reloaded[0] ? formatProductPricing(reloaded[0]) : null
    });
  } catch (error) {
    console.error('[PRODUCTS] Error updating product:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal memperbarui produk.'
    });
  }
};

const deductStock = async (req, res) => {
  const { id } = req.params;
  const { qty } = req.body;
  const numQty = parseFloat(qty);

  if (isNaN(numQty) || numQty <= 0) {
    return res.status(400).json({
      success: false,
      message: 'Jumlah pengurangan stok harus bernilai angka positif.'
    });
  }

  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    const [rows] = await connection.query('SELECT stock_kg FROM products WHERE id = ? FOR UPDATE', [id]);
    if (rows.length === 0) {
      await connection.rollback();
      return res.status(404).json({
        success: false,
        message: 'Produk tidak ditemukan.'
      });
    }

    const currentStock = parseFloat(rows[0].stock_kg);
    if (currentStock < numQty) {
      await connection.rollback();
      return res.status(400).json({
        success: false,
        message: 'Stok komoditas tidak mencukupi.'
      });
    }

    const newStock = Math.max(0, currentStock - numQty);
    await connection.query('UPDATE products SET stock_kg = ? WHERE id = ?', [newStock, id]);
    await connection.commit();

    await redisClient.delCache('lapaktani_catalog');

    return res.status(200).json({
      success: true,
      message: 'Pengurangan stok berhasil diproses.',
      data: {
        id,
        previous_stock: currentStock,
        deducted: numQty,
        remaining_stock: newStock
      }
    });
  } catch (error) {
    await connection.rollback();
    console.error('[PRODUCTS] Error deducting stock:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal memproses pengurangan stok.'
    });
  } finally {
    connection.release();
  }
};

const restoreStock = async (req, res) => {
  const { id } = req.params;
  const { qty } = req.body;
  const numQty = parseFloat(qty);

  if (isNaN(numQty) || numQty <= 0) {
    return res.status(400).json({
      success: false,
      message: 'Jumlah pengembalian stok harus bernilai angka positif.'
    });
  }

  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    const [rows] = await connection.query('SELECT stock_kg FROM products WHERE id = ? FOR UPDATE', [id]);
    if (rows.length === 0) {
      await connection.rollback();
      return res.status(404).json({
        success: false,
        message: 'Produk tidak ditemukan.'
      });
    }

    const currentStock = parseFloat(rows[0].stock_kg);
    const newStock = currentStock + numQty;
    await connection.query('UPDATE products SET stock_kg = ? WHERE id = ?', [newStock, id]);
    await connection.commit();

    await redisClient.delCache('lapaktani_catalog');

    return res.status(200).json({
      success: true,
      message: 'Pengembalian stok berhasil diproses.',
      data: {
        id,
        previous_stock: currentStock,
        restored: numQty,
        remaining_stock: newStock
      }
    });
  } catch (error) {
    await connection.rollback();
    console.error('[PRODUCTS] Error restoring stock:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal memproses pengembalian stok.'
    });
  } finally {
    connection.release();
  }
};


/**
 * Get soil telemetry & smart agri data for a product or farm
 * Endpoint: GET /api/soil/telemetry/:productId or GET /api/soil/:farm_id (US-26)
 */
const getSoilTelemetry = async (req, res) => {
  const targetId = req.params.productId || req.params.farm_id;

  if (!targetId) {
    return res.status(400).json({
      success: false,
      message: 'Parameter productId atau farm_id wajib disertakan.'
    });
  }

  try {
    const [rows] = await pool.query(
      `SELECT 
        p.id as product_id,
        p.title as product_title,
        p.farmer_id,
        COALESCE(p.farm_id, f.id, 'farm-default') as farm_id,
        COALESCE(f.land_area_ha, 2.50) as land_area_ha,
        f.gps_latitude,
        f.gps_longitude,
        COALESCE(f.soil_type, 'Vulkanik Subur') as soil_type,
        st.id as telemetry_id,
        COALESCE(st.ph_level, 6.40) as ph_level,
        COALESCE(st.nitrogen_mg_kg, 142.00) as nitrogen_mg_kg,
        COALESCE(st.phosphorus_mg_kg, 38.00) as phosphorus_mg_kg,
        COALESCE(st.potassium_mg_kg, 210.00) as potassium_mg_kg,
        COALESCE(st.moisture_percentage, 68.00) as moisture_percentage,
        COALESCE(st.fertility_index, 'SANGAT_SUBUR') as fertility_index,
        COALESCE(st.measured_by, 'Sensor NPK 8-in-1') as measured_by,
        COALESCE(st.created_at, NOW()) as telemetry_timestamp,
        fg.group_name as poktan_name,
        fg.leader_name as poktan_leader,
        v.name as village_name,
        u.full_name as farmer_name
      FROM products p
      LEFT JOIN farms f ON (p.farm_id = f.id OR f.farmer_id = p.farmer_id)
      LEFT JOIN soil_telemetries st ON st.farm_id = f.id
      LEFT JOIN farmer_profiles fp ON p.farmer_id = fp.user_id
      LEFT JOIN farmer_groups fg ON fp.farmer_group_id = fg.id
      LEFT JOIN villages v ON fg.village_id = v.id
      LEFT JOIN users u ON p.farmer_id = u.id
      WHERE p.id = ? OR f.id = ? OR st.farm_id = ?
      ORDER BY st.created_at DESC
      LIMIT 1`,
      [targetId, targetId, targetId]
    );

    const baseData = rows.length > 0 ? rows[0] : null;

    const phLevel = Number(baseData?.ph_level ?? 6.40);
    const nitrogen = Number(baseData?.nitrogen_mg_kg ?? 142.00);
    const phosphorus = Number(baseData?.phosphorus_mg_kg ?? 38.00);
    const potassium = Number(baseData?.potassium_mg_kg ?? 210.00);
    const moisture = Number(baseData?.moisture_percentage ?? 68.00);
    const rawFertility = String(baseData?.fertility_index ?? 'SANGAT_SUBUR').toUpperCase();

    let fertilityScore = 94;
    let fertilityLabel = 'Sangat Subur';
    if (rawFertility === 'OPTIMAL') {
      fertilityScore = 85;
      fertilityLabel = 'Optimal';
    } else if (rawFertility === 'KURANG_SUBUR') {
      fertilityScore = 65;
      fertilityLabel = 'Kurang Subur';
    } else if (rawFertility === 'KRITIS') {
      fertilityScore = 40;
      fertilityLabel = 'Kritis';
    }

    const temperatureCelsius = Number(baseData?.temperature_celsius ?? 27.8);
    const conductivity = Number(
      baseData?.conductivity ?? Math.round((nitrogen + phosphorus + potassium) * 3.1)
    );

    const telemetryData = {
      product_id: targetId,
      farm_id: baseData?.farm_id || 'farm-cikahuripan',
      blok_name: 'Blok A-3',
      fertility_score: fertilityScore,
      fertility_index: rawFertility,
      fertility_label: fertilityLabel,
      quality_grade: 'Kualitas Prima',
      ph_level: phLevel,
      ph_status: phLevel >= 6.0 && phLevel <= 6.8 ? 'Optimal Organik' : 'Perlu Penyesuaian',
      ph_ideal_range: '6.0 – 6.8',
      nitrogen_mg_kg: nitrogen,
      nitrogen_status: nitrogen >= 120 ? 'Baik' : 'Cukup',
      phosphorus_mg_kg: phosphorus,
      phosphorus_status: phosphorus >= 30 ? 'Sangat Baik' : 'Baik',
      potassium_mg_kg: potassium,
      potassium_status: potassium >= 180 ? 'Optimal' : 'Cukup',
      moisture_percentage: moisture,
      moisture_status: moisture >= 60 && moisture <= 75 ? 'Stabil / Cukup' : 'Perlu Irigasi',
      moisture_ideal_range: '60 – 75%',
      temperature_celsius: temperatureCelsius,
      conductivity,
      measured_by: baseData?.measured_by || 'Sensor NPK 8-in-1',
      validator: 'PPL Wilayah Binaan (Dinas Pertanian Kab. Bandung Barat)',
      poktan_name: baseData?.poktan_name || 'Poktan Tani Makmur',
      village_name: baseData?.village_name || 'Cikahuripan, Lembang (1.250 mdpl)',
      farmer_name: baseData?.farmer_name || 'Pak Wayan Sudirta',
      sync_protocol: 'Sync Otomatis LoRaWAN',
      last_updated: '2 jam yang lalu',
      created_at: baseData?.telemetry_timestamp || new Date().toISOString()
    };

    return res.status(200).json({
      success: true,
      data: telemetryData
    });
  } catch (error) {
    console.error('[SOIL_TELEMETRY] Error fetching telemetry data:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal mengambil data telemetri tanah lahan.'
    });
  }
};

/**
 * Save / record soil telemetry data from IoT sensor
 * Endpoint: POST /api/soil/telemetry (US-26)
 */
const saveSoilTelemetry = async (req, res) => {
  const {
    farm_id,
    ph_level,
    nitrogen_mg_kg,
    phosphorus_mg_kg,
    potassium_mg_kg,
    moisture_percentage,
    temperature_celsius,
    conductivity,
    fertility_index,
    measured_by
  } = req.body;

  const id = `tele-${uuidv4().substring(0, 8)}`;
  try {
    await pool.query(
      `INSERT INTO soil_telemetries 
        (id, farm_id, ph_level, nitrogen_mg_kg, phosphorus_mg_kg, potassium_mg_kg, moisture_percentage, temperature_celsius, fertility_index, measured_by, measured_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())`,
      [
        id,
        farm_id || 'farm-01',
        ph_level || 6.4,
        nitrogen_mg_kg || 142.0,
        phosphorus_mg_kg || 38.0,
        potassium_mg_kg || 210.0,
        moisture_percentage || 72.5,
        temperature_celsius || 21.5,
        fertility_index || 'Sangat Subur',
        measured_by || 'Sensor NPK 8-in-1'
      ]
    );

    return res.status(201).json({
      success: true,
      message: 'Data telemetri tanah lahan berhasil dicatat.',
      data: {
        id,
        farm_id: farm_id || 'farm-01',
        temperature_celsius: Number(temperature_celsius || 21.5),
        conductivity: Number(conductivity || 1200)
      }
    });
  } catch (error) {
    console.error('[SOIL_TELEMETRY] Error inserting telemetry data:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal mencatat data telemetri tanah.'
    });
  }
};

const convertRemainderToRetail = async (req, res) => {
  try {
    const userId = req.user?.id;
    const { id } = req.params;
    const { retail_price_per_kg, discount_percent } = req.body || {};

    const [rows] = await pool.query('SELECT * FROM products WHERE id = ? LIMIT 1', [id]);
    if (rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Produk tidak ditemukan.' });
    }
    const product = rows[0];
    const callerRole = String(req.user?.role || '').toLowerCase();
    if (String(product.farmer_id) !== String(userId) && !['admin', 'superadmin'].includes(callerRole)) {
      return res.status(403).json({ success: false, message: 'Tidak memiliki izin mengalihkan stok produk ini.' });
    }

    const updatedPrice =
      retail_price_per_kg !== undefined && Number(retail_price_per_kg) > 0
        ? Number(retail_price_per_kg)
        : Number(product.price_per_kg || product.price || 0);
    const discPct =
      discount_percent !== undefined ? Math.max(0, Math.min(90, Number(discount_percent) || 0)) : Number(product.discount_percent || 0);
    const discPrice = discPct > 0 ? Math.round(updatedPrice * (1 - discPct / 100)) : product.discount_price;

    await pool.query(
      `UPDATE products
       SET catalog_channel = 'BOTH',
           price_per_kg = ?,
           price = ?,
           discount_percent = ?,
           discount_price = ?
       WHERE id = ?`,
      [updatedPrice, updatedPrice, discPct, discPrice, id]
    );

    await redisClient.delCache('lapaktani_catalog');
    const [reloaded] = await pool.query('SELECT * FROM products WHERE id = ? LIMIT 1', [id]);

    return res.status(200).json({
      success: true,
      message: 'Sisa kuota lot B2B berhasil dialihkan ke etalase Retail untuk pembeli rumah tangga!',
      data: formatProductPricing(reloaded[0]),
    });
  } catch (error) {
    console.error('[PRODUCTS] Error converting B2B remainder to retail:', error.message);
    return res.status(500).json({ success: false, message: 'Gagal mengalihkan sisa stok ke retail.' });
  }
};

module.exports = {
  getProducts,
  getFarmerProducts,
  createProduct,
  deleteProduct,
  updateProduct,
  convertRemainderToRetail,
  deductStock,
  restoreStock,
  getSoilTelemetry,
  saveSoilTelemetry
};
