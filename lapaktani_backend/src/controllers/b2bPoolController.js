const pool = require('../config/db');
const { v4: uuidv4 } = require('uuid');

let tablesInitialized = false;

/**
 * Ensure database tables for B2B Open-Quota Harvest Pools exist and are seeded
 */
async function ensureTables() {
  if (tablesInitialized) return;
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS b2b_harvest_pools (
        id VARCHAR(50) PRIMARY KEY,
        farmer_group_id VARCHAR(50) NOT NULL DEFAULT 'fg-default',
        mitra_name VARCHAR(100) NOT NULL DEFAULT 'Mitra Tani Makmur',
        commodity_id VARCHAR(50) NOT NULL,
        commodity_name VARCHAR(100) NOT NULL,
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
      )
    `);

    await pool.query(`
      CREATE TABLE IF NOT EXISTS b2b_quota_allocations (
        id VARCHAR(50) PRIMARY KEY,
        pool_id VARCHAR(50) NOT NULL,
        buyer_id VARCHAR(50) NOT NULL,
        buyer_name VARCHAR(100) NOT NULL,
        taken_kg DECIMAL(12,2) NOT NULL DEFAULT 0.00,
        price_per_kg DECIMAL(12,2) NOT NULL DEFAULT 0.00,
        total_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00,
        status VARCHAR(30) NOT NULL DEFAULT 'confirmed',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_b2b_alloc_pool (pool_id)
      )
    `);

    // Seed default pools if empty
    const [rows] = await pool.query('SELECT COUNT(*) as count FROM b2b_harvest_pools');
    if (rows[0].count === 0) {
      await pool.query(`
        INSERT INTO b2b_harvest_pools 
          (id, farmer_group_id, mitra_name, commodity_id, commodity_name, target_harvest_date, total_quota_kg, allocated_quota_kg, remaining_quota_kg, price_per_kg, status, notes)
        VALUES 
          ('pool-01', 'fg-01', 'Mitra Tani Makmur', 'c-cabai-01', 'Cabai Merah Keriting Grade A', '15 Nov 2026', 350.00, 300.00, 50.00, 28000.00, 'open', 'Hasil panen lahan konsolidasi Lembang'),
          ('pool-02', 'fg-02', 'Mitra Tani Pasundan', 'c-tomat-01', 'Tomat Beef Organik Segar', '20 Nov 2026', 500.00, 200.00, 300.00, 12500.00, 'open', 'Dipetik subuh dari dataran tinggi Pangalengan'),
          ('pool-03', 'fg-03', 'Mitra Tani Berkah Mandiri', 'c-kentang-01', 'Kentang Granola Super', '28 Nov 2026', 1000.00, 650.00, 350.00, 16000.00, 'open', 'Sortir grade restoran & katering partai besar')
      `);
      console.log('[B2B_POOL] Seeded default forward harvest pools');
    }

    tablesInitialized = true;
  } catch (err) {
    console.error('[B2B_POOL] Table initialization error:', err.message);
  }
}

/**
 * GET /api/b2b-contracts/pools
 * Returns active open B2B forward harvest pools
 */
const getHarvestPools = async (req, res) => {
  await ensureTables();
  try {
    const [pools] = await pool.query(`
      SELECT 
        id,
        farmer_group_id,
        mitra_name,
        commodity_id,
        commodity_name,
        target_harvest_date,
        CAST(total_quota_kg AS DOUBLE) AS total_quota_kg,
        CAST(allocated_quota_kg AS DOUBLE) AS allocated_quota_kg,
        CAST(remaining_quota_kg AS DOUBLE) AS remaining_quota_kg,
        CAST(price_per_kg AS DOUBLE) AS price_per_kg,
        status,
        notes,
        created_at
      FROM b2b_harvest_pools
      ORDER BY 
        CASE WHEN status = 'open' THEN 1 ELSE 2 END,
        created_at DESC
    `);

    return res.status(200).json({
      success: true,
      message: 'Daftar bursa kuota panen B2B berhasil dimuat.',
      data: pools
    });
  } catch (error) {
    console.error('[B2B_POOL] Error fetching pools:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal memuat bursa kuota panen B2B.'
    });
  }
};

/**
 * POST /api/b2b-contracts/pools
 * Mitra Tani creates a new forward harvest pool
 */
const createHarvestPool = async (req, res) => {
  await ensureTables();
  try {
    const {
      commodity_id,
      commodity_name,
      target_harvest_date,
      total_quota_kg,
      price_per_kg,
      notes,
      mitra_name
    } = req.body;

    if (!commodity_name || !total_quota_kg || !price_per_kg || !target_harvest_date) {
      return res.status(400).json({
        success: false,
        message: 'Data tidak lengkap. Komoditas, kuota total, harga per kg, dan tanggal panen wajib diisi.'
      });
    }

    const quotaNum = parseFloat(total_quota_kg);
    const priceNum = parseFloat(price_per_kg);

    if (isNaN(quotaNum) || quotaNum <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Total kuota panen harus bernilai lebih dari 0 kg.'
      });
    }

    if (isNaN(priceNum) || priceNum <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Harga per kg harus bernilai lebih dari Rp 0.'
      });
    }

    const poolId = `pool-${uuidv4().substring(0, 8)}`;
    const effectiveMitraName = mitra_name || 'Mitra Tani Makmur';
    const effectiveCommodityId = commodity_id || `c-${uuidv4().substring(0, 6)}`;

    await pool.query(`
      INSERT INTO b2b_harvest_pools
        (id, farmer_group_id, mitra_name, commodity_id, commodity_name, target_harvest_date, total_quota_kg, allocated_quota_kg, remaining_quota_kg, price_per_kg, status, notes)
      VALUES (?, ?, ?, ?, ?, ?, ?, 0.00, ?, ?, 'open', ?)
    `, [
      poolId,
      req.user ? req.user.id : 'fg-default',
      effectiveMitraName,
      effectiveCommodityId,
      commodity_name.trim(),
      target_harvest_date.trim(),
      quotaNum,
      quotaNum,
      priceNum,
      notes ? notes.trim() : null
    ]);

    const newPool = {
      id: poolId,
      mitra_name: effectiveMitraName,
      commodity_id: effectiveCommodityId,
      commodity_name: commodity_name.trim(),
      target_harvest_date: target_harvest_date.trim(),
      total_quota_kg: quotaNum,
      allocated_quota_kg: 0.0,
      remaining_quota_kg: quotaNum,
      price_per_kg: priceNum,
      status: 'open',
      notes: notes || null
    };

    return res.status(201).json({
      success: true,
      message: 'Penawaran partai panen B2B berhasil dibuka ke bursa pasar.',
      data: newPool
    });
  } catch (error) {
    console.error('[B2B_POOL] Error creating pool:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan internal saat mendaftarkan bursa kuota panen.'
    });
  }
};

/**
 * POST /api/b2b-contracts/pools/:id/spillover-to-retail
 * Zero-Waste Spillover: converts unsold B2B quota into retail inventory in products table
 */
const spilloverToRetail = async (req, res) => {
  await ensureTables();
  const poolId = req.params.id;

  try {
    const [pools] = await pool.query(
      'SELECT * FROM b2b_harvest_pools WHERE id = ? LIMIT 1',
      [poolId]
    );

    if (pools.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Penawaran partai panen tidak ditemukan.'
      });
    }

    const poolData = pools[0];
    const remainingKg = parseFloat(poolData.remaining_quota_kg || 0);

    if (remainingKg <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Tidak ada sisa kuota untuk dialihkan ke retail (kuota telah habis terserap).'
      });
    }

    if (poolData.status === 'spilled_over') {
      return res.status(400).json({
        success: false,
        message: 'Sisa kuota pada penawaran ini sudah dialihkan ke etalase retail sebelumnya.'
      });
    }

    // Find or create retail product for this commodity
    const [existingProducts] = await pool.query(
      'SELECT id, title, stock, stock_kg FROM products WHERE commodity_id = ? LIMIT 1',
      [poolData.commodity_id]
    );

    let productId;
    if (existingProducts.length > 0) {
      productId = existingProducts[0].id;
      await pool.query(
        'UPDATE products SET stock = stock + ?, stock_kg = stock_kg + ?, updated_at = NOW() WHERE id = ?',
        [remainingKg, remainingKg, productId]
      );
    } else {
      productId = `p-spill-${uuidv4().substring(0, 8)}`;
      const retailPrice = Math.round(parseFloat(poolData.price_per_kg) * 1.15); // standard retail margin
      await pool.query(`
        INSERT INTO products 
          (id, farmer_id, commodity_id, title, description, price_per_kg, stock_kg, price, stock, image_url, created_at)
        VALUES 
          (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())
      `, [
        productId,
        req.user ? req.user.id : 'f-maman',
        poolData.commodity_id,
        `${poolData.commodity_name} (Panen Segar Mitra Tani)`,
        `Komoditas segar hasil alihan sisa kuota bursa partai ${poolData.mitra_name}. Kualitas grade A terjamin.`,
        retailPrice,
        remainingKg,
        retailPrice,
        remainingKg,
        'https://images.unsplash.com/photo-1597362925123-77861d3fbac7?w=500&auto=format&fit=crop'
      ]);
    }

    // Mark pool as spilled over
    await pool.query(
      "UPDATE b2b_harvest_pools SET status = 'spilled_over', remaining_quota_kg = 0.00 WHERE id = ?",
      [poolId]
    );

    return res.status(200).json({
      success: true,
      message: `Zero-Waste Berhasil: ${remainingKg} kg komoditas ${poolData.commodity_name} telah dialihkan ke etalase retail toko Mitra Tani!`,
      data: {
        pool_id: poolId,
        spilled_kg: remainingKg,
        product_id: productId,
        new_status: 'spilled_over'
      }
    });
  } catch (error) {
    console.error('[B2B_POOL] Spillover error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal memproses pengalihan sisa kuota ke etalase retail.'
    });
  }
};

/**
 * POST /api/b2b-contracts/take-quota
 * Buyer takes wholesale quota from open harvest pool
 */
const takeQuota = async (req, res) => {
  await ensureTables();
  const poolId = req.params.id || req.body.pool_id;
  const { quantity_kg, buyer_name } = req.body;

  try {
    const qtyNum = parseFloat(quantity_kg);
    if (!poolId || isNaN(qtyNum) || qtyNum <= 0) {
      return res.status(400).json({
        success: false,
        message: 'ID Pool dan jumlah kuota (kg) yang valid wajib disertakan.'
      });
    }

    const [pools] = await pool.query(
      'SELECT * FROM b2b_harvest_pools WHERE id = ? LIMIT 1',
      [poolId]
    );

    if (pools.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Penawaran partai panen B2B tidak ditemukan.'
      });
    }

    const poolData = pools[0];
    const currentRemaining = parseFloat(poolData.remaining_quota_kg || 0);

    if (poolData.status !== 'open') {
      return res.status(400).json({
        success: false,
        message: 'Penawaran bursa partai ini sudah tidak menerima pemesanan kuota.'
      });
    }

    if (qtyNum > currentRemaining) {
      return res.status(400).json({
        success: false,
        message: `Jumlah kuota melebihi sisa yang tersedia (${currentRemaining} kg tersisa).`
      });
    }

    const newRemaining = currentRemaining - qtyNum;
    const newAllocated = parseFloat(poolData.allocated_quota_kg || 0) + qtyNum;
    const newStatus = newRemaining <= 0.01 ? 'closed' : 'open';

    await pool.query(`
      UPDATE b2b_harvest_pools 
      SET remaining_quota_kg = ?, allocated_quota_kg = ?, status = ?
      WHERE id = ?
    `, [newRemaining, newAllocated, newStatus, poolId]);

    const allocationId = `alloc-${uuidv4().substring(0, 8)}`;
    const effectiveBuyerName = buyer_name || (req.user ? (req.user.fullName || req.user.email) : 'Pembeli Grosir B2B');
    const effectiveBuyerId = req.user ? req.user.id : 'guest-buyer';
    const totalAmount = qtyNum * parseFloat(poolData.price_per_kg || 0);

    await pool.query(`
      INSERT INTO b2b_quota_allocations 
        (id, pool_id, buyer_id, buyer_name, taken_kg, price_per_kg, total_amount, status)
      VALUES (?, ?, ?, ?, ?, ?, ?, 'confirmed')
    `, [
      allocationId,
      poolId,
      effectiveBuyerId,
      effectiveBuyerName,
      qtyNum,
      parseFloat(poolData.price_per_kg || 0),
      totalAmount
    ]);

    return res.status(200).json({
      success: true,
      message: `Berhasil mengambil kuota borongan ${qtyNum} kg dari ${poolData.mitra_name}. Kontrak telah dicatat.`,
      data: {
        allocation_id: allocationId,
        pool_id: poolId,
        taken_kg: qtyNum,
        price_per_kg: parseFloat(poolData.price_per_kg),
        total_amount: totalAmount,
        remaining_quota_kg: newRemaining,
        allocated_quota_kg: newAllocated,
        status: newStatus
      }
    });
  } catch (error) {
    console.error('[B2B_POOL] Take quota error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal mengambil kuota partai panen.'
    });
  }
};

module.exports = {
  getHarvestPools,
  createHarvestPool,
  spilloverToRetail,
  takeQuota
};
