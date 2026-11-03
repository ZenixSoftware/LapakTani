# Security Observations Needing Environmental Validation

The following candidate security concerns are grounded in source code observations but depend on deployment topology, reverse proxy configurations, or external infrastructure controls that cannot be validated from repository source alone.

---

## Candidate 1: Missing Application-Layer Rate Limiting on Authentication & Upload Endpoints

- **Candidate ID**: `NV-RATE-01`
- **Source Reference**: `server.js:66-71`, `src/routes/auth.js`, `src/routes/upload.js`
- **Claimed Root Cause**: Absence of in-application rate limiting middlewares (`express-rate-limit`) on `/api/auth/login`, `/api/auth/register`, and `/api/upload/product-image`.
- **Blocked On**:
  - Verification of edge WAF configurations (e.g., Cloudflare Rate Limiting rules, AWS WAF, or Nginx `limit_req_zone`).
- **Validation Plan**:
  1. Inspect upstream reverse proxy and CDN configuration to verify whether IP/token-based request throttling is enforced.
  2. If no upstream rate limiting is active, implement `express-rate-limit` using the existing Redis store (`redisClient`) for distributed rate limiting.

---

## Candidate 2: Permissive Default Cross-Origin Resource Sharing (CORS) Policy

- **Candidate ID**: `NV-CORS-01`
- **Source Reference**: `server.js:18` (`app.use(cors())`)
- **Claimed Root Cause**: `cors()` invoked without explicit origin allowlist defaults to reflecting `Access-Control-Allow-Origin: *`.
- **Blocked On**:
  - Verification of whether production ingress filters origins or if API is intended to be accessed by arbitrary external clients.
- **Validation Plan**:
  1. Verify expected client domains (e.g., `https://app.lapaktani.id`, `https://admin.lapaktani.id`).
  2. If specific origins are expected, restrict `cors({ origin: ['https://app.lapaktani.id'] })`.

---

## Candidate 3: Unauthenticated Local Redis Connection

- **Candidate ID**: `NV-REDIS-01`
- **Source Reference**: `src/config/redis.js:4`, `server.js:101-113`
- **Claimed Root Cause**: Redis client connects to `redis://localhost:6379` without authentication (`AUTH`) or TLS encryption.
- **Blocked On**:
  - Verification of production network isolation (container network, Unix socket, or isolated VPC).
- **Validation Plan**:
  1. Check production environment variables (`REDIS_URL` or `REDIS_PASSWORD`).
  2. Ensure Redis is bound exclusively to private loopback or Unix sockets, or require a strong password (`requirepass`) with TLS enabled.
