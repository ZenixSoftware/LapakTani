-- ==============================================================================
-- LAPAKTANI COMPLETE DATABASE DUMP (CONSOLIDATED SETUP)
-- Generated for Collaborator Synchronization (Local XAMPP / MySQL / MariaDB)
-- Database Name: lapaktani_db
-- Default Test Password for all seeded users: password123
-- ==============================================================================

CREATE DATABASE IF NOT EXISTS lapaktani_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE lapaktani_db;

SET FOREIGN_KEY_CHECKS = 0;

-- ------------------------------------------------------------------------------
-- 1. USER ROLES & PERMISSIONS
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_roles (
    id INT PRIMARY KEY,
    role_name VARCHAR(50) NOT NULL UNIQUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO user_roles (id, role_name) VALUES 
(1, 'petani'),
(2, 'penyuluh'),
(3, 'admin'),
(4, 'pembeli')
ON DUPLICATE KEY UPDATE role_name = VALUES(role_name);

-- ------------------------------------------------------------------------------
-- 2. GEOSPATIAL & VILLAGES
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS villages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    district_id INT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO villages (id, name) VALUES
(1, 'Lembang'),
(2, 'Cibodas'),
(3, 'Cikole'),
(4, 'Parongpong')
ON DUPLICATE KEY UPDATE name = VALUES(name);

-- ------------------------------------------------------------------------------
-- 3. USERS & AUTHENTICATION
-- Password hash below corresponds to 'password123'
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(50) PRIMARY KEY,
    full_name VARCHAR(150),
    email VARCHAR(150) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role_id INT DEFAULT 4,
    role ENUM('petani', 'pembeli', 'penyuluh', 'admin') DEFAULT 'pembeli',
    is_verified BOOLEAN DEFAULT TRUE,
    wallet_balance DECIMAL(15, 2) DEFAULT 5000000.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (role_id) REFERENCES user_roles(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO users (id, full_name, email, password_hash, role_id, role, is_verified, wallet_balance) VALUES
('usr-poktan-01', 'Made Irawan', 'made@poktan.lapaktani.id', '$2b$10$IPgKCxmDH2I/dXKfcL597e3o16JlFNJSR8j/R1KTMr1HiYqnshSxa', 1, 'petani', 1, 15000000.00),
('usr-petani-02', 'Pak Supardi', 'supardi@petani.lapaktani.id', '$2b$10$IPgKCxmDH2I/dXKfcL597e3o16JlFNJSR8j/R1KTMr1HiYqnshSxa', 1, 'petani', 1, 2500000.00),
('usr-penyuluh-03', 'Ahmad Penyuluh, S.P.', 'penyuluh@lapaktani.id', '$2b$10$IPgKCxmDH2I/dXKfcL597e3o16JlFNJSR8j/R1KTMr1HiYqnshSxa', 2, 'penyuluh', 1, 1000000.00),
('usr-buyer-04', 'Budi Pembeli', 'pembeli@lapaktani.id', '$2b$10$IPgKCxmDH2I/dXKfcL597e3o16JlFNJSR8j/R1KTMr1HiYqnshSxa', 4, 'pembeli', 1, 8000000.00),
('usr-admin-05', 'Admin LapakTani', 'admin@lapaktani.id', '$2b$10$IPgKCxmDH2I/dXKfcL597e3o16JlFNJSR8j/R1KTMr1HiYqnshSxa', 3, 'admin', 1, 50000000.00)
ON DUPLICATE KEY UPDATE 
    full_name = VALUES(full_name),
    password_hash = VALUES(password_hash),
    role_id = VALUES(role_id),
    role = VALUES(role);

-- ------------------------------------------------------------------------------
-- 4. USER PROFILES
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_profiles (
    id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL UNIQUE,
    full_name VARCHAR(150),
    nik_number VARCHAR(30) NULL,
    phone VARCHAR(30) NULL,
    detail_address TEXT NULL,
    birth_date DATE NULL,
    avatar_url VARCHAR(500) NULL,
    verification_status ENUM('pending', 'verified', 'rejected') DEFAULT 'verified',
    bpp_unit VARCHAR(150) NULL,
    nip VARCHAR(50) NULL,
    village_id INT DEFAULT 1,
    wallet_balance DECIMAL(15, 2) DEFAULT 5000000.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (village_id) REFERENCES villages(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO user_profiles (id, user_id, full_name, nik_number, phone, detail_address, birth_date, avatar_url, verification_status, bpp_unit, nip, village_id, wallet_balance) VALUES
('prof-01', 'usr-poktan-01', 'Made Irawan', '3204121508800001', '081234567891', 'Jl. Maribaya No. 45, Lembang', '1980-08-15', 'uploads/avatars/made.jpg', 'verified', NULL, NULL, 1, 15000000.00),
('prof-02', 'usr-petani-02', 'Pak Supardi', '3204122005750002', '081234567892', 'Kp. Cibodas RT 02/04, Lembang', '1975-05-20', 'uploads/avatars/supardi.jpg', 'verified', NULL, NULL, 2, 2500000.00),
('prof-03', 'usr-penyuluh-03', 'Ahmad Penyuluh, S.P.', '3204121003850003', '081234567893', 'Kantor BPP Lembang, Bandung Barat', '1985-03-10', 'uploads/avatars/ahmad.jpg', 'verified', 'BPP Lembang', '198503152010011002', 1, 1000000.00),
('prof-04', 'usr-buyer-04', 'Budi Pembeli', '3273011409920004', '081234567894', 'Jl. Riau No. 12, Bandung Kota', '1992-09-14', 'uploads/avatars/budi.jpg', 'verified', NULL, NULL, 1, 8000000.00),
('prof-05', 'usr-admin-05', 'Admin LapakTani', '3273010101900005', '081234567890', 'Gedung Pusat LapakTani Bandung', '1990-01-01', NULL, 'verified', NULL, NULL, 1, 50000000.00)
ON DUPLICATE KEY UPDATE 
    full_name = VALUES(full_name),
    verification_status = VALUES(verification_status),
    wallet_balance = VALUES(wallet_balance);

-- ------------------------------------------------------------------------------
-- 5. FARMER GROUPS (POKTAN / MITRA TANI)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS farmer_groups (
    id VARCHAR(50) PRIMARY KEY,
    group_name VARCHAR(150) NOT NULL,
    village_id INT DEFAULT 1,
    chairman_user_id VARCHAR(50) NULL,
    leader_name VARCHAR(150) DEFAULT 'Made Irawan',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (village_id) REFERENCES villages(id) ON DELETE SET NULL,
    FOREIGN KEY (chairman_user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO farmer_groups (id, group_name, village_id, chairman_user_id, leader_name) VALUES
('fg-01', 'Mitra Tani Makmur (Poktan Lembang)', 1, 'usr-poktan-01', 'Made Irawan'),
('fg-02', 'Mitra Tani Pasundan (Pangalengan)', 2, NULL, 'Kang Dedi'),
('fg-03', 'Mitra Tani Berkah Mandiri (Dieng)', 3, NULL, 'Pak Slamet'),
('fg-04', 'Poktan Harapan Jaya (Parongpong)', 4, NULL, 'Pak Agus')
ON DUPLICATE KEY UPDATE 
    group_name = VALUES(group_name),
    chairman_user_id = VALUES(chairman_user_id);

-- ------------------------------------------------------------------------------
-- 6. FARMER PROFILES & FARMS
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS farmer_profiles (
    user_id VARCHAR(50) PRIMARY KEY,
    farmer_group_id VARCHAR(50) NULL,
    ktp_image_url VARCHAR(255) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (farmer_group_id) REFERENCES farmer_groups(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO farmer_profiles (user_id, farmer_group_id) VALUES
('usr-poktan-01', 'fg-01'),
('usr-petani-02', 'fg-01')
ON DUPLICATE KEY UPDATE farmer_group_id = VALUES(farmer_group_id);

CREATE TABLE IF NOT EXISTS farms (
    id VARCHAR(100) PRIMARY KEY,
    farmer_id VARCHAR(50) NOT NULL,
    land_area_ha DECIMAL(10, 2) DEFAULT 1.00,
    soil_type VARCHAR(100) DEFAULT 'Andosol Vulkanik Subur',
    commodity VARCHAR(100) DEFAULT 'Cabai Merah Keriting',
    gps_latitude DECIMAL(10, 8) DEFAULT -6.81520000,
    gps_longitude DECIMAL(11, 8) DEFAULT 107.61860000,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_farm_farmer (farmer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO farms (id, farmer_id, land_area_ha, soil_type, commodity, gps_latitude, gps_longitude) VALUES
('farm-01', 'usr-poktan-01', 2.50, 'Andosol Vulkanik Subur', 'Cabai Merah Keriting', -6.81520000, 107.61860000),
('farm-02', 'usr-petani-02', 1.20, 'Aluvial Humus', 'Tomat Beef Organik', -6.82010000, 107.62540000)
ON DUPLICATE KEY UPDATE 
    land_area_ha = VALUES(land_area_ha),
    soil_type = VALUES(soil_type);

-- ------------------------------------------------------------------------------
-- 7. COMMODITIES, CATEGORIES, GRADES & UNITS
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS commodity_categories (
    id VARCHAR(50) PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO commodity_categories (id, category_name) VALUES
('cat-sayurbuah', 'Sayur Buah'),
('cat-sayurdaun', 'Sayur Daun'),
('cat-umbiumbian', 'Umbi-umbian'),
('cat-rempah', 'Rempah & Bumbu')
ON DUPLICATE KEY UPDATE category_name = VALUES(category_name);

CREATE TABLE IF NOT EXISTS commodities (
    id VARCHAR(50) PRIMARY KEY,
    category_id VARCHAR(50) NULL,
    specific_name VARCHAR(150) NOT NULL,
    FOREIGN KEY (category_id) REFERENCES commodity_categories(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO commodities (id, category_id, specific_name) VALUES
('com-cabai', 'cat-rempah', 'Cabai Merah Keriting'),
('com-tomat', 'cat-sayurbuah', 'Tomat Beef Segar'),
('com-kentang', 'cat-umbiumbian', 'Kentang Granola Dieng'),
('com-bawang', 'cat-rempah', 'Bawang Merah Brebes'),
('com-kangkung', 'cat-sayurdaun', 'Kangkung Hidroponik'),
('com-jagung', 'cat-sayurbuah', 'Jagung Manis Madu')
ON DUPLICATE KEY UPDATE specific_name = VALUES(specific_name);

CREATE TABLE IF NOT EXISTS product_grades (
    id VARCHAR(50) PRIMARY KEY,
    grade_label VARCHAR(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO product_grades (id, grade_label) VALUES
('grade-1', 'Grade A Super (Bebas Residu)'),
('grade-2', 'Grade B Standar Pasar')
ON DUPLICATE KEY UPDATE grade_label = VALUES(grade_label);

CREATE TABLE IF NOT EXISTS commodity_units (
    id VARCHAR(50) PRIMARY KEY,
    unit_name VARCHAR(50) NOT NULL,
    description VARCHAR(150) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO commodity_units (id, unit_name, description) VALUES
('unit-kg', 'Per Kilogram', '1 Kg baku timbangan digital'),
('unit-ikat', 'Per Ikat', '1 Ikat segar terikat')
ON DUPLICATE KEY UPDATE unit_name = VALUES(unit_name);

-- ------------------------------------------------------------------------------
-- 8. PRODUCTS & PRODUCT IMAGES
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS products (
    id VARCHAR(50) PRIMARY KEY,
    farmer_id VARCHAR(50) NOT NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    price_per_kg DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    stock_kg DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    image_url VARCHAR(500),
    unit_id VARCHAR(50) DEFAULT 'unit-kg',
    commodity_id VARCHAR(50) NOT NULL,
    grade_id VARCHAR(50) DEFAULT 'grade-1',
    farm_id VARCHAR(100) NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (farmer_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (commodity_id) REFERENCES commodities(id) ON DELETE CASCADE,
    FOREIGN KEY (grade_id) REFERENCES product_grades(id) ON DELETE CASCADE,
    FOREIGN KEY (unit_id) REFERENCES commodity_units(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO products (id, farmer_id, title, description, price_per_kg, stock_kg, image_url, unit_id, commodity_id, grade_id, farm_id, is_active) VALUES
('prod-001', 'usr-poktan-01', 'Cabai Merah Keriting Kencana Super', 'Cabai segar dipetik subuh dari lahan dataran tinggi Lembang (1.250 mdpl). Pedas optimal dan bebas residu pestisida.', 28000.00, 350.00, 'uploads/products/cabai.jpg', 'unit-kg', 'com-cabai', 'grade-1', 'farm-01', 1),
('prod-002', 'usr-petani-02', 'Tomat Beef Dataran Tinggi Segar', 'Tomat beef padat berdaging tebal, cocok untuk hotel, restoran, dan konsumsi harian keluarga.', 12500.00, 420.00, 'uploads/products/tomat.jpg', 'unit-kg', 'com-tomat', 'grade-1', 'farm-02', 1),
('prod-003', 'usr-poktan-01', 'Kentang Granola Super Dieng', 'Kentang grade olahan katering dan restoran, kulit mulus minim cacat.', 16000.00, 800.00, 'uploads/products/kentang.jpg', 'unit-kg', 'com-kentang', 'grade-1', 'farm-01', 1),
('prod-004', 'usr-poktan-01', 'Bawang Merah Brebes Unggul', 'Bawang merah aroma tajam dengan kadar air rendah, awet disimpan.', 32000.00, 200.00, 'uploads/products/bawang.jpg', 'unit-kg', 'com-bawang', 'grade-1', 'farm-01', 1)
ON DUPLICATE KEY UPDATE 
    price_per_kg = VALUES(price_per_kg),
    stock_kg = VALUES(stock_kg),
    image_url = VALUES(image_url);

CREATE TABLE IF NOT EXISTS product_images (
    id VARCHAR(50) PRIMARY KEY,
    product_id VARCHAR(50) NOT NULL,
    image_url VARCHAR(255) NOT NULL,
    is_primary BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO product_images (id, product_id, image_url, is_primary) VALUES
('img-01', 'prod-001', 'uploads/products/cabai.jpg', 1),
('img-02', 'prod-002', 'uploads/products/tomat.jpg', 1),
('img-03', 'prod-003', 'uploads/products/kentang.jpg', 1)
ON DUPLICATE KEY UPDATE is_primary = VALUES(is_primary);

-- ------------------------------------------------------------------------------
-- 9. SHOPPING CART
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS cart_items (
    id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL,
    product_id VARCHAR(50) NOT NULL,
    grade_id VARCHAR(50) NULL,
    quantity INT NOT NULL DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_cart_product (product_id),
    INDEX idx_cart_user (user_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------------------------
-- 10. ORDERS & ORDER ITEMS
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS orders (
    id VARCHAR(100) PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL,
    buyer_id VARCHAR(50) NULL,
    seller_id VARCHAR(50) NULL,
    farmer_id VARCHAR(50) NULL,
    invoice_number VARCHAR(100) NULL,
    order_code VARCHAR(100) NULL,
    total_amount DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    total_payment DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    shipping_fee DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    payment_method VARCHAR(50) DEFAULT 'bank_transfer',
    payment_status VARCHAR(50) DEFAULT 'unpaid',
    order_status VARCHAR(50) DEFAULT 'PENDING',
    payment_channel VARCHAR(50) NULL,
    payment_reference VARCHAR(100) NULL,
    payment_expired_at DATETIME NULL,
    delivery_address TEXT NULL,
    shipping_address TEXT NULL,
    notes TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_order_buyer (buyer_id),
    INDEX idx_order_seller (seller_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS order_items (
    id VARCHAR(100) PRIMARY KEY,
    order_id VARCHAR(100) NOT NULL,
    product_id VARCHAR(50) NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    price_per_unit DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    subtotal DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------------------------
-- 11. PAYMENTS & MIDTRANS CORE API
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS payments (
    id VARCHAR(100) PRIMARY KEY,
    order_id VARCHAR(100) NOT NULL,
    transaction_id VARCHAR(100) NULL,
    payment_type VARCHAR(50) NOT NULL,
    gross_amount DECIMAL(12, 2) NOT NULL,
    transaction_status VARCHAR(50) NOT NULL DEFAULT 'pending',
    va_number VARCHAR(100) NULL,
    bank VARCHAR(50) NULL,
    settlement_time DATETIME NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------------------------
-- 12. B2B HARVEST POOLS & OPEN-QUOTA (GROSIR / BORONGAN)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS b2b_harvest_pools (
    id VARCHAR(50) PRIMARY KEY,
    farmer_group_id VARCHAR(50) NOT NULL DEFAULT 'fg-01',
    mitra_name VARCHAR(100) NOT NULL DEFAULT 'Mitra Tani Makmur',
    commodity_id VARCHAR(50) NOT NULL,
    commodity_name VARCHAR(100) NOT NULL,
    variety VARCHAR(100) DEFAULT 'Kencana Tropis',
    grade VARCHAR(50) DEFAULT 'Grade A Super',
    image_url VARCHAR(255) DEFAULT 'uploads/products/cabai.jpg',
    min_order_kg DECIMAL(12,2) DEFAULT 50.00,
    packaging_sop VARCHAR(150) DEFAULT 'Krat Plastik & Cold Chain (12°C)',
    auto_spillover TINYINT(1) DEFAULT 1,
    target_harvest_date VARCHAR(50) NOT NULL,
    total_quota_kg DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    allocated_quota_kg DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    remaining_quota_kg DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    price_per_kg DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    status VARCHAR(30) NOT NULL DEFAULT 'open',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_b2b_pool_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO b2b_harvest_pools 
    (id, farmer_group_id, mitra_name, commodity_id, commodity_name, variety, grade, image_url, min_order_kg, packaging_sop, auto_spillover, target_harvest_date, total_quota_kg, allocated_quota_kg, remaining_quota_kg, price_per_kg, status, notes)
VALUES 
    ('pool-01', 'fg-01', 'Mitra Tani Makmur', 'com-cabai', 'Cabai Merah Keriting Super', 'Kencana Tropis', 'Grade A Super', 'uploads/products/cabai.jpg', 50.00, 'Krat Plastik & Cold Chain (12°C)', 1, '15 Nov 2026', 350.00, 300.00, 50.00, 28000.00, 'open', 'Hasil panen lahan konsolidasi Lembang bergaransi fresh'),
    ('pool-02', 'fg-02', 'Mitra Tani Pasundan', 'com-tomat', 'Tomat Beef Dataran Tinggi', 'Beef Lembang Super', 'Grade A Super', 'uploads/products/tomat.jpg', 40.00, 'Krat Berpori & Pendingin', 1, '20 Nov 2026', 500.00, 200.00, 300.00, 12500.00, 'open', 'Dipetik subuh dari dataran tinggi Pangalengan'),
    ('pool-03', 'fg-03', 'Mitra Tani Berkah Mandiri', 'com-kentang', 'Kentang Granola Dieng', 'Granola Super Dieng', 'Grade A Super', 'uploads/products/kentang.jpg', 100.00, 'Karung Jaring Ventilasi 25kg', 1, '28 Nov 2026', 1000.00, 650.00, 350.00, 16000.00, 'open', 'Sortir grade restoran & katering partai besar')
ON DUPLICATE KEY UPDATE
    total_quota_kg = VALUES(total_quota_kg),
    remaining_quota_kg = VALUES(remaining_quota_kg),
    price_per_kg = VALUES(price_per_kg);

CREATE TABLE IF NOT EXISTS b2b_quota_allocations (
    id VARCHAR(50) PRIMARY KEY,
    pool_id VARCHAR(50) NOT NULL,
    buyer_id VARCHAR(50) NOT NULL,
    buyer_name VARCHAR(100) NOT NULL,
    taken_kg DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    price_per_kg DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    total_price DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_b2b_alloc_pool (pool_id),
    INDEX idx_b2b_alloc_buyer (buyer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------------------------
-- 13. B2B ORDERS & SETTLEMENT WITH DEFICIT ESCROW PROTOCOL
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS b2b_orders (
    id VARCHAR(50) PRIMARY KEY,
    farmer_group_id VARCHAR(50) NOT NULL,
    commodity_id VARCHAR(50) NOT NULL,
    total_quota_kg DECIMAL(12, 2) NOT NULL,
    buyer_name VARCHAR(150) NOT NULL,
    buyer_id VARCHAR(50) NULL,
    deadline DATE NOT NULL,
    status VARCHAR(50) DEFAULT 'draft',
    agreed_price_per_kg DECIMAL(12,2) DEFAULT 15000.00,
    actual_delivered_kg DECIMAL(12,2) DEFAULT NULL,
    farmer_disbursed_amount DECIMAL(14,2) DEFAULT 0.00,
    buyer_refund_amount DECIMAL(14,2) DEFAULT 0.00,
    settlement_notes TEXT DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (farmer_group_id) REFERENCES farmer_groups(id) ON DELETE CASCADE,
    FOREIGN KEY (commodity_id) REFERENCES commodities(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO b2b_orders (id, farmer_group_id, commodity_id, total_quota_kg, buyer_name, buyer_id, deadline, status, agreed_price_per_kg, actual_delivered_kg) VALUES
('b2b-ord-01', 'fg-01', 'com-cabai', 500.00, 'CV Segar Mandiri Catering', 'usr-buyer-04', '2026-11-20', 'in_progress', 26000.00, NULL),
('b2b-ord-02', 'fg-01', 'com-tomat', 300.00, 'Hotel Grand Lembang', 'usr-buyer-04', '2026-11-25', 'in_progress', 11000.00, NULL)
ON DUPLICATE KEY UPDATE status = VALUES(status);

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
    FOREIGN KEY (b2b_order_id) REFERENCES b2b_orders(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO quota_allocations (id, b2b_order_id, farmer_id, allocated_kg, planting_deadline, harvest_deadline, status) VALUES
('alloc-01', 'b2b-ord-01', 'usr-petani-02', 250.00, '2026-09-01', '2026-11-18', 'planting'),
('alloc-02', 'b2b-ord-01', 'usr-poktan-01', 250.00, '2026-09-01', '2026-11-18', 'planting')
ON DUPLICATE KEY UPDATE status = VALUES(status);

CREATE TABLE IF NOT EXISTS b2b_contracts (
    id VARCHAR(100) PRIMARY KEY,
    product_id VARCHAR(100) NOT NULL,
    buyer_id VARCHAR(100) NOT NULL,
    farmer_id VARCHAR(100) NOT NULL,
    contract_number VARCHAR(100) NOT NULL UNIQUE,
    quantity_kg DECIMAL(10,2) NOT NULL,
    price_per_kg DECIMAL(12,2) NOT NULL,
    total_amount DECIMAL(14,2) NOT NULL,
    status VARCHAR(50) DEFAULT 'ACTIVE',
    harvest_estimated_at DATE,
    actual_delivered_kg DECIMAL(10,2) DEFAULT NULL,
    farmer_disbursed_amount DECIMAL(14,2) DEFAULT 0.00,
    buyer_refund_amount DECIMAL(14,2) DEFAULT 0.00,
    settlement_notes TEXT DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------------------------
-- 14. SOIL TELEMETRY IOT SENSOR
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS soil_telemetries (
    id VARCHAR(100) PRIMARY KEY,
    farm_id VARCHAR(100) NOT NULL,
    measured_by VARCHAR(100) DEFAULT 'Sensor NPK 8-in-1',
    ph_level DECIMAL(4,2) NOT NULL DEFAULT 6.40,
    nitrogen_mg_kg DECIMAL(6,2) NOT NULL DEFAULT 142.00,
    phosphorus_mg_kg DECIMAL(6,2) NOT NULL DEFAULT 38.00,
    potassium_mg_kg DECIMAL(6,2) NOT NULL DEFAULT 210.00,
    moisture_percentage DECIMAL(5,2) NOT NULL DEFAULT 72.50,
    temperature_celsius DECIMAL(5,2) NOT NULL DEFAULT 21.50,
    fertility_index VARCHAR(50) NOT NULL DEFAULT 'Sangat Subur',
    measured_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_telemetry_farm (farm_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO soil_telemetries (id, farm_id, measured_by, ph_level, nitrogen_mg_kg, phosphorus_mg_kg, potassium_mg_kg, moisture_percentage, temperature_celsius, fertility_index) VALUES
('tele-01', 'farm-01', 'Sensor NPK 8-in-1 Lembang', 6.50, 155.00, 42.00, 220.00, 74.00, 21.00, 'Sangat Subur'),
('tele-02', 'farm-02', 'Sensor NPK 8-in-1 Cibodas', 6.20, 130.00, 35.00, 195.00, 70.00, 22.50, 'Optimal')
ON DUPLICATE KEY UPDATE fertility_index = VALUES(fertility_index);

-- ------------------------------------------------------------------------------
-- 15. EDUCATIONAL ARTICLES (US-18 PENYULUH BPP)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS educational_articles (
    id VARCHAR(100) PRIMARY KEY,
    author_id VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL,
    commodity VARCHAR(100) NOT NULL,
    summary TEXT NOT NULL,
    content LONGTEXT NOT NULL,
    steps_json JSON NULL,
    image_url VARCHAR(500) NULL,
    read_time_minutes INT DEFAULT 5,
    likes_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (author_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO educational_articles (id, author_id, title, category, commodity, summary, content, read_time_minutes, likes_count) VALUES
('edu-01', 'usr-penyuluh-03', 'Panduan Pengendalian Hama Ulat Grayak Tanpa Residu Kimia', 'Hama & Penyakit', 'Cabai Merah Keriting', 'SOP terpadu penggunaan pestisida nabati daun nimba dan perangkap feromon kuning.', 'Gunakan ekstrak daun nimba konsentrasi 5% yang disemprotkan pada sore hari saat hama aktif. Kombinasikan dengan sanitasi gulma di sekitar bedengan untuk memutus siklus bertelur.', 4, 18),
('edu-02', 'usr-penyuluh-03', 'Optimasi Pemupukan NPK Berimbang untuk Tomat Dataran Tinggi', 'Nutrisi Tanah', 'Tomat Beef Segar', 'Cara mempertahankan pH tanah di angka 6.2 - 6.8 demi bobot panen maksimal.', 'Lakukan aplikasi dolomit 2 minggu sebelum masa tanam, lalu berikan NPK 16-16-16 bertahap pada fase vegetatif dan tambahkan KNO3 putih saat pembungaan.', 6, 24)
ON DUPLICATE KEY UPDATE title = VALUES(title);

-- ------------------------------------------------------------------------------
-- 16. PEST REPORTS & EARLY WARNING ALERTS (US-19)
-- ------------------------------------------------------------------------------
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO pest_reports (id, reporter_id, reporter_name, reporter_role, pest_name, crop_type, severity, affected_area, farmer_group_id, farmer_group_name, village_id, village_name, description, handling_recommendation, emergency_alert, status) VALUES
('pest-01', 'usr-petani-02', 'Pak Supardi', 'farmer', 'Kutu Kebul (Bemisia tabaci)', 'Cabai Merah Keriting', 'Sedang', '0.4 Hektar Blok Utara', 'fg-01', 'Mitra Tani Makmur (Poktan Lembang)', 1, 'Desa Lembang', 'Ditemukan bercak kuning mosaik pada daun muda cabai akibat serangan kutu kebul.', 'Pasang yellow sticky trap 40 buah per hektar dan aplikasikan insektisida nabati minyak mimba.', 1, 'active')
ON DUPLICATE KEY UPDATE status = VALUES(status);

-- ------------------------------------------------------------------------------
-- 17. NOTIFICATIONS & AUDIT LOGS
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS notifications (
    id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) DEFAULT 'quota_task',
    reference_id VARCHAR(50) NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_notif_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO notifications (id, user_id, title, message, type, reference_id, is_read) VALUES
('notif-01', 'usr-poktan-01', 'Selamat Datang di LapakTani Mitra', 'Akun Ketua Poktan Tani Makmur aktif. Silakan kelola etalase dan bursa partai panen.', 'system', NULL, 1),
('notif-02', 'usr-petani-02', 'Alokasi Kuota Tanam B2B', 'Anda mendapatkan penugasan alokasi tanam 250 kg Cabai Merah Keriting.', 'quota_task', 'alloc-01', 0)
ON DUPLICATE KEY UPDATE title = VALUES(title);

-- ------------------------------------------------------------------------------
-- 18. WALLETS & ESCROW ACCOUNTING
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS wallets (
    id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL UNIQUE,
    balance DECIMAL(15, 2) NOT NULL DEFAULT 5000000.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO wallets (id, user_id, balance) VALUES
('w-poktan-01', 'usr-poktan-01', 15000000.00),
('w-petani-02', 'usr-petani-02', 2500000.00),
('w-buyer-04', 'usr-buyer-04', 8000000.00)
ON DUPLICATE KEY UPDATE balance = VALUES(balance);

CREATE TABLE IF NOT EXISTS wallet_transactions (
    id VARCHAR(50) PRIMARY KEY,
    wallet_id VARCHAR(50) NOT NULL,
    transaction_type ENUM('credit', 'debit', 'escrow_disbursement', 'escrow_refund') NOT NULL,
    amount DECIMAL(15, 2) NOT NULL,
    reference_id VARCHAR(100) NULL,
    description TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (wallet_id) REFERENCES wallets(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO wallet_transactions (id, wallet_id, transaction_type, amount, reference_id, description) VALUES
('tx-01', 'w-poktan-01', 'credit', 15000000.00, 'INIT-01', 'Saldo modal awal dompet LapakPay Mitra'),
('tx-02', 'w-buyer-04', 'credit', 8000000.00, 'INIT-02', 'Saldo modal awal dompet pembeli borongan')
ON DUPLICATE KEY UPDATE amount = VALUES(amount);

SET FOREIGN_KEY_CHECKS = 1;
