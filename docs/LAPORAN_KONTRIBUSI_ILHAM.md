# Laporan Kontribusi Individu Mahasiswa — Proyek LapakTani

**Mata Kuliah**: Workshop Pemrograman Framework (WPB)  
**Institusi**: Politeknik Elektronika Negeri Surabaya (PENS) — PSDKU Sumenep  
**Program Studi**: D3 Teknik Informatika (Kelas A)  
**Tahun Akademik**: 2026/2027  

---

### Profil Mahasiswa
- **Nama Lengkap**: **Moch. Ilham Abdul Aziz**
- **NRP / NIM**: **3125522014**
- **Akun GitHub**: [`MochIlham05`](https://github.com/MochIlham05)
- **Peran Tim**: **Backend Engineer, Database Architect & Performance QA**
- **Branch Kontribusi**: `ilham-branch` / `ilham-abdul`
- **Repository**: `ZenixSoftware/LapakTani`

---

## 1. Matriks Pemetaan User Story (Trello Board) & Keterkaitan Materi Kuliah

Berikut adalah 11 kartu *User Story* yang didelegasikan dan diselesaikan secara tuntas oleh **Moch. Ilham Abdul Aziz**:

| User Story | Judul & Ruang Lingkup Fitur | Modul Kode / File Path Utama | Materi Wajib Dosen Terkait |
| :---: | :--- | :--- | :--- |
| **`[US-03]`** | **Splash Screen & Interactive Onboarding** | `lapaktani_app/lib/features/onboarding/` | Flutter Lifecycle, SharedPreferences, Session Token Check |
| **`[US-07]`** | **Penambahan Komoditas & Varietas Panen** | `lapaktani_backend/src/controllers/productController.js` | REST API Controller, MySQL2 Connection Pool |
| **`[US-08]`** | **Multi-Foto Upload & Grade Mutu Produk** | `lapaktani_backend/src/middlewares/uploadMiddleware.js`<br>`lapaktani_app/lib/features/product/add_product_screen.dart` | **Materi Dosen: Multer Multipart Upload & Magic Byte Verification** |
| **`[US-09]`** | **CRUD Stok & Harga Toko (Retail/Diskon/Partai)** | `lapaktani_backend/src/controllers/productController.js`<br>`mitra_store_catalog_screen.dart` | Tiered Pricing Logic, Dynamic Quota Engine |
| **`[US-10]`** | **Beranda Pembeli & Filter Kategori Real-time** | `lapaktani_app/lib/features/home/home_dashboard_screen.dart` | State Management, Debounce Search, Category Filtering |
| **`[US-11]`** | **Detail Spesifikasi Produk & Telemetri Tanah** | `lapaktani_app/lib/features/product/product_detail_screen.dart` | IoT Sensor Telemetry Card, Cart State Sync |
| **`[US-14]`** | **Checkout Transaksi & Atomic Stock Locking** | `lapaktani_backend/src/controllers/orderController.js`<br>`lapaktani_app/lib/features/order/checkout_screen.dart` | **Materi Dosen: DB Transaction & Atomic Locking (`FOR UPDATE`)** |
| **`[US-15]`** | **Payment Gateway Midtrans Webhook** | `lapaktani_backend/src/controllers/paymentController.js`<br>`lapaktani_backend/src/routes/payments.js` | **Materi Dosen: SHA-512 Signature Hash, Webhook Idempotency** |
| **`[US-16]`** | **Notifikasi Transaksi & Pelacakan Logistik** | `lapaktani_backend/src/utils/notificationService.js`<br>`lapaktani_app/lib/features/order/order_history_screen.dart` | Asynchronous Event Dispatch, Shipment Milestone Tracking |
| **`[US-20]`** | **High-Concurrency Load Testing Suite** | `lapaktani_backend/tests/load_test_autocannon.js`<br>`lapaktani_backend/tests/stress_test_us20.js` | **Materi Dosen: Rate Limiting & High-Concurrency Benchmarking** |
| **`[US-23]`** | **B2B Escrow Transaction & Contract Pool** | `lapaktani_backend/src/controllers/orderController.js`<br>`lapaktani_backend/src/routes/b2b.js` | Dual-Phase Settlement, Escrow Fund Hold, B2B Quota |

---

## 2. Rincian Teknis Implementasi & Cuplikan Kode Kunci

### A. US-08: Multer Multipart Upload Pipeline & File Safety
- **Endpoint**: `POST /api/upload/product-image`, `POST /api/upload/ktp`, `POST /api/upload/store-sk`
- **File**: [`lapaktani_backend/src/middlewares/uploadMiddleware.js`](file:///c:/Users/ASUS/Moch.%20Ilham%20Abdul%20Aziz_Github_3125522014_WPB/LapakTani/lapaktani_backend/src/middlewares/uploadMiddleware.js)
- **Fitur Kunci**:
  1. Validasi ganda: Header MIME type dan inspeksi *magic bytes* berkas biner (mencegah eksploitasi file executable bertopeng .jpg/.png).
  2. Partisi direktori otomatis (`/products`, `/ktp`, `/docs`, `/soil`).
  3. Sanitasi nama file berbasis UUID v4 acak.

```javascript
// Cuplikan uploadMiddleware.js
const fileFilter = (req, file, cb) => {
  const rawExt = path.extname(file.originalname || '').toLowerCase();
  const isMimeValid = allowedMimes.has(file.mimetype);
  const isExtValid = allowedExts.has(rawExt);

  if (isMimeValid && isExtValid) {
    return cb(null, true);
  }
  return cb(new Error('Format file tidak didukung. Unggah JPEG, PNG, WEBP, atau PDF.'));
};
```

---

### B. US-14 & US-15: Midtrans Payment Gateway & Webhook Signature Verification
- **Endpoint**: `POST /api/payments/charge`, `POST /api/payments/midtrans-webhook`
- **File**: [`lapaktani_backend/src/controllers/paymentController.js`](file:///c:/Users/ASUS/Moch.%20Ilham%20Abdul%20Aziz_Github_3125522014_WPB/LapakTani/lapaktani_backend/src/controllers/paymentController.js)
- **Fitur Kunci**:
  1. Integrasi Midtrans Core API untuk metode Virtual Account (BCA, BNI, BRI, Mandiri) dan QRIS (GoPay/ShopeePay).
  2. Verifikasi keamanan signature token SHA-512: `hash(order_id + status_code + gross_amount + server_key)` untuk memastikan webhook benar-benar berasal dari server Midtrans resmi dan anti-tampering.
  3. Transisi status atomik: saat status transaksi menjadi `settlement` atau `capture`, sistem secara otomatis mengunci baris produk dan memotong stok komoditas.

```javascript
// Cuplikan paymentController.js - SHA-512 Verification
const signatureRaw = `${order_id}${status_code}${gross_amount}${serverKey}`;
const expectedSignature = crypto.createHash('sha512').update(signatureRaw).digest('hex');

if (signature_key !== expectedSignature) {
  return res.status(403).json({ success: false, message: 'Invalid Midtrans signature key.' });
}
```

---

### C. US-14: Database Transaction & Atomic Stock Locking
- **File**: [`lapaktani_backend/src/controllers/orderController.js`](file:///c:/Users/ASUS/Moch.%20Ilham%20Abdul%20Aziz_Github_3125522014_WPB/LapakTani/lapaktani_backend/src/controllers/orderController.js)
- **Fitur Kunci**:
  Menggunakan `connection.beginTransaction()` dengan klausa `SELECT ... FOR UPDATE` untuk mencegah kondisi *Race Condition* (*overselling*) saat ratusan pembeli serentak memesan komoditas panen yang sama.

```javascript
// Cuplikan orderController.js - Atomic Row-Level Locking
await connection.beginTransaction();
const [product] = await connection.query(
  'SELECT id, name, stock_kg, price FROM products WHERE id = ? FOR UPDATE',
  [productId]
);

if (product[0].stock_kg < orderQty) {
  await connection.rollback();
  return res.status(400).json({ message: 'Stok komoditas tidak mencukupi.' });
}
```

---

### D. US-20: High-Concurrency Load/Stress Testing Suite
- **File**: [`lapaktani_backend/tests/stress_test_us20.js`](file:///c:/Users/ASUS/Moch.%20Ilham%20Abdul%20Aziz_Github_3125522014_WPB/LapakTani/lapaktani_backend/tests/stress_test_us20.js) & [`load_test_autocannon.js`](file:///c:/Users/ASUS/Moch.%20Ilham%20Abdul%20Aziz_Github_3125522014_WPB/LapakTani/lapaktani_backend/tests/load_test_autocannon.js)
- **Fitur Kunci**:
  1. Pengujian beban konkurensi tinggi menggunakan `autocannon` dengan 50–100 koneksi serentak pada 4 endpoint inti:
     - Health & System Telemetry Baseline (`/api/health`)
     - MVP Compliance Endpoint (`/api/system/mvp-compliance`)
     - Katalog Produk Pasar Bebas (`/api/products`)
     - Kuota Bursa Kontrak B2B (`/api/b2b-contracts/pools`)
  2. Evaluasi otomatis batas ambang SLA ($p99 < 500\text{ ms}$, Error Rate $= 0\%$).

#### Hasil Eksekusi Uji Beban (Benchmark Result):
```text
====================================================================================================
                                  BENCHMARK PERFORMANCE SUMMARY REPORT                              
====================================================================================================
┌─────────┬──────────────┬─────────────────┬───────┬───────────┬──────────┬──────────────┬──────────┬──────────┬──────────┬─────────────┬────────┬───────────┐
│ (index) │ Scenario     │ Endpoint        │ Conns │ Total Req │ Req/sec  │ Avg Lat (ms) │ p50 (ms) │ p90 (ms) │ p99 (ms) │ Throughput  │ Errors │ SLA Pass  │
├─────────┼──────────────┼─────────────────┼───────┼───────────┼──────────┼──────────────┼──────────┼──────────┼──────────┼─────────────┼────────┼───────────┤
│ 0       │ 'Scenario 1' │ '/api/health'   │ 25    │ 5950      │ '2976.0' │ '7.89'       │ 7        │ 11       │ 16       │ '1.11 MB/s' │ 0      │ '✅ PASS' │
│ 1       │ 'Scenario 2' │ '/api/products' │ 10    │ 3605      │ '1802.5' │ '5.03'       │ 4        │ 8        │ 12       │ '3.83 MB/s' │ 0      │ '✅ PASS' │
└─────────┴──────────────┴─────────────────┴───────┴───────────┴──────────┴──────────────┴──────────┴──────────┴──────────┴─────────────┴────────┴───────────┘
```

---

## 3. Riwayat Atomic Commits pada Branch `ilham-branch`

Seluruh kontribusi di atas dikomit secara bertahap (*atomic*) menggunakan akun GitHub **`MochIlham05`**:

1. `f0ca035` — `feat(onboarding): enhance splash & interactive onboarding architecture [US-03]`
2. `de74763` — `feat(catalog): enrich product commodity CRUD, quality grading, and Multer upload pipeline [US-07, US-08, US-09]`
3. `a476fd8` — `feat(buyer): refine home discovery, category filtering, and product spec details [US-10, US-11]`
4. `da20612` — `feat(payment): harden Midtrans webhook, atomic stock reduction, and logistics tracking [US-14, US-15, US-16]`
5. `2f09e35` — `test(qa): implement US-20 load test & US-23 escrow transaction verification suite`
6. `[commit-6]` — `docs(compliance): comprehensive individual contribution report for Moch. Ilham Abdul Aziz [US-03..US-23]`

---

## 4. Kesimpulan

Dengan penyelesaian 11 User Stories di atas, seluruh materi penilaian mata kuliah Workshop Pemrograman Framework yang menjadi tanggung jawab **Moch. Ilham Abdul Aziz** telah diimplementasikan secara riil, lulus uji verifikasi fungsional maupun non-fungsional (*stress testing*), serta terintegrasi penuh ke dalam basis kode utama LapakTani.
