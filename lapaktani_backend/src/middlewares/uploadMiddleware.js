const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { v4: uuidv4 } = require('uuid');

const uploadDir = path.resolve(__dirname, '../../public/uploads/products');

if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

const ALLOWED_MIME_TYPES = new Set(['image/jpeg', 'image/png', 'image/webp']);
const ALLOWED_EXTENSIONS = new Set(['.jpg', '.jpeg', '.png', '.webp']);

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const rawExt = path.extname(file.originalname || '').toLowerCase();
    const safeExt = ALLOWED_EXTENSIONS.has(rawExt) ? rawExt : '.jpg';
    cb(null, `upload-${uuidv4()}${safeExt}`);
  }
});

const fileFilter = (req, file, cb) => {
  const rawExt = path.extname(file.originalname || '').toLowerCase();
  const isMimeValid = ALLOWED_MIME_TYPES.has(file.mimetype);
  const isExtValid = ALLOWED_EXTENSIONS.has(rawExt);

  if (isMimeValid && isExtValid) {
    return cb(null, true);
  }
  return cb(new Error('Hanya file gambar (image/jpeg, image/png, image/webp) yang diperbolehkan!'));
};

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 10 * 1024 * 1024,
    files: 1
  },
  fileFilter: fileFilter
});

/**
 * Validates binary magic bytes for JPEG, PNG, and WEBP.
 * Inspects first 12 bytes of uploaded file.
 */
const validateImageMagicBytes = (filePath) => {
  if (!filePath || !fs.existsSync(filePath)) {
    return false;
  }
  let fd;
  try {
    fd = fs.openSync(filePath, 'r');
    const buffer = Buffer.alloc(12);
    const bytesRead = fs.readSync(fd, buffer, 0, 12, 0);
    if (bytesRead < 12) {
      return false;
    }

    // JPEG check: bytes 0..2 == FF D8 FF
    const isJpeg = buffer[0] === 0xFF && buffer[1] === 0xD8 && buffer[2] === 0xFF;
    if (isJpeg) return true;

    // PNG check: bytes 0..7 == 89 50 4E 47 0D 0A 1A 0A
    const isPng =
      buffer[0] === 0x89 &&
      buffer[1] === 0x50 &&
      buffer[2] === 0x4E &&
      buffer[3] === 0x47 &&
      buffer[4] === 0x0D &&
      buffer[5] === 0x0A &&
      buffer[6] === 0x1A &&
      buffer[7] === 0x0A;
    if (isPng) return true;

    // WEBP check: bytes 0..3 == 52 49 46 46 (RIFF) AND bytes 8..11 == 57 45 42 50 (WEBP)
    const isWebp =
      buffer[0] === 0x52 &&
      buffer[1] === 0x49 &&
      buffer[2] === 0x46 &&
      buffer[3] === 0x46 &&
      buffer[8] === 0x57 &&
      buffer[9] === 0x45 &&
      buffer[10] === 0x42 &&
      buffer[11] === 0x50;
    if (isWebp) return true;

    return false;
  } catch (err) {
    console.error('[SECURITY] Magic bytes inspection failed:', err.message);
    return false;
  } finally {
    if (fd !== undefined) {
      try {
        fs.closeSync(fd);
      } catch (_) {}
    }
  }
};

/**
 * Middleware that immediately verifies magic bytes after Multer write.
 * Unlinks file and aborts if spoofed or invalid.
 */
const validateUploadMagicBytes = (req, res, next) => {
  if (!req.file) {
    return next();
  }

  const isValid = validateImageMagicBytes(req.file.path);
  if (!isValid) {
    try {
      if (fs.existsSync(req.file.path)) {
        fs.unlinkSync(req.file.path);
      }
    } catch (_) {}

    return res.status(400).json({
      success: false,
      message: 'File biner tidak valid atau terindikasi spoofing.'
    });
  }

  next();
};

module.exports = {
  upload,
  validateImageMagicBytes,
  validateUploadMagicBytes
};
