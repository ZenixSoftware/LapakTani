const DEFAULT_API_KEY = 'lapaktani_secure_gateway_2026_key';

const BYPASS_EXACT_PATHS = new Set([
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

  const expectedApiKey = process.env.LAPAKTANI_API_KEY || DEFAULT_API_KEY;
  const providedApiKey = req.headers['x-api-key'];

  if (!providedApiKey || providedApiKey !== expectedApiKey) {
    return res.status(401).json({
      success: false,
      message: 'Unauthorized: Invalid or missing X-API-Key',
    });
  }

  return next();
};

module.exports = apiKeyMiddleware;
