/**
 * Material 4: L1 In-Memory Node Cache with per-key TTL, hit/miss tracking,
 * and Express X-Node-Cache: HIT | MISS header instrumentation.
 */
class LapakTaniNodeCache {
  constructor(defaultTtlSeconds = 300) {
    this.defaultTtlSeconds = defaultTtlSeconds;
    this.store = new Map();
    this.hits = 0;
    this.misses = 0;
  }

  get(key) {
    const entry = this.store.get(key);
    if (!entry) {
      this.misses += 1;
      return null;
    }

    if (Date.now() > entry.expiresAt) {
      this.store.delete(key);
      this.misses += 1;
      return null;
    }

    this.hits += 1;
    try {
      return JSON.parse(entry.serialized);
    } catch (_) {
      return entry.raw;
    }
  }

  set(key, value, ttlSeconds = this.defaultTtlSeconds) {
    const ttlMs = Math.max(1, Number(ttlSeconds) || this.defaultTtlSeconds) * 1000;
    let serialized = null;
    try {
      serialized = JSON.stringify(value);
    } catch (_) {
      serialized = null;
    }

    this.store.set(key, {
      serialized,
      raw: serialized === null ? value : undefined,
      expiresAt: Date.now() + ttlMs,
      ttlSeconds: Math.round(ttlMs / 1000),
      cachedAt: new Date().toISOString(),
    });
    return true;
  }

  del(key) {
    return this.store.delete(key);
  }

  delByPrefix(prefix) {
    let removed = 0;
    for (const k of this.store.keys()) {
      if (String(k).startsWith(prefix)) {
        this.store.delete(k);
        removed += 1;
      }
    }
    return removed;
  }

  flush() {
    this.store.clear();
  }

  stats() {
    const now = Date.now();
    const activeKeys = [];
    for (const [key, entry] of this.store.entries()) {
      if (now <= entry.expiresAt) {
        activeKeys.push({
          key,
          ttlRemainingSeconds: Math.max(0, Math.round((entry.expiresAt - now) / 1000)),
          cachedAt: entry.cachedAt,
        });
      } else {
        this.store.delete(key);
      }
    }

    return {
      layer: 'L1_NODE_MEMORY_CACHE',
      size: activeKeys.length,
      hits: this.hits,
      misses: this.misses,
      defaultTtlSeconds: this.defaultTtlSeconds,
      uptimeSeconds: Math.round(process.uptime()),
      activeKeys,
    };
  }
}

const nodeCache = new LapakTaniNodeCache(300);

function applyNodeCacheHeader(res, status = 'MISS') {
  if (res && typeof res.setHeader === 'function' && !res.headersSent) {
    res.setHeader('X-Node-Cache', status === 'HIT' ? 'HIT' : 'MISS');
  }
}

function withNodeCache(keyResolver, ttlSeconds = 300) {
  return (req, res, next) => {
    const key = typeof keyResolver === 'function' ? keyResolver(req) : String(keyResolver);
    const cached = nodeCache.get(key);
    if (cached !== null) {
      applyNodeCacheHeader(res, 'HIT');
      return res.status(200).json(cached);
    }

    applyNodeCacheHeader(res, 'MISS');
    const origJson = res.json.bind(res);
    res.json = (body) => {
      if (res.statusCode >= 200 && res.statusCode < 300 && body && body.success !== false) {
        nodeCache.set(key, body, ttlSeconds);
      }
      return origJson(body);
    };
    return next();
  };
}

module.exports = nodeCache;
module.exports.LapakTaniNodeCache = LapakTaniNodeCache;
module.exports.nodeCache = nodeCache;
module.exports.applyNodeCacheHeader = applyNodeCacheHeader;
module.exports.withNodeCache = withNodeCache;
