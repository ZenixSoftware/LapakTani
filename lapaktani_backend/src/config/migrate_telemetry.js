const pool = require('./db');

const runMigration = async () => {
  let connection;
  try {
    connection = await pool.getConnection();
    console.log('[MIGRATION] Running migration 006: Soil Telemetry & B2B Contracts...');

    // 1. Expand farms.id to VARCHAR(100)
    await connection.query('ALTER TABLE farms MODIFY COLUMN id VARCHAR(100) NOT NULL');
    console.log('[MIGRATION] farms.id column adjusted to VARCHAR(100).');

    // 2. Add farm_id to products if not exists
    const [cols] = await connection.query("SHOW COLUMNS FROM products LIKE 'farm_id'");
    if (cols.length === 0) {
      await connection.query('ALTER TABLE products ADD COLUMN farm_id VARCHAR(100) DEFAULT NULL');
      console.log('[MIGRATION] Added farm_id column to products table.');
    }

    // Try adding foreign key if not already present
    try {
      await connection.query('ALTER TABLE products ADD CONSTRAINT fk_products_farm_id FOREIGN KEY (farm_id) REFERENCES farms(id) ON DELETE SET NULL');
      console.log('[MIGRATION] Added foreign key fk_products_farm_id.');
    } catch (fkErr) {
      if (fkErr.code === 'ER_DUP_KEY' || fkErr.code === 'ER_FK_DUP_NAME' || fkErr.message.includes('already exists')) {
        console.log('[MIGRATION] Foreign key fk_products_farm_id already exists.');
      } else {
        console.warn('[MIGRATION] Notice on foreign key constraint:', fkErr.message);
      }
    }

    // Link products to farms by matching farmer_id
    await connection.query(`
      UPDATE products p
      JOIN farms f ON p.farmer_id = f.farmer_id
      SET p.farm_id = f.id
      WHERE p.farm_id IS NULL
    `);
    console.log('[MIGRATION] Synchronized products.farm_id with matching farms.');

    // 3. Create soil_telemetries table
    await connection.query(`
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
        INDEX idx_soil_farm_id (farm_id)
      )
    `);
    console.log('[MIGRATION] Table soil_telemetries confirmed.');

    // Seed default telemetry for existing farms if table is empty
    const [telemetryCount] = await connection.query('SELECT COUNT(*) as count FROM soil_telemetries');
    if (telemetryCount[0].count === 0) {
      const [farms] = await connection.query('SELECT id, farmer_id FROM farms LIMIT 10');
      for (const farm of farms) {
        await connection.query(`
          INSERT INTO soil_telemetries 
            (id, farm_id, measured_by, ph_level, nitrogen_mg_kg, phosphorus_mg_kg, potassium_mg_kg, moisture_percentage, fertility_index)
          VALUES 
            (?, ?, 'Sensor NPK 8-in-1', 6.40, 142.00, 38.00, 210.00, 68.00, 'SANGAT_SUBUR')
        `, [`TEL-${farm.id.substring(0, 8)}-${Date.now()}`, farm.id]);
      }
      console.log(`[MIGRATION] Seeded default IoT telemetry for ${farms.length} farms.`);
    }

    // 4. Create b2b_contracts table
    await connection.query(`
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
        INDEX idx_b2b_product (product_id),
        INDEX idx_b2b_buyer (buyer_id),
        INDEX idx_b2b_farmer (farmer_id)
      )
    `);
    console.log('[MIGRATION] Table b2b_contracts confirmed.');

    console.log('[MIGRATION] 006 Migration executed successfully.');
    process.exit(0);
  } catch (error) {
    console.error('[MIGRATION] Error running migration 006:', error.message);
    process.exit(1);
  } finally {
    if (connection) connection.release();
  }
};

if (require.main === module) {
  runMigration();
}

module.exports = runMigration;
