const buckets = new Map();

const globalStats = {
  totalChecked: 0,
  totalBlocked: 0,
  policies: new Map(),
};

function getClientIp(req) {
  const forwarded = req.headers['x-forwarded-for'];
  if (forwarded && typeof forwarded === 'string') {
    return forwarded.split(',')[0].trim();
  }
  return req.ip || req.socket?.remoteAddress || '127.0.0.1';
}

/**
 * Sliding-window Rate Limiter Middleware (Material 7)
 * Sets X-RateLimit-Policy, X-RateLimit-Limit, X-RateLimit-Remaining, X-RateLimit-Reset,
 * and returns HTTP 429 Too Many Requests when the sliding-window budget is exceeded.
 */
function createRateLimiter({ name = 'api_limiter', windowMs = 60000, maxRequests = 120 } = {}) {
  globalStats.policies.set(name, {
    name,
    windowSeconds: Math.round(windowMs / 1000),
    maxRequests,
  });

  return (req, res, next) => {
    if (req.method === 'OPTIONS') {
      return next();
    }

    const now = Date.now();
    const clientIp = getClientIp(req);

    const rawTestLimit = req.headers['x-ratelimit-test-limit'];
    const parsedTestLimit = rawTestLimit !== undefined ? parseInt(String(rawTestLimit), 10) : NaN;
    const isTestOverride = Number.isInteger(parsedTestLimit) && parsedTestLimit >= 1 && parsedTestLimit <= 20;

    const effectiveLimit = isTestOverride ? parsedTestLimit : maxRequests;
    const bucketKey = isTestOverride
      ? `test:${clientIp}:${name}:${effectiveLimit}`
      : `${clientIp}:${name}`;

    let timestamps = buckets.get(bucketKey) || [];
    const windowStart = now - windowMs;
    timestamps = timestamps.filter((ts) => ts > windowStart);

    timestamps.push(now);
    buckets.set(bucketKey, timestamps);

    const count = timestamps.length;
    const remaining = Math.max(0, effectiveLimit - count);
    const oldestTs = timestamps[0] || now;
    const resetEpochSeconds = Math.ceil((oldestTs + windowMs) / 1000);
    const retryAfterSeconds = Math.max(1, Math.ceil((oldestTs + windowMs - now) / 1000));

    globalStats.totalChecked += 1;

    res.setHeader(
      'X-RateLimit-Policy',
      `${name};w=${Math.round(windowMs / 1000)};limit=${effectiveLimit}`
    );
    res.setHeader('X-RateLimit-Limit', String(effectiveLimit));
    res.setHeader('X-RateLimit-Remaining', String(remaining));
    res.setHeader('X-RateLimit-Reset', String(resetEpochSeconds));

    if (count > effectiveLimit) {
      globalStats.totalBlocked += 1;
      res.setHeader('Retry-After', String(retryAfterSeconds));
      return res.status(429).json({
        success: false,
        code: 'RATE_LIMIT_EXCEEDED',
        message: 'Terlalu banyak permintaan (Rate Limit Exceeded). Silakan coba beberapa saat lagi.',
        limiter: name,
        limit: effectiveLimit,
        window_seconds: Math.round(windowMs / 1000),
        retry_after_seconds: retryAfterSeconds,
      });
    }

    return next();
  };
}

const authRateLimiter = createRateLimiter({
  name: 'auth_sliding_window',
  windowMs: 60 * 1000,
  maxRequests: 60,
});

const orderRateLimiter = createRateLimiter({
  name: 'orders_sliding_window',
  windowMs: 60 * 1000,
  maxRequests: 120,
});

const apiRateLimiter = createRateLimiter({
  name: 'global_api_sliding_window',
  windowMs: 60 * 1000,
  maxRequests: 300,
});

function getRateLimiterStats() {
  return {
    active: true,
    algorithm: 'sliding_window_log',
    totalChecked: globalStats.totalChecked,
    totalBlocked: globalStats.totalBlocked,
    activeBuckets: buckets.size,
    policies: Array.from(globalStats.policies.values()),
  };
}

module.exports = {
  createRateLimiter,
  authRateLimiter,
  orderRateLimiter,
  apiRateLimiter,
  getRateLimiterStats,
};
