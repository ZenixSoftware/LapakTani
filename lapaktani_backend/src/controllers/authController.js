const { v4: uuidv4 } = require('uuid');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const pool = require('../config/db');
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
    const roleId = (role && role.toLowerCase() === 'petani') ? 1 : 4;
    const assignedRole = roleId === 1 ? 'petani' : 'pembeli';
    const userName = full_name ? full_name.trim() : email.split('@')[0];

    const connection = await pool.getConnection();
    try {
      await connection.beginTransaction();

      await connection.query(
        'INSERT INTO users (id, email, password_hash, role_id, full_name, role) VALUES (?, ?, ?, ?, ?, ?)',
        [userId, email.trim().toLowerCase(), passwordHash, roleId, userName, assignedRole]
      );

      const profileId = uuidv4();
      await connection.query(
        'INSERT INTO user_profiles (id, user_id, full_name) VALUES (?, ?, ?)',
        [profileId, userId, userName]
      );

      await connection.commit();
    } catch (dbErr) {
      await connection.rollback();
      throw dbErr;
    } finally {
      connection.release();
    }

    const token = jwt.sign(
      { id: userId, email: email.trim().toLowerCase(), role_id: roleId, role: assignedRole },
      process.env.JWT_SECRET || 'lapaktani_secret_2026',
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    return res.status(201).json({
      success: true,
      message: 'Registrasi berhasil.',
      token,
      user: {
        id: userId,
        full_name: userName,
        email: email.trim().toLowerCase(),
        role_id: roleId,
        role: assignedRole
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

const ROLE_ID_TO_NAME = {
  1: 'petani',
  2: 'penyuluh',
  3: 'admin',
  4: 'pembeli',
  5: 'dinas'
};

const DEMO_ALIAS_PASSWORDS = {
  'penyuluh@lapaktani.id': 'penyuluh123',
  'dinas@lapaktani.id': 'dinas123',
  'admin@lapaktani.id': 'admin123',
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

    let isChairman = userRole === 'admin' || Number(user.role_id) === 3;
    if (!isChairman && Number(user.role_id) === 1) {
      const [chairmanRows] = await pool.query(
        'SELECT 1 FROM farmer_groups WHERE chairman_user_id = ? LIMIT 1',
        [user.id]
      );
      isChairman = chairmanRows.length > 0;
    }

    const token = jwt.sign(
      { id: user.id, email: user.email, role_id: user.role_id, role: userRole, is_chairman: isChairman },
      process.env.JWT_SECRET || 'lapaktani_secret_2026',
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

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
