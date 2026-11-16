const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { v4: uuidv4 } = require('uuid');

const BASE_UPLOADS_DIR = path.resolve(__dirname, '../../public/uploads');
const UPLOAD_SUBDIRS = {
  products: path.join(BASE_UPLOADS_DIR, 'products'),
  ktp: path.join(BASE_UPLOADS_DIR, 'ktp'),
  docs: path.join(BASE_UPLOADS_DIR, 'docs'),
  soil: path.join(BASE_UPLOADS_DIR, 'soil'),
};

for (const dirPath of Object.values(UPLOAD_SUBDIRS)) {
  if (!fs.existsSync(dirPath)) {
    fs.mkdirSync(dirPath, { recursive: true });
  }
}

const IMAGE_MIME_TYPES = new Set(['image/jpeg', 'image/png', 'image/webp']);
const IMAGE_EXTENSIONS = new Set(['.jpg', '.jpeg', '.png', '.webp']);
const DOC_MIME_TYPES = new Set(['image/jpeg', 'image/png', 'image/webp', 'application/pdf']);
const DOC_EXTENSIONS = new Set(['.jpg', '.jpeg', '.png', '.webp', '.pdf']);

function createUploader(subFolder = 'products', allowPdf = false) {
  const targetDir = UPLOAD_SUBDIRS[subFolder] || UPLOAD_SUBDIRS.products;
  const allowedMimes = allowPdf ? DOC_MIME_TYPES : IMAGE_MIME_TYPES;
  const allowedExts = allowPdf ? DOC_EXTENSIONS : IMAGE_EXTENSIONS;

  const storage = multer.diskStorage({
    destination: (req, file, cb) => {
      if (!fs.existsSync(targetDir)) {
        fs.mkdirSync(targetDir, { recursive: true });
      }
      cb(null, targetDir);
    },
    filename: (req, file, cb) => {
      const rawExt = path.extname(file.originalname || '').toLowerCase();
      const safeExt = allowedExts.has(rawExt) ? rawExt : '.jpg';
      const prefix = subFolder === 'products' ? 'upload' : subFolder;
      cb(null, `${prefix}-${uuidv4()}${safeExt}`);
    }
  });

  const fileFilter = (req, file, cb) => {
    const rawExt = path.extname(file.originalname || '').toLowerCase();
    const isMimeValid = allowedMimes.has(file.mimetype);
    const isExtValid = allowedExts.has(rawExt);

    if (isMimeValid && isExtValid) {
      return cb(null, true);
    }
    return cb(
      new Error(
        allowPdf
          ? 'Hanya file gambar (JPG/PNG/WEBP) atau dokumen PDF yang diperbolehkan!'
          : 'Hanya file gambar (image/jpeg, image/png, image/webp) yang diperbolehkan!'
      )
    );
  };

  return multer({
    storage,
    limits: {
      fileSize: 10 * 1024 * 1024,
      files: 1
    },
    fileFilter
  });
}

/**
 * Validates binary magic bytes for JPEG, PNG, WEBP, and optionally PDF (%PDF).
 * Inspects first 12 bytes of uploaded file.
 */
const validateFileMagicBytes = (filePath, allowPdf = false) => {
  if (!filePath || !fs.existsSync(filePath)) {
    return false;
  }
  let fd;
  try {
    fd = fs.openSync(filePath, 'r');
    const buffer = Buffer.alloc(12);
    const bytesRead = fs.readSync(fd, buffer, 0, 12, 0);
    if (bytesRead < 4) {
      return false;
    }

    // PDF check when explicitly allowed & .pdf extension or %PDF signature
    if (allowPdf) {
      const isPdf =
        buffer[0] === 0x25 && // %
        buffer[1] === 0x50 && // P
        buffer[2] === 0x44 && // D
        buffer[3] === 0x46;   // F
      if (isPdf) return true;
    }

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

const validateImageMagicBytes = (filePath) => validateFileMagicBytes(filePath, false);

/**
 * Middleware that immediately verifies magic bytes after Multer write.
 * Unlinks file and aborts if spoofed or invalid.
 */
const validateUploadMagicBytes = (req, res, next) => {
  if (!req.file) {
    return next();
  }

  const ext = path.extname(req.file.originalname || req.file.filename || '').toLowerCase();
  const allowPdf = ext === '.pdf' || req.file.mimetype === 'application/pdf';
  const isValid = validateFileMagicBytes(req.file.path, allowPdf);
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

const uploadProductImage = createUploader('products', false);
const uploadKtpDocument = createUploader('ktp', false);
const uploadStoreSkDocument = createUploader('docs', true);
const uploadFieldPhoto = createUploader('soil', false);

module.exports = {
  upload: uploadProductImage,
  uploadProductImage,
  uploadKtpDocument,
  uploadStoreSkDocument,
  uploadFieldPhoto,
  UPLOAD_SUBDIRS,
  createUploader,
  validateImageMagicBytes,
  validateFileMagicBytes,
  validateUploadMagicBytes
};
