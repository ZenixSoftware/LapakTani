/**
 * [US-01] L2 Distributed Cache (Redis) with Resilient In-Memory Buffer Fallback
 * Lead Backend & Database Architect: Rafael Rizky (Rafariz19)
 * 
 * Implements high-throughput L2 caching with TTL auto-expiration,
 * connection resiliency fallback, and detailed cache performance stats.
 */
const { createClient } = require('redis');
require('dotenv').config({ quiet: true });

const REDIS_URL = process.env.REDIS_URL || 'redis://localhost:6379';

const redisClient = createClient({
  url: REDIS_URL,
  RESP: 2,
  socket: {
    connectTimeout: 2000,
    reconnectStrategy: (retries) => {
      if (retries > 3) {
        return false;
      }
      return 500;
    }
  }
});

const l2FallbackMap = new Map();
let redisHits = 0;
let redisMisses = 0;

redisClient.on('error', (err) => {
  const msg = err && err.message ? err.message : String(err);
  if (
    msg.toLowerCase().includes("unknown command 'hello'") ||
    msg.toLowerCase().includes('unknown command `hello`') ||
    msg.toLowerCase().includes('unknown command "hello"') ||
    msg.toLowerCase().includes('unknown command hello')
  ) {
    return;
  }
  console.error('[REDIS] Error:', msg);
});

redisClient.on('connect', () => {
  console.log('[REDIS] Connected to Redis server (localhost:6379)');
});

redisClient.connectRedis = async () => {
  if (!redisClient.isOpen) {
    try {
      await redisClient.connect();
    } catch (err) {
      const msg = err && err.message ? err.message : String(err);
      if (
        !msg.toLowerCase().includes("unknown command 'hello'") &&
        !msg.toLowerCase().includes('unknown command `hello`') &&
        !msg.toLowerCase().includes('unknown command hello')
      ) {
        console.warn('[REDIS] Connection warning:', msg);
      }
    }
  }
  return redisClient;
};

redisClient.getCache = async (key) => {
  if (redisClient.isOpen) {
    try {
      const raw = await redisClient.get(key);
      if (raw !== null && raw !== undefined) {
        redisHits += 1;
        return {
          hit: true,
          value: JSON.parse(raw),
          backend: REDIS_URL,
        };
      }
      redisMisses += 1;
      return { hit: false, value: null, backend: REDIS_URL };
    } catch (err) {
      console.warn('[REDIS] Cache get fallback warning:', err.message);
    }
  }

  const fallback = l2FallbackMap.get(key);
  if (fallback && Date.now() <= fallback.expiresAt) {
    redisHits += 1;
    return {
      hit: true,
      value: JSON.parse(fallback.serialized),
      backend: 'redis_fallback_buffer',
    };
  }
  if (fallback) {
    l2FallbackMap.delete(key);
  }
  redisMisses += 1;
  return {
    hit: false,
    value: null,
    backend: 'redis_fallback_buffer',
  };
};

redisClient.setCache = async (key, data, ttlSeconds = 300) => {
  const ttl = Math.max(1, Number(ttlSeconds) || 300);
  const serialized = JSON.stringify(data);
  l2FallbackMap.set(key, {
    serialized,
    expiresAt: Date.now() + ttl * 1000,
  });

  if (redisClient.isOpen) {
    try {
      await redisClient.setEx(key, ttl, serialized);
      return true;
    } catch (err) {
      console.warn('[REDIS] Cache set warning:', err.message);
    }
  }
  return false;
};

redisClient.delCache = async (key) => {
  l2FallbackMap.delete(key);
  if (redisClient.isOpen) {
    try {
      await redisClient.del(key);
    } catch (err) {
      console.warn('[REDIS] Cache del warning:', err.message);
    }
  }
};

redisClient.getRedisStats = () => ({
  layer: 'L2_REDIS_CACHE',
  endpoint: REDIS_URL,
  isOpen: Boolean(redisClient.isOpen),
  mode: redisClient.isOpen ? 'live_redis_server' : 'resilient_fallback_buffer',
  hits: redisHits,
  misses: redisMisses,
  fallbackBufferSize: l2FallbackMap.size,
  trackedKeys: ['lapaktani_catalog', 'gis_monitoring_summary', 'session_state:*'],
});

module.exports = redisClient;
module.exports.redisClient = redisClient;
module.exports.connectRedis = redisClient.connectRedis;
module.exports.getCache = redisClient.getCache;
module.exports.setCache = redisClient.setCache;
module.exports.delCache = redisClient.delCache;
module.exports.getRedisStats = redisClient.getRedisStats;
