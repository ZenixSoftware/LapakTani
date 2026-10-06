const express = require('express');
const cors = require('cors');
require('dotenv').config({ quiet: true });

const pool = require('./src/config/db');
const redisClient = require('./src/config/redis');
const authRoutes = require('./src/routes/auth');
const productRoutes = require('./src/routes/products');
const profileRoutes = require('./src/routes/profiles');
const penyuluhRoutes = require('./src/routes/penyuluh');

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
app.use('/api/profiles', profileRoutes);
app.use('/api/penyuluh', penyuluhRoutes);

app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: `Rute ${req.method} ${req.originalUrl} tidak ditemukan.`
  });
});

app.use((err, req, res, next) => {
  console.error('[SERVER] Unhandled error:', err.message);
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
      console.log('[MYSQL] Connected to database');
      conn.release();
    } catch (dbErr) {
      console.warn('[MYSQL] Connection warning:', dbErr.message);
    }

    try {
      if (!redisClient.isOpen) {
        await redisClient.connect();
      }
    } catch (redisErr) {
      const errMsg = redisErr && redisErr.message ? redisErr.message : String(redisErr);
      if (
        !errMsg.toLowerCase().includes("unknown command 'hello'") &&
        !errMsg.toLowerCase().includes('unknown command `hello`') &&
        !errMsg.toLowerCase().includes('unknown command hello')
      ) {
        console.warn('[REDIS] Connection warning:', errMsg);
      }
    }

    app.listen(PORT, () => {
      console.log(`[SERVER] Running on http://localhost:${PORT}`);
    });
  } catch (error) {
    console.error('[SERVER] Fatal error starting server:', error.message);
    process.exit(1);
  }
};

startServer();

module.exports = app;
