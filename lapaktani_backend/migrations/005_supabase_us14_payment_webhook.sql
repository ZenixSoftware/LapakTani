-- ==============================================================================
-- Migration: 005_supabase_us14_payment_webhook.sql
-- User Story: [US-14] Integrasi Layanan Payment Gateway & Pembayaran Otomatis
-- Target: Supabase / PostgreSQL
-- ==============================================================================

-- 1. TAMBAH KOLOM METADATA PAYMENT GATEWAY PADA TABEL PEMESANAN
ALTER TABLE public.pemesanan
  ADD COLUMN IF NOT EXISTS payment_channel VARCHAR(50) DEFAULT 'LAPAKPAY_SIMULATOR',
  ADD COLUMN IF NOT EXISTS payment_reference VARCHAR(100),
  ADD COLUMN IF NOT EXISTS payment_expired_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS payment_signature VARCHAR(255),
  ADD COLUMN IF NOT EXISTS payment_payload JSONB;

CREATE INDEX IF NOT EXISTS idx_pemesanan_payment_ref ON public.pemesanan (payment_reference);
CREATE INDEX IF NOT EXISTS idx_pemesanan_payment_status ON public.pemesanan (payment_status);

-- 2. REFRESH VIEW AGAR MENYERTAKAN KOLOM BARU
CREATE OR REPLACE VIEW public.orders AS SELECT * FROM public.pemesanan;


-- 3. FUNGSI ATOMIK & IDEMPOTENT PENANGANAN WEBHOOK CALLBACK PAYMENT GATEWAY
-- Menangani verifikasi signature, perubahan status idempotent, dan rollback stok jika expired/cancel.
CREATE OR REPLACE FUNCTION public.fn_handle_payment_gateway_webhook(
    p_payload JSONB,
    p_server_key VARCHAR DEFAULT ''
)
RETURNS JSONB AS $$
DECLARE
    v_order_id VARCHAR;
    v_invoice_number VARCHAR;
    v_status_code VARCHAR;
    v_gross_amount NUMERIC;
    v_signature_key VARCHAR;
    v_transaction_status VARCHAR;
    v_expected_signature VARCHAR;
    v_order RECORD;
    v_item RECORD;
BEGIN
    -- Ekstrak data utama dari payload webhook
    v_order_id := p_payload->>'order_id';
    v_status_code := COALESCE(p_payload->>'status_code', '200');
    v_gross_amount := (p_payload->>'gross_amount')::NUMERIC;
    v_signature_key := p_payload->>'signature_key';
    v_transaction_status := lower(COALESCE(p_payload->>'transaction_status', 'settlement'));

    IF v_order_id IS NULL THEN
        RAISE EXCEPTION 'Field "order_id" wajib disertakan dalam payload callback.';
    END IF;

    -- Cari data pesanan di tabel pemesanan
    SELECT * INTO v_order
    FROM public.pemesanan
    WHERE id = v_order_id OR invoice_number = v_order_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Pesanan dengan ID/Invoice "%" tidak ditemukan.', v_order_id;
    END IF;

    -- Validasi Signature Key jika disertakan (Format SHA512 standar Midtrans)
    -- Formula: SHA512(order_id + status_code + gross_amount + server_key)
    IF v_signature_key IS NOT NULL AND v_signature_key <> '' THEN
        v_expected_signature := encode(digest(v_order.id || v_status_code || v_order.total_amount::text || p_server_key, 'sha512'), 'hex');
        -- Catatan: jika signature tidak cocok dan bukan mode simulasi, tolak webhook
        IF lower(v_signature_key) <> lower(v_expected_signature) AND v_signature_key <> 'SIMULATED_TEST_SIGNATURE' THEN
            RAISE EXCEPTION 'Signature key webhook tidak valid / tidak terverifikasi.';
        END IF;
    END IF;

    -- IDEMPOTENCY CHECK:
    -- Jika pesanan sudah berstatus 'PAID' dan menerima callback sukses lagi, abaikan tanpa error ganda
    IF v_order.payment_status = 'PAID' AND (v_transaction_status IN ('settlement', 'capture', 'success')) THEN
        RETURN jsonb_build_object(
            'success', true,
            'idempotent', true,
            'message', 'Pesanan sudah berstatus PAID sebelumnya. Callback diabaikan secara aman.',
            'order_id', v_order.id,
            'invoice_number', v_order.invoice_number,
            'payment_status', v_order.payment_status
        );
    END IF;

    -- PENANGANAN STATUS BERDASARKAN RESPON GATEWAY
    IF v_transaction_status IN ('settlement', 'capture', 'success') THEN
        -- Status BERHASIL/LUNAS
        UPDATE public.pemesanan
        SET payment_status = 'PAID',
            order_status = 'PROCESSING',
            payment_signature = v_signature_key,
            payment_payload = p_payload,
            updated_at = NOW()
        WHERE id = v_order.id;

    ELSIF v_transaction_status IN ('pending', 'waiting_payment') THEN
        -- Status MENUNGGU PEMBAYARAN
        UPDATE public.pemesanan
        SET payment_status = 'PENDING',
            order_status = 'WAITING_PAYMENT',
            payment_payload = p_payload,
            updated_at = NOW()
        WHERE id = v_order.id;

    ELSIF v_transaction_status IN ('expire', 'expired', 'cancel', 'cancelled', 'deny', 'failed') THEN
        -- Status KEDALUWARSA ATAU GAGAL
        -- Kembalikan stok komoditas ke etalase secara otomatis jika belum pernah dibatalkan
        IF v_order.payment_status <> 'EXPIRED' AND v_order.payment_status <> 'CANCELLED' THEN
            FOR v_item IN SELECT product_id, quantity FROM public.rincian_item WHERE order_id = v_order.id LOOP
                UPDATE public.products
                SET stock_kg = stock_kg + v_item.quantity
                WHERE id = v_item.product_id;
            END LOOP;
        END IF;

        UPDATE public.pemesanan
        SET payment_status = CASE WHEN v_transaction_status LIKE '%expire%' THEN 'EXPIRED' ELSE 'FAILED' END,
            order_status = 'CANCELLED',
            payment_payload = p_payload,
            updated_at = NOW()
        WHERE id = v_order.id;
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'message', 'Status pesanan berhasil diperbarui via Webhook.',
        'order_id', v_order.id,
        'invoice_number', v_order.invoice_number,
        'previous_status', v_order.payment_status,
        'current_status', (SELECT payment_status FROM public.pemesanan WHERE id = v_order.id),
        'transaction_status', v_transaction_status,
        'timestamp', NOW()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
