const { v4: uuidv4 } = require('uuid');
const pool = require('../config/db');
const redisClient = require('../config/redis');

const getProducts = async (req, res) => {
  try {
    if (redisClient.isOpen) {
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

    const query = `
      SELECT 
        p.id, 
        p.title, 
        p.price_per_kg, 
        p.stock_kg, 
        p.image_url, 
        c.specific_name as category, 
        pg.grade_label as grade, 
        fg.group_name as poktan_name, 
        v.name as village_name 
      FROM products p 
      JOIN commodities c ON p.commodity_id = c.id 
      JOIN product_grades pg ON p.grade_id = pg.id 
      JOIN farmer_profiles fp ON p.farmer_id = fp.user_id 
      JOIN farmer_groups fg ON fp.farmer_group_id = fg.id 
      JOIN villages v ON fg.village_id = v.id
    `;

    const [rows] = await pool.query(query);

    if (redisClient.isOpen) {
      try {
        await redisClient.setEx('lapaktani_catalog', 3600, JSON.stringify(rows));
      } catch (redisErr) {
        console.warn('[REDIS] Cache set warning:', redisErr.message);
      }
    }

    return res.status(200).json({
      success: true,
      source: 'mysql_db',
      count: rows.length,
      data: rows
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Gagal mengambil katalog produk.',
      error: error.message
    });
  }
};

const createProduct = async (req, res) => {
  try {
    const farmerId = req.user ? req.user.id : null;

    if (!farmerId) {
      return res.status(401).json({
        success: false,
        message: 'Akses tidak sah. ID petani tidak ditemukan dalam token.'
      });
    }

    const { title, price_per_kg, stock_kg, commodity_id, grade_id } = req.body;

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

    await pool.query(
      `INSERT INTO products (id, farmer_id, commodity_id, grade_id, title, price_per_kg, stock_kg)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [
        productId,
        farmerId,
        commodity_id,
        grade_id,
        title.trim(),
        numericPrice,
        numericStock
      ]
    );

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
        stock_kg: numericStock
      }
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Gagal menambahkan produk ke katalog.',
      error: error.message
    });
  }
};

module.exports = {
  getProducts,
  createProduct
};
