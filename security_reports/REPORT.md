# LapakTani Express.js Backend Security Audit Report

## 1. Executive Summary

This report documents the security audit conducted on the LapakTani Express.js REST API backend (`lapaktani_backend`). The assessment utilized a source-first, defensive methodology aligned with Cloudflare security audit standards and the 6-phase audit workflow.

During the assessment, **5 confirmed security findings** were identified, including **2 Critical** vulnerabilities and **1 High** vulnerability:
- **AUTH-01 (Critical)**: An insecure fallback mechanism in `authMiddleware.js` grants any unauthenticated caller administrative access to the first registered farmer account when no token or an invalid token is provided.
- **AUTH-02 (Critical)**: Sensitive administrative farmer verification routes under `/api/penyuluh` lack authentication and authorization middleware entirely, exposing Indonesian citizen Personally Identifiable Information (NIK, addresses, GPS coordinates, KTP photos) and allowing unauthorized status modification.
- **UPLOAD-01 (High)**: File upload validation in `uploadMiddleware.js` relies solely on client-controlled `Content-Type` headers without magic-byte verification, coupled with static asset serving without strict MIME/CSP headers.
- **AUTH-03 (Medium)**: Discrepant, weak hardcoded JWT secret fallbacks between authentication and authorization modules.
- **DOS-01 (Low)**: Temporal Dead Zone ReferenceError in `productController.js` causing HTTP 500 crashes during product updates.

Parameterized queries (`mysql2/promise`) are consistently enforced across all database interactions, successfully mitigating SQL injection risks.

---

## 2. Assessment Scope & Target Architecture

| Property | Value |
| :--- | :--- |
| **Target Application** | LapakTani REST API (`lapaktani_backend`) |
| **Runtime Environment** | Node.js (v24.11.1), Express.js (v5.2.1), MySQL 8.x, Redis 6.x |
| **Audit Scope** | `lapaktani_backend/server.js`, `lapaktani_backend/src/**` |
| **Primary Controllers** | `authController.js`, `productController.js`, `profileController.js`, `penyuluhController.js`, `masterDataController.js`, `uploadController.js` |
| **Middlewares** | `authMiddleware.js`, `uploadMiddleware.js` |
| **Audited Commit** | `107e625` (main branch) |
| **Audit Profile** | Standard / Comprehensive Source Audit |

---

## 3. Methodology

The audit followed the 6-phase Cloudflare security audit methodology:
1. **Phase 1: Reconnaissance & Scoping** — Mapping routes, entrypoints, database models, session management, and trust boundaries.
2. **Phase 2: Coverage-Led Hunting Waves** — Investigating authentication, authorization, file upload mechanisms, input parsing, and state lifecycle.
3. **Phase 3: Candidate Validation** — Testing boundary assumptions, establishing source traces, identifying invariants, and determining concrete principal impact.
4. **Phase 4: Structured Output** — Compiling deterministic findings into `findings.json` with rigorous schema constraints.
5. **Phase 5: Independent Verification** — Reviewing source references, verifying line numbers, confirming impact calibration, and validating absence of false positives.
6. **Phase 6: Reporting** — Generating this report, companion detail specifications, and validation items.

---

## 4. Severity Distribution & Findings Summary

| Identifier | Title | Subsystem | Severity | Status |
| :--- | :--- | :--- | :--- | :--- |
| **AUTH-01** | Insecure Authentication Fallback & Token Bypass | `authMiddleware.js` | **Critical** | Confirmed |
| **AUTH-02** | Missing Auth & Access Control on Penyuluh Routes | `routes/penyuluh.js` | **Critical** | Confirmed |
| **UPLOAD-01** | Insecure Upload Validation via Client MIME Type | `uploadMiddleware.js` | **High** | Confirmed |
| **AUTH-03** | Inconsistent Hardcoded JWT Secret Fallbacks | `authController.js` | **Medium** | Confirmed |
| **DOS-01** | TDZ ReferenceError in updateProduct Handler | `productController.js` | **Low** | Confirmed |

---

## 5. Subsystem Security Evaluation

### 5.1 Authentication & Authorization
- **Vulnerabilities**: Two critical flaws exist. In `authMiddleware.js`, failing or absent token validation triggers a fallback query selecting the first farmer in `farmer_profiles`, setting `req.user` to that farmer, and allowing the request to proceed. In `routes/penyuluh.js`, all endpoints are completely open without middleware.
- **SQL Injection**: Parameterized SQL queries are utilized throughout authentication queries. Password hashing uses `bcryptjs` with salt round 10.

### 5.2 File Upload & Media Handling
- File uploads are handled via `multer.diskStorage` saving to `public/uploads/products`.
- File naming incorporates timestamp and random integers (`product-${uniqueSuffix}${ext}`), which mitigates path traversal.
- However, file validation inspects `file.mimetype` directly from the client's request header rather than checking file magic numbers (e.g., via `file-type` or `sharp`). Express serves `/uploads` statically without `X-Content-Type-Options: nosniff` or CSP restrictions.

### 5.3 Database Queries & SQL Injection
- Evaluated `mysql2/promise` queries across all 6 controllers. All dynamic queries use parameter arrays `[?]` with placeholders. No raw string interpolation was identified in SQL execution.

### 5.4 Business Logic & Error Handling
- Variable scope error (TDZ) identified in `productController.js` when handling `image_urls`.
- No rate limiting exists on login, registration, or upload endpoints.

---

## 6. Strategic Remediation Roadmap

1. **Immediate (P0 - Critical)**:
   - Remove fallback database queries in `src/middlewares/authMiddleware.js`. Return immediate HTTP 401 when tokens are missing or invalid.
   - Enforce `verifyToken` and `requireRole('penyuluh', 'admin')` in `src/routes/penyuluh.js`.
2. **Short-Term (P1 - High)**:
   - Implement magic number / buffer signature inspection for uploads using `file-type` or `sharp`.
   - Add security headers (`helmet`, `X-Content-Type-Options: nosniff`) and restrict CORS origins in `server.js`.
   - Fix lexical variable declarations (`updates`, `params`) in `src/controllers/productController.js`.
3. **Medium-Term (P2 - Medium)**:
   - Centralize JWT configuration and enforce mandatory non-empty `JWT_SECRET` on server initialization.
   - Introduce rate limiting (`express-rate-limit`) on `/api/auth/*` and `/api/upload/*`.
