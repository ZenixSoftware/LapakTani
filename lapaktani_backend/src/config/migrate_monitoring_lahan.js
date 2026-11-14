const pool = require('./db');

/**
 * Migration helper for Sumenep Precision Agriculture & 8-in-1 Soil Monitoring
 * Grafted from Pens-Agri monitoring_lahan & Sumenep Poktan datasets.
 */
const runMonitoringLahanMigration = async () => {
  let connection;
  try {
    connection = await pool.getConnection();
    console.log('[MIGRATION] Running Sumenep monitoring_lahan migration...');

    // 1. Create monitoring_lahan table
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
        rekomendasi_ppl TEXT NULL,
        status_verifikasi_ppl VARCHAR(30) DEFAULT 'verified',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_monitoring_desa (nama_desa),
        INDEX idx_monitoring_komoditas (komoditas),
        INDEX idx_monitoring_status_ppl (status_verifikasi_ppl),
        INDEX idx_monitoring_created (created_at DESC)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);

    // 2. Seed Sumenep villages into villages table (IDs 101..108)
    await connection.query(`
      INSERT INTO villages (id, name) VALUES
      (101, 'Mandala (Kec. Gapura, Sumenep)'),
      (102, 'Pakondang (Kec. Rubaru, Sumenep)'),
      (103, 'Karangnangka (Kec. Rubaru, Sumenep)'),
      (104, 'Tambak Sari (Kec. Rubaru, Sumenep)'),
      (105, 'Pasongsongan (Kec. Pasongsongan, Sumenep)'),
      (106, 'Guluk-Guluk (Kec. Guluk-Guluk, Sumenep)'),
      (107, 'Talango (Kec. Talango, Sumenep)'),
      (108, 'Ambunten (Kec. Ambunten, Sumenep)')
      ON DUPLICATE KEY UPDATE name = VALUES(name);
    `);

    // 3. Seed authentic Sumenep Poktan groups from Pens-Agri dataset
    await connection.query(`
      INSERT INTO farmer_groups (id, group_name, village_id, chairman_user_id, leader_name) VALUES
      ('fg-smp-01', 'Poktan Sekar Sari (Pasongsongan)', 105, NULL, 'Misyono'),
      ('fg-smp-02', 'Poktan Bukit Johar (Guluk-Guluk)', 106, NULL, 'H. Fauzan'),
      ('fg-smp-03', 'Poktan Sumber Lestari (Gapura)', 101, NULL, 'Trisno'),
      ('fg-smp-04', 'Poktan Al Hikmah (Talango)', 107, NULL, 'Matra''is'),
      ('fg-smp-05', 'Poktan Sumber Patemon (Ambunten)', 108, NULL, 'Dahlani'),
      ('fg-smp-06', 'Poktan Anugrah (Rubaru)', 102, NULL, 'Mansur')
      ON DUPLICATE KEY UPDATE group_name = VALUES(group_name), village_id = VALUES(village_id), leader_name = VALUES(leader_name);
    `);

    // 4. Seed representative Sumenep monitoring_lahan telemetry plots if empty
    const [countRows] = await connection.query('SELECT COUNT(*) AS count FROM monitoring_lahan');
    if (countRows[0].count === 0) {
      await connection.query(`
        INSERT INTO monitoring_lahan (
          farm_id, user_id, latitude, longitude, nama_desa, kecamatan,
          irigasi, listrik, pompa_air, sumber_air, kondisi_air, sumber_energi_pompa,
          pembajak, tadahan_hujan, komoditas, varietas, luas_lahan, status_lahan,
          kelompok_tani, gagal_panen, hasil_panen_lalu, satuan_panen,
          temp, moisture, conductivity, ph, nitrogen, phosphorus, potassium, fertility,
          tipe_penginput, rekomendasi_ppl, status_verifikasi_ppl
        ) VALUES
        ('farm-smp-01', 'usr-poktan-01', -6.97715990, 113.80453020, 'Mandala', 'Gapura',
         'ya', 'ya', 'ya', 'sumur bor', 'lancar', 'PLN',
         'traktor', 'tidak', 'jagung', 'Bisi 18 Hibrida', '0.7 H', 'milik sendiri',
         'Poktan Sumber Lestari (Gapura)', 'tidak', 5.40, 'ton',
         31.00, 64.50, 1420, 6.40, 145, 32, 185, 84,
         'penyuluh', 'Kondisi NPK & pH optimal untuk jagung hibrida. Pertahankan jadwal pengairan sumur bor 2x seminggu.', 'verified'),
        ('farm-smp-02', 'usr-petani-02', -6.97547730, 113.80073160, 'Pakondang', 'Rubaru',
         'ya', 'tidak', 'ya', 'sumur bor', 'lancar', 'BBM',
         'traktor', 'tidak', 'padi', 'Inpari 32', '0.8 H', 'milik sendiri',
         'Poktan Anugrah (Rubaru)', 'tidak', 6.10, 'ton',
         29.60, 72.00, 1380, 6.50, 132, 34, 178, 86,
         'penyuluh', 'Kelembapan ideal fase vegetatif padi. Tambahkan pupuk Urea susulan 50 kg/Ha pada HST ke-25.', 'verified'),
        ('farm-smp-03', NULL, -6.95689170, 113.77893970, 'Karangnangka', 'Rubaru',
         'tidak', 'tidak', 'ya', 'sumur bor', 'sulit', 'BBM',
         'manual', 'ya', 'cabai', 'Ori 212', '0.6 H', 'milik sendiri',
         'Poktan Anugrah (Rubaru)', 'tidak', 1.80, 'ton',
         32.60, 11.40, 290, 5.10, 42, 14, 72, 16,
         'petani', 'TITIK KRITIS: Tanah terlalu asam (pH 5.1) & kekeringan (11.4%). Berikan Dolomit 1.5 Ton/Ha + mulsa jerami.', 'needs_action'),
        ('farm-smp-04', NULL, -6.96889060, 113.79210220, 'Tambak Sari', 'Rubaru',
         'tidak', 'tidak', 'ya', 'sumur bor', 'tersedia', 'BBM',
         'manual', 'tidak', 'tembakau', 'Prancak-95 Sumenep', '0.9 H', 'milik sendiri',
         'Poktan Anugrah (Rubaru)', 'tidak', 1.45, 'ton',
         31.80, 54.00, 1210, 6.30, 118, 28, 195, 76,
         'penyuluh', 'Profil Kalium baik untuk mutu rajangan tembakau Prancak-95. Jaga drainase agar akar tidak tergenang.', 'verified'),
        ('farm-smp-05', NULL, -6.90624100, 113.67985000, 'Pasongsongan', 'Pasongsongan',
         'ya', 'ya', 'ya', 'sumur bor', 'lancar', 'PLN',
         'traktor', 'tidak', 'bawang merah', 'Batu Ijo / Rubaru', '1.1 H', 'milik sendiri',
         'Poktan Sekar Sari (Pasongsongan)', 'tidak', 7.20, 'ton',
         30.40, 61.50, 1480, 6.20, 124, 36, 190, 82,
         'penyuluh', 'Produktivitas tinggi. Monitoring embun bulu saat kelembapan malam > 70%.', 'verified'),
        ('farm-smp-06', NULL, -7.06418000, 113.69432000, 'Guluk-Guluk', 'Guluk-Guluk',
         'tidak', 'tidak', 'tidak', 'tadahan hujan', 'sulit', 'Manual',
         'sapi', 'ya', 'singkong', 'Manggu Lokal', '0.8 H', 'sewa',
         'Poktan Bukit Johar (Guluk-Guluk)', 'ya', 8.50, 'ton',
         33.40, 12.80, 340, 5.30, 55, 16, 88, 18,
         'petani', 'TITIK KRITIS: Deplesi hara pasca gagal panen & air sulit. Aplikasikan kompos kandang 3 Ton/Ha sebelum olah tanah.', 'needs_action'),
        ('farm-smp-07', NULL, -7.07891000, 113.92451000, 'Talango', 'Talango',
         'tidak', 'ya', 'ya', 'sumur bor', 'tersedia', 'PLN',
         'sapi', 'tidak', 'kacang', 'Tuban Lokal', '0.5 H', 'milik sendiri',
         'Poktan Al Hikmah (Talango)', 'tidak', 28.00, 'sak',
         30.90, 52.40, 1120, 6.60, 96, 26, 148, 72,
         'petani', 'Symbiosis bintil akar aktif. Tambah SP-36 100 kg/Ha untuk pengisian polong maksimal.', 'pending'),
        ('farm-smp-08', NULL, -6.88942000, 113.75824000, 'Ambunten', 'Ambunten',
         'ya', 'ya', 'ya', 'sumur bor', 'lancar', 'PLN',
         'traktor', 'tidak', 'jagung', 'Lamuru Sumenep', '1.0 H', 'milik sendiri',
         'Poktan Sumber Patemon (Ambunten)', 'tidak', 4.90, 'ton',
         29.80, 58.20, 1340, 6.40, 138, 30, 165, 80,
         'penyuluh', 'Standar kesuburan terpenuhi untuk jagung komposit. Siap alokasi serapan gudang Poktan.', 'verified');
      `);
      console.log('[MIGRATION] Seeded 8 representative Sumenep monitoring_lahan plots.');
    }

    console.log('[MIGRATION] Sumenep monitoring_lahan migration completed.');
  } catch (err) {
    console.error('[MIGRATION] Error running monitoring_lahan migration:', err.message);
    throw err;
  } finally {
    if (connection) connection.release();
  }
};

module.exports = runMonitoringLahanMigration;
