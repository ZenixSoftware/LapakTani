CREATE DATABASE IF NOT EXISTS lapaktani_db;
USE lapaktani_db;

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
    id VARCHAR(36) PRIMARY KEY,
    full_name VARCHAR(150),
    email VARCHAR(150) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role_id INT DEFAULT 4,
    role ENUM('petani', 'pembeli') DEFAULT 'pembeli',
    is_verified BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (role_id) REFERENCES user_roles(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    farmer_id VARCHAR(36) NOT NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    price DECIMAL(12, 2) NOT NULL,
    stock INT NOT NULL DEFAULT 0,
    image_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (farmer_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS product_images (
    id VARCHAR(50) PRIMARY KEY,
    product_id VARCHAR(50),
    image_url VARCHAR(255),
    is_primary BOOLEAN DEFAULT false,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);

