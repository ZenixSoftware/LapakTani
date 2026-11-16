const jwt = require('jsonwebtoken');
require('dotenv').config({ quiet: true });

const ROLE_ID_MAP = {
  1: 'petani',
  2: 'penyuluh',
  3: 'admin',
  4: 'pembeli',
  5: 'dinas'
};

const ROLE_NAME_TO_ID = {
  petani: 1,
  penyuluh: 2,
  admin: 3,
  pembeli: 4,
  dinas: 5
};

const getJwtSecret = () => process.env.JWT_SECRET || 'lapaktani_secret_2026';

/**
 * Sign a multi-role JWT across the 5 LapakTani roles (petani, penyuluh, admin, pembeli, dinas)
 */
const signUserToken = (userPayload = {}, options = {}) => {
  const normalizedRole = String(
    userPayload.role || ROLE_ID_MAP[Number(userPayload.role_id)] || 'pembeli'
  ).toLowerCase();
  const resolvedRoleId = Number(userPayload.role_id) || ROLE_NAME_TO_ID[normalizedRole] || 4;
  const payload = {
    id: userPayload.id,
    email: userPayload.email,
    role_id: resolvedRoleId,
    role: ROLE_ID_MAP[resolvedRoleId] || normalizedRole,
    is_chairman: Boolean(userPayload.is_chairman),
  };

  return jwt.sign(payload, getJwtSecret(), {
    expiresIn: options.expiresIn || process.env.JWT_EXPIRES_IN || '7d',
  });
};

/**
 * Verify a raw JWT string and return the decoded payload
 */
const verifyRawToken = (token) => {
  return jwt.verify(token, getJwtSecret());
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
    const decoded = verifyRawToken(token);
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
      req.user = verifyRawToken(token);
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
  requireRole,
  signUserToken,
  verifyRawToken,
  ROLE_ID_MAP,
  ROLE_NAME_TO_ID
};
