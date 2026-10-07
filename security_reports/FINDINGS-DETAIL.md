# Detailed Vulnerability Breakdown

## Finding AUTH-01: Insecure Authentication Fallback and Universal Token Bypass in authMiddleware

- **Identifier**: `AUTH-01:authMiddleware.js:8-41`
- **Verdict**: Confirmed
- **Severity**: Critical (Likelihood: Critical | Impact: Critical)
- **Subsystem**: Authentication (`lapaktani_backend/src/middlewares/authMiddleware.js`)
- **CWE**: CWE-287 (Improper Authentication), CWE-639 (Authorization Bypass Through User-Controlled Key)

### Description
In `src/middlewares/authMiddleware.js`, the `verifyToken` function contains a fallback branch when the `Authorization` header is missing or malformed, as well as a secondary fallback branch when `jwt.verify` throws an error (e.g. for expired or invalid tokens). Both fallback branches query the database for the first farmer profile and attach it to `req.user`, subsequently invoking `next()`:

```javascript
// src/middlewares/authMiddleware.js:8-17
if (!authHeader || !authHeader.startsWith('Bearer ')) {
  try {
    const [farmers] = await pool.query(
      'SELECT u.id, u.email, u.role FROM users u JOIN farmer_profiles fp ON u.id = fp.user_id LIMIT 1'
    );
    if (farmers.length > 0) {
      req.user = farmers[0];
      return next();
    }
  } catch (_) {}
  return res.status(401).json({ ... });
}
```

### Exploit Reproduction
1. Issue a request to any protected endpoint without credentials:
   ```http
   GET /api/products/me HTTP/1.1
   Host: localhost:3000
   ```
2. The server responds with `200 OK` containing the first farmer's private product inventory.
3. Issue a creation or deletion request:
   ```http
   POST /api/products HTTP/1.1
   Host: localhost:3000
   Content-Type: application/json

   {
     "title": "Unauthorized Crop",
     "price_per_kg": 25000,
     "stock_kg": 50,
     "commodity_id": "com-1",
     "grade_id": "grade-1"
   }
   ```
4. The product is inserted on behalf of the victim farmer account.

### Remediation
Remove all fallback database queries. Enforce strict rejection on missing or invalid tokens:

```javascript
// src/middlewares/authMiddleware.js
const jwt = require('jsonwebtoken');
require('dotenv').config({ quiet: true });

const verifyToken = (req, res, next) => {
  const authHeader = req.headers.authorization || req.headers.Authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      success: false,
      message: 'Akses ditolak. Token autentikasi tidak disediakan.'
    });
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'lapaktani_secret_2026');
    req.user = decoded;
    next();
  } catch (error) {
    return res.status(401).json({
      success: false,
      message: 'Token tidak valid atau telah kedaluwarsa.'
    });
  }
};

module.exports = { verifyToken };
```

---

## Finding AUTH-02: Missing Authentication and Access Control on Administrative Agricultural Field Officer Routes

- **Identifier**: `AUTH-02:routes/penyuluh.js:5-7`
- **Verdict**: Confirmed
- **Severity**: Critical (Likelihood: Critical | Impact: Critical)
- **Subsystem**: Authorization & Route Protection (`lapaktani_backend/src/routes/penyuluh.js`)
- **CWE**: CWE-306 (Missing Authentication for Critical Function), CWE-285 (Improper Authorization)

### Description
In `src/routes/penyuluh.js`, endpoints designed for agricultural field officers (*penyuluh*) to review and approve/reject farmer registrations are mounted without authentication or role verification middleware:

```javascript
// src/routes/penyuluh.js:5-7
router.get('/pending-farmers', penyuluhController.getPendingFarmers);
router.get('/farmers', penyuluhController.getAllFarmers);
router.put('/verify-farmer/:id', penyuluhController.verifyFarmer);
```

### Exploit Reproduction
1. Issue an unauthenticated `GET` request:
   ```http
   GET /api/penyuluh/pending-farmers HTTP/1.1
   Host: localhost:3000
   ```
2. The server dumps sensitive Personally Identifiable Information (PII) including:
   - Full Name (`full_name`)
   - 16-digit National ID Number (`nik_number`)
   - Phone Number (`phone`)
   - Residential Address (`detail_address`)
   - Farm GPS Coordinates (`gps_latitude`, `gps_longitude`)
   - National ID Card Image URL (`ktp_image_url`)
3. Issue an unauthenticated `PUT` request to verify an arbitrary account:
   ```http
   PUT /api/penyuluh/verify-farmer/target-uuid HTTP/1.1
   Host: localhost:3000
   Content-Type: application/json

   {
     "status": "verified"
   }
   ```
4. The database updates `user_profiles.verification_status = 'verified'` and `users.is_verified = 1`.

### Remediation
Apply `verifyToken` and introduce role checking middleware requiring `req.user.role === 'penyuluh' || req.user.role === 'admin'`:

```javascript
// src/routes/penyuluh.js
const express = require('express');
const router = express.Router();
const penyuluhController = require('../controllers/penyuluhController');
const { verifyToken } = require('../middlewares/authMiddleware');

const requirePenyuluh = (req, res, next) => {
  if (!req.user || !['penyuluh', 'admin'].includes(req.user.role)) {
    return res.status(403).json({
      success: false,
      message: 'Akses ditolak. Endpoint ini hanya dapat diakses oleh penyuluh atau administrator.'
    });
  }
  next();
};

router.use(verifyToken, requirePenyuluh);

router.get('/pending-farmers', penyuluhController.getPendingFarmers);
router.get('/farmers', penyuluhController.getAllFarmers);
router.put('/verify-farmer/:id', penyuluhController.verifyFarmer);

module.exports = router;
```

---

## Finding UPLOAD-01: Insecure File Upload Validation via Client-Controlled Content-Type Header

- **Identifier**: `UPLOAD-01:uploadMiddleware.js:25-34`
- **Verdict**: Confirmed
- **Severity**: High (Likelihood: High | Impact: Medium)
- **Subsystem**: File Handling (`lapaktani_backend/src/middlewares/uploadMiddleware.js`)
- **CWE**: CWE-434 (Unrestricted Upload of File with Dangerous Type)

### Description
In `src/middlewares/uploadMiddleware.js`, `fileFilter` verifies MIME type using `file.mimetype`. The `file.mimetype` property is directly populated from the HTTP multipart part `Content-Type` header supplied by the client:

```javascript
// src/middlewares/uploadMiddleware.js:25-34
const fileFilter = (req, file, cb) => {
  const allowedTypes = /jpeg|jpg|png|webp/;
  const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
  const mimetype = allowedTypes.test(file.mimetype);

  if (extname && mimetype) {
    return cb(null, true);
  }
  cb(new Error('Hanya file gambar (jpg, jpeg, png, webp) yang diperbolehkan!'));
};
```

Because `mimetype` is client-controlled, any binary or script payload named with an allowed extension (e.g. `payload.png`) and sent with `Content-Type: image/png` passes validation.

### Exploit Reproduction
1. Issue a multipart POST upload with script payload:
   ```http
   POST /api/upload/product-image HTTP/1.1
   Host: localhost:3000
   Content-Type: multipart/form-data; boundary=---------------------------974767299852498929531610575

   -----------------------------974767299852498929531610575
   Content-Disposition: form-data; name="image"; filename="exploit.html.png"
   Content-Type: image/png

   <script>alert('Stored XSS')</script>
   -----------------------------974767299852498929531610575--
   ```
2. The server accepts the upload, writes it to `public/uploads/products/product-[timestamp]-[rand].png`, and returns the public URL.
3. Accessing the file via Express static serving can execute client-side scripts if rendered by browsers without anti-sniffing headers.

### Remediation
1. Inspect binary magic numbers (file signatures) using a verification library (e.g. `file-type` or `sharp`).
2. Add `helmet` in `server.js` with `X-Content-Type-Options: nosniff`.
3. Set restrictive Content-Security-Policy headers on static asset routes.

---

## Finding AUTH-03: Inconsistent and Weak Hardcoded JWT Secret Fallbacks

- **Identifier**: `AUTH-03:authController.js:45`
- **Verdict**: Confirmed
- **Severity**: Medium (Likelihood: Medium | Impact: High)
- **Subsystem**: Key Management (`lapaktani_backend/src/controllers/authController.js`, `lapaktani_backend/src/middlewares/authMiddleware.js`)
- **CWE**: CWE-798 (Use of Hard-coded Credentials), CWE-321 (Use of Cryptographic Key Across Contexts)

### Description
Discrepant hardcoded default keys exist between token issuance and token verification:
- `src/controllers/authController.js:45`: `process.env.JWT_SECRET || 'lapaktani_secret_2026'`
- `src/middlewares/authMiddleware.js:28`: `process.env.JWT_SECRET || 'lapaktani_secret_jwt_key_2026'`

If `JWT_SECRET` is unset in the environment, tokens issued during registration/login cannot be decrypted by `authMiddleware.js`. Furthermore, hardcoded dictionary strings allow offline token forgery if source code is exposed.

### Remediation
Consolidate JWT secret management into a single configuration file (`src/config/jwt.js`). Refuse to launch in production if `JWT_SECRET` is not set or lacks adequate entropy.

---

## Finding DOS-01: Temporal Dead Zone ReferenceError in updateProduct Handler

- **Identifier**: `DOS-01:productController.js:351`
- **Verdict**: Confirmed
- **Severity**: Low (Likelihood: Medium | Impact: Low)
- **Subsystem**: Product Management (`lapaktani_backend/src/controllers/productController.js`)
- **CWE**: CWE-755 (Improper Handling of Exceptional Conditions)

### Description
In `src/controllers/productController.js` lines 351-352:
```javascript
if (image_urls.length > 0 && image_url === undefined) {
  updates.push('image_url = ?');
  params.push(image_urls[0]);
}
```
The variables `const updates = [];` and `const params = [];` are declared on lines 357-358. Accessing `updates` before its declaration triggers a JavaScript runtime `ReferenceError`, resulting in an unhandled 500 error.

### Remediation
Move the declarations of `updates` and `params` before line 340.
