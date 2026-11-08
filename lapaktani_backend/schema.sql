CREATE DATABASE IF NOT EXISTS lapaktani_db;
USE lapaktani_db;

-- 1. Roles & Users
CREATE TABLE IF NOT EXISTS user_roles (
    id INT PRIMARY KEY,
    role_name VARCHAR(50) NOT NULL
);

INSERT IGNORE INTO user_roles (id, role_name) VALUES 
(1, 'petani'),
(2, 'penyuluh'),
(3, 'admin'),
(4, 'pembeli');

CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(50) PRIMARY KEY,
    full_name VARCHAR(150),
    email VARCHAR(150) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role_id INT DEFAULT 4,
    role ENUM('petani', 'pembeli', 'penyuluh', 'admin') DEFAULT 'pembeli',
    is_verified BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (role_id) REFERENCES user_roles(id) ON DELETE SET NULL
);

-- 2. Geospatial & Villages
CREATE TABLE IF NOT EXISTS villages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    district_id INT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT IGNORE INTO villages (id, name) VALUES
(1, 'Lembang'),
(2, 'Cibodas'),
(3, 'Cikole'),
(4, 'Parongpong');

-- 3. User Profiles
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
    wallet_balance DECIMAL(12, 2) DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (village_id) REFERENCES villages(id) ON DELETE SET NULL
);

-- 4. Farmer Groups (Poktan)
CREATE TABLE IF NOT EXISTS farmer_groups (
    id VARCHAR(50) PRIMARY KEY,
    group_name VARCHAR(150) NOT NULL,
    village_id INT DEFAULT 1,
    chairman_user_id VARCHAR(50) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (village_id) REFERENCES villages(id) ON DELETE SET NULL,
    FOREIGN KEY (chairman_user_id) REFERENCES users(id) ON DELETE SET NULL
);

INSERT IGNORE INTO farmer_groups (id, group_name, village_id) VALUES
('fg-lembang-01', 'Poktan Tani Makmur', 1),
('fg-cibodas-02', 'Poktan Sumber Rejeki', 2),
('fg-cikole-03', 'Poktan Subur Mandiri', 3),
('fg-parongpong-04', 'Poktan Harapan Jaya', 4);

-- 5. Farmer Profiles & Farms
CREATE TABLE IF NOT EXISTS farmer_profiles (
    user_id VARCHAR(50) PRIMARY KEY,
    farmer_group_id VARCHAR(50) NULL,
    ktp_image_url VARCHAR(255) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (farmer_group_id) REFERENCES farmer_groups(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS farms (
    id VARCHAR(100) PRIMARY KEY,
    farmer_id VARCHAR(50) NOT NULL,
    land_area_ha DECIMAL(10, 2) DEFAULT 1.00,
    soil_type VARCHAR(100) DEFAULT 'Aluvial Subur',
    gps_latitude DECIMAL(10, 8) DEFAULT -6.81520000,
    gps_longitude DECIMAL(11, 8) DEFAULT 107.61860000,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_farm_farmer (farmer_id)
);

-- 6. Commodities, Categories, Grades & Units
CREATE TABLE IF NOT EXISTS commodity_categories (
    id VARCHAR(50) PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL
);

INSERT IGNORE INTO commodity_categories (id, category_name) VALUES
('cat-sayurbuah', 'Sayur Buah'),
('cat-sayurdaun', 'Sayur Daun'),
('cat-umbiumbian', 'Umbi-umbian'),
('cat-rempah', 'Rempah & Bumbu');

CREATE TABLE IF NOT EXISTS commodities (
    id VARCHAR(50) PRIMARY KEY,
    category_id VARCHAR(50) NULL,
    specific_name VARCHAR(150) NOT NULL,
    FOREIGN KEY (category_id) REFERENCES commodity_categories(id) ON DELETE SET NULL
);

INSERT IGNORE INTO commodities (id, category_id, specific_name) VALUES
('com-tomat', 'cat-sayurbuah', 'Tomat Beef Segar'),
('com-kangkung', 'cat-sayurdaun', 'Kangkung Hidroponik'),
('com-kentang', 'cat-umbiumbian', 'Kentang Granola Super'),
('com-cabai', 'cat-rempah', 'Cabai Rawit Merah'),
('cmd-bawang-03', 'cat-rempah', 'Bawang Merah Brebes'),
('cmd-jagung-05', 'cat-sayurbuah', 'Jagung Manis Madu');

CREATE TABLE IF NOT EXISTS product_grades (
    id VARCHAR(50) PRIMARY KEY,
    grade_label VARCHAR(100) NOT NULL
);

INSERT IGNORE INTO product_grades (id, grade_label) VALUES
('grade-1', 'Grade A / Super'),
('grade-2', 'Grade B / Standar');

CREATE TABLE IF NOT EXISTS commodity_units (
    id VARCHAR(50) PRIMARY KEY,
    unit_name VARCHAR(50) NOT NULL,
    description VARCHAR(150) NULL
);

INSERT IGNORE INTO commodity_units (id, unit_name, description) VALUES
('unit-kg', 'Per Kilogram', '1 Kg baku timbangan'),
('unit-ikat', 'Per Ikat', '1 Ikat segar');

-- 7. Products & Product Images
CREATE TABLE IF NOT EXISTS products (
    id VARCHAR(50) PRIMARY KEY,
    farmer_id VARCHAR(50) NOT NULL,
    commodity_id VARCHAR(50) NULL,
    grade_id VARCHAR(50) NULL,
    unit_id VARCHAR(50) NULL,
    farm_id VARCHAR(100) NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    price_per_kg DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    stock_kg DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    price DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    stock INT NOT NULL DEFAULT 0,
    image_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (farmer_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (commodity_id) REFERENCES commodities(id) ON DELETE SET NULL,
    FOREIGN KEY (grade_id) REFERENCES product_grades(id) ON DELETE SET NULL,
    FOREIGN KEY (unit_id) REFERENCES commodity_units(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS product_images (
    id VARCHAR(50) PRIMARY KEY,
    product_id VARCHAR(50) NOT NULL,
    image_url VARCHAR(500) NOT NULL,
    is_primary BOOLEAN DEFAULT false,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);

-- 8. Cart Items
CREATE TABLE IF NOT EXISTS cart_items (
    id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL,
    product_id VARCHAR(50) NOT NULL,
    grade_id VARCHAR(50) NULL,
    quantity INT NOT NULL DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_cart_product (product_id),
    INDEX idx_cart_user (user_id)
);

-- 9. Orders & Order Items
CREATE TABLE IF NOT EXISTS orders (
    id VARCHAR(100) PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL,
    order_number VARCHAR(100) NOT NULL UNIQUE,
    total_amount DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    shipping_fee DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    payment_method VARCHAR(50) DEFAULT 'bank_transfer',
    payment_status VARCHAR(50) DEFAULT 'unpaid',
    status VARCHAR(50) DEFAULT 'WAITING_PAYMENT',
    delivery_address TEXT NULL,
    shipping_notes TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_order_user (user_id),
    INDEX idx_order_status (status)
);

CREATE TABLE IF NOT EXISTS order_items (
    id VARCHAR(100) PRIMARY KEY,
    order_id VARCHAR(100) NOT NULL,
    product_id VARCHAR(50) NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    price_per_unit DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    subtotal DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);

-- 10. Payments
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
);

-- 11. B2B Orders & Quota Allocations
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
    FOREIGN KEY (farmer_group_id) REFERENCES farmer_groups(id) ON DELETE CASCADE,
    FOREIGN KEY (commodity_id) REFERENCES commodities(id) ON DELETE CASCADE
);

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
);

-- 12. Soil Telemetry
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
    measured_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 13. Educational Articles (US-18)
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
);

-- 14. Pest Reports & Alerts (US-19)
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
);

-- 15. Notifications
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
);
