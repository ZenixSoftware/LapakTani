const jwt = require('jsonwebtoken');
require('dotenv').config({ quiet: true });

const ROLE_ID_MAP = {
  1: 'petani',
  2: 'penyuluh',
  3: 'admin',
  4: 'pembeli',
  5: 'dinas'
};

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

/**
 * Decodes JWT if present, otherwise proceeds with req.user undefined.
 * Useful for telemetry ingestion endpoints shared by IoT devices and logged-in farmers/PPL.
 */
const optionalVerifyToken = (req, res, next) => {
  const authHeader = req.headers.authorization || req.headers.Authorization;
  if (authHeader && authHeader.startsWith('Bearer ')) {
    const token = authHeader.split(' ')[1];
    try {
      req.user = jwt.verify(token, process.env.JWT_SECRET || 'lapaktani_secret_2026');
    } catch (_) {
      req.user = undefined;
    }
  }
  next();
};

const requireRole = (...allowedRoles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Akses tidak sah. Token otentikasi diperlukan.'
      });
    }

    const userRoleId = Number(req.user.role_id);
    const canonicalById = ROLE_ID_MAP[userRoleId] || '';
    const userRole = (req.user.role || canonicalById).toLowerCase();
    const isChairman = Boolean(req.user.is_chairman);

    const isAuthorized = allowedRoles.some((role) => {
      if (typeof role === 'number') {
        return userRoleId === role;
      }
      const target = String(role).toLowerCase();
      if (userRole === target || canonicalById === target) {
        return true;
      }
      if (target === 'penyuluh' && userRoleId === 2) return true;
      if (target === 'admin' && (userRoleId === 3 || isChairman)) return true;
      if (target === 'dinas' && userRoleId === 5) return true;
      if (target === 'petani' && userRoleId === 1) return true;
      if (target === 'pembeli' && userRoleId === 4) return true;
      return false;
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
  optionalVerifyToken,
  requireRole
};
