const { createClient } = require('redis');
require('dotenv').config();

const redisClient = createClient({
  url: process.env.REDIS_URL || 'redis://localhost:6379',
  socket: {
    connectTimeout: 2000,
    reconnectStrategy: (retries) => {
      if (retries > 2) {
        return false;
      }
      return 500;
    }
  }
});

redisClient.on('error', (err) => {
  console.warn('[Redis Client Warning]', err.message);
});

redisClient.on('connect', () => {
  console.log('✓ [Redis] Berhasil terhubung ke Redis server.');
});

redisClient.connectRedis = async () => {
  if (!redisClient.isOpen) {
    try {
      await redisClient.connect();
    } catch (err) {
      console.warn('! [Redis] Gagal terhubung ke Redis server:', err.message);
    }
  }
  return redisClient;
};

module.exports = redisClient;
module.exports.redisClient = redisClient;
module.exports.connectRedis = redisClient.connectRedis;

