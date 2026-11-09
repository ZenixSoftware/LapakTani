const crypto = require('crypto');

/**
 * Universal Request Logger & Performance Monitoring Middleware
 * Usable across all routes and routing in LapakTani API.
 * Intercepts incoming HTTP requests, assigns a unique X-Request-Id,
 * and tracks execution latency upon response completion.
 */
const requestLogger = (req, res, next) => {
  const startTime = process.hrtime.bigint();
  const requestId = req.headers['x-request-id'] || crypto.randomUUID().substring(0, 8);

  req.id = requestId;
  res.setHeader('X-Request-Id', requestId);

  const clientIp = (
    req.headers['x-forwarded-for'] ||
    req.socket?.remoteAddress ||
    req.ip ||
    '127.0.0.1'
  ).split(',')[0].trim();

  const timestamp = new Date().toISOString();
  console.log(`[REQ ${requestId}] --> ${req.method} ${req.originalUrl || req.url} from ${clientIp} [${timestamp}]`);

  res.on('finish', () => {
    const endTime = process.hrtime.bigint();
    const durationMs = (Number(endTime - startTime) / 1e6).toFixed(2);
    const statusCode = res.statusCode;

    let statusColor = '\x1b[32m';
    if (statusCode >= 500) {
      statusColor = '\x1b[31m';
    } else if (statusCode >= 400) {
      statusColor = '\x1b[33m';
    } else if (statusCode >= 300) {
      statusColor = '\x1b[36m';
    }
    const resetColor = '\x1b[0m';

    console.log(
      `[RES ${requestId}] <-- ${req.method} ${req.originalUrl || req.url} ${statusColor}${statusCode}${resetColor} (${durationMs} ms)`
    );
  });

  next();
};

module.exports = requestLogger;

