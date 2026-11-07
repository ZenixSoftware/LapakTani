-- ==============================================================================
-- Migration 009: B2B Partial Fulfillment Deficit Protocol & Wallet Infrastructure
-- US-24 & B2B Agribusiness Escrow Settlement
-- ==============================================================================

USE lapaktani_db;

-- 1. Relax ENUM constraints to support PARTIALLY_FULFILLED
ALTER TABLE b2b_orders MODIFY COLUMN status VARCHAR(50) DEFAULT 'draft';
ALTER TABLE b2b_contracts MODIFY COLUMN status VARCHAR(50) DEFAULT 'ACTIVE';

-- 2. Add deficit tracking and escrow accounting columns to b2b_orders
SET @dbname = DATABASE();
SET @tablename = 'b2b_orders';

-- agreed_price_per_kg
SET @preparedStatement = (SELECT IF(
  (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name = @tablename AND table_schema = @dbname AND column_name = 'agreed_price_per_kg') > 0,
  'SELECT 1',
  'ALTER TABLE b2b_orders ADD COLUMN agreed_price_per_kg DECIMAL(12,2) DEFAULT 15000.00'
));
PREPARE alterIfNotExists FROM @preparedStatement; EXECUTE alterIfNotExists; DEALLOCATE PREPARE alterIfNotExists;

-- actual_delivered_kg
SET @preparedStatement = (SELECT IF(
  (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name = @tablename AND table_schema = @dbname AND column_name = 'actual_delivered_kg') > 0,
  'SELECT 1',
  'ALTER TABLE b2b_orders ADD COLUMN actual_delivered_kg DECIMAL(12,2) DEFAULT NULL'
));
PREPARE alterIfNotExists FROM @preparedStatement; EXECUTE alterIfNotExists; DEALLOCATE PREPARE alterIfNotExists;

-- buyer_id
SET @preparedStatement = (SELECT IF(
  (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name = @tablename AND table_schema = @dbname AND column_name = 'buyer_id') > 0,
  'SELECT 1',
  'ALTER TABLE b2b_orders ADD COLUMN buyer_id VARCHAR(50) DEFAULT NULL'
));
PREPARE alterIfNotExists FROM @preparedStatement; EXECUTE alterIfNotExists; DEALLOCATE PREPARE alterIfNotExists;

-- settlement_notes
SET @preparedStatement = (SELECT IF(
  (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name = @tablename AND table_schema = @dbname AND column_name = 'settlement_notes') > 0,
  'SELECT 1',
  'ALTER TABLE b2b_orders ADD COLUMN settlement_notes TEXT DEFAULT NULL'
));
PREPARE alterIfNotExists FROM @preparedStatement; EXECUTE alterIfNotExists; DEALLOCATE PREPARE alterIfNotExists;

-- farmer_disbursed_amount
SET @preparedStatement = (SELECT IF(
  (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name = @tablename AND table_schema = @dbname AND column_name = 'farmer_disbursed_amount') > 0,
  'SELECT 1',
  'ALTER TABLE b2b_orders ADD COLUMN farmer_disbursed_amount DECIMAL(14,2) DEFAULT 0.00'
));
PREPARE alterIfNotExists FROM @preparedStatement; EXECUTE alterIfNotExists; DEALLOCATE PREPARE alterIfNotExists;

-- buyer_refund_amount
SET @preparedStatement = (SELECT IF(
  (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name = @tablename AND table_schema = @dbname AND column_name = 'buyer_refund_amount') > 0,
  'SELECT 1',
  'ALTER TABLE b2b_orders ADD COLUMN buyer_refund_amount DECIMAL(14,2) DEFAULT 0.00'
));
PREPARE alterIfNotExists FROM @preparedStatement; EXECUTE alterIfNotExists; DEALLOCATE PREPARE alterIfNotExists;

-- 3. Add settlement columns to b2b_contracts
SET @tablename = 'b2b_contracts';

SET @preparedStatement = (SELECT IF(
  (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name = @tablename AND table_schema = @dbname AND column_name = 'actual_delivered_kg') > 0,
  'SELECT 1',
  'ALTER TABLE b2b_contracts ADD COLUMN actual_delivered_kg DECIMAL(10,2) DEFAULT NULL'
));
PREPARE alterIfNotExists FROM @preparedStatement; EXECUTE alterIfNotExists; DEALLOCATE PREPARE alterIfNotExists;

SET @preparedStatement = (SELECT IF(
  (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name = @tablename AND table_schema = @dbname AND column_name = 'farmer_disbursed_amount') > 0,
  'SELECT 1',
  'ALTER TABLE b2b_contracts ADD COLUMN farmer_disbursed_amount DECIMAL(14,2) DEFAULT 0.00'
));
PREPARE alterIfNotExists FROM @preparedStatement; EXECUTE alterIfNotExists; DEALLOCATE PREPARE alterIfNotExists;

SET @preparedStatement = (SELECT IF(
  (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name = @tablename AND table_schema = @dbname AND column_name = 'buyer_refund_amount') > 0,
  'SELECT 1',
  'ALTER TABLE b2b_contracts ADD COLUMN buyer_refund_amount DECIMAL(14,2) DEFAULT 0.00'
));
PREPARE alterIfNotExists FROM @preparedStatement; EXECUTE alterIfNotExists; DEALLOCATE PREPARE alterIfNotExists;

SET @preparedStatement = (SELECT IF(
  (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name = @tablename AND table_schema = @dbname AND column_name = 'settlement_notes') > 0,
  'SELECT 1',
  'ALTER TABLE b2b_contracts ADD COLUMN settlement_notes TEXT DEFAULT NULL'
));
PREPARE alterIfNotExists FROM @preparedStatement; EXECUTE alterIfNotExists; DEALLOCATE PREPARE alterIfNotExists;

-- 4. Ensure wallet_balance on users and user_profiles
SET @preparedStatement = (SELECT IF(
  (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name = 'users' AND table_schema = @dbname AND column_name = 'wallet_balance') > 0,
  'SELECT 1',
  'ALTER TABLE users ADD COLUMN wallet_balance DECIMAL(15,2) DEFAULT 5000000.00'
));
PREPARE alterIfNotExists FROM @preparedStatement; EXECUTE alterIfNotExists; DEALLOCATE PREPARE alterIfNotExists;

SET @preparedStatement = (SELECT IF(
  (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name = 'user_profiles' AND table_schema = @dbname AND column_name = 'wallet_balance') > 0,
  'SELECT 1',
  'ALTER TABLE user_profiles ADD COLUMN wallet_balance DECIMAL(15,2) DEFAULT 5000000.00'
));
PREPARE alterIfNotExists FROM @preparedStatement; EXECUTE alterIfNotExists; DEALLOCATE PREPARE alterIfNotExists;

-- 5. Ensure commodity column on farms
SET @preparedStatement = (SELECT IF(
  (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name = 'farms' AND table_schema = @dbname AND column_name = 'commodity') > 0,
  'SELECT 1',
  'ALTER TABLE farms ADD COLUMN commodity VARCHAR(100) DEFAULT \'Cabai Rawit\''
));
PREPARE alterIfNotExists FROM @preparedStatement; EXECUTE alterIfNotExists; DEALLOCATE PREPARE alterIfNotExists;
