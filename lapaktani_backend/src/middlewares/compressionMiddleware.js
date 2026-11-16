const zlib = require('zlib');

const stats = {
  engine: 'native-zlib-gzip',
  totalResponses: 0,
  gzipAppliedCount: 0,
  deflateAppliedCount: 0,
  totalBytesBefore: 0,
  totalBytesAfter: 0,
};

function compressBufferGzip(input) {
  const buf = Buffer.isBuffer(input) ? input : Buffer.from(String(input ?? ''), 'utf8');
  return zlib.gzipSync(buf, { level: zlib.constants.Z_DEFAULT_COMPRESSION });
}

function getCompressionStats() {
  const savedBytes = Math.max(0, stats.totalBytesBefore - stats.totalBytesAfter);
  const ratioPct =
    stats.totalBytesBefore > 0
      ? Number(((savedBytes / stats.totalBytesBefore) * 100).toFixed(2))
      : 0;

  return {
    active: true,
    engine: stats.engine,
    totalResponses: stats.totalResponses,
    gzipAppliedCount: stats.gzipAppliedCount,
    deflateAppliedCount: stats.deflateAppliedCount,
    totalBytesBefore: stats.totalBytesBefore,
    totalBytesAfter: stats.totalBytesAfter,
    estimatedCompressionSavingsPct: ratioPct,
  };
}

/**
 * HTTP Response Compression Middleware (Material 3: Compression via native zlib)
 * Compresses JSON/text responses using gzip or deflate when requested via Accept-Encoding,
 * while computing compressed byte metrics and setting X-Response-Compressed headers.
 */
const compressionMiddleware = (options = {}) => {
  const threshold = Number.isFinite(options.threshold) ? options.threshold : 0;

  return (req, res, next) => {
    if (req.path && req.path.startsWith('/uploads')) {
      return next();
    }

    res.setHeader('X-Response-Compressed', 'true');
    res.setHeader('X-Compression-Engine', stats.engine);
    res.vary('Accept-Encoding');

    const originalJson = res.json.bind(res);
    const originalSend = res.send.bind(res);

    const dispatchBuffer = (rawBuffer) => {
      if (res.headersSent || res.statusCode === 204 || res.statusCode === 304) {
        return res.end(rawBuffer);
      }

      const rawLen = rawBuffer.length;
      const gzipBuf = compressBufferGzip(rawBuffer);

      stats.totalResponses += 1;
      stats.totalBytesBefore += rawLen;
      res.setHeader('X-Original-Bytes', String(rawLen));
      res.setHeader('X-Compressed-Bytes', String(gzipBuf.length));

      const acceptEncoding = String(req.headers['accept-encoding'] || '').toLowerCase();
      const skipClientEncoding = Boolean(req.headers['x-no-compression']) || rawLen < threshold;

      if (!skipClientEncoding && acceptEncoding.includes('gzip')) {
        stats.gzipAppliedCount += 1;
        stats.totalBytesAfter += gzipBuf.length;
        res.setHeader('Content-Encoding', 'gzip');
        res.setHeader('Content-Length', String(gzipBuf.length));
        return res.end(gzipBuf);
      }

      if (!skipClientEncoding && acceptEncoding.includes('deflate')) {
        const deflateBuf = zlib.deflateSync(rawBuffer);
        stats.deflateAppliedCount += 1;
        stats.totalBytesAfter += deflateBuf.length;
        res.setHeader('Content-Encoding', 'deflate');
        res.setHeader('Content-Length', String(deflateBuf.length));
        return res.end(deflateBuf);
      }

      stats.totalBytesAfter += rawLen;
      res.setHeader('Content-Length', String(rawLen));
      return res.end(rawBuffer);
    };

    res.json = (body) => {
      if (res.headersSent) {
        return originalJson(body);
      }
      if (!res.getHeader('Content-Type')) {
        res.setHeader('Content-Type', 'application/json; charset=utf-8');
      }
      const jsonStr = JSON.stringify(body);
      return dispatchBuffer(Buffer.from(jsonStr === undefined ? 'null' : jsonStr, 'utf8'));
    };

    res.send = (body) => {
      if (res.headersSent || req.method === 'HEAD') {
        return originalSend(body);
      }
      if (body === undefined || body === null) {
        return originalSend(body);
      }
      if (typeof body === 'object' && !Buffer.isBuffer(body)) {
        if (!res.getHeader('Content-Type')) {
          res.setHeader('Content-Type', 'application/json; charset=utf-8');
        }
        const jsonStr = JSON.stringify(body);
        return dispatchBuffer(Buffer.from(jsonStr === undefined ? 'null' : jsonStr, 'utf8'));
      }
      if (!res.getHeader('Content-Type')) {
        res.setHeader('Content-Type', Buffer.isBuffer(body) ? 'application/octet-stream' : 'text/html; charset=utf-8');
      }
      const rawBuf = Buffer.isBuffer(body) ? body : Buffer.from(String(body), 'utf8');
      return dispatchBuffer(rawBuf);
    };

    return next();
  };
};

module.exports = compressionMiddleware;
module.exports.compressionMiddleware = compressionMiddleware;
module.exports.compressBufferGzip = compressBufferGzip;
module.exports.getCompressionStats = getCompressionStats;
