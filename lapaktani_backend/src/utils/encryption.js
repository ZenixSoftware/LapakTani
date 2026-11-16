const crypto = require('crypto');

const CIPHER_PREFIX = 'enc:v1:';
const ALGORITHM = 'aes-256-cbc';

function deriveEncryptionKey() {
  const secretSource =
    process.env.ENCRYPTION_SECRET ||
    process.env.LAPAKTANI_API_KEY ||
    process.env.JWT_SECRET ||
    'lapaktani_aes256_master_key_2026';

  return crypto.createHash('sha256').update(String(secretSource)).digest();
}

/**
 * Encrypt plaintext UTF-8 string using AES-256-CBC with a fresh 16-byte random IV.
 */
function encryptData(plainText) {
  if (plainText === undefined || plainText === null || plainText === '') {
    return null;
  }
  const str = String(plainText);
  if (str.startsWith(CIPHER_PREFIX)) {
    return str;
  }

  const key = deriveEncryptionKey();
  const iv = crypto.randomBytes(16);
  const cipher = crypto.createCipheriv(ALGORITHM, key, iv);
  let encryptedHex = cipher.update(str, 'utf8', 'hex');
  encryptedHex += cipher.final('hex');

  return `${CIPHER_PREFIX}${iv.toString('hex')}:${encryptedHex}`;
}

/**
 * Decrypt AES-256-CBC ciphertext produced by encryptData.
 * Legacy unencrypted values are returned unchanged for backward compatibility.
 */
function decryptData(cipherPayload) {
  if (cipherPayload === undefined || cipherPayload === null) {
    return cipherPayload;
  }
  const str = String(cipherPayload);
  if (!str.startsWith(CIPHER_PREFIX)) {
    return str;
  }

  const body = str.slice(CIPHER_PREFIX.length);
  const parts = body.split(':');
  if (parts.length !== 2) {
    return str;
  }

  const [ivHex, encryptedHex] = parts;
  const key = deriveEncryptionKey();
  const iv = Buffer.from(ivHex, 'hex');
  const decipher = crypto.createDecipheriv(ALGORITHM, key, iv);
  let decrypted = decipher.update(encryptedHex, 'hex', 'utf8');
  decrypted += decipher.final('utf8');
  return decrypted;
}

function encryptJsonPayload(obj) {
  return encryptData(JSON.stringify(obj ?? {}));
}

function decryptJsonPayload(cipherText) {
  const raw = decryptData(cipherText);
  if (!raw) return null;
  try {
    return JSON.parse(raw);
  } catch (_) {
    return raw;
  }
}

function maskNik(nik) {
  const raw = decryptData(nik);
  if (!raw) return '';
  const s = String(raw).trim();
  if (s.length <= 6) return '*'.repeat(s.length);
  return `${s.slice(0, 4)}${'*'.repeat(Math.max(4, s.length - 6))}${s.slice(-2)}`;
}

function verifyEncryptionSelfTest() {
  const probeText = `LapakTani-NIK-3529010101900001@${Date.now()}`;
  const sampleCipher = encryptData(probeText);
  const roundtrip = decryptData(sampleCipher);
  return {
    algorithm: 'AES-256-CBC',
    ivLengthBytes: 16,
    keyLengthBits: 256,
    roundtripVerified: roundtrip === probeText,
    sampleCipherPrefix: sampleCipher ? `${sampleCipher.slice(0, 28)}...` : null,
  };
}

module.exports = {
  CIPHER_PREFIX,
  ALGORITHM,
  encryptData,
  decryptData,
  encryptJsonPayload,
  decryptJsonPayload,
  maskNik,
  verifyEncryptionSelfTest,
};
