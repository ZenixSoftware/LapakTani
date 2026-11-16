# LapakTani Relational Database Schema Dictionary (MySQL 24+ Tables)
**User Story:** `[US-02]` Perancangan & Eksekusi Skema Basis Data Relasional MySQL 24+ Tabel & Migrasi  
**Lead Backend & Database Architect:** Rafael Rizky (`Rafariz19`)  
**Database Management System:** MySQL 8.0+ / MariaDB with InnoDB Engine  
**Charset & Collation:** `utf8mb4_unicode_ci`

---

## 1. Executive Summary & Architecture Overview
Basis data LapakTani dirancang dengan prinsip normalisasi relasional (3NF), integritas referensial kuat (`FOREIGN KEY` dengan `ON DELETE CASCADE / SET NULL`), serta indexing optimal pada query pencarian geospasial desa, pemetaan kuota Poktan, dan histori transaksi.

Total entitas tabel aktif dalam arsitektur LapakTani mencapai **42 tabel relasional**, melampaui batas minimal target 24 tabel.

```
                      +-----------------------------+
                      |         user_roles          |
                      +--------------+--------------+
                                     | 1:N
                      +--------------v--------------+
                      |            users            |
                      +---+----------+----------+---+
                          |          |          |
            1:1 +---------v----+     |     +----v---------+ 1:N
                |user_profiles |     |     |notifications |
                +--------------+     |     +--------------+
                                     |
                 +-------------------+-------------------+
                 | 1:N                                   | 1:N
  +--------------v--------------+         +--------------v--------------+
  |        farmer_groups        |         |           orders            |
  +--------------+--------------+         +--------------+--------------+
                 | 1:N                                   | 1:N
  +--------------v--------------+         +--------------v--------------+
  |       farmer_profiles       |         |         order_items         |
  +--------------+--------------+         +--------------+--------------+
                 | 1:N                                   | 1:1
  +--------------v--------------+         +--------------v--------------+
  |            farms            |         |          payments           |
  +--------------+--------------+         +-----------------------------+
                 |
      +----------+----------+
      | 1:N                 | 1:N
+-----v-------------+ +-----v-------------+
| soil_telemetries  | | monitoring_lahan  |
+-------------------+ +-------------------+
```

---

## 2. Tabel Domain & Detail Skema

### Domain A: Master Wilayah Administrasi & Geospasial
1. **`provinces`**: Data master provinsi Indonesia (Kode Kemendagri & nama).
2. **`regencies`**: Data kabupaten/kota (`province_id` FK).
3. **`districts`**: Data kecamatan (`regency_id` FK, fokus pilot: Sumenep).
4. **`villages`**: Data desa/kelurahan (`district_id` FK, titik temu Poktan dan PPL).

### Domain B: Autentikasi, Akun & Peran Pengguna
5. **`user_roles`**: 5 Peran sistem (`1: petani`, `2: penyuluh`, `3: admin`, `4: pembeli`, `5: dinas`).
6. **`users`**: Kredensial akun, email unik, hash bcrypt, status verifikasi NIK/KTP.
7. **`user_profiles`**: Profil demografi, bio, foto avatar, nomor kontak, relasi wilayah desa.
8. **`wallets`**: Dompet digital pengguna untuk pencairan hasil panen & refund.
9. **`wallet_transactions`**: Riwayat mutasi debit/kredit saldo dompet petani & pembeli.

### Domain C: Kelembagaan Petani & Manajemen Lahan (Poktan)
10. **`farmer_groups`**: Kelompok Tani (Poktan), nama poktan, desa, ID ketua (`chairman_user_id`).
11. **`farmer_profiles`**: Profil keanggotaan poktan petani, luas garapan (ha), komoditas utama.
12. **`farms`**: Bidang lahan fisik, koordinat GPS (lat, lng), jenis tanah, luas meter persegi.
13. **`monitoring_lahan`**: Log monitoring kondisi tanah & fase vegetatif/generatif oleh PPL & petani.
14. **`farmer_daily_logs`**: Catatan harian aktivitas tani (pemupukan, penyiraman, semprot obat).

### Domain D: Komoditas, Katalog Produk & E-Commerce Retail
15. **`commodity_categories`**: Kategori tanaman (Pangan, Hortikultura, Perkebunan).
16. **`commodities`**: Data jenis tanaman (Cabai Rawit, Jagung Hibrida, Bawang Merah, Padi).
17. **`product_grades`**: Standar mutu panen (Grade A Super, Grade B Standar, Grade C Industri).
18. **`commodity_units`**: Satuan ukur (Kg, Ton, Kuintal, Ikat, Karung).
19. **`products`**: Etalase produk retail petani dan toko mitra tani.
20. **`product_images`**: Multi-foto galeri produk.
21. **`cart_items`**: Keranjang belanja interaktif pembeli.
22. **`store_applications`**: Pengajuan registrasi toko kios saprotan/mitra tani desa.

### Domain E: Transaksi, Checkout, & Gateway Pembayaran
23. **`orders`**: Transaksi pemesanan dengan nomor invoice resmi (`INV/YYYYMMDD/LPK/...`).
24. **`order_items`**: Rincian produk, kuantitas, harga satuan, dan subtotal per invoice.
25. **`payments`**: Status transaksi Midtrans/Payment Gateway, va_number, snap_token, settlement_time.

### Domain F: Konsolidasi Panen & B2B Wholesale (Poktan)
26. **`b2b_harvest_pools`**: Penawaran borongan hasil panen konsolidasi anggota Poktan.
27. **`b2b_quota_allocations` / `quota_allocations`**: Pembagian jatah kuota panen per petani anggota.
28. **`b2b_orders`**: Kontrak pembelian partai besar oleh offtaker/industri.
29. **`b2b_contracts`**: Dokumen legalitas kesepakatan pasokan komoditas jangka panjang.
30. **`fertilizer_allocations`**: Alokasi pupuk subsidi desa per musim tanam.
31. **`harvest_reports`**: Laporan hasil panen riil petani di tingkat desa.
32. **`harvest_purchase_offers`**: Penawaran harga beli gabah/komoditas dari juragan/pedagang besar.

### Domain G: Edukasi, Forum Komunitas & Komunikasi PPL
33. **`educational_articles`**: Artikel panduan budidaya resmi BPP & forum diskusi publik.
34. **`village_forum_posts`**: Forum tertutup khusus warga desa dan penyuluh pembina desa.
35. **`ppl_forum_posts`**: Forum koordinasi teknis antar-penyuluh pertanian se-kabupaten.
36. **`ppl_decision_reports`**: Rekomendasi teknis & surat keputusan penyuluh atas kendala lapangan.
37. **`pest_reports`**: Laporan serangan hama penyakit tanaman (OPT) disertai foto geolokasi.
38. **`notifications`**: Peringatan dini ledakan hama, kuota panen, dan notifikasi pesanan.

### Domain H: Chat & Direct Messaging Real-Time
39. **`chat_conversations`**: Ruang obrolan langsung (DM Petani-Penyuluh, Petani-Pembeli).
40. **`chat_participants`**: Anggota percakapan dengan tracking `last_read_at`.
41. **`chat_messages`**: Pesan teks, tautan gambar, dan payload negosiasi pesanan.
42. **`soil_telemetries`**: Data telemetri sensor IoT tanah (pH, NPK, kelembaban, suhu).

---

## 3. Eksekutor Migrasi Skema Basis Data
Semua migrasi dieksekusi secara idempotent (`CREATE TABLE IF NOT EXISTS`, `ALTER TABLE ... ADD COLUMN IF NOT EXISTS`) melalui runner berikut:
- `lapaktani_backend/src/config/migrate_pest_alert.js`
- `lapaktani_backend/src/config/migrate_monitoring_lahan.js`
- `lapaktani_backend/src/config/migrate_streamlined_agro_flow.js`
- `lapaktani_backend/src/config/migrate_telemetry.js`
- `lapaktani_backend/migrations/001_add_birth_date.sql` s/d `009_b2b_partial_fulfillment_and_wallets.sql`
