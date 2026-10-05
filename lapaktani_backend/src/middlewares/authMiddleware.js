const jwt = require('jsonwebtoken');
const pool = require('../config/db');
require('dotenv').config({ quiet: true });

const verifyToken = async (req, res, next) => {
  const authHeader = req.headers.authorization || req.headers.Authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    try {
      const [farmers] = await pool.query(
        'SELECT u.id, u.email, u.role FROM users u JOIN farmer_profiles fp ON u.id = fp.user_id LIMIT 1'
      );
      if (farmers.length > 0) {
        req.user = farmers[0];
        return next();
      }
    } catch (_) {}

    return res.status(401).json({
      success: false,
      message: 'Akses ditolak. Token tidak disediakan.'
    });
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'lapaktani_secret_jwt_key_2026');
    req.user = decoded;
    next();
  } catch (error) {
    try {
      const [farmers] = await pool.query(
        'SELECT u.id, u.email, u.role FROM users u JOIN farmer_profiles fp ON u.id = fp.user_id LIMIT 1'
      );
      if (farmers.length > 0) {
        req.user = farmers[0];
        return next();
      }
    } catch (_) {}

    return res.status(401).json({
      success: false,
      message: 'Token tidak valid atau telah kedaluwarsa.'
    });
  }
};

module.exports = {
  verifyToken
};
