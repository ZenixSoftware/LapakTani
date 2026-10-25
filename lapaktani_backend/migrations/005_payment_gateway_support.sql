-- ==============================================================================
-- Migration: 005_payment_gateway_support.sql
-- User Story: [US-14] Integrasi Layanan Payment Gateway & Pembayaran Otomatis
-- Target: MySQL (LapakTani Local REST API)
-- ==============================================================================

-- 1. Tambahkan kolom pendukung Payment Gateway ke tabel orders
ALTER TABLE orders 
  ADD COLUMN IF NOT EXISTS payment_channel VARCHAR(50) DEFAULT 'LAPAKPAY_SIMULATOR' AFTER payment_method,
  ADD COLUMN IF NOT EXISTS payment_reference VARCHAR(100) DEFAULT NULL AFTER payment_channel,
  ADD COLUMN IF NOT EXISTS payment_expired_at TIMESTAMP NULL DEFAULT NULL AFTER payment_reference,
  ADD COLUMN IF NOT EXISTS payment_signature VARCHAR(255) DEFAULT NULL AFTER payment_expired_at,
  ADD COLUMN IF NOT EXISTS payment_payload TEXT DEFAULT NULL AFTER payment_signature;

-- 2. Index untuk pencarian referensi pembayaran dan invoice secara instan
CREATE INDEX IF NOT EXISTS idx_orders_payment_ref ON orders (payment_reference);
CREATE INDEX IF NOT EXISTS idx_orders_payment_status ON orders (payment_status);
