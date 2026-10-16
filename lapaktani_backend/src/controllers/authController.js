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

const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Email dan password wajib diisi.'
      });
    }

    const [users] = await pool.query(
      'SELECT * FROM users WHERE email = ? LIMIT 1',
      [email.trim().toLowerCase()]
    );

    if (users.length === 0) {
      return res.status(401).json({
        success: false,
        message: 'Email atau password salah.'
      });
    }

    const user = users[0];
    const isMatch = await bcrypt.compare(password, user.password_hash);

    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Email atau password salah.'
      });
    }

    const userRole = user.role || (user.role_id === 1 ? 'petani' : 'pembeli');

    const token = jwt.sign(
      { id: user.id, email: user.email, role_id: user.role_id, role: userRole },
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
