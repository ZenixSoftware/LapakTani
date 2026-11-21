const { v4: uuidv4 } = require('uuid');
const bcrypt = require('bcryptjs');
const pool = require('../config/db');
const redisClient = require('../config/redis');
const { signUserToken, ROLE_ID_MAP } = require('../middlewares/authMiddleware');
require('dotenv').config({ quiet: true });

const register = async (req, res) => {
  try {
    const { email, password, full_name, role } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Email dan password wajib diisi.'
      });
    }

    const requestedRole = role ? String(role).trim().toLowerCase() : 'pembeli';
    if (['dinas', 'penyuluh', 'superadmin'].includes(requestedRole)) {
      return res.status(403).json({
        success: false,
        code: 'AUTHORITY_REGISTRATION_LOCKED',
        message: 'Pendaftaran mandiri untuk peran Dinas, Penyuluh, dan Super Admin ditutup. Akun otoritas hanya dapat diterbitkan oleh Super Admin Sistem.'
      });
    }

    const [existingUsers] = await pool.query(
      'SELECT id FROM users WHERE email = ? LIMIT 1',
      [email.trim().toLowerCase()]
    );

    if (existingUsers.length > 0) {
      return res.status(409).json({
        success: false,
        message: 'Email sudah terdaftar. Silakan gunakan email lain.'
      });
    }

    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);

    const userId = uuidv4();
    const normalizedRole = role ? String(role).trim().toLowerCase() : 'pembeli';
    const isSellerRole = ['admin', 'penjual', 'seller'].includes(normalizedRole);
    const roleId = normalizedRole === 'petani' ? 1 : (isSellerRole ? 3 : 4);
    const assignedRole = roleId === 1 ? 'petani' : (roleId === 3 ? 'admin' : 'pembeli');
    const adminTier = roleId === 3 ? 'RETAIL_MERCHANT' : null;
    const isB2bVerified = false;
    const userName = full_name ? full_name.trim() : email.split('@')[0];

    const connection = await pool.getConnection();
    try {
      await connection.beginTransaction();

      await connection.query(
        `INSERT INTO users (id, email, password_hash, role_id, full_name, role, admin_tier, is_b2b_verified${roleId === 3 ? ', is_verified' : ''})
         VALUES (?, ?, ?, ?, ?, ?, ?, 0${roleId === 3 ? ', 1' : ''})`,
        [userId, email.trim().toLowerCase(), passwordHash, roleId, userName, assignedRole, adminTier]
      );

      const profileId = uuidv4();
      await connection.query(
        'INSERT INTO user_profiles (id, user_id, full_name) VALUES (?, ?, ?)',
        [profileId, userId, userName]
      );

      if (roleId === 3) {
        const storeId = `store-${uuidv4().slice(0, 10)}`;
        const resolvedStoreName = (req.body?.nama_toko && String(req.body.nama_toko).trim())
          ? String(req.body.nama_toko).trim()
          : `Lapak ${userName}`;
        const resolvedAddress = (req.body?.alamat_gudang && String(req.body.alamat_gudang).trim())
          ? String(req.body.alamat_gudang).trim()
          : 'Indonesia';
        await connection.query(
          `INSERT INTO store_applications
           (id, user_id, nama_toko, alamat_lengkap, status, admin_tier, auto_kyc_passed, b2b_status, is_b2b_verified, is_store_open)
           VALUES (?, ?, ?, ?, 'APPROVED', 'RETAIL_MERCHANT', 1, 'NONE', 0, 1)`,
          [storeId, userId, resolvedStoreName, resolvedAddress]
        );
      }

      await connection.commit();
    } catch (dbErr) {
      await connection.rollback();
      throw dbErr;
    } finally {
      connection.release();
    }

    const token = signUserToken({
      id: userId,
      email: email.trim().toLowerCase(),
      role_id: roleId,
      role: assignedRole,
      admin_tier: adminTier,
      is_b2b_verified: isB2bVerified,
      is_chairman: false
    });

    return res.status(201).json({
      success: true,
      message: roleId === 3
        ? 'Registrasi berhasil! Akun Penjual Retail Anda langsung aktif.'
        : 'Registrasi berhasil.',
      token,
      user: {
        id: userId,
        full_name: userName,
        email: email.trim().toLowerCase(),
        role_id: roleId,
        role: assignedRole,
        admin_tier: adminTier,
        is_b2b_verified: isB2bVerified,
        is_verified: roleId === 3
      }
    });
  } catch (error) {
    console.error('[AUTH] Error during registration:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan server saat registrasi.'
    });
  }
};

const ROLE_ID_TO_NAME = ROLE_ID_MAP;

const DEMO_ALIAS_PASSWORDS = {
  'superadmin@lapaktani.id': 'superadmin123',
  'penyuluh@lapaktani.id': 'penyuluh123',
  'dinas@lapaktani.id': 'dinas123',
  'admin@lapaktani.id': 'admin123',
  'retail@lapaktani.id': 'admin123',
  'made@poktan.lapaktani.id': 'admin123',
  'supardi@petani.lapaktani.id': 'petani123',
  'petani.supardi@lapaktani.id': 'petani123',
  'pembeli@lapaktani.id': 'pembeli123'
};

const resolveCanonicalRole = (user) => {
  const byId = ROLE_ID_TO_NAME[Number(user.role_id)];
  if (byId) return byId;
  return (user.role || 'pembeli').toLowerCase();
};

const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Email dan password wajib diisi.'
      });
    }

    const cleanEmail = email.trim().toLowerCase();
    const [users] = await pool.query(
      'SELECT * FROM users WHERE email = ? LIMIT 1',
      [cleanEmail]
    );

    if (users.length === 0) {
      return res.status(401).json({
        success: false,
        message: 'Email atau password salah.'
      });
    }

    const user = users[0];
    if (user.is_active === 0 || user.is_active === false) {
      return res.status(403).json({
        success: false,
        code: 'ACCOUNT_DEACTIVATED',
        message: 'Akun Anda sedang dinonaktifkan oleh Super Admin Sistem.'
      });
    }

    let isMatch = await bcrypt.compare(password, user.password_hash);

    // Allow documented role-alias demo passwords only for seeded demo accounts still using the default 'password123' hash
    if (!isMatch && DEMO_ALIAS_PASSWORDS[cleanEmail] === password) {
      isMatch = await bcrypt.compare('password123', user.password_hash);
    }

    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Email atau password salah.'
      });
    }

    const userRole = resolveCanonicalRole(user);

    let adminTier = user.admin_tier || null;
    if (userRole === 'admin' && !adminTier) {
      try {
        const [storeRows] = await pool.query(
          'SELECT admin_tier FROM store_applications WHERE user_id = ? LIMIT 1',
          [user.id]
        );
        adminTier = storeRows[0]?.admin_tier || 'B2B_OFFTAKER';
      } catch (_) {
        adminTier = 'B2B_OFFTAKER';
      }
    }

    let isChairman = userRole === 'admin' || Number(user.role_id) === 3;
    if (!isChairman && Number(user.role_id) === 1) {
      const [chairmanRows] = await pool.query(
        'SELECT 1 FROM farmer_groups WHERE chairman_user_id = ? LIMIT 1',
        [user.id]
      );
      isChairman = chairmanRows.length > 0;
    }

    const isB2bVerified = Boolean(user.is_b2b_verified) || (userRole === 'admin' && adminTier === 'B2B_OFFTAKER');
    const token = signUserToken({
      id: user.id,
      email: user.email,
      role_id: user.role_id,
      role: userRole,
      admin_tier: adminTier,
      is_b2b_verified: isB2bVerified,
      is_chairman: isChairman
    });

    await redisClient.setCache(
      `session_state:${user.id}`,
      {
        userId: user.id,
        role: userRole,
        role_id: user.role_id,
        admin_tier: adminTier,
        is_chairman: isChairman,
        lastLoginAt: new Date().toISOString()
      },
      86400
    ).catch(() => {});

    return res.status(200).json({
      success: true,
      message: 'Login berhasil.',
      token,
      user: {
        id: user.id,
        full_name: user.full_name,
        email: user.email,
        role_id: user.role_id,
        role: userRole,
        admin_tier: adminTier,
        is_b2b_verified: isB2bVerified,
        is_chairman: isChairman,
        is_verified: Boolean(user.is_verified)
      }
    });
  } catch (error) {
    console.error('[AUTH] Error during login:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan server saat login.'
    });
  }
};

module.exports = {
  register,
  login
};
