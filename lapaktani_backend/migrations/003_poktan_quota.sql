-- Migration: 003_poktan_quota.sql
-- US-24 Manajemen Konsolidasi Lahan & Alokasi Kuota Panen Poktan

-- 1. Ensure basic farmer_groups table exists and has chairman_user_id column
CREATE TABLE IF NOT EXISTS farmer_groups (
    id VARCHAR(50) PRIMARY KEY,
    group_name VARCHAR(150) NOT NULL,
    village_id INT DEFAULT 1,
    chairman_user_id VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_farmer_groups_chairman FOREIGN KEY (chairman_user_id) REFERENCES users(id) ON DELETE SET NULL
);

-- Add chairman_user_id safely referencing users(id) if missing in existing table
SET @dbname = DATABASE();
SET @tablename = 'farmer_groups';
SET @columnname = 'chairman_user_id';
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE
      (table_name = @tablename)
      AND (table_schema = @dbname)
      AND (column_name = @columnname)
  ) > 0,
  'SELECT 1',
  'ALTER TABLE farmer_groups ADD COLUMN chairman_user_id VARCHAR(50) NULL, ADD CONSTRAINT fk_farmer_groups_chairman FOREIGN KEY (chairman_user_id) REFERENCES users(id) ON DELETE SET NULL'
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

-- 2. Ensure farmer_profiles table exists
CREATE TABLE IF NOT EXISTS farmer_profiles (
    user_id VARCHAR(50) PRIMARY KEY,
    farmer_group_id VARCHAR(50),
    ktp_image_url VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Ensure farms table exists
CREATE TABLE IF NOT EXISTS farms (
    id VARCHAR(50) PRIMARY KEY,
    farmer_id VARCHAR(50) NOT NULL,
    land_area_ha DECIMAL(10, 2) DEFAULT 0.00,
    soil_type VARCHAR(100),
    gps_latitude DECIMAL(10, 8),
    gps_longitude DECIMAL(11, 8),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_farm_farmer (farmer_id)
);

-- 4. Ensure commodities table exists
CREATE TABLE IF NOT EXISTS commodities (
    id VARCHAR(50) PRIMARY KEY,
    specific_name VARCHAR(150) NOT NULL
);

-- Seed default commodities if empty
INSERT IGNORE INTO commodities (id, specific_name) VALUES
('cmd-kentang-01', 'Kentang Granola Super'),
('cmd-cabai-02', 'Cabai Merah Keriting'),
('cmd-bawang-03', 'Bawang Merah Brebes'),
('cmd-tomat-04', 'Tomat Beef Segar'),
('cmd-jagung-05', 'Jagung Manis Madu'),
('cmd-wortel-06', 'Wortel Brastagi');

-- 5. Tabel Pesanan B2B untuk Poktan
CREATE TABLE IF NOT EXISTS b2b_orders (
    id VARCHAR(50) PRIMARY KEY,
    farmer_group_id VARCHAR(50) NOT NULL,
    commodity_id VARCHAR(50) NOT NULL,
    total_quota_kg DECIMAL(12, 2) NOT NULL,
    buyer_name VARCHAR(150) NOT NULL,
    deadline DATE NOT NULL,
    status ENUM('draft', 'allocated', 'in_progress', 'completed', 'cancelled') DEFAULT 'draft',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_b2b_group (farmer_group_id),
    INDEX idx_b2b_commodity (commodity_id)
);

-- 6. Tabel Alokasi Kuota ke Petani Anggota
CREATE TABLE IF NOT EXISTS quota_allocations (
    id VARCHAR(50) PRIMARY KEY,
    b2b_order_id VARCHAR(50) NOT NULL,
    farmer_id VARCHAR(50) NOT NULL,
    allocated_kg DECIMAL(12, 2) NOT NULL,
    planting_deadline DATE,
    harvest_deadline DATE,
    status ENUM('pending', 'planting', 'harvesting', 'delivered', 'cancelled') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_alloc_order (b2b_order_id),
    INDEX idx_alloc_farmer (farmer_id)
);

-- 7. Tabel Notifikasi Pengguna
CREATE TABLE IF NOT EXISTS notifications (
    id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) DEFAULT 'quota_task',
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_notif_user (user_id)
);
