const pool = require('./db');

async function addColumnIfMissing(connection, tableName, columnName, columnDefSql) {
  const [cols] = await connection.query(`SHOW COLUMNS FROM \`${tableName}\` LIKE ?`, [columnName]);
  if (cols.length === 0) {
    await connection.query(`ALTER TABLE \`${tableName}\` ADD COLUMN \`${columnName}\` ${columnDefSql}`);
  }
}

async function alignTableCollations(connection, tableNames) {
  try {
    const [userStatus] = await connection.query("SHOW TABLE STATUS LIKE 'users'");
    const targetCollation = userStatus[0]?.Collation;
    if (!targetCollation || !/^[a-z0-9_]+$/i.test(targetCollation)) return;

    const charset = targetCollation.split('_')[0];
    for (const tbl of tableNames) {
      const [status] = await connection.query('SHOW TABLE STATUS LIKE ?', [tbl]);
      if (status[0]?.Collation && status[0].Collation !== targetCollation) {
        await connection.query(
          `ALTER TABLE \`${tbl}\` CONVERT TO CHARACTER SET ${charset} COLLATE ${targetCollation}`
        );
      }
    }
  } catch (err) {
    console.warn('[MIGRATION_AGRO_FLOW] Collation alignment notice:', err.message);
  }
}

async function resolveUserIdByEmail(connection, email, fallbackId) {
  const [rows] = await connection.query('SELECT id FROM users WHERE LOWER(email) = ? LIMIT 1', [
    email.toLowerCase(),
  ]);
  return rows[0]?.id || fallbackId;
}

const runStreamlinedAgroFlowMigration = async () => {
  let connection;
  try {
    connection = await pool.getConnection();
    console.log('[MIGRATION_AGRO_FLOW] Running streamlined 5-role agro flow migration...');

    // 1. Roles confirmation
    await connection.query(`
      INSERT INTO user_roles (id, role_name) VALUES
      (1, 'petani'),
      (2, 'penyuluh'),
      (3, 'admin'),
      (4, 'pembeli'),
      (5, 'dinas')
      ON DUPLICATE KEY UPDATE role_name = VALUES(role_name);
    `);

    try {
      await connection.query(`
        ALTER TABLE users
        MODIFY COLUMN role ENUM('petani', 'pembeli', 'penyuluh', 'admin', 'dinas') DEFAULT 'pembeli'
      `);
    } catch (enumErr) {
      console.warn('[MIGRATION_AGRO_FLOW] users.role enum notice:', enumErr.message);
    }

    // 2. Seed all 27 Sumenep districts & villages + extend with postal code & store quota
    await connection.query(`
      INSERT INTO provinces (id, name) VALUES
      (35, 'Jawa Timur')
      ON DUPLICATE KEY UPDATE name = VALUES(name);
    `);

    await connection.query(`
      INSERT INTO regencies (id, province_id, name) VALUES
      (3529, 35, 'Kabupaten Sumenep')
      ON DUPLICATE KEY UPDATE province_id = VALUES(province_id), name = VALUES(name);
    `);

    await connection.query(`
      INSERT INTO districts (id, regency_id, name) VALUES
      (352901, 3529, 'Kota Sumenep'),
      (352902, 3529, 'Kalianget'),
      (352903, 3529, 'Manding'),
      (352904, 3529, 'Talango'),
      (352905, 3529, 'Bluto'),
      (352906, 3529, 'Saronggi'),
      (352907, 3529, 'Lenteng'),
      (352908, 3529, 'Guluk-Guluk'),
      (352909, 3529, 'Ganding'),
      (352910, 3529, 'Pragaan'),
      (352911, 3529, 'Ambunten'),
      (352912, 3529, 'Pasongsongan'),
      (352913, 3529, 'Dasuk'),
      (352914, 3529, 'Rubaru'),
      (352915, 3529, 'Batuan'),
      (352916, 3529, 'Gapura'),
      (352917, 3529, 'Dungkek'),
      (352918, 3529, 'Batang-Batang'),
      (352919, 3529, 'Batuputih'),
      (352920, 3529, 'Nonggunong'),
      (352921, 3529, 'Gayam'),
      (352922, 3529, 'Raas'),
      (352923, 3529, 'Sapeken'),
      (352924, 3529, 'Arjasa'),
      (352925, 3529, 'Kangayan'),
      (352926, 3529, 'Masalembu'),
      (352927, 3529, 'Giligenting')
      ON DUPLICATE KEY UPDATE regency_id = VALUES(regency_id), name = VALUES(name);
    `);

    await addColumnIfMissing(connection, 'villages', 'postal_code', "VARCHAR(10) NULL DEFAULT '69471'");
    await addColumnIfMissing(connection, 'villages', 'is_store_quota_enabled', 'TINYINT(1) NOT NULL DEFAULT 0');
    await addColumnIfMissing(connection, 'villages', 'max_stores_quota', 'INT NOT NULL DEFAULT 5');

    await connection.query(`
      INSERT INTO villages (id, district_id, name, postal_code) VALUES
      (110, 352901, 'Kolor (Kec. Kota Sumenep)', '69417'),
      (111, 352901, 'Pabian (Kec. Kota Sumenep)', '69411'),
      (112, 352902, 'Kalianget Timur (Kec. Kalianget)', '69471'),
      (113, 352903, 'Manding Daya (Kec. Manding)', '69452'),
      (114, 352905, 'Bluto (Kec. Bluto)', '69466'),
      (115, 352906, 'Saronggi (Kec. Saronggi)', '69467'),
      (116, 352907, 'Lenteng Timur (Kec. Lenteng)', '69461'),
      (117, 352909, 'Ganding (Kec. Ganding)', '69462'),
      (118, 352910, 'Pragaan Laok (Kec. Pragaan)', '69465'),
      (119, 352913, 'Kerta Barat (Kec. Dasuk)', '69454'),
      (120, 352915, 'Batuan (Kec. Batuan)', '69451'),
      (121, 352917, 'Lapa Taman (Kec. Dungkek)', '69474'),
      (122, 352918, 'Batang-Batang Daya (Kec. Batang-Batang)', '69473'),
      (123, 352919, 'Batuputih Laok (Kec. Batuputih)', '69453'),
      (124, 352920, 'Nonggunong (Kec. Nonggunong)', '69483'),
      (125, 352921, 'Gayam (Kec. Gayam)', '69483'),
      (126, 352922, 'Alasmalang (Kec. Raas)', '69485'),
      (127, 352923, 'Sapeken (Kec. Sapeken)', '69493'),
      (128, 352924, 'Kalinganyar (Kec. Arjasa)', '69491'),
      (129, 352925, 'Kangayan (Kec. Kangayan)', '69491'),
      (130, 352926, 'Masakambing (Kec. Masalembu)', '69492'),
      (131, 352927, 'Aenganyar (Kec. Giligenting)', '69482')
      ON DUPLICATE KEY UPDATE district_id = VALUES(district_id), name = VALUES(name), postal_code = COALESCE(NULLIF(postal_code, ''), VALUES(postal_code));
    `);

    const villageDefaults = [
      { id: 101, postal: '69472', quotaEnabled: 1, maxQuota: 3 }, // Mandala (Gapura)
      { id: 102, postal: '69456', quotaEnabled: 0, maxQuota: 5 }, // Pakondang (Rubaru)
      { id: 103, postal: '69456', quotaEnabled: 0, maxQuota: 5 }, // Karangnangka (Rubaru)
      { id: 104, postal: '69456', quotaEnabled: 0, maxQuota: 5 }, // Tambak Sari (Rubaru)
      { id: 105, postal: '69457', quotaEnabled: 0, maxQuota: 5 }, // Pasongsongan
      { id: 106, postal: '69463', quotaEnabled: 0, maxQuota: 5 }, // Guluk-Guluk
      { id: 107, postal: '69481', quotaEnabled: 0, maxQuota: 5 }, // Talango
      { id: 108, postal: '69455', quotaEnabled: 0, maxQuota: 5 }, // Ambunten
      { id: 109, postal: '69474', quotaEnabled: 1, maxQuota: 3 }, // Dungkek
    ];
    for (const v of villageDefaults) {
      await connection.query(
        `UPDATE villages
         SET postal_code = COALESCE(NULLIF(postal_code, ''), ?),
             is_store_quota_enabled = CASE WHEN id IN (101, 109) THEN ? ELSE is_store_quota_enabled END,
             max_stores_quota = CASE WHEN id IN (101, 109) THEN ? ELSE max_stores_quota END
         WHERE id = ?`,
        [v.postal, v.quotaEnabled, v.maxQuota, v.id]
      );
    }

    // Resolve seeded demo actors
    const dinasId = await resolveUserIdByEmail(connection, 'dinas@lapaktani.id', 'usr-dinas-06');
    const penyuluhId = await resolveUserIdByEmail(connection, 'penyuluh@lapaktani.id', 'usr-ppl-03');
    const adminId = await resolveUserIdByEmail(connection, 'admin@lapaktani.id', 'usr-admin-05');
    const petaniId = await resolveUserIdByEmail(connection, 'supardi@petani.lapaktani.id', 'usr-petani-supardi');
    const buyerId = await resolveUserIdByEmail(connection, 'pembeli@lapaktani.id', 'usr-buyer-04');

    // 3. Fertilizer Allocations table (Dinas Pertanian <-> Penyuluh Desa)
    await connection.query(`
      CREATE TABLE IF NOT EXISTS fertilizer_allocations (
        id VARCHAR(50) PRIMARY KEY,
        village_id INT NOT NULL DEFAULT 109,
        district_id INT NOT NULL DEFAULT 352917,
        village_name VARCHAR(100) DEFAULT 'Dungkek',
        penyuluh_id VARCHAR(50) NOT NULL,
        penyuluh_name VARCHAR(120) DEFAULT 'Ir. Ahmad Hidayat, M.Agr.',
        jenis_pupuk VARCHAR(120) NOT NULL,
        jumlah_ton DECIMAL(10,2) NOT NULL DEFAULT 2.50,
        alasan_kebutuhan TEXT NULL,
        status ENUM('USULAN_PPL','KONFIRMASI_DINAS','DIKIRIM_DINAS','DITERIMA_DESA') DEFAULT 'USULAN_PPL',
        titik_ambil_desa VARCHAR(255) NULL,
        catatan_dinas TEXT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        INDEX idx_fa_village (village_id),
        INDEX idx_fa_status (status)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);

    await connection.query(
      `INSERT IGNORE INTO fertilizer_allocations
       (id, village_id, district_id, village_name, penyuluh_id, penyuluh_name, jenis_pupuk, jumlah_ton, alasan_kebutuhan, status, titik_ambil_desa, catatan_dinas)
       VALUES
       ('fert-smp-01', 109, 352917, 'Dungkek', ?, 'Ir. Ahmad Hidayat, M.Agr. (Penyuluh BPP Sumenep)', 'Dolomit Super & NPK Phonska Subsidi', 3.50, 'Pemulihan pH asam (4.9) dan kekurangan hara di kelompok tani bawang merah Desa Dungkek.', 'DIKIRIM_DINAS', 'Balai Poktan Harapan Dungkek (Depan Embung Desa)', 'Sudah dikonfirmasi Dinas Pertanian Kab. Sumenep & dijadwalkan tiba via armada BPP.'),
       ('fert-smp-02', 101, 352901, 'Mandala', ?, 'Ir. Ahmad Hidayat, M.Agr. (Penyuluh BPP Sumenep)', 'Urea Subsidi & Organik Petroganik', 2.00, 'Kebutuhan susulan fase vegetatif tanaman jagung & cabai di Desa Mandala.', 'USULAN_PPL', 'Gudang Poktan Sumber Lestari Mandala', 'Menunggu konfirmasi pengiriman Dinas Pertanian Kab. Sumenep.')`,
      [penyuluhId, penyuluhId]
    );

    // 4. Two-step Store Applications & Store Settings table
    await connection.query(`
      CREATE TABLE IF NOT EXISTS store_applications (
        id VARCHAR(50) PRIMARY KEY,
        user_id VARCHAR(50) NOT NULL,
        nama_toko VARCHAR(150) NOT NULL,
        tipe_pengelola ENUM('POKTAN','KOPERASI','PENGEPUL_DESA') DEFAULT 'POKTAN',
        nik VARCHAR(32) NULL,
        no_hp VARCHAR(30) NULL,
        province_id INT DEFAULT 35,
        regency_id INT DEFAULT 3529,
        district_id INT DEFAULT 352901,
        village_id INT DEFAULT 101,
        village_name VARCHAR(100) DEFAULT 'Mandala',
        postal_code VARCHAR(10) DEFAULT '69472',
        alamat_lengkap TEXT NULL,
        dokumen_syarat_url VARCHAR(500) NULL,
        default_min_wholesale_kg INT NOT NULL DEFAULT 30,
        store_discount_banner VARCHAR(255) NULL,
        is_store_open TINYINT(1) NOT NULL DEFAULT 1,
        status ENUM('DRAFT_FROZEN','PENDING_PPL','APPROVED','REJECTED') DEFAULT 'PENDING_PPL',
        reviewed_by_ppl VARCHAR(50) NULL,
        rejection_reason TEXT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        INDEX idx_sa_user (user_id),
        INDEX idx_sa_village_status (village_id, status)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);

    await connection.query(
      `INSERT IGNORE INTO store_applications
       (id, user_id, nama_toko, tipe_pengelola, nik, no_hp, province_id, regency_id, district_id, village_id, village_name, postal_code, alamat_lengkap, dokumen_syarat_url, default_min_wholesale_kg, store_discount_banner, is_store_open, status, reviewed_by_ppl)
       VALUES
       ('store-app-01', ?, 'Koperasi Tani Sumber Lestari Sumenep', 'KOPERASI', '3529011204850001', '081234509876', 35, 3529, 352901, 101, 'Mandala', '69472', 'Jl. Raya Gapura KM 4, Desa Mandala, Kec. Gapura, Sumenep', 'uploads/docs/akta_koperasi_sumenep.pdf', 30, 'Promo Panen Raya Sumenep Hemat s/d 15% + Diskon Partai B2B', 1, 'APPROVED', ?),
       ('store-app-02', ?, 'Unit Usaha Poktan Harapan Dungkek', 'POKTAN', '3529172207880003', '081357902468', 35, 3529, 352917, 109, 'Dungkek', '69474', 'Dusun Embung Timur, Desa Dungkek, Kec. Dungkek, Sumenep', 'uploads/docs/sk_poktan_dungkek.pdf', 25, 'Serapan Bawang Merah & Cabai Jamu Segar Dungkek', 1, 'PENDING_PPL', NULL)`,
      [adminId, penyuluhId, buyerId]
    );

    // 5. Scoped Forums: Inter-PPL Forum & Private Village Forum
    await connection.query(`
      CREATE TABLE IF NOT EXISTS ppl_forum_posts (
        id VARCHAR(50) PRIMARY KEY,
        penyuluh_id VARCHAR(50) NOT NULL,
        penyuluh_name VARCHAR(120) NOT NULL,
        bpp_kecamatan VARCHAR(100) DEFAULT 'BPP Sumenep',
        topik VARCHAR(180) NOT NULL,
        komoditas VARCHAR(100) DEFAULT 'Hortikultura',
        isi_diskusi TEXT NOT NULL,
        rekomendasi_teknis TEXT NULL,
        likes_count INT NOT NULL DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_pfp_created (created_at DESC)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);

    await connection.query(
      `INSERT IGNORE INTO ppl_forum_posts
       (id, penyuluh_id, penyuluh_name, bpp_kecamatan, topik, komoditas, isi_diskusi, rekomendasi_teknis, likes_count)
       VALUES
       ('ppl-post-01', ?, 'Ir. Ahmad Hidayat, M.Agr.', 'BPP Kec. Dungkek & Gapura', 'Penanganan Salinitas Pesisir & pH Asam Bawang Merah Sumenep', 'Bawang Merah', 'Temuan sensor NPK 8-in-1 di Desa Dungkek menunjukkan pH turun ke 4.9 dengan EC 1750 uS/cm akibat intrusi musim kemarau. Apakah teman-teman BPP Rubaru juga menemukan pola serupa?', 'Gunakan kombinasi kapur Dolomit 2 Ton/Ha + pembenah organik humat 14 hari pra-tanam serta mulsa jerami untuk menahan evaporasi.', 8),
       ('ppl-post-02', ?, 'Ir. Siti Rahmawati, S.P.', 'BPP Kec. Rubaru', 'Mitigasi Layu Fusarium & Lalat Buah pada Cabai Ori 212', 'Cabai Rawit', 'Di Desa Karangnangka terjadi peningkatan kelembapan tidak merata setelah hujan awal. Disarankan penyemprotan Trichoderma preventif di sekitar perakaran.', 'Aplikasi Trichoderma sp. 10g/liter kocoran + perangkap metil eugenol di pinggir petak.', 5)`,
      [penyuluhId, penyuluhId]
    );

    await connection.query(`
      CREATE TABLE IF NOT EXISTS village_forum_posts (
        id VARCHAR(50) PRIMARY KEY,
        village_id INT NOT NULL DEFAULT 109,
        village_name VARCHAR(100) DEFAULT 'Dungkek',
        author_id VARCHAR(50) NOT NULL,
        author_name VARCHAR(120) NOT NULL,
        author_role ENUM('penyuluh','petani','admin') DEFAULT 'penyuluh',
        kategori ENUM('INFO_PUPUK','TANYA_JAWAB','PERINGATAN_HAMA','ARAHAN_TANAM') DEFAULT 'INFO_PUPUK',
        judul VARCHAR(180) NOT NULL,
        isi_pesan TEXT NOT NULL,
        titik_ambil_pupuk VARCHAR(255) NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_vf_village (village_id, created_at DESC)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);

    await connection.query(
      `INSERT IGNORE INTO village_forum_posts
       (id, village_id, village_name, author_id, author_name, author_role, kategori, judul, isi_pesan, titik_ambil_pupuk)
       VALUES
       ('vf-post-01', 109, 'Dungkek', ?, 'Ir. Ahmad Hidayat, M.Agr.', 'penyuluh', 'INFO_PUPUK', 'Jadwal Pengambilan Pupuk Subsidi Dolomit & NPK Desa Dungkek', 'Pupuk bantuan Dinas Pertanian Kab. Sumenep sebanyak 3.5 Ton telah tiba untuk anggota Poktan Harapan Dungkek. Harap membawa KTP asli & kartu anggota Poktan mulai pukul 08.00 WIB.', 'Balai Poktan Harapan Dungkek (Depan Embung Desa)'),
       ('vf-post-02', 109, 'Dungkek', ?, 'Pak Supardi (Poktan Harapan)', 'petani', 'TANYA_JAWAB', 'Laporan Ujung Daun Bawang Merah Menguning di Blok Timur', 'Mohon saran Pak Penyuluh, beberapa rumpun bawang merah umur 21 HST mulai menguning di tepi daun setelah pengairan sumur bor kemarin.', NULL),
       ('vf-post-03', 101, 'Mandala', ?, 'Ir. Ahmad Hidayat, M.Agr.', 'penyuluh', 'ARAHAN_TANAM', 'Arahan Penjarangan & Pemupukan Susulan Jagung Desa Mandala', 'Pastikan drainase antar guludan bersih sebelum aplikasi Urea susulan minggu ini.', 'Gudang Poktan Sumber Lestari Mandala')`,
      [penyuluhId, petaniId, penyuluhId]
    );

    // 6. Farmer Harvest Broadcasts & Transparent Offtaker Purchase Offers
    await connection.query(`
      CREATE TABLE IF NOT EXISTS harvest_reports (
        id VARCHAR(50) PRIMARY KEY,
        farmer_id VARCHAR(50) NOT NULL,
        farmer_name VARCHAR(120) DEFAULT 'Petani Mitra',
        poktan_id VARCHAR(50) NULL,
        village_id INT NOT NULL DEFAULT 109,
        village_name VARCHAR(100) DEFAULT 'Dungkek',
        district_id INT NOT NULL DEFAULT 352917,
        komoditas VARCHAR(100) NOT NULL,
        status_tanam ENUM('MULAI_TANAM','HAMPIR_PANEN','SIAP_PANEN','LAPOR_HAMA','MINTA_SARAN') DEFAULT 'HAMPIR_PANEN',
        estimasi_panen_date DATE NULL,
        estimasi_berat_kg DECIMAL(12,2) NOT NULL DEFAULT 0,
        catatan TEXT NULL,
        foto_url VARCHAR(500) NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_hr_village (village_id, status_tanam),
        INDEX idx_hr_farmer (farmer_id)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);

    await connection.query(
      `INSERT IGNORE INTO harvest_reports
       (id, farmer_id, farmer_name, poktan_id, village_id, village_name, district_id, komoditas, status_tanam, estimasi_panen_date, estimasi_berat_kg, catatan)
       VALUES
       ('hr-smp-01', ?, 'Pak Supardi (Poktan Harapan)', 'fg-smp-07', 109, 'Dungkek', 352917, 'Bawang Merah Sumenep Super', 'SIAP_PANEN', DATE_ADD(CURDATE(), INTERVAL 2 DAY), 450.00, 'Umbi padat, kering askip 70%, siap petik dan ditimbang oleh Admin Toko / Offtaker desa.'),
       ('hr-smp-02', ?, 'Pak Supardi (Poktan Harapan)', 'fg-smp-07', 109, 'Dungkek', 352917, 'Cabai Rawit Lokal', 'HAMPIR_PANEN', DATE_ADD(CURDATE(), INTERVAL 7 DAY), 180.00, 'Buah mulai memerah 60%, bebas serangan lalat buah.')`,
      [petaniId, petaniId]
    );

    await connection.query(`
      CREATE TABLE IF NOT EXISTS harvest_purchase_offers (
        id VARCHAR(50) PRIMARY KEY,
        harvest_report_id VARCHAR(50) NULL,
        store_admin_id VARCHAR(50) NOT NULL,
        store_name VARCHAR(150) DEFAULT 'Koperasi Tani Sumber Lestari',
        farmer_id VARCHAR(50) NULL,
        nama_petani_walkin VARCHAR(120) NULL,
        komoditas VARCHAR(100) NOT NULL,
        estimasi_berat_kg DECIMAL(12,2) NOT NULL DEFAULT 0,
        berat_timbang_riil_kg DECIMAL(12,2) NULL,
        harga_acuan_pasar_per_kg DECIMAL(12,2) NOT NULL DEFAULT 0,
        biaya_transport_per_kg DECIMAL(12,2) NOT NULL DEFAULT 0,
        biaya_operasional_lain_per_kg DECIMAL(12,2) NOT NULL DEFAULT 0,
        rincian_biaya_catatan TEXT NULL,
        harga_tawar_bersih_per_kg DECIMAL(12,2) NOT NULL DEFAULT 0,
        total_nilai_kontrak DECIMAL(14,2) NOT NULL DEFAULT 0,
        bukti_harga_pasar_url VARCHAR(500) NULL,
        status ENUM('OFFER_SENT','ACCEPTED_CONTRACT','WEIGHED_AND_PAID','REJECTED','TRADITIONAL_WALKIN') DEFAULT 'OFFER_SENT',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        INDEX idx_hpo_farmer (farmer_id, status),
        INDEX idx_hpo_store (store_admin_id, status)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);

    await connection.query(
      `INSERT IGNORE INTO harvest_purchase_offers
       (id, harvest_report_id, store_admin_id, store_name, farmer_id, komoditas, estimasi_berat_kg, harga_acuan_pasar_per_kg, biaya_transport_per_kg, biaya_operasional_lain_per_kg, rincian_biaya_catatan, harga_tawar_bersih_per_kg, total_nilai_kontrak, status)
       VALUES
       ('hpo-smp-01', 'hr-smp-01', ?, 'Koperasi Tani Sumber Lestari Sumenep', ?, 'Bawang Merah Sumenep Super', 450.00, 28000.00, 1200.00, 800.00, 'Acuan Pasar Induk Anom Sumenep Rp 28.000/kg; potongan pick-up dari Dungkek Rp 1.200/kg + sortasi/karung jaring Rp 800/kg.', 26000.00, 11700000.00, 'OFFER_SENT')`,
      [adminId, petaniId]
    );

    // 7. Seller-Configurable Retail, Discount & Wholesale Tiered Pricing columns on products & orders
    await addColumnIfMissing(connection, 'products', 'discount_percent', 'DECIMAL(5,2) NOT NULL DEFAULT 0');
    await addColumnIfMissing(connection, 'products', 'discount_price', 'DECIMAL(12,2) NULL');
    await addColumnIfMissing(connection, 'products', 'is_wholesale_enabled', 'TINYINT(1) NOT NULL DEFAULT 1');
    await addColumnIfMissing(connection, 'products', 'min_wholesale_qty', 'INT NOT NULL DEFAULT 30');
    await addColumnIfMissing(connection, 'products', 'wholesale_price', 'DECIMAL(12,2) NULL');
    await addColumnIfMissing(connection, 'products', 'store_village_id', 'INT NULL DEFAULT 101');

    // Backfill default wholesale pricing where null and make sample promos rich
    await connection.query(`
      UPDATE products
      SET price = COALESCE(NULLIF(price, 0), price_per_kg, 15000),
          min_wholesale_qty = COALESCE(NULLIF(min_wholesale_qty, 0), 30),
          wholesale_price = COALESCE(wholesale_price, ROUND(COALESCE(NULLIF(price_per_kg, 0), price, 15000) * 0.85)),
          store_village_id = COALESCE(store_village_id, 101)
    `);

    await connection.query(`
      UPDATE products
      SET discount_percent = 10.00,
          discount_price = ROUND(COALESCE(NULLIF(price_per_kg, 0), price, 15000) * 0.90)
      WHERE discount_percent = 0 AND id IN ('prod-tomat-lembang-001', 'prod-cabai-rawit-004')
    `);

    await addColumnIfMissing(connection, 'orders', 'order_tier', "ENUM('RETAIL','PARTAI_B2B') NOT NULL DEFAULT 'RETAIL'");
    await addColumnIfMissing(connection, 'orders', 'applied_unit_price', 'DECIMAL(12,2) NULL');
    await addColumnIfMissing(connection, 'orders', 'discount_saved', 'DECIMAL(12,2) NOT NULL DEFAULT 0');
    await addColumnIfMissing(connection, 'orders', 'wholesale_agreement_accepted', 'TINYINT(1) NOT NULL DEFAULT 0');
    await addColumnIfMissing(connection, 'orders', 'wholesale_agreement_note', 'TEXT NULL');

    // 8. Ensure Unified 5-Role DM Chat & Dual-Target RAG Decision Tables exist idempotently
    await connection.query(`
      CREATE TABLE IF NOT EXISTS chat_conversations (
        id VARCHAR(50) PRIMARY KEY,
        type ENUM('DIRECT','ORDER') DEFAULT 'DIRECT',
        order_id VARCHAR(50) NULL,
        title VARCHAR(200) NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        INDEX idx_chat_type (type),
        INDEX idx_chat_order (order_id),
        INDEX idx_chat_updated (updated_at DESC)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);

    await connection.query(`
      CREATE TABLE IF NOT EXISTS chat_participants (
        conversation_id VARCHAR(50) NOT NULL,
        user_id VARCHAR(50) NOT NULL,
        last_read_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (conversation_id, user_id),
        INDEX idx_cp_user (user_id)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);

    await connection.query(`
      CREATE TABLE IF NOT EXISTS chat_messages (
        id VARCHAR(50) PRIMARY KEY,
        conversation_id VARCHAR(50) NOT NULL,
        sender_id VARCHAR(50) NOT NULL,
        message_type ENUM('TEXT','ORDER_CARD','ADVISORY_CARD') DEFAULT 'TEXT',
        body TEXT NOT NULL,
        metadata_json LONGTEXT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_cm_conv (conversation_id, created_at)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);

    await connection.query(`
      CREATE TABLE IF NOT EXISTS ppl_decision_reports (
        id VARCHAR(50) PRIMARY KEY,
        plot_id VARCHAR(50) NULL,
        village_id INT NOT NULL DEFAULT 109,
        penyuluh_id VARCHAR(50) NOT NULL,
        penyuluh_name VARCHAR(120) NOT NULL,
        desa VARCHAR(100) NOT NULL,
        kecamatan VARCHAR(100) DEFAULT 'Sumenep',
        poktan_id VARCHAR(50) NULL,
        komoditas VARCHAR(100) DEFAULT 'Hortikultura',
        rag_context_json LONGTEXT NULL,
        decision_summary TEXT NOT NULL,
        action_plan TEXT NOT NULL,
        target_scope ENUM('DINAS_ONLY','FARMERS_ONLY','BOTH') DEFAULT 'BOTH',
        status ENUM('SENT','REVIEWED','ACKNOWLEDGED') DEFAULT 'SENT',
        dinas_notes TEXT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        INDEX idx_pdr_desa (desa),
        INDEX idx_pdr_village (village_id),
        INDEX idx_pdr_scope (target_scope),
        INDEX idx_pdr_status (status),
        INDEX idx_pdr_created (created_at DESC)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);
    await addColumnIfMissing(connection, 'ppl_decision_reports', 'village_id', 'INT NOT NULL DEFAULT 109');
    await addColumnIfMissing(connection, 'ppl_decision_reports', 'updated_at', 'TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP');

    await alignTableCollations(connection, [
      'fertilizer_allocations',
      'store_applications',
      'ppl_forum_posts',
      'village_forum_posts',
      'harvest_reports',
      'harvest_purchase_offers',
      'chat_conversations',
      'chat_participants',
      'chat_messages',
      'ppl_decision_reports',
    ]);

    // Ensure Dinas <-> Penyuluh starter DIRECT conversation exists for Web & Mobile DM
    await connection.query(
      `INSERT IGNORE INTO chat_conversations (id, type, order_id, title)
       VALUES ('conv-dinas-ppl-01', 'DIRECT', NULL, 'Koordinasi Dinas Pertanian & Penyuluh BPP')`
    );
    await connection.query(
      `INSERT IGNORE INTO chat_participants (conversation_id, user_id)
       VALUES ('conv-dinas-ppl-01', ?), ('conv-dinas-ppl-01', ?)`,
      [dinasId, penyuluhId]
    );
    await connection.query(
      `INSERT IGNORE INTO chat_messages (id, conversation_id, sender_id, message_type, body, metadata_json)
       VALUES ('msg-dinas-ppl-01', 'conv-dinas-ppl-01', ?, 'TEXT', 'Selamat pagi BPP Sumenep. Silakan laporkan kebutuhan pupuk subsidi dan kondisi lahan kritis melalui DM atau AI RAG Dispatch.', NULL)`,
      [dinasId]
    );

    console.log('[MIGRATION_AGRO_FLOW] Completed streamlined 5-role agro flow migration.');
  } catch (error) {
    console.error('[MIGRATION_AGRO_FLOW] Error:', error.message);
    throw error;
  } finally {
    if (connection) connection.release();
  }
};

if (require.main === module) {
  runStreamlinedAgroFlowMigration()
    .then(() => process.exit(0))
    .catch(() => process.exit(1));
}

module.exports = runStreamlinedAgroFlowMigration;
