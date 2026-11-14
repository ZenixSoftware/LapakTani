const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const pool = require('./db');

/**
 * Helper to upsert a demo user safely without colliding on email unique constraints.
 * Returns the canonical user id (varchar(36)).
 */
async function ensureDemoUser(connection, { preferredId, email, fullName, roleId, role, passwordHash, bppUnit = null, villageId = 101 }) {
  const cleanEmail = email.trim().toLowerCase();
  const [existing] = await connection.query('SELECT id FROM users WHERE email = ? LIMIT 1', [cleanEmail]);

  let userId;
  if (existing.length > 0) {
    userId = existing[0].id;
    await connection.query(
      'UPDATE users SET full_name = ?, role_id = ?, role = ?, is_verified = 1 WHERE id = ?',
      [fullName, roleId, role, userId]
    );
  } else {
    userId = preferredId && preferredId.length <= 36 ? preferredId : uuidv4();
    await connection.query(
      `INSERT INTO users (id, email, password_hash, role_id, full_name, role, is_verified, wallet_balance)
       VALUES (?, ?, ?, ?, ?, ?, 1, 5000000.00)`,
      [userId, cleanEmail, passwordHash, roleId, fullName, role]
    );
  }

  // Ensure corresponding user_profiles row exists (safe FK to villages)
  const [profRows] = await connection.query('SELECT id FROM user_profiles WHERE user_id = ? LIMIT 1', [userId]);
  if (profRows.length === 0) {
    const profId = uuidv4();
    await connection.query(
      `INSERT INTO user_profiles (id, user_id, full_name, verification_status, bpp_unit, village_id, wallet_balance)
       VALUES (?, ?, ?, 'verified', ?, ?, 5000000.00)`,
      [profId, userId, fullName, bppUnit, villageId]
    );
  } else {
    await connection.query(
      `UPDATE user_profiles SET full_name = ?, verification_status = 'verified', bpp_unit = COALESCE(?, bpp_unit) WHERE user_id = ?`,
      [fullName, bppUnit, userId]
    );
  }

  return userId;
}

/**
 * Migration helper for Sumenep Precision Agriculture, 8-in-1 Soil Monitoring,
 * 4-Role RBAC (Petani/Poktan Admin, Penyuluh, Dinas, Pembeli),
 * Dual-Target RAG Decision Dispatch, and Unified Chat Engine.
 */
const runMonitoringLahanMigration = async () => {
  let connection;
  try {
    connection = await pool.getConnection();
    console.log('[MIGRATION] Running Sumenep monitoring_lahan + 4-role RBAC + RAG + Chat migration...');

    // 1. Ensure user_roles supports all 5 canonical RBAC entries (1..5)
    await connection.query(`
      CREATE TABLE IF NOT EXISTS user_roles (
        id INT PRIMARY KEY,
        role_name VARCHAR(50) NOT NULL UNIQUE
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);

    await connection.query(`
      INSERT INTO user_roles (id, role_name) VALUES
      (1, 'petani'),
      (2, 'penyuluh'),
      (3, 'admin'),
      (4, 'pembeli'),
      (5, 'dinas')
      ON DUPLICATE KEY UPDATE role_name = VALUES(role_name);
    `);

    // Expand users.role ENUM so 'penyuluh', 'admin', 'dinas' can be stored cleanly
    try {
      await connection.query(`
        ALTER TABLE users
        MODIFY COLUMN role ENUM('petani', 'pembeli', 'penyuluh', 'admin', 'dinas') DEFAULT 'pembeli'
      `);
    } catch (alterErr) {
      console.warn('[MIGRATION] users.role alter notice:', alterErr.message);
    }

    // 2. Ensure administrative region tables exist
    await connection.query(`
      CREATE TABLE IF NOT EXISTS provinces (
        id INT NOT NULL PRIMARY KEY,
        name VARCHAR(100) NOT NULL
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);

    await connection.query(`
      CREATE TABLE IF NOT EXISTS regencies (
        id INT NOT NULL PRIMARY KEY,
        province_id INT NOT NULL,
        name VARCHAR(100) NOT NULL,
        INDEX idx_regencies_province (province_id),
        CONSTRAINT fk_regencies_province FOREIGN KEY (province_id) REFERENCES provinces(id)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);

    await connection.query(`
      CREATE TABLE IF NOT EXISTS districts (
        id INT NOT NULL PRIMARY KEY,
        regency_id INT NOT NULL,
        name VARCHAR(100) NOT NULL,
        INDEX idx_districts_regency (regency_id),
        CONSTRAINT fk_districts_regency FOREIGN KEY (regency_id) REFERENCES regencies(id)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);

    await connection.query(`
      CREATE TABLE IF NOT EXISTS villages (
        id INT NOT NULL PRIMARY KEY,
        district_id INT NOT NULL,
        name VARCHAR(100) NOT NULL,
        INDEX idx_villages_district (district_id),
        CONSTRAINT fk_villages_district FOREIGN KEY (district_id) REFERENCES districts(id)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);

    // 3. Seed parent region hierarchy: Province -> Regency -> Sumenep Districts (incl. Dungkek) -> Villages
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
      (352917, 3529, 'Dungkek')
      ON DUPLICATE KEY UPDATE regency_id = VALUES(regency_id), name = VALUES(name);
    `);

    await connection.query(`
      INSERT INTO villages (id, district_id, name) VALUES
      (101, 352916, 'Mandala (Kec. Gapura, Sumenep)'),
      (102, 352914, 'Pakondang (Kec. Rubaru, Sumenep)'),
      (103, 352914, 'Karangnangka (Kec. Rubaru, Sumenep)'),
      (104, 352914, 'Tambak Sari (Kec. Rubaru, Sumenep)'),
      (105, 352912, 'Pasongsongan (Kec. Pasongsongan, Sumenep)'),
      (106, 352908, 'Guluk-Guluk (Kec. Guluk-Guluk, Sumenep)'),
      (107, 352904, 'Talango (Kec. Talango, Sumenep)'),
      (108, 352911, 'Ambunten (Kec. Ambunten, Sumenep)'),
      (109, 352917, 'Dungkek (Kec. Dungkek, Sumenep)')
      ON DUPLICATE KEY UPDATE district_id = VALUES(district_id), name = VALUES(name);
    `);

    // 4. Create monitoring_lahan table (+ submitted_by_role column)
    await connection.query(`
      CREATE TABLE IF NOT EXISTS monitoring_lahan (
        id INT AUTO_INCREMENT PRIMARY KEY,
        farm_id VARCHAR(100) NULL,
        user_id VARCHAR(100) NULL,
        latitude DECIMAL(10, 8) NOT NULL DEFAULT -6.97715990,
        longitude DECIMAL(11, 8) NOT NULL DEFAULT 113.80453020,
        nama_desa VARCHAR(100) DEFAULT 'Mandala',
        kecamatan VARCHAR(100) DEFAULT 'Gapura',
        irigasi VARCHAR(20) DEFAULT 'tidak',
        listrik VARCHAR(20) DEFAULT 'tidak',
        pompa_air VARCHAR(20) DEFAULT 'ya',
        sumber_air VARCHAR(100) DEFAULT 'sumur bor',
        kondisi_air VARCHAR(50) DEFAULT 'tersedia',
        sumber_energi_pompa VARCHAR(50) DEFAULT 'BBM',
        pembajak VARCHAR(50) DEFAULT 'traktor',
        tadahan_hujan VARCHAR(20) DEFAULT 'tidak',
        komoditas VARCHAR(100) DEFAULT 'jagung',
        varietas VARCHAR(100) DEFAULT 'Hibrida',
        luas_lahan VARCHAR(50) DEFAULT '0.8 H',
        status_lahan VARCHAR(100) DEFAULT 'milik sendiri',
        kelompok_tani VARCHAR(150) DEFAULT 'ya',
        gagal_panen VARCHAR(20) DEFAULT 'tidak',
        hasil_panen_lalu DECIMAL(10, 2) DEFAULT 4.20,
        satuan_panen VARCHAR(20) DEFAULT 'ton',
        temp DECIMAL(5, 2) DEFAULT 30.20,
        moisture DECIMAL(5, 2) DEFAULT 16.50,
        conductivity INT DEFAULT 70,
        ph DECIMAL(4, 2) DEFAULT 6.40,
        nitrogen INT DEFAULT 38,
        phosphorus INT DEFAULT 24,
        potassium INT DEFAULT 110,
        fertility INT DEFAULT 78,
        foto_daun VARCHAR(500) NULL,
        foto_pohon VARCHAR(500) NULL,
        foto_tanah VARCHAR(500) NULL,
        tipe_penginput VARCHAR(30) DEFAULT 'petani',
        submitted_by_role VARCHAR(30) DEFAULT 'petani',
        rekomendasi_ppl TEXT NULL,
        status_verifikasi_ppl VARCHAR(30) DEFAULT 'verified',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_monitoring_desa (nama_desa),
        INDEX idx_monitoring_komoditas (komoditas),
        INDEX idx_monitoring_status_ppl (status_verifikasi_ppl),
        INDEX idx_monitoring_created (created_at DESC)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);

    const [subCol] = await connection.query("SHOW COLUMNS FROM monitoring_lahan LIKE 'submitted_by_role'");
    if (subCol.length === 0) {
      await connection.query("ALTER TABLE monitoring_lahan ADD COLUMN submitted_by_role VARCHAR(30) DEFAULT 'petani' AFTER tipe_penginput");
      await connection.query("UPDATE monitoring_lahan SET submitted_by_role = COALESCE(NULLIF(tipe_penginput, ''), 'petani')");
    }

    // 5. Upsert 4-Role + Buyer Demo Accounts cleanly
    const defaultPasswordHash = await bcrypt.hash('password123', 10);

    const dinasUserId = await ensureDemoUser(connection, {
      preferredId: 'usr-dinas-06',
      email: 'dinas@lapaktani.id',
      fullName: 'Ir. R. Bambang Sutrisno, M.Si. (Dinas Pertanian Sumenep)',
      roleId: 5,
      role: 'dinas',
      passwordHash: defaultPasswordHash,
      bppUnit: 'Dinas Pertanian Ketahanan Pangan Kab. Sumenep',
      villageId: 101
    });

    const penyuluhUserId = await ensureDemoUser(connection, {
      preferredId: 'usr-ppl-03',
      email: 'penyuluh@lapaktani.id',
      fullName: 'Ir. Ahmad Hidayat, M.Agr. (Penyuluh BPP Sumenep)',
      roleId: 2,
      role: 'penyuluh',
      passwordHash: defaultPasswordHash,
      bppUnit: 'BPP Kabupaten Sumenep',
      villageId: 101
    });

    const poktanAdminId = await ensureDemoUser(connection, {
      preferredId: 'usr-admin-05',
      email: 'admin@lapaktani.id',
      fullName: 'H. Trisno Wijaya (Ketua Poktan / Admin Koperasi)',
      roleId: 3,
      role: 'admin',
      passwordHash: defaultPasswordHash,
      bppUnit: null,
      villageId: 101
    });

    const poktanSecondaryId = await ensureDemoUser(connection, {
      preferredId: 'usr-poktan-01',
      email: 'made@poktan.lapaktani.id',
      fullName: 'Made Irawan (Ketua Poktan Mitra)',
      roleId: 3,
      role: 'admin',
      passwordHash: defaultPasswordHash,
      bppUnit: null,
      villageId: 101
    });

    const petaniUserId = await ensureDemoUser(connection, {
      preferredId: 'usr-petani-02',
      email: 'supardi@petani.lapaktani.id',
      fullName: 'Pak Supardi (Petani Sumenep)',
      roleId: 1,
      role: 'petani',
      passwordHash: defaultPasswordHash,
      bppUnit: null,
      villageId: 109
    });

    const buyerUserId = await ensureDemoUser(connection, {
      preferredId: 'usr-buyer-04',
      email: 'pembeli@lapaktani.id',
      fullName: 'Resto Sari Laut BSD (Pembeli B2B)',
      roleId: 4,
      role: 'pembeli',
      passwordHash: defaultPasswordHash,
      bppUnit: null,
      villageId: 101
    });

    // Normalize existing role_id=2 or role_id=3 or role_id=5 users
    await connection.query("UPDATE users SET role = 'penyuluh' WHERE role_id = 2");
    await connection.query("UPDATE users SET role = 'admin' WHERE role_id = 3");
    await connection.query("UPDATE users SET role = 'dinas' WHERE role_id = 5");

    // 6. Seed authentic Sumenep Poktan groups (incl. Desa Dungkek)
    await connection.query(`
      INSERT INTO farmer_groups (id, group_name, village_id, chairman_user_id, leader_name) VALUES
      ('fg-smp-01', 'Poktan Sekar Sari (Pasongsongan)', 105, NULL, 'Misyono'),
      ('fg-smp-02', 'Poktan Bukit Johar (Guluk-Guluk)', 106, NULL, 'H. Fauzan'),
      ('fg-smp-03', 'Poktan Sumber Lestari (Gapura)', 101, ?, 'Trisno'),
      ('fg-smp-04', 'Poktan Al Hikmah (Talango)', 107, NULL, 'Matra''is'),
      ('fg-smp-05', 'Poktan Sumber Patemon (Ambunten)', 108, NULL, 'Dahlani'),
      ('fg-smp-06', 'Poktan Anugrah (Rubaru)', 102, NULL, 'Mansur'),
      ('fg-smp-07', 'Poktan Harapan Dungkek (Dungkek)', 109, ?, 'K.H. Moh. Halil')
      ON DUPLICATE KEY UPDATE group_name = VALUES(group_name), village_id = VALUES(village_id), leader_name = VALUES(leader_name), chairman_user_id = COALESCE(VALUES(chairman_user_id), chairman_user_id);
    `, [poktanAdminId, poktanSecondaryId]);

    // 7. Seed representative Sumenep monitoring_lahan plots if empty
    const [countRows] = await connection.query('SELECT COUNT(*) AS count FROM monitoring_lahan');
    if (countRows[0].count === 0) {
      await connection.query(`
        INSERT INTO monitoring_lahan (
          farm_id, user_id, latitude, longitude, nama_desa, kecamatan,
          irigasi, listrik, pompa_air, sumber_air, kondisi_air, sumber_energi_pompa,
          pembajak, tadahan_hujan, komoditas, varietas, luas_lahan, status_lahan,
          kelompok_tani, gagal_panen, hasil_panen_lalu, satuan_panen,
          temp, moisture, conductivity, ph, nitrogen, phosphorus, potassium, fertility,
          tipe_penginput, submitted_by_role, rekomendasi_ppl, status_verifikasi_ppl
        ) VALUES
        ('farm-smp-01', ?, -6.97715990, 113.80453020, 'Mandala', 'Gapura',
         'ya', 'ya', 'ya', 'sumur bor', 'lancar', 'PLN',
         'traktor', 'tidak', 'jagung', 'Bisi 18 Hibrida', '0.7 H', 'milik sendiri',
         'Poktan Sumber Lestari (Gapura)', 'tidak', 5.40, 'ton',
         31.00, 64.50, 1420, 6.40, 145, 32, 185, 84,
         'penyuluh', 'penyuluh', 'Kondisi NPK & pH optimal untuk jagung hibrida. Pertahankan jadwal pengairan sumur bor 2x seminggu.', 'verified'),
        ('farm-smp-02', ?, -6.97547730, 113.80073160, 'Pakondang', 'Rubaru',
         'ya', 'tidak', 'ya', 'sumur bor', 'lancar', 'BBM',
         'traktor', 'tidak', 'padi', 'Inpari 32', '0.8 H', 'milik sendiri',
         'Poktan Anugrah (Rubaru)', 'tidak', 6.10, 'ton',
         29.60, 72.00, 1380, 6.50, 132, 34, 178, 86,
         'penyuluh', 'penyuluh', 'Kelembapan ideal fase vegetatif padi. Tambahkan pupuk Urea susulan 50 kg/Ha pada HST ke-25.', 'verified'),
        ('farm-smp-03', NULL, -6.95689170, 113.77893970, 'Karangnangka', 'Rubaru',
         'tidak', 'tidak', 'ya', 'sumur bor', 'sulit', 'BBM',
         'manual', 'ya', 'cabai', 'Ori 212', '0.6 H', 'milik sendiri',
         'Poktan Anugrah (Rubaru)', 'tidak', 1.80, 'ton',
         32.60, 11.40, 290, 5.10, 42, 14, 72, 16,
         'petani', 'petani', 'TITIK KRITIS: Tanah terlalu asam (pH 5.1) & kekeringan (11.4%). Berikan Dolomit 1.5 Ton/Ha + mulsa jerami.', 'needs_action'),
        ('farm-smp-04', NULL, -6.96889060, 113.79210220, 'Tambak Sari', 'Rubaru',
         'tidak', 'tidak', 'ya', 'sumur bor', 'tersedia', 'BBM',
         'manual', 'tidak', 'tembakau', 'Prancak-95 Sumenep', '0.9 H', 'milik sendiri',
         'Poktan Anugrah (Rubaru)', 'tidak', 1.45, 'ton',
         31.80, 54.00, 1210, 6.30, 118, 28, 195, 76,
         'penyuluh', 'penyuluh', 'Profil Kalium baik untuk mutu rajangan tembakau Prancak-95. Jaga drainase agar akar tidak tergenang.', 'verified'),
        ('farm-smp-05', NULL, -6.90624100, 113.67985000, 'Pasongsongan', 'Pasongsongan',
         'ya', 'ya', 'ya', 'sumur bor', 'lancar', 'PLN',
         'traktor', 'tidak', 'bawang merah', 'Batu Ijo / Rubaru', '1.1 H', 'milik sendiri',
         'Poktan Sekar Sari (Pasongsongan)', 'tidak', 7.20, 'ton',
         30.40, 61.50, 1480, 6.20, 124, 36, 190, 82,
         'penyuluh', 'penyuluh', 'Produktivitas tinggi. Monitoring embun bulu saat kelembapan malam > 70%.', 'verified'),
        ('farm-smp-06', NULL, -7.06418000, 113.69432000, 'Guluk-Guluk', 'Guluk-Guluk',
         'tidak', 'tidak', 'tidak', 'tadahan hujan', 'sulit', 'Manual',
         'sapi', 'ya', 'singkong', 'Manggu Lokal', '0.8 H', 'sewa',
         'Poktan Bukit Johar (Guluk-Guluk)', 'ya', 8.50, 'ton',
         33.40, 12.80, 340, 5.30, 55, 16, 88, 18,
         'petani', 'petani', 'TITIK KRITIS: Deplesi hara pasca gagal panen & air sulit. Aplikasikan kompos kandang 3 Ton/Ha sebelum olah tanah.', 'needs_action'),
        ('farm-smp-07', NULL, -7.07891000, 113.92451000, 'Talango', 'Talango',
         'tidak', 'ya', 'ya', 'sumur bor', 'tersedia', 'PLN',
         'sapi', 'tidak', 'kacang', 'Tuban Lokal', '0.5 H', 'milik sendiri',
         'Poktan Al Hikmah (Talango)', 'tidak', 28.00, 'sak',
         30.90, 52.40, 1120, 6.60, 96, 26, 148, 72,
         'petani', 'petani', 'Symbiosis bintil akar aktif. Tambah SP-36 100 kg/Ha untuk pengisian polong maksimal.', 'pending'),
        ('farm-smp-08', NULL, -6.88942000, 113.75824000, 'Ambunten', 'Ambunten',
         'ya', 'ya', 'ya', 'sumur bor', 'lancar', 'PLN',
         'traktor', 'tidak', 'jagung', 'Lamuru Sumenep', '1.0 H', 'milik sendiri',
         'Poktan Sumber Patemon (Ambunten)', 'tidak', 4.90, 'ton',
         29.80, 58.20, 1340, 6.40, 138, 30, 165, 80,
         'penyuluh', 'penyuluh', 'Standar kesuburan terpenuhi untuk jagung komposit. Siap alokasi serapan gudang Poktan.', 'verified')
      `, [poktanAdminId, petaniUserId]);
    }

    // Ensure Desa Dungkek critical plot (farm-smp-09) exists idempotently
    const [dungkekRows] = await connection.query("SELECT id FROM monitoring_lahan WHERE farm_id = 'farm-smp-09' LIMIT 1");
    if (dungkekRows.length === 0) {
      await connection.query(`
        INSERT INTO monitoring_lahan (
          farm_id, user_id, latitude, longitude, nama_desa, kecamatan,
          irigasi, listrik, pompa_air, sumber_air, kondisi_air, sumber_energi_pompa,
          pembajak, tadahan_hujan, komoditas, varietas, luas_lahan, status_lahan,
          kelompok_tani, gagal_panen, hasil_panen_lalu, satuan_panen,
          temp, moisture, conductivity, ph, nitrogen, phosphorus, potassium, fertility,
          tipe_penginput, submitted_by_role, rekomendasi_ppl, status_verifikasi_ppl
        ) VALUES (
          'farm-smp-09', ?, -6.99420000, 114.07250000, 'Dungkek', 'Dungkek',
          'tidak', 'tidak', 'tidak', 'tadahan hujan', 'sulit', 'Manual',
          'manual', 'ya', 'bawang merah', 'Batu Ijo & Cabai Jamu', '1.2 H', 'milik sendiri',
          'Poktan Harapan Dungkek (Dungkek)', 'ya', 2.10, 'ton',
          33.40, 10.80, 1750, 4.90, 38, 12, 68, 14,
          'petani', 'petani',
          'PRIORITAS DARURAT DESA DUNGKEK: pH tanah sangat asam (4.9), kelembapan kritis (10.8%), dan salinitas/EC tinggi (1750 uS/cm). Ajukan bantuan pompa embung & Dolomit ke Dinas Pertanian serta lakukan pengapuran 2 Ton/Ha + mulsa organik.',
          'needs_action'
        )
      `, [petaniUserId]);
      console.log('[MIGRATION] Seeded critical Desa Dungkek plot (farm-smp-09).');
    }

    // 8. Dual-Target RAG Decision Reports Table (Penyuluh -> Dinas Pertanian & Petani/Poktan)
    await connection.query(`
      CREATE TABLE IF NOT EXISTS ppl_decision_reports (
        id VARCHAR(50) PRIMARY KEY,
        plot_id VARCHAR(50) NULL,
        penyuluh_id VARCHAR(50) NOT NULL,
        penyuluh_name VARCHAR(120) DEFAULT 'Ir. Ahmad Hidayat, M.Agr.',
        desa VARCHAR(100) NOT NULL,
        kecamatan VARCHAR(100) DEFAULT 'Sumenep',
        poktan_id VARCHAR(50) NULL,
        komoditas VARCHAR(100) DEFAULT 'Padi & Hortikultura',
        rag_context_json LONGTEXT NULL,
        decision_summary TEXT NOT NULL,
        action_plan TEXT NOT NULL,
        target_scope ENUM('DINAS_ONLY','FARMERS_ONLY','BOTH') DEFAULT 'BOTH',
        status ENUM('SENT','REVIEWED','ACKNOWLEDGED') DEFAULT 'SENT',
        dinas_notes TEXT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_pdr_desa (desa),
        INDEX idx_pdr_scope (target_scope),
        INDEX idx_pdr_status (status),
        INDEX idx_pdr_created (created_at DESC)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);

    const [dungkekPlot] = await connection.query("SELECT id FROM monitoring_lahan WHERE farm_id = 'farm-smp-09' LIMIT 1");
    const dungkekPlotId = dungkekPlot.length > 0 ? String(dungkekPlot[0].id) : 'farm-smp-09';

    await connection.query(`
      INSERT INTO ppl_decision_reports (
        id, plot_id, penyuluh_id, penyuluh_name, desa, kecamatan, poktan_id, komoditas,
        rag_context_json, decision_summary, action_plan, target_scope, status, dinas_notes
      ) VALUES
      (
        'dec-dungkek-01', ?, ?, 'Ir. Ahmad Hidayat, M.Agr. (BPP Sumenep)', 'Dungkek', 'Dungkek', 'fg-smp-07', 'Bawang Merah & Cabai Jamu',
        ?,
        'Intervensi Terpadu Kekeringan & Keasaman Tanah (pH 4.9, Lengas 10.8%) di Desa Dungkek, Kec. Dungkek.',
        '1. UNTUK PETANI & POKTAN HARAPAN DUNGKEK: Hentikan pemupukan Urea tunggal sementara; aplikasikan Dolomit/Kapur Pertanian 2.0 Ton/Ha bertahap 14 hari sebelum tanam, pasang mulsa jerami 5 cm untuk menekan penguapan, dan gunakan pupuk organik cair pengikat lengas.\n2. UNTUK DINAS PERTANIAN KAB. SUMENEP: Rekomendasi alokasi darurat 2 unit pompa irigasi submersibel, droping 3 Ton kapur Dolomit bersubsidi, dan rehabilitasi embung tadah hujan Desa Dungkek.',
        'BOTH', 'SENT', NULL
      ),
      (
        'dec-karangnangka-02', 'farm-smp-03', ?, 'Ir. Ahmad Hidayat, M.Agr. (BPP Sumenep)', 'Karangnangka', 'Rubaru', 'fg-smp-06', 'Cabai Ori 212',
        ?,
        'Pemulihan pH Tanah Asam (5.1) & Mitigasi Layu Cabai di Poktan Anugrah, Desa Karangnangka.',
        '1. Lakukan pengapuran Dolomit 1.5 Ton/Ha pada guludan.\n2. Tambahkan Trichoderma + kompos matang 2 Ton/Ha untuk mengembalikan kesuburan (skor saat ini 16/100).\n3. Atur giliran sumur bor Poktan setiap 3 hari pada pagi/sore.',
        'FARMERS_ONLY', 'SENT', NULL
      )
      ON DUPLICATE KEY UPDATE decision_summary = VALUES(decision_summary), action_plan = VALUES(action_plan);
    `, [
      dungkekPlotId,
      penyuluhUserId,
      JSON.stringify({
        desa: 'Dungkek',
        kecamatan: 'Dungkek',
        ph: 4.9,
        moisture: 10.8,
        ec: 1750,
        nitrogen: 38,
        phosphorus: 12,
        potassium: 68,
        fertility: 14,
        kondisi_air: 'sulit',
        severity: 'CRITICAL'
      }),
      penyuluhUserId,
      JSON.stringify({
        desa: 'Karangnangka',
        kecamatan: 'Rubaru',
        ph: 5.1,
        moisture: 11.4,
        nitrogen: 42,
        phosphorus: 14,
        potassium: 72,
        fertility: 16,
        kondisi_air: 'sulit',
        severity: 'HIGH'
      })
    ]);

    // 9. Farmer Daily Logs Table (Petani -> Penyuluh telemetry/condition notes)
    await connection.query(`
      CREATE TABLE IF NOT EXISTS farmer_daily_logs (
        id VARCHAR(50) PRIMARY KEY,
        user_id VARCHAR(50) NOT NULL,
        farmer_name VARCHAR(120) NOT NULL,
        desa VARCHAR(100) NOT NULL,
        kecamatan VARCHAR(100) DEFAULT 'Sumenep',
        poktan_id VARCHAR(50) NULL,
        komoditas VARCHAR(100) DEFAULT 'Bawang Merah',
        activity_type VARCHAR(80) DEFAULT 'Pemantauan Rutin',
        notes TEXT NOT NULL,
        moisture DECIMAL(5,2) NULL,
        ph DECIMAL(4,2) NULL,
        photo_url VARCHAR(500) NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_fdl_user (user_id),
        INDEX idx_fdl_desa (desa),
        INDEX idx_fdl_created (created_at DESC)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);

    await connection.query(`
      INSERT INTO farmer_daily_logs (
        id, user_id, farmer_name, desa, kecamatan, poktan_id, komoditas, activity_type, notes, moisture, ph
      ) VALUES (
        'log-dungkek-01', ?, 'Pak Supardi (Poktan Harapan)', 'Dungkek', 'Dungkek', 'fg-smp-07',
        'Bawang Merah Batu Ijo', 'Laporan Kekeringan & Kondisi Tanah',
        'Sumur bor ujung timur mulai surut, daun bawang menguning di ujung. Mohon arahan dosis Dolomit dan jadwal pengairan dari Bapak Penyuluh.',
        10.80, 4.90
      )
      ON DUPLICATE KEY UPDATE notes = VALUES(notes);
    `, [petaniUserId]);

    // 10. Unified Social & Order Direct Messaging Engine
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

    // Align collations of new tables with the users table to prevent mixed-collation JOIN errors across MySQL 8 / MariaDB
    try {
      const [userTblStatus] = await connection.query("SHOW TABLE STATUS LIKE 'users'");
      const targetCollation = userTblStatus[0]?.Collation;
      if (targetCollation && /^[a-z0-9_]+$/i.test(targetCollation)) {
        const charset = targetCollation.split('_')[0];
        const newTables = [
          'ppl_decision_reports',
          'farmer_daily_logs',
          'chat_conversations',
          'chat_participants',
          'chat_messages'
        ];
        for (const tbl of newTables) {
          const [tblStatus] = await connection.query(`SHOW TABLE STATUS LIKE ?`, [tbl]);
          if (tblStatus[0]?.Collation && tblStatus[0].Collation !== targetCollation) {
            await connection.query(
              `ALTER TABLE \`${tbl}\` CONVERT TO CHARACTER SET ${charset} COLLATE ${targetCollation}`
            );
          }
        }
      }
    } catch (collationErr) {
      console.warn('[MIGRATION] Collation alignment notice:', collationErr.message);
    }

    // Seed starter conversations so DM & Order Chat are immediately demonstrable
    const convAdvisoryId = 'conv-ppl-petani-01';
    const convPoktanId = 'conv-poktan-petani-02';
    const convOrderId = 'conv-order-sample-03';

    await connection.query(`
      INSERT INTO chat_conversations (id, type, order_id, title) VALUES
      (?, 'DIRECT', NULL, 'Konsultasi Penyuluh BPP Sumenep'),
      (?, 'DIRECT', NULL, 'Koordinasi Poktan & Serapan Hasil'),
      (?, 'ORDER', 'ORD-SAMPLE-001', 'Pesanan B2B Resto Sari Laut')
      ON DUPLICATE KEY UPDATE title = VALUES(title);
    `, [convAdvisoryId, convPoktanId, convOrderId]);

    await connection.query(`
      INSERT IGNORE INTO chat_participants (conversation_id, user_id) VALUES
      (?, ?), (?, ?),
      (?, ?), (?, ?),
      (?, ?), (?, ?);
    `, [
      convAdvisoryId, penyuluhUserId, convAdvisoryId, petaniUserId,
      convPoktanId, poktanAdminId, convPoktanId, petaniUserId,
      convOrderId, buyerUserId, convOrderId, poktanAdminId
    ]);

    await connection.query(`
      INSERT INTO chat_messages (id, conversation_id, sender_id, message_type, body, metadata_json) VALUES
      (
        'msg-init-01', ?, ?, 'ADVISORY_CARD',
        'Arahan Resmi Penyuluh Desa Dungkek: Segera aplikasikan Dolomit 2 Ton/Ha dan mulsa jerami pada lahan dengan pH 4.9.',
        ?
      ),
      (
        'msg-init-02', ?, ?, 'TEXT',
        'Halo Pak Supardi, jadwal serapan bawang merah Poktan Sumber Lestari minggu ini dibuka hingga 1.2 Ton.',
        NULL
      ),
      (
        'msg-init-03', ?, ?, 'ORDER_CARD',
        'Pesanan Baru #INV/20261114/LPK/SMP01 — Cabai Merah & Bawang Sumenep (120 kg)',
        ?
      )
      ON DUPLICATE KEY UPDATE body = VALUES(body);
    `, [
      convAdvisoryId,
      penyuluhUserId,
      JSON.stringify({
        report_id: 'dec-dungkek-01',
        desa: 'Dungkek',
        kecamatan: 'Dungkek',
        komoditas: 'Bawang Merah & Cabai Jamu',
        ph: 4.9,
        moisture: 10.8
      }),
      convPoktanId,
      poktanAdminId,
      convOrderId,
      buyerUserId,
      JSON.stringify({
        order_id: 'ORD-SAMPLE-001',
        invoice_number: 'INV/20261114/LPK/SMP01',
        total_amount: 4250000,
        status: 'PROCESSING',
        items_summary: 'Bawang Merah Sumenep Grade A (120 kg)'
      })
    ]);

    console.log('[MIGRATION] Completed Sumenep 4-role RBAC, RAG decisions & Unified Chat migration.');
    return {
      dinasUserId,
      penyuluhUserId,
      poktanAdminId,
      petaniUserId,
      buyerUserId
    };
  } catch (err) {
    console.error('[MIGRATION] Error running monitoring_lahan migration:', err.message);
    throw err;
  } finally {
    if (connection) connection.release();
  }
};

if (require.main === module) {
  runMonitoringLahanMigration()
    .then(() => process.exit(0))
    .catch(() => process.exit(1));
}

module.exports = runMonitoringLahanMigration;
