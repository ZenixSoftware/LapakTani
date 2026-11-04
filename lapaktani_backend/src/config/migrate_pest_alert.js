const pool = require('./db');

/**
 * Migration helper for US-19 Pest Reports and Alerts
 */
const runPestAlertMigration = async () => {
  let connection;
  try {
    connection = await pool.getConnection();
    console.log('[MIGRATION] Running migration 008: Pest Reports & Alerts (US-19)...');

    // 1. Create pest_reports table
    await connection.query(`
      CREATE TABLE IF NOT EXISTS pest_reports (
        id VARCHAR(50) PRIMARY KEY,
        reporter_id VARCHAR(50) NOT NULL,
        reporter_name VARCHAR(150) NOT NULL,
        reporter_role VARCHAR(50) DEFAULT 'farmer',
        pest_name VARCHAR(150) NOT NULL,
        crop_type VARCHAR(150) NOT NULL,
        severity ENUM('Ringan', 'Sedang', 'Berat') NOT NULL DEFAULT 'Sedang',
        affected_area VARCHAR(100) NOT NULL,
        farmer_group_id VARCHAR(50) NULL,
        farmer_group_name VARCHAR(150) NOT NULL,
        village_id INT DEFAULT 1,
        village_name VARCHAR(150) DEFAULT 'Desa Lembang',
        image_url VARCHAR(500) NULL,
        description TEXT NOT NULL,
        handling_recommendation TEXT NULL,
        emergency_alert BOOLEAN DEFAULT FALSE,
        status ENUM('active', 'contained', 'resolved') DEFAULT 'active',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        INDEX idx_pest_severity (severity),
        INDEX idx_pest_status (status),
        INDEX idx_pest_emergency (emergency_alert),
        INDEX idx_pest_group (farmer_group_id),
        INDEX idx_pest_created (created_at DESC)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
    `);

    // 2. Ensure notifications table exists and has reference_id
    await connection.query(`
      CREATE TABLE IF NOT EXISTS notifications (
        id VARCHAR(50) PRIMARY KEY,
        user_id VARCHAR(50) NOT NULL,
        title VARCHAR(200) NOT NULL,
        message TEXT NOT NULL,
        type VARCHAR(50) DEFAULT 'pest_alert',
        reference_id VARCHAR(50) NULL,
        is_read BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_notif_user (user_id),
        INDEX idx_notif_type (type)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
    `);

    // Check if reference_id exists in notifications
    const [cols] = await connection.query("SHOW COLUMNS FROM notifications LIKE 'reference_id'");
    if (cols.length === 0) {
      await connection.query('ALTER TABLE notifications ADD COLUMN reference_id VARCHAR(50) NULL');
      console.log('[MIGRATION] Added reference_id to notifications table.');
    }

    // 3. Seed initial critical pest alert if table is empty
    const [countRows] = await connection.query('SELECT COUNT(*) as count FROM pest_reports');
    if (countRows[0].count === 0) {
      await connection.query(`
        INSERT INTO pest_reports (
          id, reporter_id, reporter_name, reporter_role, pest_name, crop_type, 
          severity, affected_area, farmer_group_id, farmer_group_name, 
          village_id, village_name, image_url, description, 
          handling_recommendation, emergency_alert, status
        ) VALUES (
          'pest-alert-init-01',
          'f-maman',
          'H. Maman Suratman',
          'Ketua Poktan',
          'Ulat Grayak (Spodoptera frugiperda)',
          'Jagung & Cabai Merah',
          'Berat',
          '1.2 Hektar',
          'fg-lembang-01',
          'Poktan Tani Makmur',
          1,
          'Desa Lembang',
          'https://images.unsplash.com/photo-1592417817098-8f3d6910985c?auto=format&fit=crop&w=800&q=80',
          'Ditemukan serangan ulat grayak instar 3-4 memakan daun muda dan tongkol jagung seluas kurang lebih 1.2 ha di blok timur. Penularan cepat karena angin kencang.',
          'Segera lakukan penyemprotan insektisida nabati mimba atau Bacillus thuringiensis pada pagi hari (pukul 06.00-08.00 WIB). Pasang perangkap feromon di sekeliling blok lahan.',
          TRUE,
          'active'
        )
      `);
      console.log('[MIGRATION] Seeded initial critical pest alert.');
    }

    console.log('[MIGRATION] Pest Reports & Alerts migration completed successfully.');
  } catch (error) {
    console.warn('[MIGRATION] Notice during pest reports migration:', error.message);
  } finally {
    if (connection) connection.release();
  }
};

module.exports = runPestAlertMigration;

