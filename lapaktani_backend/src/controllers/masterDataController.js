const pool = require('../config/db');
const nodeCache = require('../utils/nodeCache');
const { applyNodeCacheHeader } = nodeCache;

/**
 * GET /api/master/commodities
 * Fetch list of specific commodities (L1 Node Cache enabled)
 */
const getCommodities = async (req, res) => {
  try {
    const cacheKey = 'master_commodities';
    const cached = nodeCache.get(cacheKey);
    if (cached !== null) {
      applyNodeCacheHeader(res, 'HIT');
      return res.status(200).json({
        success: true,
        source: 'node_cache',
        count: cached.length,
        data: cached
      });
    }

    const [rows] = await pool.query('SELECT id, specific_name FROM commodities ORDER BY specific_name ASC');
    nodeCache.set(cacheKey, rows, 600);
    applyNodeCacheHeader(res, 'MISS');

    return res.status(200).json({
      success: true,
      source: 'mysql_db',
      count: rows.length,
      data: rows
    });
  } catch (error) {
    console.error('[MASTER] Error fetching commodities:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal mengambil data komoditas.'
    });
  }
};

/**
 * GET /api/master/grades
 * Fetch list of product grades (L1 Node Cache enabled)
 */
const getProductGrades = async (req, res) => {
  try {
    const cacheKey = 'master_grades';
    const cached = nodeCache.get(cacheKey);
    if (cached !== null) {
      applyNodeCacheHeader(res, 'HIT');
      return res.status(200).json({
        success: true,
        source: 'node_cache',
        count: cached.length,
        data: cached
      });
    }

    const [rows] = await pool.query('SELECT id, grade_label FROM product_grades ORDER BY grade_label ASC');
    nodeCache.set(cacheKey, rows, 600);
    applyNodeCacheHeader(res, 'MISS');

    return res.status(200).json({
      success: true,
      source: 'mysql_db',
      count: rows.length,
      data: rows
    });
  } catch (error) {
    console.error('[MASTER] Error fetching grades:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal mengambil data grade produk.'
    });
  }
};

/**
 * GET /api/master/units
 * Fetch list of commodity units (L1 Node Cache enabled)
 */
const getUnits = async (req, res) => {
  try {
    const cacheKey = 'master_units';
    const cached = nodeCache.get(cacheKey);
    if (cached !== null) {
      applyNodeCacheHeader(res, 'HIT');
      return res.status(200).json({
        success: true,
        source: 'node_cache',
        count: cached.length,
        data: cached
      });
    }

    const [rows] = await pool.query('SELECT * FROM commodity_units ORDER BY id ASC');
    nodeCache.set(cacheKey, rows, 600);
    applyNodeCacheHeader(res, 'MISS');

    return res.status(200).json({
      success: true,
      source: 'mysql_db',
      count: rows.length,
      data: rows
    });
  } catch (error) {
    console.error('[MASTER] Error fetching units:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal mengambil data satuan komoditas.'
    });
  }
};

module.exports = {
  getCommodities,
  getProductGrades,
  getUnits
};
