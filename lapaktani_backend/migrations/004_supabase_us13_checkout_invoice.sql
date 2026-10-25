-- ==============================================================================
-- Migration: 004_supabase_us13_checkout_invoice.sql
-- User Story: [US-13] Checkout Pemesanan & Pembuatan Invoice (Supabase / PostgreSQL)
-- Description: Skema tabel pemesanan & rincian_item, generator invoice unik,
--              pengurangan stok atomic (RPC Function), serta simulasi pembayaran dompet.
-- ==============================================================================

-- 1. TABEL PEMESANAN (ORDERS)
CREATE TABLE IF NOT EXISTS public.pemesanan (
    id VARCHAR(50) PRIMARY KEY DEFAULT ('ORD-' || to_char(NOW(), 'YYYYMMDDHH24MISS') || '-' || substr(md5(random()::text), 1, 6)),
    user_id VARCHAR(50) NOT NULL,
    invoice_number VARCHAR(100) NOT NULL UNIQUE,
    total_amount NUMERIC(14, 2) NOT NULL DEFAULT 0,
    shipping_fee NUMERIC(14, 2) NOT NULL DEFAULT 0,
    payment_method VARCHAR(50) NOT NULL DEFAULT 'LAPAKPAY_SIMULATOR',
    payment_status VARCHAR(50) NOT NULL DEFAULT 'PAID', -- Status: MENUNGGU_PEMBAYARAN, PAID, CANCELLED
    order_status VARCHAR(50) NOT NULL DEFAULT 'PROCESSING', -- Status: PROCESSING, SHIPPED, DELIVERED, CANCELLED
    delivery_address TEXT NOT NULL,
    courier_service VARCHAR(100) DEFAULT 'Kurir Pendingin Mitra',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexing untuk query performa tinggi
CREATE INDEX IF NOT EXISTS idx_pemesanan_user_id ON public.pemesanan (user_id);
CREATE INDEX IF NOT EXISTS idx_pemesanan_invoice ON public.pemesanan (invoice_number);

-- 2. TABEL RINCIAN ITEM (ORDER ITEMS)
CREATE TABLE IF NOT EXISTS public.rincian_item (
    id VARCHAR(50) PRIMARY KEY DEFAULT ('OI-' || substr(md5(random()::text), 1, 12)),
    order_id VARCHAR(50) NOT NULL,
    product_id VARCHAR(50) NOT NULL,
    grade_id VARCHAR(50),
    quantity INT NOT NULL CHECK (quantity > 0),
    price_per_unit NUMERIC(14, 2) NOT NULL DEFAULT 0,
    subtotal NUMERIC(14, 2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT fk_rincian_item_order FOREIGN KEY (order_id) REFERENCES public.pemesanan(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_rincian_item_order_id ON public.rincian_item (order_id);
CREATE INDEX IF NOT EXISTS idx_rincian_item_product_id ON public.rincian_item (product_id);

-- Alias view agar kompatibel dengan penamaan 'orders' dan 'order_items'
CREATE OR REPLACE VIEW public.orders AS SELECT * FROM public.pemesanan;
CREATE OR REPLACE VIEW public.order_items AS SELECT * FROM public.rincian_item;


-- 3. FUNGSI GENERATOR NOMOR INVOICE RESMI (INV/YYYYMMDD/LPK/XXXXX)
CREATE OR REPLACE FUNCTION public.fn_generate_invoice_number()
RETURNS VARCHAR AS $$
DECLARE
    v_date_prefix VARCHAR;
    v_random_code VARCHAR;
BEGIN
    v_date_prefix := to_char(NOW(), 'YYYYMMDD');
    v_random_code := upper(substr(md5(random()::text), 1, 5));
    RETURN 'INV/' || v_date_prefix || '/LPK/' || v_random_code;
END;
$$ LANGUAGE plpgsql;


-- 4. ATOMIC DATABASE RPC FUNCTION (CHECKOUT, PENGURANGAN STOK, & SIMULATOR DOMPET)
-- Mencegah race condition & overselling menggunakan SELECT ... FOR UPDATE
CREATE OR REPLACE FUNCTION public.fn_process_checkout(
    p_user_id VARCHAR,
    p_items JSONB,
    p_delivery_address TEXT,
    p_shipping_fee NUMERIC DEFAULT 0,
    p_payment_method VARCHAR DEFAULT 'LAPAKPAY_SIMULATOR'
)
RETURNS JSONB AS $$
DECLARE
    v_order_id VARCHAR;
    v_invoice_number VARCHAR;
    v_total_amount NUMERIC := 0;
    v_item RECORD;
    v_product RECORD;
    v_item_subtotal NUMERIC;
    v_wallet_balance NUMERIC := 2500000; -- Default saldo simulator
    v_validated_items JSONB := '[]'::jsonb;
BEGIN
    -- Validasi keranjang kosong
    IF p_items IS NULL OR jsonb_array_length(p_items) = 0 THEN
        RAISE EXCEPTION 'Keranjang belanja kosong atau tidak valid.';
    END IF;

    -- Validasi alamat
    IF p_delivery_address IS NULL OR trim(p_delivery_address) = '' THEN
        RAISE EXCEPTION 'Alamat pengiriman wajib diisi.';
    END IF;

    -- Generate ID & Invoice
    v_order_id := 'ORD-' || to_char(NOW(), 'YYYYMMDDHH24MISS') || '-' || upper(substr(md5(random()::text), 1, 6));
    v_invoice_number := public.fn_generate_invoice_number();

    -- Loop kalkulasi, lock stok, & verifikasi ketersediaan (Atomic Lock)
    FOR v_item IN SELECT * FROM jsonb_to_recordset(p_items) AS x(
        product_id VARCHAR,
        quantity INT,
        price_per_unit NUMERIC,
        grade_id VARCHAR
    ) LOOP
        -- Lock row produk secara atomik agar tidak terjadi race condition
        SELECT id, title, stock_kg, COALESCE(price_per_kg, price, 0) AS price
        INTO v_product
        FROM public.products
        WHERE id = v_item.product_id
        FOR UPDATE;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Produk dengan ID % tidak ditemukan.', v_item.product_id;
        END IF;

        -- Validasi stok mencukupi
        IF v_product.stock_kg < v_item.quantity THEN
            RAISE EXCEPTION 'Stok untuk produk "%" tidak mencukupi (Tersedia: % kg, diminta: % kg).', 
                v_product.title, v_product.stock_kg, v_item.quantity;
        END IF;

        -- Hitung subtotal
        v_item_subtotal := COALESCE(v_item.price_per_unit, v_product.price) * v_item.quantity;
        v_total_amount := v_total_amount + v_item_subtotal;

        -- Kurangi stok komoditas pertanian secara otomatis
        UPDATE public.products
        SET stock_kg = stock_kg - v_item.quantity
        WHERE id = v_item.product_id;

        -- Kumpulkan item yang terverifikasi
        v_validated_items := v_validated_items || jsonb_build_object(
            'product_id', v_item.product_id,
            'title', v_product.title,
            'grade_id', v_item.grade_id,
            'quantity', v_item.quantity,
            'price_per_unit', COALESCE(v_item.price_per_unit, v_product.price),
            'subtotal', v_item_subtotal
        );
    END LOOP;

    -- Tambah ongkos kirim ke total tagihan
    v_total_amount := v_total_amount + COALESCE(p_shipping_fee, 0);

    -- Pengecekan saldo dompet / simulator LapakPay
    SELECT COALESCE(wallet_balance, 2500000) INTO v_wallet_balance
    FROM public.user_profiles
    WHERE user_id = p_user_id;

    IF v_wallet_balance IS NOT NULL AND v_wallet_balance < v_total_amount THEN
        RAISE EXCEPTION 'Saldo dompet tidak mencukupi. Saldo: Rp %, Total Tagihan: Rp %', v_wallet_balance, v_total_amount;
    END IF;

    -- Potong saldo dompet jika tabel profil tersedia
    UPDATE public.user_profiles
    SET wallet_balance = wallet_balance - v_total_amount
    WHERE user_id = p_user_id;

    -- Simpan data transaksi ke tabel pemesanan
    INSERT INTO public.pemesanan (
        id, user_id, invoice_number, total_amount, shipping_fee,
        payment_method, payment_status, order_status, delivery_address, created_at
    ) VALUES (
        v_order_id, p_user_id, v_invoice_number, v_total_amount, COALESCE(p_shipping_fee, 0),
        p_payment_method, 'PAID', 'PROCESSING', p_delivery_address, NOW()
    );

    -- Simpan rincian item ke tabel rincian_item
    FOR v_item IN SELECT * FROM jsonb_to_recordset(v_validated_items) AS y(
        product_id VARCHAR,
        grade_id VARCHAR,
        quantity INT,
        price_per_unit NUMERIC,
        subtotal NUMERIC
    ) LOOP
        INSERT INTO public.rincian_item (
            id, order_id, product_id, grade_id, quantity, price_per_unit, subtotal, created_at
        ) VALUES (
            'OI-' || substr(md5(random()::text), 1, 12),
            v_order_id,
            v_item.product_id,
            v_item.grade_id,
            v_item.quantity,
            v_item.price_per_unit,
            v_item.subtotal,
            NOW()
        );
    END LOOP;

    -- Hapus item yang sudah di-checkout dari cart_items (jika ada)
    DELETE FROM public.cart_items
    WHERE user_id = p_user_id
      AND product_id IN (
          SELECT (x->>'product_id')::VARCHAR FROM jsonb_array_elements(p_items) AS x
      );

    -- Return detail pesanan dan nomor invoice resmi
    RETURN jsonb_build_object(
        'success', true,
        'message', 'Pesanan dan invoice resmi berhasil diterbitkan.',
        'data', jsonb_build_object(
            'order_id', v_order_id,
            'invoice_number', v_invoice_number,
            'total_amount', v_total_amount,
            'shipping_fee', COALESCE(p_shipping_fee, 0),
            'payment_status', 'PAID',
            'order_status', 'PROCESSING',
            'payment_method', p_payment_method,
            'delivery_address', p_delivery_address,
            'items', v_validated_items,
            'created_at', NOW()
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
