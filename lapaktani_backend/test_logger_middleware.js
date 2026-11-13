/**
 * Unit Test / Verifikasi Middleware: Request Logger & Performance Monitoring
 */
const assert = require('assert');
const { EventEmitter } = require('events');
const { requestLogger, getStatusColor, getFormattedTimestamp } = require('./src/middlewares/loggerMiddleware');

function createMockReqRes(method = 'GET', url = '/api/products') {
  const req = {
    method,
    url,
    originalUrl: url,
    headers: { 'x-forwarded-for': '192.168.1.100' },
    socket: { remoteAddress: '127.0.0.1' }
  };

  const res = new EventEmitter();
  res.statusCode = 200;
  res.headersSent = false;
  res.headers = {};

  res.setHeader = function (key, value) {
    res.headers[key.toLowerCase()] = value;
  };

  res.writeHead = function (code) {
    if (code) res.statusCode = code;
    return res;
  };

  res.send = function () {
    res.emit('finish');
    return res;
  };

  return { req, res };
}

async function runTests() {
  console.log('=== [TEST] Uji Coba Middleware: Request Logger & Performance Monitoring ===\n');
  let passed = 0;

  // Test 1: Middleware melanjutkan eksekusi ke next()
  console.log('1. Menguji fungsi pemanggilan callback next()...');
  const { req: req1, res: res1 } = createMockReqRes('GET', '/api/products');
  let nextCalled = false;
  requestLogger(req1, res1, () => {
    nextCalled = true;
  });
  assert.strictEqual(nextCalled, true, 'Middleware wajib memanggil next() agar router berikutnya dapat dieksekusi.');
  console.log('   ✓ Callback next() berhasil dipanggil.');
  passed++;

  // Test 2: Injeksi Header X-Response-Time
  console.log('\n2. Menguji injeksi Header X-Response-Time pada respon HTTP...');
  const { req: req2, res: res2 } = createMockReqRes('POST', '/api/auth/login');
  requestLogger(req2, res2, () => {});
  
  // Simulasi proses komputasi ringan
  await new Promise(resolve => setTimeout(resolve, 15));
  res2.writeHead(200);
  res2.send();

  assert(res2.headers['x-response-time'], 'Header X-Response-Time harus disematkan pada response.');
  assert(res2.headers['x-response-time'].endsWith('ms'), 'Format X-Response-Time harus berupa milidetik (ms).');
  console.log(`   ✓ Header X-Response-Time terverifikasi: ${res2.headers['x-response-time']}`);
  passed++;

  // Test 3: Formatting timestamp & status colors
  console.log('\n3. Menguji pewarnaan status dan formatting timestamp...');
  const timestamp = getFormattedTimestamp();
  assert(timestamp.length >= 19, 'Timestamp harus terformat rapi (YYYY-MM-DD HH:mm:ss)');
  
  const green = getStatusColor(200);
  const yellow = getStatusColor(404);
  const red = getStatusColor(500);
  assert(green.includes('32'), 'Status 200 harus berwarna hijau');
  assert(yellow.includes('33'), 'Status 404 harus berwarna kuning');
  assert(red.includes('31'), 'Status 500 harus berwarna merah');
  console.log(`   ✓ Timestamp: ${timestamp}`);
  console.log(`   ✓ Color mapping berhasil: 200 (Hijau), 404 (Kuning), 500 (Merah)`);
  passed++;

  console.log('\n======================================================');
  console.log(`🎉 SEMUA PENGUJIAN (${passed}/3) MIDDLEWARE BERHASIL LOLOS!`);
  console.log('Middleware siap digunakan pada SEMUA router LapakTani.');
  console.log('======================================================\n');
}

runTests().catch(err => {
  console.error('❌ Gagal pengujian:', err);
  process.exit(1);
});
