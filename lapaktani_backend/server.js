const express = require('express');
const cors = require('cors');
require('dotenv').config();

const pool = require('./src/config/db');
const redisClient = require('./src/config/redis');
const authRoutes = require('./src/routes/auth');
const productRoutes = require('./src/routes/products');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.get('/', (req, res) => {
  res.status(200).json({
    status: 'online',
    service: 'LapakTani Local REST API',
    version: '1.0.0',
    timestamp: new Date().toISOString()
  });
});

app.get('/api/health', async (req, res) => {
  let dbStatus = 'disconnected';
  let redisStatus = 'disconnected';

  try {
    const connection = await pool.getConnection();
    await connection.ping();
    connection.release();
    dbStatus = 'connected';
  } catch (err) {
    dbStatus = `error: ${err.message}`;
  }

  try {
    if (redisClient.isOpen) {
      await redisClient.ping();
      redisStatus = 'connected';
    } else {
      redisStatus = 'not_open';
    }
  } catch (err) {
    redisStatus = `error: ${err.message}`;
  }

  res.status(200).json({
    uptime: process.uptime(),
    database: dbStatus,
    redis: redisStatus,
    timestamp: new Date().toISOString()
  });
});

app.use('/api/auth', authRoutes);
app.use('/api/products', productRoutes);

app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: `Rute ${req.method} ${req.originalUrl} tidak ditemukan.`
  });
});

app.use((err, req, res, next) => {
  console.error('[Unhandled Error]', err);
  res.status(500).json({
    success: false,
    message: 'Terjadi kesalahan internal server.',
    error: err.message
  });
});

const startServer = async () => {
  try {
    try {
      const conn = await pool.getConnection();
      console.log('✓ [MySQL] Berhasil terhubung ke database.');
      conn.release();
    } catch (dbErr) {
      console.warn('! [MySQL] Peringatan koneksi database:', dbErr.message);
    }

    try {
      if (!redisClient.isOpen) {
        await redisClient.connect();
        console.log('✓ [Redis] Berhasil terhubung ke Redis server (localhost:6379).');
      }
    } catch (redisErr) {
      console.warn('! [Redis] Peringatan koneksi Redis:', redisErr.message);
    }

    app.listen(PORT, () => {
      console.log(`🚀 [Server] LapakTani API berjalan di http://localhost:${PORT}`);
    });
  } catch (error) {
    console.error('Fatal error starting server:', error);
    process.exit(1);
  }
};

startServer();

module.exports = app;
