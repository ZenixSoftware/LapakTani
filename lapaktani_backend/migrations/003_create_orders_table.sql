-- Migration: 003_create_orders_table.sql
-- US-13: Checkout Pemesanan & Pembuatan Invoice (MySQL Transaction & Invoice Table)

CREATE TABLE IF NOT EXISTS orders (
  id VARCHAR(50) PRIMARY KEY,
  user_id VARCHAR(50) NOT NULL,
  invoice_number VARCHAR(100) NOT NULL UNIQUE,
  total_amount DECIMAL(14, 2) NOT NULL DEFAULT 0,
  shipping_fee DECIMAL(14, 2) NOT NULL DEFAULT 0,
  payment_method VARCHAR(50) NOT NULL DEFAULT 'LAPAKPAY_SIMULATOR',
  payment_status VARCHAR(50) NOT NULL DEFAULT 'PAID',
  order_status VARCHAR(50) NOT NULL DEFAULT 'PROCESSING',
  delivery_address TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_orders_user (user_id),
  INDEX idx_orders_invoice (invoice_number)
);

CREATE TABLE IF NOT EXISTS order_items (
  id VARCHAR(50) PRIMARY KEY,
  order_id VARCHAR(50) NOT NULL,
  product_id VARCHAR(50) NOT NULL,
  grade_id VARCHAR(50),
  quantity INT NOT NULL DEFAULT 1,
  price_per_unit DECIMAL(14, 2) NOT NULL DEFAULT 0,
  subtotal DECIMAL(14, 2) NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_order_items_order (order_id),
  INDEX idx_order_items_product (product_id),
  FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
);
