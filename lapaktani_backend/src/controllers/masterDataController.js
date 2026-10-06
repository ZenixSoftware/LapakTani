const pool = require('../config/db');

/**
 * GET /api/master/commodities
 * Fetch list of specific commodities
 */
const getCommodities = async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT id, specific_name FROM commodities ORDER BY specific_name ASC');
    return res.status(200).json({
      success: true,
      count: rows.length,
      data: rows
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Gagal mengambil data komoditas.',
      error: error.message
    });
  }
};

/**
 * GET /api/master/grades
 * Fetch list of product grades
 */
const getProductGrades = async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT id, grade_label FROM product_grades ORDER BY grade_label ASC');
    return res.status(200).json({
      success: true,
      count: rows.length,
      data: rows
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Gagal mengambil data grade produk.',
      error: error.message
    });
  }
};

/**
 * GET /api/master/units
 * Fetch list of commodity units
 */
const getUnits = async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM commodity_units ORDER BY id ASC');
    return res.status(200).json({
      success: true,
      count: rows.length,
      data: rows
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Gagal mengambil data satuan komoditas.',
      error: error.message
    });
  }
};

module.exports = {
  getCommodities,
  getProductGrades,
  getUnits
};
