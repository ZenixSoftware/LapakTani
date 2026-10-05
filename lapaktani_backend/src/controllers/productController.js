const pool = require('../config/db');
const redisClient = require('../config/redis');

const getProducts = async (req, res) => {
  try {
    let cachedCatalog = null;
    try {
      cachedCatalog = await redisClient.get('catalog_products');
    } catch (redisErr) {
      console.warn('[REDIS] Cache get warning:', redisErr.message);
    }

    if (cachedCatalog) {
      const parsedData = JSON.parse(cachedCatalog);
      return res.status(200).json({
        success: true,
        source: 'redis_cache',
        count: parsedData.length,
        data: parsedData
      });
    }

    const [rows] = await pool.query(`
      SELECT 
        p.id, 
        p.farmer_id, 
        p.title, 
        p.description, 
        p.price, 
        p.stock, 
        p.image_url, 
        p.created_at,
        u.full_name AS farmer_name,
        u.email AS farmer_email
      FROM products p
      LEFT JOIN users u ON p.farmer_id = u.id
      ORDER BY p.created_at DESC
    `);

    try {
      await redisClient.setEx('catalog_products', 3600, JSON.stringify(rows));
    } catch (redisErr) {
      console.warn('[REDIS] Cache set warning:', redisErr.message);
    }

    return res.status(200).json({
      success: true,
      source: 'database',
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
    const { title, description, price, stock, image_url } = req.body;
    const farmerId = req.user.id;

    if (!title || price === undefined || price === null) {
      return res.status(400).json({
        success: false,
        message: 'Judul produk dan harga wajib diisi.'
      });
    }

    const numericPrice = parseFloat(price);
    const numericStock = parseInt(stock || 0, 10);

    if (isNaN(numericPrice) || numericPrice < 0) {
      return res.status(400).json({
        success: false,
        message: 'Harga produk harus berupa angka positif.'
      });
    }

    const [result] = await pool.query(
      `INSERT INTO products (farmer_id, title, description, price, stock, image_url)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [
        farmerId,
        title.trim(),
        description ? description.trim() : null,
        numericPrice,
        isNaN(numericStock) ? 0 : numericStock,
        image_url ? image_url.trim() : null
      ]
    );

    try {
      await redisClient.del('catalog_products');
    } catch (redisErr) {
      console.warn('[REDIS] Invalidation warning:', redisErr.message);
    }

    return res.status(201).json({
      success: true,
      message: 'Produk berhasil ditambahkan ke katalog.',
      data: {
        id: result.insertId,
        farmer_id: farmerId,
        title: title.trim(),
        description: description ? description.trim() : null,
        price: numericPrice,
        stock: isNaN(numericStock) ? 0 : numericStock,
        image_url: image_url ? image_url.trim() : null
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
