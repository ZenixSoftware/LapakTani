const path = require('path');
const express = require('express');
const cors = require('cors');
require('dotenv').config({ quiet: true });

const pool = require('./src/config/db');
const redisClient = require('./src/config/redis');
const authRoutes = require('./src/routes/auth');
const productRoutes = require('./src/routes/products');
const profileRoutes = require('./src/routes/profiles');
const penyuluhRoutes = require('./src/routes/penyuluh');
const masterRoutes = require('./src/routes/master');
const uploadRoutes = require('./src/routes/upload');
const educationRoutes = require('./src/routes/education');
const cartRoutes = require('./src/routes/cart');
const orderRoutes = require('./src/routes/orders');
const soilRoutes = require('./src/routes/soil');
const paymentRoutes = require('./src/routes/payments');
const poktanRoutes = require('./src/routes/poktan');
const b2bRoutes = require('./src/routes/b2b');
const pestReportRoutes = require('./src/routes/pestReports');
const runPestAlertMigration = require('./src/config/migrate_pest_alert');
const runMonitoringLahanMigration = require('./src/config/migrate_monitoring_lahan');
const requestLogger = require('./src/middlewares/requestLogger');
const apiKeyMiddleware = require('./src/middlewares/apiKeyMiddleware');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors({
  origin: true,
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-API-Key', 'x-api-key', 'Accept', 'X-Request-Id'],
}));
// Global Middleware: Request Logger & Performance Monitoring (Berjalan di SEMUA router/routing)
app.use(requestLogger);
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, 'public')));
app.use('/uploads', express.static(path.join(__dirname, 'public/uploads')));


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

app.use('/api', apiKeyMiddleware);

app.use('/api/auth', authRoutes);
app.use('/api/products', productRoutes);
app.use('/api/profiles', profileRoutes);
app.use('/api/penyuluh', penyuluhRoutes);
app.use('/api/master', masterRoutes);
app.use('/api/upload', uploadRoutes);
app.use('/api/education', educationRoutes);
app.use('/api/cart', cartRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/soil', soilRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/poktan', poktanRoutes);
app.use('/api/b2b-contracts', b2bRoutes);
app.use('/api/contracts', b2bRoutes);
app.use('/api/pest-reports', pestReportRoutes);
app.use('/api/pest-alerts', pestReportRoutes);
app.use('/api/ppl', penyuluhRoutes);


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
    message: 'Terjadi kesalahan internal server.'
  });
});

const startServer = async () => {
  try {
    try {
      const conn = await pool.getConnection();
      console.log('[MYSQL] Connected to database');

      await conn.query(`
        CREATE TABLE IF NOT EXISTS cart_items (
          id VARCHAR(50) PRIMARY KEY,
          user_id VARCHAR(50) NOT NULL,
          product_id VARCHAR(50) NOT NULL,
          grade_id VARCHAR(50),
          quantity INT NOT NULL DEFAULT 1,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
          INDEX idx_cart_product (product_id),
          INDEX idx_cart_user (user_id)
        )
      `);
      console.log('[MYSQL] cart_items table verified');

      conn.release();

      try {
        await runPestAlertMigration();
      } catch (pestMigErr) {
        console.warn('[MIGRATION] Pest alert migration notice:', pestMigErr.message);
      }

      try {
        await runMonitoringLahanMigration();
      } catch (monitoringMigErr) {
        console.warn('[MIGRATION] Monitoring lahan migration notice:', monitoringMigErr.message);
      }
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
