/**
 * ============================================================================
 * LAPAKTANI REST API - REQUEST LOGGER & PERFORMANCE MONITORING MIDDLEWARE
 * ============================================================================
 * 
 * Deskripsi:
 * Middleware universal untuk mencatat seluruh lalu lintas request HTTP yang masuk,
 * memantau waktu respons (latency dalam ms), serta memberikan header X-Response-Time.
 * 
 * Karakteristik:
 * 1. Universal / Global: Wajib dan dapat berjalan pada SEMUA router maupun routing.
 * 2. Performance Tracking: Menghitung durasi eksekusi request secara akurat.
 * 3. Color-Coded Console: Menampilkan kode warna terminal berdasarkan status HTTP:
 *    - 2xx (Hijau) : Sukses
 *    - 3xx (Biru)  : Pengalihan (Redirect)
 *    - 4xx (Kuning): Kesalahan Klien (Bad Request / Not Found / Unauthorized)
 *    - 5xx (Merah) : Kesalahan Internal Server
 * 4. Header Injection: Menyisipkan header 'X-Response-Time' pada setiap respons klien.
 * ============================================================================
 */

// ANSI Color Escape Codes untuk pewarnaan terminal console
const COLORS = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  dim: '\x1b[2m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  red: '\x1b[31m',
  cyan: '\x1b[36m',
  magenta: '\x1b[35m',
  gray: '\x1b[90m',
};

/**
 * Mendapatkan representasi warna terminal berdasarkan status code HTTP
 * @param {number} statusCode 
 * @returns {string} ANSI color code
 */
const getStatusColor = (statusCode) => {
  if (statusCode >= 500) return COLORS.red;
  if (statusCode >= 400) return COLORS.yellow;
  if (statusCode >= 300) return COLORS.cyan;
  if (statusCode >= 200) return COLORS.green;
  return COLORS.reset;
};

/**
 * Format timestamp lokal Indonesia (WIB)
 * @returns {string} formatted datetime string
 */
const getFormattedTimestamp = () => {
  const now = new Date();
  return now.toISOString().replace('T', ' ').substring(0, 19);
};

/**
 * Middleware utama: Request Logger & Response Time Tracker
 * Digunakan secara global pada server.js: app.use(requestLogger);
 */
const requestLogger = (req, res, next) => {
  // 1. Catat waktu awal request masuk (High-resolution nanoseconds timer)
  const startTime = process.hrtime.bigint();

  // 2. Override res.writeHead untuk menyisipkan header X-Response-Time sebelum headers terkirim
  const originalWriteHead = res.writeHead;
  res.writeHead = function (...args) {
    const diffNanos = process.hrtime.bigint() - startTime;
    const durationMs = (Number(diffNanos) / 1e6).toFixed(2);
    
    // Set header jika header belum dikirim ke klien
    if (!res.headersSent) {
      res.setHeader('X-Response-Time', `${durationMs}ms`);
    }

    return originalWriteHead.apply(this, args);
  };

  // 3. Listener saat respon selesai dikirimkan ke klien (event: 'finish')
  res.on('finish', () => {
    const diffNanos = process.hrtime.bigint() - startTime;
    const durationMs = (Number(diffNanos) / 1e6).toFixed(2);

    const method = req.method;
    const url = req.originalUrl || req.url;
    const statusCode = res.statusCode;
    const ip = req.headers['x-forwarded-for'] || req.socket.remoteAddress || '127.0.0.1';
    const timestamp = getFormattedTimestamp();

    const statusColor = getStatusColor(statusCode);
    const methodColor = method === 'GET' ? COLORS.cyan :
                        method === 'POST' ? COLORS.green :
                        method === 'PUT' || method === 'PATCH' ? COLORS.yellow :
                        method === 'DELETE' ? COLORS.red : COLORS.magenta;

    // Log terformat rapi di terminal console
    console.log(
      `${COLORS.gray}[${timestamp}]${COLORS.reset} ` +
      `${methodColor}${method.padEnd(7)}${COLORS.reset} ` +
      `${url.padEnd(35)} ` +
      `${statusColor}${statusCode}${COLORS.reset} ` +
      `${COLORS.gray}(${durationMs}ms)${COLORS.reset} ` +
      `${COLORS.dim}IP: ${ip}${COLORS.reset}`
    );
  });

  // Lanjutkan eksekusi ke middleware / router berikutnya
  next();
};

module.exports = {
  requestLogger,
  getStatusColor,
  getFormattedTimestamp
};
