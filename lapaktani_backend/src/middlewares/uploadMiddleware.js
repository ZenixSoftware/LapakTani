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

module.exports = upload;
