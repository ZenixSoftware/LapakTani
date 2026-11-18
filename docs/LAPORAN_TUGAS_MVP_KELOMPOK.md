# Laporan Implementasi MVP & Kepatuhan 9 Materi Teknis Workshop — Proyek LapakTani

**Program Studi / Institusi**: Workshop Pemrograman Framework — Politeknik Elektronika Negeri Surabaya (PENS) Kampus Sumenep  
**Nama Proyek**: **LapakTani** (*Ekosistem Agribisnis Hulu–ke–Hilir, Forward Contract B2B, & Monitoring Agronomi Sumenep*)  
**Repository & Branch Aktif**: `ZenixSoftware/LapakTani` — Branch `valo-Branch`  
**Domain Produksi Cloudflare Tunnel**:
- Backend REST API: `https://api-lapaktani.velosixraptor.my.id/api`
- Web Portal Penyuluh (PPL), Dinas Pertanian & Super Admin: `https://lapaktani.velosixraptor.my.id` *(alias lama: `https://ppl-lapaktani.velosixraptor.my.id`)*

**Anggota Kelompok**:
1. **M. Davana Yudista Firdausy** *(Lead Full-Stack, Security, DevOps & Flutter/Backend Architect)*
2. **Moch. Ilham Abdul Aziz** *(Backend Database, Payment Gateway Midtrans, Pest Alert & Stress Testing)*
3. **Rafael Rizky** *(Poktan Consolidation, Fulfillment Tracking, & GIS Sumenep Integration)*
4. **Hafizhah Naya** *(Buyer Home/Category Discovery, Edukasi PPL, Spot Market & Peta Sebaran)*

---

## Bagian 1 — Matriks Eksekutif 9 Materi Wajib Dosen (MVP Technical Compliance Matrix)

Seluruh **9 materi teknis wajib** dari perkuliahan Workshop Pemrograman Framework telah diimplementasikan secara eksplisit pada `lapaktani_backend`, terintegrasi aktif di `lapaktani_backend/server.js`, dan dapat diaudit secara *real-time* melalui endpoint diagnostik **`GET /api/system/mvp-compliance`**.

| No | Materi Wajib Dosen | Status | Modul & Baris Kode Utama | Bukti Mekanisme & Header / Endpoint Verifikasi |
| :-: | :--- | :---: | :--- | :--- |
| **1** | **JWT Multi-Role Auth** (`petani`, `penyuluh`, `admin`, `pembeli`, `dinas`, `superadmin`) | VERIFIED | `lapaktani_backend/src/middlewares/authMiddleware.js` (`L4-L140`)<br>`lapaktani_backend/src/controllers/authController.js` (`L8-L240`) | `signUserToken`, `verifyRawToken`, `verifyToken`, `optionalVerifyToken`, `requireRole` mendukung 6 role (`ROLE_ID_MAP` ID 1–6) + `admin_tier` pada `POST /api/auth/login` & penguncian registrasi otoritas di `/register`. |
| **2** | **Multer Multipart File Upload** | ACTIVE | `lapaktani_backend/src/middlewares/uploadMiddleware.js` (`L1-L190`)<br>`lapaktani_backend/src/routes/upload.js` (`L1-L72`)<br>`lapaktani_backend/src/controllers/uploadController.js` (`L1-L40`) | Upload `multipart/form-data` terpisah untuk foto produk (`/product-image`), KTP (`/ktp`), SK toko PDF/gambar (`/store-sk`), dan foto lahan (`/field-photo`) lengkap dengan inspeksi *magic bytes* (`JPEG`, `PNG`, `WEBP`, `%PDF`). |
| **3** | **HTTP Response Compression** | ACTIVE | `lapaktani_backend/src/middlewares/compressionMiddleware.js` (`L1-L135`)<br>`lapaktani_backend/server.js` (`L72`) | Kompresi respons API menggunakan Node `zlib` (`gzip`/`deflate`), mengatur header `X-Response-Compressed: true`, `X-Compression-Engine: native-zlib-gzip`, `X-Original-Bytes`, dan `X-Compressed-Bytes`. |
| **4** | **Cache in Node (L1 In-Memory TTL)** | VERIFIED | `lapaktani_backend/src/utils/nodeCache.js` (`L5-L133`)<br>`lapaktani_backend/src/controllers/agroSupplyChainController.js` (`L41-L97`, `L822-L855`)<br>`lapaktani_backend/src/controllers/masterDataController.js` (`L1-L108`) | Kelas `LapakTaniNodeCache` menyimpan data referensi wilayah Sumenep (`sumenep_regions_villages`), kuota toko desa (`sumenep_villages_quota`), serta master komoditas/grade/satuan dengan TTL & invalidasi otomatis. Mengembalikan header `X-Node-Cache: HIT \| MISS`. |
| **5** | **Cache in Redis (L2 Distributed Cache)** | ACTIVE | `lapaktani_backend/src/config/redis.js` (`L1-L145`)<br>`lapaktani_backend/src/controllers/productController.js` (`L100-L220`)<br>`lapaktani_backend/src/controllers/penyuluhController.js` (`L568-L645`) | Klien Redis (`localhost:6379`, RESP 2) dengan `getCache`, `setCache`, `delCache`, dan buffer resilien untuk katalog produk (`lapaktani_catalog`), ringkasan GIS (`gis_monitoring_summary`), dan sesi login (`session_state:*`). Mengembalikan `X-Redis-Cache: HIT \| MISS`. |
| **6** | **Asynchronous Background Job Queue** | ACTIVE | `lapaktani_backend/src/utils/jobQueue.js` (`L10-L258`)<br>`lapaktani_backend/src/controllers/orderController.js`<br>`lapaktani_backend/src/controllers/agroSupplyChainController.js` (`L743-L760`) | Kelas `LapakTaniJobQueue` menggunakan dual backend (`redis+memory_worker`) dengan *retry exponential backoff* (maks. 3 percobaan) untuk 4 tipe job: `ORDER_NOTIFICATION_DISPATCH`, `HARVEST_BROADCAST_FANOUT`, `WHATSAPP_FONNTE_DISPATCH`, dan `SERVER_LOSS_RECOVERY_ALERT`. |
| **7** | **Sliding-Window Rate Limiter** | ACTIVE | `lapaktani_backend/src/middlewares/rateLimiter.js` (`L22-L122`)<br>`lapaktani_backend/server.js` (`L77`, `L253`, `L261`) | Pembatasan trafik berbasis *sliding window* pada `/api` (300 req/menit), `/api/auth` (60 req/menit), dan `/api/orders` (120 req/menit). Mengembalikan header `X-RateLimit-Limit`, `X-RateLimit-Remaining`, dan status HTTP `429 Too Many Requests`. |
| **8** | **Enkripsi Berlapis (`AES-256-CBC`, `bcrypt`, `X-API-Key`)** | VERIFIED | `lapaktani_backend/src/utils/encryption.js` (`L1-L110`)<br>`lapaktani_backend/src/middlewares/apiKeyMiddleware.js` (`L24-L81`)<br>`lapaktani_backend/src/controllers/profileController.js`<br>`lapaktani_backend/src/controllers/orderController.js` (`L431-L438`) | Enkripsi `AES-256-CBC` (`encryptData` / `decryptData` / `encryptJsonPayload`) untuk NIK & *escrow seal* checkout, hashing sandi `bcryptjs`, serta validasi global 256-bit `X-API-Key` menggunakan `crypto.timingSafeEqual`. |
| **9** | **Notifikasi Transaksi & Server Loss Guard** | VERIFIED | `lapaktani_backend/src/utils/notificationService.js` (`L27-L276`)<br>`lapaktani_backend/server.js` (`L60`)<br>`lapaktani_backend/src/controllers/orderController.js` (`L538-L547`, `L746-L756`, `L1249-L1258`)<br>`lapaktani_backend/src/controllers/paymentController.js` (`L263-L270`) | `notifyTransactionEvent` memicu notifikasi DB + antrean job saat order dibuat, dibayar via Midtrans webhook, dikirim, hingga selesai. `registerServerLossHandlers` menjaga `uncaughtException`, `unhandledRejection`, dan error pool MySQL/Redis agar insiden tercatat dan antrean pemulihan aktif tanpa menjatuhkan proses. |

### Perintah Uji `curl` untuk Setiap Materi (9/9)

> Gunakan nilai `LAPAKTANI_API_KEY` aktif dari konfigurasi environment Anda sebagai `<LAPAKTANI_API_KEY>`.

1. **Verifikasi Diagnostik Terpusat 9 Materi (`GET /api/system/mvp-compliance`)**
```bash
curl -s -i -H "X-API-Key: <LAPAKTANI_API_KEY>" "http://localhost:3000/api/system/mvp-compliance?enqueue_test=true"
```

2. **Uji Materi 1 — JWT Multi-Role (`POST /api/auth/login`)**
```bash
curl -s -X POST -H "Content-Type: application/json" -H "X-API-Key: <LAPAKTANI_API_KEY>" \
  -d "{\"email\":\"penyuluh@lapaktani.id\",\"password\":\"password123\"}" \
  http://localhost:3000/api/auth/login
```

3. **Uji Materi 2 — Multer Multipart Upload + Magic Bytes (`POST /api/upload/store-sk`)**
```bash
curl -s -X POST -H "X-API-Key: <LAPAKTANI_API_KEY>" \
  -F "document=@/path/to/sk_poktan.pdf" \
  http://localhost:3000/api/upload/store-sk
```

4. **Uji Materi 3 — HTTP Compression Gzip (`Content-Encoding: gzip` & `X-Response-Compressed: true`)**
```bash
curl -s -i -H "Accept-Encoding: gzip" -H "X-API-Key: <LAPAKTANI_API_KEY>" --compressed \
  http://localhost:3000/api/products
```

5. **Uji Materi 4 — L1 Cache in Node (`X-Node-Cache: MISS` -> `HIT`)**
```bash
curl -s -D - -o /dev/null -H "X-API-Key: <LAPAKTANI_API_KEY>" http://localhost:3000/api/regions/sumenep
curl -s -D - -o /dev/null -H "X-API-Key: <LAPAKTANI_API_KEY>" http://localhost:3000/api/regions/sumenep
```

6. **Uji Materi 5 — L2 Cache in Redis (`X-Redis-Cache: MISS` -> `HIT`)**
```bash
curl -s -D - -o /dev/null -H "X-API-Key: <LAPAKTANI_API_KEY>" http://localhost:3000/api/products
curl -s -D - -o /dev/null -H "X-API-Key: <LAPAKTANI_API_KEY>" http://localhost:3000/api/products
```

7. **Uji Materi 6 — Background Job Queue (`LapakTaniJobQueue` via `/api/system/mvp-compliance`)**
```bash
curl -s -H "X-API-Key: <LAPAKTANI_API_KEY>" "http://localhost:3000/api/system/mvp-compliance?enqueue_test=true"
```

8. **Uji Materi 7 — Rate Limiter Sliding Window (`200` -> `200` -> `429 Too Many Requests`)**
```bash
curl -s -o /dev/null -w "%{http_code}\n" -H "X-API-Key: <LAPAKTANI_API_KEY>" -H "X-RateLimit-Test-Limit: 2" http://localhost:3000/api/health
curl -s -o /dev/null -w "%{http_code}\n" -H "X-API-Key: <LAPAKTANI_API_KEY>" -H "X-RateLimit-Test-Limit: 2" http://localhost:3000/api/health
curl -s -i -H "X-API-Key: <LAPAKTANI_API_KEY>" -H "X-RateLimit-Test-Limit: 2" http://localhost:3000/api/health
```

9. **Uji Materi 8 & 9 — Proteksi `X-API-Key` (Tanpa Key -> `401 Unauthorized`) & Transaksi/Failover Audit**
```bash
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:3000/api/health
```

> **Hasil Observasi Uji Lokal (MySQL 8.4 + Redis 6379 aktif)**:
> - Request tanpa `X-API-Key` ke `/api/health` -> `401 Unauthorized`.
> - `GET /api/system/mvp-compliance` -> `200 OK`, `compliance_score: "9/9 (100%)"`, `X-Response-Compressed: true`, `redisMode: "live_redis_server"`.
> - `GET /api/regions/sumenep` -> `200 MISS` diikuti `200 HIT` (`X-Node-Cache`).
> - `GET /api/products` -> `200 MISS` diikuti `200 HIT` (`X-Redis-Cache`), dan kompresi Gzip menurunkan ukuran respons dari `5.286` bytes menjadi `1.021` bytes (`Content-Encoding: gzip`).
> - `GET /api/health` dengan `X-RateLimit-Test-Limit: 2` -> `200`, `200`, kemudian `429 Too Many Requests` (`X-RateLimit-Remaining: 1 -> 0 -> 0`).

---

## Bagian 2 — Rincian Penyelesaian User Story Individu: M. Davana Yudista Firdausy

Berdasarkan pembagian kartu Trello resmi (`UbzpfVZu - lapaktani.json`) dan integrasi *full-stack* lintas repository (`lapaktani_backend`, `lapaktani_web`, dan `lapaktani_app`), berikut pemetaan kontribusi dan penyelesaian User Story oleh **M. Davana Yudista Firdausy**:

### A. User Stories Fokus MVP yang Diminta

| Kode Trello | Nama User Story | Implementasi Backend (`lapaktani_backend`) | Implementasi Web (`lapaktani_web`) | Implementasi Mobile (`lapaktani_app`) |
| :--- | :--- | :--- | :--- | :--- |
| **`[US-04]`** | Registrasi & Autentikasi Akun Multi-Role | `src/routes/auth.js`, `src/controllers/authController.js` (`register`, `login`, `bcryptjs`, Redis `session_state:*`), `src/middlewares/authMiddleware.js` (`signUserToken`, 5 role RBAC) | `src/components/LoginModal.tsx`, `src/services/api.ts` (`setAuthToken`, `getStoredUser`) | `lib/features/auth/login_screen.dart`, `lib/features/auth/register_screen.dart`, `lib/features/auth/auth_repository.dart`, `lib/core/services/user_session.dart` |
| **`[US-05]`** | Registrasi Profil Petani, Asosiasi Poktan & Pendaftaran Toko | `src/controllers/profileController.js` (`setupFarmerProfile`, validasi NIK 16-digit + AES-256 preview), `src/controllers/agroSupplyChainController.js` (`applyForStore`, kuota toko desa, `DRAFT_FROZEN`), `src/routes/upload.js` | `src/components/PenyuluhStoreAndForumHub.tsx` (manajemen pengajuan toko & kuota desa PPL) | `lib/features/profile/complete_farmer_profile_screen.dart`, `lib/features/auth/store_registration_screen.dart` (auto-registrasi/JWT sebelum `/api/store/apply`), `lib/core/services/region_service.dart` |
| **`[US-06]`** | Validasi & Persetujuan Akun Petani oleh Penyuluh (PPL) + Geofencing Lahan | `src/routes/penyuluh.js`, `src/controllers/penyuluhController.js` (`getPendingFarmers`, `getAllFarmers`, `verifyFarmer`), `src/routes/dinas.js` | `src/App.tsx`, `src/components/HeroBanner.tsx`, `src/components/QueueTable.tsx`, `src/components/AuditDesk.tsx` (Peta & Audit Geofencing PPL) | `lib/features/profile/verification_pending_screen.dart`, `lib/features/penyuluh/screens/penyuluh_hub_screen.dart` |
| **`[US-12]`** | Manajemen Keranjang Belanja & Alamat Pengiriman | `src/routes/cart.js`, `src/controllers/cartController.js` (`getCart`, `addToCart`, `updateCartQuantity`, `removeFromCart`), tabel MySQL `cart_items` (`server.js`) | — *(Fokus mobile buyer)* | `lib/features/cart/cart_screen.dart` (manajemen keranjang, kalkulasi subtotal & pilih item) |
| **`[US-13]`** | Checkout Pemesanan & Pembuatan Invoice + Escrow Seal | `src/routes/orders.js`, `src/controllers/orderController.js` (`checkoutOrder` transaksi ACID `FOR UPDATE`, `generateInvoiceNumber`, `escrow_seal` AES-256-CBC, hook `ORDER_CARD` & `notifyTransactionEvent`) | `src/components/WebDirectMessageDrawer.tsx` (pemantauan chat & eskalasi) | `lib/features/order/checkout_screen.dart`, `lib/features/order/order_success_screen.dart`, `lib/features/orders/models/order_model.dart`, `lib/features/orders/services/order_service.dart` |
| **`[US-18]`** | Edukasi Pertanian & Badge Resmi Penyuluh *(integrasi & perbaikan overflow/heroTag lintas tim)* | `src/routes/education.js`, `src/controllers/educationController.js` (`getArticles`, `getArticleById`, `createArticle`) | — *(Terhubung via endpoint API edukasi & penyuluh)* | `lib/features/community/screens/education_feed_screen.dart` (fix Row overflow 360dp & `fab_education_feed`), `education_detail_screen.dart`, `create_education_post_screen.dart`, `lib/features/community/widgets/penyuluh_official_badge.dart` |
| **`[US-19]`** | Pelaporan & Peringatan Dini Serangan Hama (Pest Alert) *(integrasi PR & persistensi MySQL)* | `src/routes/pestReports.js`, `src/controllers/pestReportController.js`, `src/config/migrate_pest_alert.js` | Terintegrasi dengan data eskalasi PPL & `AiDecisionSupport.tsx` | `lib/features/community/screens/create_pest_report_screen.dart`, `pest_alert_detail_screen.dart`, `lib/features/community/services/pest_alert_service.dart`, `lib/features/community/widgets/pest_alert_banner.dart` |
| **`[US-22]`** | Bursa Kontrak Tanam B2B & Penentuan Target Panen (Forward Pool + Zero-Waste Spillover) | `src/routes/b2b.js`, `src/controllers/b2bPoolController.js` (`getHarvestPools`, `createHarvestPool`, `takeQuota`, `spilloverToRetail`, protokol defisit parsial) | — *(Konsolidasi melalui REST API & mobile)* | `lib/features/buyer/screens/wholesale_detail_screen.dart`, `lib/features/home/home_dashboard_screen.dart` (Tab Grosir B2B), `lib/features/poktan/screens/mitra_store_catalog_screen.dart`, `lib/features/poktan/widgets/create_wholesale_pool_sheet.dart` |
| **`[US-26]`** | Telemetri Kualitas Tanah Smart Agri (pH & NPK 8-in-1 + Pemetaan Lahan) | `src/routes/soil.js`, `src/controllers/productController.js` (`getSoilTelemetry`, `saveSoilTelemetry`), `src/controllers/penyuluhController.js` (`getMonitoringLahan`, `getMonitoringSummary`, `saveMonitoringLahan`, `generateRagDecision`, `dispatchRagDecision`) | `src/components/SmartAgriDashboard.tsx`, `src/components/SumenepLandMonitoring.tsx`, `src/components/SensorDataTable.tsx`, `src/components/AiDecisionSupport.tsx`, `src/components/AiPolicyBrief.tsx`, `src/components/PlotInspectorModal.tsx` | `lib/features/product/widgets/soil_telemetry_card.dart`, `lib/features/petani/screens/petani_land_monitoring_screen.dart`, `lib/features/penyuluh/screens/ppl_soil_checkup_screen.dart`, `lib/features/penyuluh/screens/soil_fertility_map_screen.dart` |

### B. Kontribusi Tambahan Terkait Infrastruktur, DevOps & User Story Lintas Tim (Trello)
- **`[US-01]` & Arsitektur Dasar**: Konfigurasi monorepo Flutter (`lapaktani_app/lib/core/services/api_service.dart`, `app_config.dart`, `app_colors.dart`, `custom_soft_card.dart`), Migrasi ke Cloudflare Tunnel (`api-lapaktani.velosixraptor.my.id` & `lapaktani.velosixraptor.my.id`), perbaikan `vite.config` `allowedHosts`, serta implementasi 9 materi wajib backend di `server.js`.
- **`[US-07]` Penambahan Komoditas Panen & Grade Mutu**: `src/controllers/productController.js` (`createProduct`, `normalizePricingInput` Retail/Diskon/Partai B2B), `add_product_screen.dart`, `edit_product_screen.dart`, dan perbaikan *null-safe DECIMAL string-to-num parsing* di 6 layar Flutter.
- **`[US-17]` Forum Diskusi Komunitas & Unified 6-Role Chat**: `src/routes/chat.js`, `src/controllers/chatController.js`, `community_repository.dart`, `discussion_comment_sheet.dart`, `chat_room_screen.dart`, `WebDirectMessageDrawer.tsx`.
- **`[US-20]` Load/Stress Testing**: `lapaktani_backend/tests/load_test_autocannon.js` (`npm run test:load`) + middleware `rateLimiter.js` & `compressionMiddleware.js`.
- **`[US-21]` & `[US-27]` UAT, Rilis Multi-Role APK & Peta Kesuburan Tanah PPL**: `RoleBasedAppShell` (`lib/features/navigation/role_based_app_shell.dart`), audit seluruh `FloatingActionButton` `heroTag` unik (`5/5` FAB), serta integrasi Peta Kesuburan Tanah Sumenep & RAG Dual-Target PPL.

### C. Arsitektur 6-Role Governance & Rantai Pasok 2-Tier (B2B Offtaker / Retail Auto-KYC)
1. **6-Role RBAC & Super Admin Governance (`superadmin`, `role_id=6`)**:
   - Registrasi mandiri untuk `dinas`, `penyuluh`, dan `superadmin` dikunci (`HTTP 403 AUTHORITY_REGISTRATION_LOCKED` pada `POST /api/auth/register`).
   - Provisioning akun resmi Dinas/Penyuluh (`POST /api/superadmin/provision-authority`), aktivasi/nonaktif akun (`PUT /api/superadmin/authorities/:id/status`), audit & pembekuan/reaktivasi toko 2-tier (`PUT /api/superadmin/stores/:id/status`), serta pemantauan kas `platform_fee_ledger` tersedia melalui `/api/superadmin/*` dan `lapaktani_web/src/components/SuperAdminGovernanceHub.tsx`.
2. **Two-Tier Store Onboarding (`B2B_OFFTAKER` vs `RETAIL_MERCHANT` Auto-KYC)**:
   - `B2B_OFFTAKER` (Koperasi/Gudang Partai) melalui antrean `PENDING_PPL`, verifikasi kuota toko desa, dan pencatatan `kapasitas_gudang_kg`.
   - `RETAIL_MERCHANT` (Pedagang Retail/Pasar) melalui jalur `Auto-KYC` (`status: APPROVED`, `auto_kyc_passed: true`), bebas batas kuota desa, dan langsung menerima peningkatan sesi JWT `admin` + `admin_tier: 'RETAIL_MERCHANT'` (`POST /api/store/apply` & `store_registration_screen.dart`).
3. **Farmer Multi-Offtaker Contracts & Automated Pro-Rata Deficit Engine**:
   - Petani dapat mencantumkan `luas_lahan_ha` saat menyiarkan panen, menyetujui lebih dari satu kontrak toko, lalu memanggil `POST /api/petani/harvest-reports/:id/declare-harvested` dengan `realisasi_panen_kg` riil (`petani_simple_screen.dart`).
   - Apabila realisasi panen lebih rendah dari total volume kontrak (`is_deficit: true`), sistem menghitung `share_ratio` dan memperbarui `allocated_pro_rata_kg` masing-masing offtaker secara proporsional (terverifikasi: `300 kg` estimasi, kontrak `200 + 100 kg`, realisasi `240 kg` -> `160 kg` & `80 kg`).
4. **B2B Open-Bid Lots (`MENTAH`/`SIAP_PAKAI`), Post-Escrow Traceability, 1-Click Restock & Remainder Switch**:
   - Komoditas mendukung klasifikasi `processing_state` (`MENTAH` / `SIAP_PAKAI`), `catalog_channel` (`B2B_BID_LOT` / `RETAIL_CATALOG` / `BOTH`), dan `fulfillment_options` (`DELIVERY_ONLY` / `PICKUP_ONLY` / `BOTH`) pada `add_product_screen.dart`, `mitra_store_catalog_screen.dart`, dan `wholesale_detail_screen.dart`.
   - `B2B_OFFTAKER` diblokir (`HTTP 403 B2B_OFFTAKER_CANNOT_BUY`) dari penawaran lot toko lain; identitas petani (`source_farmer_name`) disembunyikan di `GET /api/b2b/lots` & sebelum pembayaran, lalu otomatis dibuka setelah status `PAID_ESCROW`.
   - Setelah status `COMPLETED`, `RETAIL_MERCHANT` dapat menyalin lot ke katalog toko retail melalui `POST /api/b2b/bids/:bidId/restock-to-retail` (1-Click Restock), sementara `B2B_OFFTAKER` dapat membuka sisa stok lot B2B ke etalase retail melalui `PUT /api/products/:id/convert-remainder-to-retail`.
5. **Capped Hybrid Refund Engine & `platform_fee_ledger`**:
   - Pembatalan sepihak oleh Pembeli dikenakan potongan biaya layanan `min(Rp 50.000, max(Rp 10.000, round(gross * 2%)))`, sedangkan pembatalan oleh Penjual mengembalikan 100% tanpa potongan (`src/utils/refundHelper.js`, `POST /api/orders/:id/cancel-with-refund`, `POST /api/b2b/bids/:bidId/cancel-with-refund`, & `buyer_orders_screen.dart`), dengan jejak tersimpan pada tabel `platform_fee_ledger`.

> **Hasil Verifikasi Terbaru (`valo-Branch`)**:
> - **Uji E2E Backend (`MySQL 8.4 + Redis 6379`)**: Seluruh 6 skenario end-to-end (RBAC 6-role + locked register `403`, 2-tier Auto-KYC vs B2B + suspend/reactivate, Pro-Rata `240 kg -> 160 + 80 kg`, B2B open-bid + blokir B2B buyer `403` + unmasking pasca-`PAID_ESCROW` + 1-Click Restock + remainder switch, Refund Hybrid `floor Rp 10rb / 2% / cap Rp 50rb`, serta `GET /api/system/mvp-compliance` -> `9/9 (100%)`) **LULUS**.
> - **Web Portal (`lapaktani_web`)**: Build produksi `tsc -b && vite build` **LULUS (exit code 0)**.
> - **Aplikasi Mobile (`lapaktani_app`)**: `flutter analyze` **0 isu** dan `flutter test` **LULUS (semua tes lolos)**.

---

## Bagian 3 — Ringkasan Kontribusi & Tanggung Jawab Trello Anggota Tim Lainnya

| Anggota Tim | Kartu Trello yang Ditangani | Ringkasan Implementasi Teknis di Repository |
| :--- | :--- | :--- |
| **Moch. Ilham Abdul Aziz** | `[US-02]`, `[US-04]`, `[US-06]`, `[US-08]`, `[US-13]`, `[US-14]`, `[US-19]`, `[US-20]`, `[US-21]`, `[US-22]`, `[US-23]` | • Perancangan skema relasional MySQL (`lapaktani_complete_latest.sql`, migrasi XAMPP/MySQL) dan fondasi endpoint order/checkout.<br>• Integrasi **Midtrans Core API** (`POST /api/payments/charge`, VA Bank & QRIS, verifikasi SHA-512 webhook callback idempoten di `paymentController.js` & `orderController.js`).<br>• Modul **Pest Alert (`US-19`)** (`pestReportController.js`, `migrate_pest_alert.js`, `pest_alert_service.dart`, banner peringatan dini) serta konsep jaminan dana *Escrow B2B* (`[US-23]`). |
| **Rafael Rizky** | `[US-01]`, `[US-02]`, `[US-03]`, `[US-05]`, `[US-09]`, `[US-11]`, `[US-15]`, `[US-16]`, `[US-21]`, `[US-24]` | • **Manajemen Poktan & Konsolidasi Lahan (`US-24`)**: `src/routes/poktan.js`, `src/controllers/poktanController.js`, `poktan_dashboard_screen.dart`, `allocate_quota_sheet.dart`, `farmer_tasks_screen.dart`.<br>• **CRUD Stok, Detail Produk & Logistik (`US-09`, `US-11`, `US-15`, `US-16`)**: `my_products_screen.dart`, `search_screen.dart`, `product_detail_screen.dart`, `order_tracking_screen.dart`, pengurangan/pemulihan stok otomatis (`deductStock` / `restoreStock`).<br>• Kontribusi dataset & integrasi **Monitoring Lahan Sumenep** (resolusi PR #13 `rizky-branch` -> `valo-Branch`). |
| **Hafizhah Naya** | `[US-03]`, `[US-10]`, `[US-18]`, `[US-21]`, `[US-25]`, `[US-27]` | • **Onboarding, Beranda Pembeli & Filter Komoditas (`US-03`, `US-10`)**: `splash_screen.dart`, `onboarding_screen.dart`, tampilan katalog kategori pada `home_dashboard_screen.dart`.<br>• **Edukasi Pertanian & Lencana PPL (`US-18`)**: `education_feed_screen.dart`, `education_detail_screen.dart`, `create_education_post_screen.dart`, `penyuluh_official_badge.dart`.<br>• **Peta Geospasial PPL (`US-27`) & Penyaluran Surplus (`US-25`)**: `soil_fertility_map_screen.dart`, `penyuluh_hub_screen.dart`, serta rute spot market pada `src/routes/products.js`. |

---

*Disusun dan diverifikasi pada branch aktif `valo-Branch` (`2026-11-18`).*
