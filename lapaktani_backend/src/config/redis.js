const { createClient } = require('redis');
require('dotenv').config({ quiet: true });

const redisClient = createClient({
  url: process.env.REDIS_URL || 'redis://localhost:6379',
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

module.exports = redisClient;
module.exports.redisClient = redisClient;
module.exports.connectRedis = redisClient.connectRedis;
