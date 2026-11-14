const crypto = require('crypto');

const BYPASS_EXACT_PATHS = new Set([
  '/',
  '/api/health',
  '/health',
  '/api/payments/midtrans-webhook',
  '/api/payments/midtrans-callback',
  '/api/payments/notification',
  '/api/payments/webhook',
  '/payments/midtrans-webhook',
  '/payments/midtrans-callback',
  '/payments/notification',
  '/payments/webhook',
  '/midtrans-webhook',
  '/midtrans-callback',
  '/notification',
  '/webhook',
]);

/**
 * Constant-time string comparison using crypto.timingSafeEqual.
 * Returns false if either key is empty or lengths do not match.
 */
const safeCompareKeys = (providedKey, expectedKey) => {
  if (!providedKey || !expectedKey) return false;
  const providedBuf = Buffer.from(providedKey, 'utf8');
  const expectedBuf = Buffer.from(expectedKey, 'utf8');
  if (providedBuf.length !== expectedBuf.length) return false;
  return crypto.timingSafeEqual(providedBuf, expectedBuf);
};

/**
 * Global/API Gateway X-API-Key anti-spoofing middleware.
 * Bypasses CORS preflight (OPTIONS), Midtrans payment webhooks, static /uploads assets, and health checks.
 */
const apiKeyMiddleware = (req, res, next) => {
  if (req.method === 'OPTIONS') {
    return next();
  }

  const originalPath = (req.originalUrl || '').split('?')[0].replace(/\/+$/, '') || '/';
  const routePath = (req.path || '').split('?')[0].replace(/\/+$/, '') || '/';

  if (
    originalPath.startsWith('/uploads') ||
    routePath.startsWith('/uploads') ||
    BYPASS_EXACT_PATHS.has(originalPath) ||
    BYPASS_EXACT_PATHS.has(routePath)
  ) {
    return next();
  }

  const expectedApiKey = (process.env.LAPAKTANI_API_KEY || '').trim();
  const providedApiKey =
    typeof req.headers['x-api-key'] === 'string' ? req.headers['x-api-key'].trim() : '';

  if (!expectedApiKey) {
    return res.status(500).json({
      success: false,
      message: 'Server API key configuration error',
    });
  }

  if (!safeCompareKeys(providedApiKey, expectedApiKey)) {
    return res.status(401).json({
      success: false,
      message: 'Unauthorized: Invalid or missing X-API-Key',
    });
  }

  return next();
};

module.exports = apiKeyMiddleware;
