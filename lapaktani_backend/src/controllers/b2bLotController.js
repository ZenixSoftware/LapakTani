const { v4: uuidv4 } = require('uuid');
const pool = require('../config/db');
const redisClient = require('../config/redis');
const { notifyTransactionEvent } = require('../utils/notificationService');
const { calculateHybridRefundFee, recordPlatformFeeLedger } = require('../utils/refundHelper');

const UNMASKED_BID_STATUSES = new Set([
  'PAID_ESCROW',
  'READY_FOR_DELIVERY',
  'READY_FOR_PICKUP',
  'COMPLETED',
]);

async function resolveCallerAdminTier(user) {
  if (!user) return null;
  if (user.admin_tier) return String(user.admin_tier).toUpperCase();

  try {
    const [uRows] = await pool.query('SELECT admin_tier FROM users WHERE id = ? LIMIT 1', [user.id]);
    if (uRows[0]?.admin_tier) return String(uRows[0].admin_tier).toUpperCase();

    const [sRows] = await pool.query(
      'SELECT admin_tier FROM store_applications WHERE user_id = ? LIMIT 1',
      [user.id]
    );
    if (sRows[0]?.admin_tier) return String(sRows[0].admin_tier).toUpperCase();
  } catch (_) {}

  const role = String(user.role || '').toLowerCase();
  return role === 'admin' || Number(user.role_id) === 3 ? 'B2B_OFFTAKER' : null;
}

function serializeBidRow(row) {
  const isUnmasked = UNMASKED_BID_STATUSES.has(String(row.status || '').toUpperCase());
  let traceability = null;
  if (isUnmasked && row.source_farmer_snapshot_json) {
    try {
      traceability = JSON.parse(row.source_farmer_snapshot_json);
    } catch (_) {
      traceability = null;
    }
  } else if (isUnmasked) {
    traceability = {
      farmer_id: row.product_source_farmer_id || null,
      farmer_name: row.product_source_farmer_name || 'Pak Supardi (Poktan Harapan Sumenep)',
      farmer_phone: row.product_source_farmer_phone || '081234567890',
      village_name: row.village_name || 'Sumenep',
    };
  }

  return {
    ...row,
    bid_qty_kg: Number(row.bid_qty_kg || 0),
    bid_price_per_kg: Number(row.bid_price_per_kg || 0),
    total_bid_amount: Number(row.total_bid_amount || 0),
    restocked_to_retail: Boolean(Number(row.restocked_to_retail || 0)),
    source_farmer_traceability: traceability,
    source_farmer_name: traceability ? traceability.farmer_name : null,
    source_farmer_village: traceability ? traceability.village_name : null,
    is_farmer_contact_unmasked: Boolean(isUnmasked),
  };
}

/**
 * GET /api/b2b/lots
 * List products configured as B2B_BID_LOT or BOTH with MENTAH vs SIAP_PAKAI badges
 */
const getB2BLots = async (req, res) => {
  try {
    const { processing_state } = req.query;
    const conditions = ["p.catalog_channel IN ('B2B_BID_LOT', 'BOTH')"];
    const params = [];

    if (processing_state && ['MENTAH', 'SIAP_PAKAI'].includes(String(processing_state).toUpperCase())) {
      conditions.push('p.processing_state = ?');
      params.push(String(processing_state).toUpperCase());
    }

    const [rows] = await pool.query(
      `SELECT p.id, p.farmer_id AS seller_admin_id, p.title, p.description, p.price_per_kg,
              p.wholesale_price, p.min_wholesale_qty, p.stock_kg, p.image_url,
              p.processing_state, p.catalog_channel, p.fulfillment_options,
              COALESCE(sa.nama_toko, u.full_name, 'Toko Mitra B2B') AS seller_store_name,
              COALESCE(v.name, 'Sumenep') AS village_name
       FROM products p
       LEFT JOIN users u ON p.farmer_id = u.id
       LEFT JOIN store_applications sa ON p.farmer_id = sa.user_id
       LEFT JOIN villages v ON p.store_village_id = v.id
       WHERE ${conditions.join(' AND ')}
       ORDER BY p.created_at DESC, p.id DESC
       LIMIT 60`,
      params
    );

    return res.status(200).json({
      success: true,
      count: rows.length,
      data: rows.map((r) => ({
        ...r,
        price_per_kg: Number(r.price_per_kg || 0),
        wholesale_price: Number(r.wholesale_price || r.price_per_kg || 0),
        min_wholesale_qty: Number(r.min_wholesale_qty || 30),
        stock_kg: Number(r.stock_kg || 0),
        source_farmer_name: null,
        source_farmer_traceability: null,
        is_farmer_contact_unmasked: false,
      })),
    });
  } catch (error) {
    console.error('[B2B_LOTS] Error fetching B2B lots:', error.message);
    return res.status(500).json({ success: false, message: 'Gagal memuat lot Bursa Open-Bid B2B.' });
  }
};

/**
 * GET /api/b2b/bids & GET /api/b2b-contracts/lot-bids
 * Lists B2B lot bids scoped to the caller (seller, bidder, or superadmin)
 */
const getB2BLotBids = async (req, res) => {
  try {
    const userId = req.user.id;
    const callerRole = String(req.user?.role || '').toLowerCase();
    const isSuper = callerRole === 'superadmin' || Number(req.user?.role_id) === 6;

    const whereClause = isSuper ? '1=1' : '(b.seller_admin_id = ? OR b.bidder_user_id = ?)';
    const params = isSuper ? [] : [userId, userId];

    const [rows] = await pool.query(
      `SELECT b.*,
              p.image_url AS product_image_url,
              p.source_farmer_id AS product_source_farmer_id,
              p.source_farmer_name AS product_source_farmer_name,
              p.source_farmer_phone AS product_source_farmer_phone,
              COALESCE(sa.nama_toko, su.full_name, 'Toko B2B') AS seller_store_name,
              COALESCE(v.name, 'Sumenep') AS village_name
       FROM b2b_lot_bids b
       LEFT JOIN products p ON b.product_id = p.id
       LEFT JOIN users su ON b.seller_admin_id = su.id
       LEFT JOIN store_applications sa ON b.seller_admin_id = sa.user_id
       LEFT JOIN villages v ON p.store_village_id = v.id
       WHERE ${whereClause}
       ORDER BY b.updated_at DESC, b.created_at DESC
       LIMIT 80`,
      params
    );

    return res.status(200).json({
      success: true,
      count: rows.length,
      data: rows.map(serializeBidRow),
    });
  } catch (error) {
    console.error('[B2B_BIDS] Error loading lot bids:', error.message);
    return res.status(500).json({ success: false, message: 'Gagal memuat daftar penawaran lot B2B.' });
  }
};

/**
 * POST /api/b2b/lots/:productId/bid
 * Allows pembeli (HOTEL_B2B) or admin RETAIL_MERCHANT to bid/order from a B2B_OFFTAKER lot.
 * Explicitly blocks B2B_OFFTAKER admins from buying from another store.
 */
const placeB2BLotBid = async (req, res) => {
  const bidderId = req.user?.id;
  if (!bidderId) {
    return res.status(401).json({ success: false, message: 'Token otentikasi diperlukan.' });
  }

  const callerRole = String(req.user?.role || '').toLowerCase();
  const callerRoleId = Number(req.user?.role_id || 4);
  const callerTier = await resolveCallerAdminTier(req.user);

  if ((callerRole === 'admin' || callerRoleId === 3) && callerTier === 'B2B_OFFTAKER') {
    return res.status(403).json({
      success: false,
      code: 'B2B_OFFTAKER_CANNOT_BUY',
      message: 'Admin B2B (Offtaker) tidak memiliki fitur membeli atau menawar produk dari toko lain.',
    });
  }

  if (!['pembeli', 'admin'].includes(callerRole) && ![3, 4].includes(callerRoleId)) {
    return res.status(403).json({
      success: false,
      message: 'Hanya Pembeli Bisnis/Hotel atau Admin Retail yang dapat menawar lot B2B.',
    });
  }

  const { productId } = req.params;
  const {
    bid_qty_kg,
    bid_price_per_kg,
    fulfillment_method = 'DIANTAR_PENJUAL',
    delivery_address = 'Kabupaten Sumenep',
    pay_immediately = false,
  } = req.body || {};

  const qty = Number(bid_qty_kg || 0);
  if (isNaN(qty) || qty <= 0) {
    return res.status(400).json({ success: false, message: 'Kuantitas tawaran (kg) harus lebih dari 0.' });
  }

  const method = ['DIANTAR_PENJUAL', 'DIAMBIL_SENDIRI'].includes(String(fulfillment_method).toUpperCase())
    ? String(fulfillment_method).toUpperCase()
    : 'DIANTAR_PENJUAL';
  const bidderType = callerRole === 'admin' || callerRoleId === 3 ? 'RETAIL_MERCHANT' : 'HOTEL_B2B';

  let connection;
  try {
    connection = await pool.getConnection();
    await connection.beginTransaction();

    const [pRows] = await connection.query('SELECT * FROM products WHERE id = ? LIMIT 1 FOR UPDATE', [productId]);
    if (pRows.length === 0) {
      await connection.rollback();
      return res.status(404).json({ success: false, message: 'Lot B2B tidak ditemukan.' });
    }

    const product = pRows[0];
    if (String(product.farmer_id) === String(bidderId)) {
      await connection.rollback();
      return res.status(400).json({ success: false, message: 'Tidak dapat menawar lot produk milik sendiri.' });
    }

    const availableStock = Number(product.stock_kg || 0);
    if (availableStock < qty) {
      await connection.rollback();
      return res.status(400).json({
        success: false,
        message: `Stok lot tidak mencukupi (tersedia ${availableStock} kg, diminta ${qty} kg).`,
      });
    }

    const unitBidPrice =
      bid_price_per_kg !== undefined && Number(bid_price_per_kg) > 0
        ? Number(bid_price_per_kg)
        : Number(product.wholesale_price || product.price_per_kg || product.price || 0);
    const totalBidAmount = Math.round(qty * unitBidPrice);
    const bidId = `bid-${uuidv4().slice(0, 10)}`;
    const initialStatus = pay_immediately ? 'PAID_ESCROW' : 'PENDING_BID';

    const [userRows] = await connection.query('SELECT full_name FROM users WHERE id = ? LIMIT 1', [bidderId]);
    const bidderName = userRows[0]?.full_name || req.user.full_name || 'Pembeli Mitra';

    await connection.query('UPDATE products SET stock_kg = stock_kg - ? WHERE id = ?', [qty, product.id]);

    const snapshot = initialStatus === 'PAID_ESCROW'
      ? JSON.stringify({
          farmer_id: product.source_farmer_id || product.farmer_id,
          farmer_name: product.source_farmer_name || 'Pak Supardi (Poktan Harapan Sumenep)',
          farmer_phone: product.source_farmer_phone || '081234567890',
        })
      : null;

    await connection.query(
      `INSERT INTO b2b_lot_bids
       (id, product_id, product_title, processing_state, seller_admin_id, bidder_user_id, bidder_name, bidder_type, bid_qty_kg, bid_price_per_kg, total_bid_amount, fulfillment_method, delivery_address, status, source_farmer_snapshot_json)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        bidId,
        product.id,
        product.title,
        product.processing_state || 'SIAP_PAKAI',
        product.farmer_id,
        bidderId,
        bidderName,
        bidderType,
        qty,
        unitBidPrice,
        totalBidAmount,
        method,
        String(delivery_address || 'Kabupaten Sumenep').trim(),
        initialStatus,
        snapshot,
      ]
    );

    await connection.commit();
    await redisClient.delCache('lapaktani_catalog').catch(() => {});

    // Non-blocking ORDER chat ORDER_CARD & transaction notification
    try {
      const sellerId = product.farmer_id;
      const [existingConvs] = await pool.query(
        `SELECT cc.id FROM chat_conversations cc
         JOIN chat_participants cp1 ON cc.id = cp1.conversation_id AND cp1.user_id = ?
         JOIN chat_participants cp2 ON cc.id = cp2.conversation_id AND cp2.user_id = ?
         WHERE cc.type = 'ORDER'
         ORDER BY cc.updated_at DESC LIMIT 1`,
        [bidderId, sellerId]
      );
      let convId = existingConvs[0]?.id || null;
      if (!convId) {
        convId = `conv-b2b-${uuidv4().slice(0, 10)}`;
        await pool.query(
          `INSERT INTO chat_conversations (id, type, order_id, title) VALUES (?, 'ORDER', ?, ?)`,
          [convId, bidId, `B2B Lot — ${product.title}`]
        );
        await pool.query(
          `INSERT IGNORE INTO chat_participants (conversation_id, user_id) VALUES (?, ?), (?, ?)`,
          [convId, bidderId, convId, sellerId]
        );
      }
      await pool.query(
        `INSERT INTO chat_messages (id, conversation_id, sender_id, message_type, body, metadata_json)
         VALUES (?, ?, ?, 'ORDER_CARD', ?, ?)`,
        [
          `msg-${uuidv4().slice(0, 12)}`,
          convId,
          bidderId,
          `Bid B2B [${bidderType}] ${product.title} (${qty} kg @ Rp ${unitBidPrice.toLocaleString('id-ID')}/kg = Rp ${totalBidAmount.toLocaleString('id-ID')}) — Metode: ${method}`,
          JSON.stringify({
            bid_id: bidId,
            product_id: product.id,
            bidder_type: bidderType,
            qty_kg: qty,
            total_bid_amount: totalBidAmount,
            fulfillment_method: method,
            status: initialStatus,
          }),
        ]
      );
    } catch (_) {}

    notifyTransactionEvent({
      eventType: initialStatus === 'PAID_ESCROW' ? 'ORDER_PAID' : 'ORDER_CREATED',
      orderId: bidId,
      invoiceNumber: bidId,
      buyerId: bidderId,
      sellerId: product.farmer_id,
      totalAmount: totalBidAmount,
      status: initialStatus,
      message: `Tawaran Lot B2B ${product.title} (${qty} kg) dari ${bidderName} [${bidderType}].`,
    }).catch(() => {});

    const [created] = await pool.query('SELECT * FROM b2b_lot_bids WHERE id = ?', [bidId]);
    return res.status(201).json({
      success: true,
      message: `Tawaran lot B2B ${qty} kg berhasil dikirim dengan metode ${method}.`,
      data: serializeBidRow(created[0]),
    });
  } catch (error) {
    if (connection) await connection.rollback().catch(() => {});
    console.error('[B2B_BIDS] Error placing bid:', error.message);
    return res.status(500).json({ success: false, message: 'Gagal mengajukan penawaran lot B2B.' });
  } finally {
    if (connection) connection.release();
  }
};

/**
 * PUT /api/b2b/bids/:bidId/status
 * Seller or bidder transitions bid status (ACCEPTED_READY_TO_PAY -> PAID_ESCROW -> READY_FOR_DELIVERY / READY_FOR_PICKUP -> COMPLETED).
 * On PAID_ESCROW: notifies source farmer first & unmasks source farmer traceability info.
 */
const updateB2BLotBidStatus = async (req, res) => {
  try {
    const userId = req.user.id;
    const { bidId } = req.params;
    const { status } = req.body || {};
    const nextStatus = String(status || '').trim().toUpperCase();

    const validStatuses = [
      'ACCEPTED_READY_TO_PAY',
      'PAID_ESCROW',
      'READY_FOR_DELIVERY',
      'READY_FOR_PICKUP',
      'COMPLETED',
    ];

    if (!validStatuses.includes(nextStatus)) {
      return res.status(400).json({
        success: false,
        message: `Status tidak valid. Gunakan: ${validStatuses.join(', ')}`,
      });
    }

    const [rows] = await pool.query(
      `SELECT b.*,
              p.source_farmer_id, p.source_farmer_name, p.source_farmer_phone,
              COALESCE(v.name, 'Sumenep') AS village_name
       FROM b2b_lot_bids b
       LEFT JOIN products p ON b.product_id = p.id
       LEFT JOIN villages v ON p.store_village_id = v.id
       WHERE b.id = ? LIMIT 1`,
      [bidId]
    );

    if (rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Data bid B2B tidak ditemukan.' });
    }

    const bid = rows[0];
    const callerRole = String(req.user?.role || '').toLowerCase();
    const isSeller = String(bid.seller_admin_id) === String(userId);
    const isBidder = String(bid.bidder_user_id) === String(userId);
    const isSuper = callerRole === 'superadmin' || Number(req.user?.role_id) === 6;

    if (!isSeller && !isBidder && !isSuper) {
      return res.status(403).json({ success: false, message: 'Tidak memiliki akses ke transaksi lot B2B ini.' });
    }

    let snapshotJson = bid.source_farmer_snapshot_json;
    if (UNMASKED_BID_STATUSES.has(nextStatus) && !snapshotJson) {
      snapshotJson = JSON.stringify({
        farmer_id: bid.source_farmer_id || null,
        farmer_name: bid.source_farmer_name || 'Pak Supardi (Poktan Harapan Sumenep)',
        farmer_phone: bid.source_farmer_phone || '081234567890',
        village_name: bid.village_name || 'Sumenep',
      });
    }

    await pool.query(
      `UPDATE b2b_lot_bids
       SET status = ?, source_farmer_snapshot_json = COALESCE(?, source_farmer_snapshot_json), updated_at = NOW()
       WHERE id = ?`,
      [nextStatus, snapshotJson, bidId]
    );

    // Priority alert to source farmer immediately upon PAID_ESCROW
    if (nextStatus === 'PAID_ESCROW' && bid.source_farmer_id) {
      try {
        await pool.query(
          `INSERT INTO notifications (id, user_id, title, message, type, reference_id, is_read)
           VALUES (?, ?, ?, ?, 'farmer_lot_paid', ?, 0)`,
          [
            `ntf-${uuidv4().slice(0, 12)}`,
            bid.source_farmer_id,
            `Lot Panen Terjual & Lunas Escrow (${bid.bid_qty_kg} kg)`,
            `Produk ${bid.product_title} (${bid.bid_qty_kg} kg) dibayar lunas di escrow oleh ${bid.bidder_name}. Kontak transparansi petani telah dibuka untuk koordinasi pasca-panen.`,
            bidId,
          ]
        );
      } catch (_) {}
    }

    notifyTransactionEvent({
      eventType: nextStatus === 'PAID_ESCROW' ? 'ORDER_PAID' : (nextStatus === 'COMPLETED' ? 'ORDER_COMPLETED' : 'ORDER_STATUS_UPDATED'),
      orderId: bidId,
      invoiceNumber: bidId,
      buyerId: bid.bidder_user_id,
      sellerId: bid.seller_admin_id,
      totalAmount: bid.total_bid_amount,
      status: nextStatus,
      message: `Lot B2B ${bid.product_title} (${bid.bid_qty_kg} kg) diperbarui menjadi ${nextStatus}.`,
    }).catch(() => {});

    const [updated] = await pool.query('SELECT * FROM b2b_lot_bids WHERE id = ?', [bidId]);
    return res.status(200).json({
      success: true,
      message: `Status lot B2B berhasil diperbarui ke ${nextStatus}.`,
      data: serializeBidRow(updated[0]),
    });
  } catch (error) {
    console.error('[B2B_BIDS] Error updating bid status:', error.message);
    return res.status(500).json({ success: false, message: 'Gagal memperbarui status penawaran lot B2B.' });
  }
};

/**
 * POST /api/b2b/bids/:bidId/restock-to-retail
 * 1-Click Restock for RETAIL_MERCHANT once their B2B purchase reaches COMPLETED
 */
const restockB2BBidToRetail = async (req, res) => {
  let connection;
  try {
    const userId = req.user.id;
    const { bidId } = req.params;
    const { retail_price_per_kg, discount_percent = 0, retail_title } = req.body || {};

    connection = await pool.getConnection();
    await connection.beginTransaction();

    const [rows] = await connection.query(
      `SELECT b.*, p.commodity_id, p.grade_id, p.unit_id, p.image_url, p.description,
              p.source_farmer_id, p.source_farmer_name, p.source_farmer_phone, p.store_village_id
       FROM b2b_lot_bids b
       LEFT JOIN products p ON b.product_id = p.id
       WHERE b.id = ? LIMIT 1 FOR UPDATE`,
      [bidId]
    );

    if (rows.length === 0) {
      await connection.rollback();
      return res.status(404).json({ success: false, message: 'Transaksi B2B tidak ditemukan.' });
    }

    const bid = rows[0];
    if (String(bid.bidder_user_id) !== String(userId)) {
      await connection.rollback();
      return res.status(403).json({ success: false, message: 'Hanya pembeli B2B terkait yang dapat merestock ke tokonya.' });
    }

    if (bid.bidder_type !== 'RETAIL_MERCHANT') {
      await connection.rollback();
      return res.status(403).json({ success: false, message: 'Fitur 1-Click Restock khusus untuk Admin Retail.' });
    }

    if (String(bid.status).toUpperCase() !== 'COMPLETED') {
      await connection.rollback();
      return res.status(400).json({
        success: false,
        message: 'Konfirmasi penerimaan barang (COMPLETED) terlebih dahulu sebelum memindahkan ke etalase Retail.',
      });
    }

    if (Number(bid.restocked_to_retail) === 1) {
      await connection.rollback();
      return res.status(409).json({
        success: false,
        message: 'Item pembelian B2B ini sudah dimasukkan ke daftar toko retail Anda.',
      });
    }

    const costPrice = Number(bid.bid_price_per_kg || 10000);
    const retailPrice =
      retail_price_per_kg !== undefined && Number(retail_price_per_kg) > 0
        ? Number(retail_price_per_kg)
        : Math.round(costPrice * 1.15);
    const discPct = Math.max(0, Math.min(80, Number(discount_percent) || 0));
    const discPrice = discPct > 0 ? Math.round(retailPrice * (1 - discPct / 100)) : null;

    const newProductId = `prod-rtl-${uuidv4().slice(0, 8)}`;
    const qty = Number(bid.bid_qty_kg || 1);
    const productTitle = retail_title ? String(retail_title).trim() : `${bid.product_title} (Eceran Retail)`;

    // Ensure farmer_profiles FK exists for retail merchant owner before inserting into products
    const [fpRows] = await connection.query(
      'SELECT user_id FROM farmer_profiles WHERE user_id = ? LIMIT 1',
      [userId]
    );
    if (fpRows.length === 0) {
      const [groups] = await connection.query('SELECT id FROM farmer_groups LIMIT 1');
      const fallbackGroupId = groups[0]?.id || '3be588df-b4b6-496b-aeac-efa43e3a7735';
      await connection.query(
        'INSERT INTO farmer_profiles (user_id, farmer_group_id) VALUES (?, ?) ON DUPLICATE KEY UPDATE farmer_group_id = VALUES(farmer_group_id)',
        [userId, fallbackGroupId]
      );
    }

    let resolvedCommodityId = bid.commodity_id;
    if (!resolvedCommodityId) {
      const [comms] = await connection.query('SELECT id FROM commodities LIMIT 1');
      resolvedCommodityId = comms[0]?.id || 'com-tomat';
    }
    let resolvedGradeId = bid.grade_id;
    if (!resolvedGradeId) {
      const [grds] = await connection.query('SELECT id FROM product_grades LIMIT 1');
      resolvedGradeId = grds[0]?.id || 'grade-1';
    }
    let resolvedUnitId = bid.unit_id;
    if (!resolvedUnitId) {
      const [units] = await connection.query('SELECT id FROM commodity_units LIMIT 1');
      resolvedUnitId = units[0]?.id || 'unit-kg';
    }

    await connection.query(
      `INSERT INTO products
       (id, farmer_id, commodity_id, grade_id, unit_id, title, description, price_per_kg, stock_kg, price, stock, image_url, discount_percent, discount_price, is_wholesale_enabled, min_wholesale_qty, wholesale_price, store_village_id, processing_state, catalog_channel, fulfillment_options, source_farmer_id, source_farmer_name, source_farmer_phone, created_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, 30, ?, ?, 'SIAP_PAKAI', 'RETAIL_CATALOG', 'BOTH', ?, ?, ?, NOW())`,
      [
        newProductId,
        userId,
        resolvedCommodityId,
        resolvedGradeId,
        resolvedUnitId,
        productTitle,
        bid.description || `Stok kulakan B2B siap pakai (${qty} kg) tersedia di etalase Admin Retail.`,
        retailPrice,
        qty,
        retailPrice,
        Math.floor(qty),
        bid.image_url || 'uploads/products/tomat.jpg',
        discPct,
        discPrice,
        retailPrice,
        bid.store_village_id || 109,
        bid.source_farmer_id || null,
        bid.source_farmer_name || 'Pak Supardi (Poktan Harapan Sumenep)',
        bid.source_farmer_phone || '081234567890',
      ]
    );

    await connection.query('UPDATE b2b_lot_bids SET restocked_to_retail = 1, updated_at = NOW() WHERE id = ?', [bidId]);
    await connection.commit();
    await redisClient.delCache('lapaktani_catalog').catch(() => {});

    const [createdProd] = await pool.query('SELECT * FROM products WHERE id = ?', [newProductId]);
    return res.status(201).json({
      success: true,
      message: `${productTitle} (${qty} kg) berhasil ditambahkan ke etalase Toko Retail Anda (1-Click Restock)!`,
      data: {
        bid_id: bidId,
        restocked_to_retail: true,
        retail_product: createdProd[0],
      },
    });
  } catch (error) {
    if (connection) await connection.rollback().catch(() => {});
    console.error('[B2B_RESTOCK] Error restocking to retail:', error.message);
    return res.status(500).json({ success: false, message: 'Gagal menambahkan produk ke daftar toko retail.' });
  } finally {
    if (connection) connection.release();
  }
};

/**
 * POST /api/b2b/bids/:bidId/cancel-with-refund
 * Capped Hybrid Refund Fee on B2B Bid cancellation
 */
const cancelB2BBidWithRefund = async (req, res) => {
  const userId = req.user.id;
  const { bidId } = req.params;
  const { cancelled_by = 'BUYER', reason = 'Pembatalan kontrak lot B2B' } = req.body || {};

  let connection;
  try {
    connection = await pool.getConnection();
    await connection.beginTransaction();

    const [rows] = await connection.query('SELECT * FROM b2b_lot_bids WHERE id = ? LIMIT 1 FOR UPDATE', [bidId]);
    if (rows.length === 0) {
      await connection.rollback();
      return res.status(404).json({ success: false, message: 'Data bid B2B tidak ditemukan.' });
    }

    const bid = rows[0];
    if (String(bid.status).startsWith('CANCELLED_')) {
      await connection.rollback();
      return res.status(409).json({ success: false, message: 'Kontrak lot B2B sudah dibatalkan sebelumnya.' });
    }

    const isSeller = String(bid.seller_admin_id) === String(userId);
    const actor = isSeller && String(cancelled_by).toUpperCase() === 'SELLER' ? 'SELLER' : 'BUYER';
    const nextStatus = actor === 'SELLER' ? 'CANCELLED_BY_SELLER' : 'CANCELLED_BY_BUYER';
    const refundInfo = calculateHybridRefundFee(bid.total_bid_amount, actor);

    await connection.query('UPDATE products SET stock_kg = stock_kg + ? WHERE id = ?', [
      Number(bid.bid_qty_kg || 0),
      bid.product_id,
    ]);

    await connection.query(
      'UPDATE b2b_lot_bids SET status = ?, updated_at = NOW() WHERE id = ?',
      [nextStatus, bidId]
    );

    const ledgerId = await recordPlatformFeeLedger(connection, {
      refId: bidId,
      refType: 'B2B_BID',
      userId,
      cancelledBy: refundInfo.cancelledBy,
      grossAmount: refundInfo.grossAmount,
      feeCharged: refundInfo.feeCharged,
      refundedAmount: refundInfo.refundedAmount,
      reason,
    });

    await connection.commit();
    await redisClient.delCache('lapaktani_catalog').catch(() => {});

    notifyTransactionEvent({
      eventType: 'ORDER_CANCELLED',
      orderId: bidId,
      invoiceNumber: bidId,
      buyerId: bid.bidder_user_id,
      sellerId: bid.seller_admin_id,
      totalAmount: refundInfo.refundedAmount,
      status: nextStatus,
      message: `Bid Lot B2B ${bid.product_title} dibatalkan (${actor}). Biaya platform: Rp ${refundInfo.feeCharged.toLocaleString('id-ID')}. Refund: Rp ${refundInfo.refundedAmount.toLocaleString('id-ID')}.`,
    }).catch(() => {});

    return res.status(200).json({
      success: true,
      message: `Pembatalan diproses (${nextStatus}). Refund Rp ${refundInfo.refundedAmount.toLocaleString('id-ID')} (Fee: Rp ${refundInfo.feeCharged.toLocaleString('id-ID')}).`,
      data: {
        ledger_id: ledgerId,
        bid_id: bidId,
        status: nextStatus,
        cancelled_by: refundInfo.cancelledBy,
        gross_amount: refundInfo.grossAmount,
        fee_charged: refundInfo.feeCharged,
        refunded_amount: refundInfo.refundedAmount,
        fee_formula: refundInfo.feeFormula,
      },
    });
  } catch (error) {
    if (connection) await connection.rollback().catch(() => {});
    console.error('[B2B_CANCEL] Error:', error.message);
    return res.status(500).json({ success: false, message: 'Gagal membatalkan kontrak lot B2B.' });
  } finally {
    if (connection) connection.release();
  }
};

module.exports = {
  getB2BLots,
  getB2BLotBids,
  placeB2BLotBid,
  updateB2BLotBidStatus,
  restockB2BBidToRetail,
  cancelB2BBidWithRefund,
};
