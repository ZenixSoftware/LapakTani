/**
 * [US-01] Database Connection Pool Configuration
 * Lead Backend & Database Architect: Rafael Rizky (Rafariz19)
 * 
 * Provides an enterprise-grade MySQL2 promise-based connection pool
 * with keep-alive, connection limits, and diagnostic health probes.
 */
const mysql = require('mysql2/promise');
require('dotenv').config({ quiet: true });

const dbHost = process.env.DB_HOST || 'localhost';
const dbPort = parseInt(process.env.DB_PORT || '3306', 10);
const dbName = process.env.DB_NAME || 'lapaktani_db';

const pool = mysql.createPool({
  host: dbHost,
  port: dbPort,
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: dbName,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  connectTimeout: 10000,
  enableKeepAlive: true,
});

/**
 * Diagnostic health check utility for MySQL pool
 * @returns {Promise<{status: string, host: string, database: string}>}
 */
pool.checkHealth = async () => {
  try {
    const connection = await pool.getConnection();
    await connection.ping();
    connection.release();
    return { status: 'connected', host: dbHost, database: dbName };
  } catch (err) {
    return { status: 'disconnected', error: err.message, host: dbHost, database: dbName };
  }
};

// Non-blocking startup diagnostic so database downtime surfaces immediately in logs
pool.getConnection()
  .then((connection) => {
    console.log(`[DB] Connected to MySQL (${dbHost}:${dbPort}/${dbName})`);
    connection.release();
  })
  .catch((err) => {
    console.error(`[DB ERROR] Cannot connect to MySQL (${err.code || 'UNKNOWN'}): ${err.message}`);
  });

module.exports = pool;
