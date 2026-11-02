-- ==============================================================================
-- Migration 006: Soil Telemetries IoT & B2B Contracts
-- ==============================================================================

USE lapaktani_db;

-- 1. Ensure farms.id is VARCHAR(100)
ALTER TABLE farms MODIFY COLUMN id VARCHAR(100) NOT NULL;

-- 2. Add farm_id to products if not exists and link foreign key
ALTER TABLE products ADD COLUMN IF NOT EXISTS farm_id VARCHAR(100) DEFAULT NULL;

-- Link existing products to farms by matching farmer_id where possible
UPDATE products p
JOIN farms f ON p.farmer_id = f.farmer_id
SET p.farm_id = f.id
WHERE p.farm_id IS NULL;

-- 3. Create soil_telemetries table
CREATE TABLE IF NOT EXISTS soil_telemetries (
    id VARCHAR(100) PRIMARY KEY,
    farm_id VARCHAR(100) NOT NULL,
    measured_by VARCHAR(100) DEFAULT 'Sensor NPK 8-in-1',
    ph_level DECIMAL(4,2) NOT NULL DEFAULT 6.40,
    nitrogen_mg_kg DECIMAL(6,2) NOT NULL DEFAULT 142.00,
    phosphorus_mg_kg DECIMAL(6,2) NOT NULL DEFAULT 38.00,
    potassium_mg_kg DECIMAL(6,2) NOT NULL DEFAULT 210.00,
    moisture_percentage DECIMAL(5,2) NOT NULL DEFAULT 68.00,
    fertility_index ENUM('SANGAT_SUBUR', 'OPTIMAL', 'KURANG_SUBUR', 'KRITIS') DEFAULT 'OPTIMAL',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (farm_id) REFERENCES farms(id) ON DELETE CASCADE
);

-- 4. Create b2b_contracts table
CREATE TABLE IF NOT EXISTS b2b_contracts (
    id VARCHAR(100) PRIMARY KEY,
    product_id VARCHAR(100) NOT NULL,
    buyer_id VARCHAR(100) NOT NULL,
    farmer_id VARCHAR(100) NOT NULL,
    contract_number VARCHAR(100) NOT NULL UNIQUE,
    quantity_kg DECIMAL(10,2) NOT NULL,
    price_per_kg DECIMAL(12,2) NOT NULL,
    total_amount DECIMAL(14,2) NOT NULL,
    status ENUM('DRAFT', 'OFFERED', 'ACTIVE', 'COMPLETED', 'CANCELLED') DEFAULT 'ACTIVE',
    harvest_estimated_at DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);
