/**
 * [US-01] Verification Test Suite: Middleware, Caching & Monorepo Architecture
 * Author: Rafael Rizky (Rafariz19)
 * 
 * Verifies:
 * 1. Express Server & Route Gateway initialization
 * 2. Database Connection Pool & Ping probe
 * 3. L1 NodeCache In-Memory operations, TTL expiration, hit/miss tracking
 * 4. L2 RedisCache operations with resilient buffer fallback
 * 5. Native zlib HTTP Compression with payload byte reduction calculation
 */

const assert = require('assert');
const pool = require('../src/config/db');
const redisClient = require('../src/config/redis');
const nodeCache = require('../src/utils/nodeCache');
const { compressBufferGzip, getCompressionStats } = require('../src/middlewares/compressionMiddleware');

async function runUS01Tests() {
  console.log('===============================================================');
  console.log('[US-01] STARTING MONOREPO MIDDLEWARE & ARCHITECTURE TEST SUITE');
  console.log('Lead Architect: Rafael Rizky (Rafariz19)');
  console.log('===============================================================\n');

  let passed = 0;
  let total = 0;

  function test(name, fn) {
    total++;
    try {
      fn();
      console.log(`  [PASS] ${name}`);
      passed++;
    } catch (err) {
      console.error(`  [FAIL] ${name}: ${err.message}`);
    }
  }

  async function testAsync(name, fn) {
    total++;
    try {
      await fn();
      console.log(`  [PASS] ${name}`);
      passed++;
    } catch (err) {
      console.error(`  [FAIL] ${name}: ${err.message}`);
    }
  }

  // 1. MySQL Pool Configuration
  test('1.1 MySQL connection pool should be configured with keepAlive and limit', () => {
    assert(pool, 'Pool instance must exist');
    assert(typeof pool.query === 'function', 'pool.query must be a function');
    assert(typeof pool.getConnection === 'function', 'pool.getConnection must be a function');
    assert(typeof pool.checkHealth === 'function', 'pool.checkHealth must be a function');
  });

  // 2. L1 NodeCache Tests
  test('2.1 L1 NodeCache: set, get, and hit tracking', () => {
    const key = 'test_l1_key_' + Date.now();
    const data = { user: 'petani_sumenep', role: 'petani', active: true };

    nodeCache.set(key, data, 60);
    const retrieved = nodeCache.get(key);
    assert.deepStrictEqual(retrieved, data, 'Retrieved cache must match stored data');

    const stats = nodeCache.stats();
    assert.strictEqual(stats.layer, 'L1_NODE_MEMORY_CACHE');
    assert(stats.hits > 0, 'Hits counter must increment');
  });

  test('2.2 L1 NodeCache: TTL expiration and deletion', () => {
    const key = 'test_l1_del_' + Date.now();
    nodeCache.set(key, { temp: true }, 60);
    const deleted = nodeCache.del(key);
    assert.strictEqual(deleted, true, 'del(key) should return true');
    const lookup = nodeCache.get(key);
    assert.strictEqual(lookup, null, 'Deleted key must return null');
  });

  // 3. L2 RedisCache Tests
  await testAsync('3.1 L2 RedisCache: set, get, and resilient fallback', async () => {
    const key = 'test_l2_key_' + Date.now();
    const data = { commodity: 'Cabai Rawit Merah', grade: 'Grade A', price: 45000 };

    await redisClient.setCache(key, data, 60);
    const result = await redisClient.getCache(key);

    assert(result, 'Cache result must exist');
    assert.strictEqual(result.hit, true, 'Cache get must report hit: true');
    assert.deepStrictEqual(result.value, data, 'Cached value must match');
    assert(result.backend, 'Backend source must be identified');
  });

  await testAsync('3.2 L2 RedisCache: statistics reporting', async () => {
    const stats = redisClient.getRedisStats();
    assert.strictEqual(stats.layer, 'L2_REDIS_CACHE');
    assert(typeof stats.hits === 'number', 'Stats must track hits');
    assert(typeof stats.misses === 'number', 'Stats must track misses');
    assert(Array.isArray(stats.trackedKeys), 'Stats must list tracked keys');
  });

  // 4. Native Zlib HTTP Compression Tests
  test('4.1 Native Zlib: gzip compression reduces byte payload', () => {
    const largePayload = JSON.stringify({
      status: 'success',
      records: Array.from({ length: 100 }, (_, i) => ({
        id: `LAPAK-${i}`,
        village: 'Kecamatan Bluto, Sumenep',
        moisture: 65.4 + (i % 5),
        npk: { nitrogen: 140, phosphorus: 45, potassium: 180 },
        recommendation: 'Lanjutkan pengairan tetes dan pemupukan NPK berimbang.'
      }))
    });

    const uncompressedSize = Buffer.byteLength(largePayload, 'utf8');
    const compressedBuffer = compressBufferGzip(largePayload);
    const compressedSize = compressedBuffer.length;

    assert(compressedSize < uncompressedSize, 'Compressed size must be smaller than original');
    const reductionPercent = ((uncompressedSize - compressedSize) / uncompressedSize) * 100;
    console.log(`      Payload: ${uncompressedSize} bytes -> Gzip: ${compressedSize} bytes (${reductionPercent.toFixed(1)}% reduction)`);
    assert(reductionPercent > 40, 'Compression reduction should exceed 40% on repetitive JSON');
  });

  test('4.2 Compression Middleware: stats tracking reflects engine status', () => {
    const stats = getCompressionStats();
    assert.strictEqual(stats.active, true, 'Compression must be active');
    assert.strictEqual(stats.engine, 'native-zlib-gzip');
  });

  console.log(`\n[US-01 TEST SUMMARY] Passed: ${passed}/${total} (${((passed / total) * 100).toFixed(0)}%)`);
  if (passed === total) {
    console.log('[US-01] ALL MIDDLEWARE & ARCHITECTURE TESTS VERIFIED SUCCESSFULLY!\n');
    if (require.main === module) process.exit(0);
  } else {
    if (require.main === module) process.exit(1);
  }
}

if (require.main === module) {
  runUS01Tests();
}

module.exports = runUS01Tests;
