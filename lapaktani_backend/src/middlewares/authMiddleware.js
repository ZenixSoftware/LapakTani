const jwt = require('jsonwebtoken');
require('dotenv').config({ quiet: true });

const verifyToken = (req, res, next) => {
  const authHeader = req.headers.authorization || req.headers.Authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      success: false,
      message: 'Akses ditolak. Token tidak disediakan.'
    });
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'lapaktani_secret_2026');
    req.user = decoded;
    next();
  } catch (error) {
    return res.status(401).json({
      success: false,
      message: 'Token tidak valid atau telah kedaluwarsa.'
    });
  }
};

const requireRole = (...allowedRoles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Akses tidak sah. Token otentikasi diperlukan.'
      });
    }

    const userRole = (req.user.role || '').toLowerCase();
    const userRoleId = req.user.role_id;

    const isAuthorized = allowedRoles.some((role) => {
      if (typeof role === 'number') {
        return userRoleId === role;
      }
      const target = String(role).toLowerCase();
      return userRole === target || (target === 'penyuluh' && userRoleId === 2);
    });

    if (!isAuthorized) {
      return res.status(403).json({
        success: false,
        message: 'Akses ditolak. Anda tidak memiliki izin untuk mengakses resource ini.'
      });
    }

    next();
  };
};

module.exports = {
  verifyToken,
  requireRole
};
