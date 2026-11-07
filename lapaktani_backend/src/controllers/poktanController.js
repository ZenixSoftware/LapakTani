const { v4: uuidv4 } = require('uuid');
const pool = require('../config/db');

/**
 * Helper: Find Poktan info for a user and check if user is Chairman / Pengurus
 */
async function getUserPoktanInfo(userId) {
  const [rows] = await pool.query(
    `SELECT 
      fg.id AS group_id, 
      fg.group_name, 
      fg.village_id,
      fg.chairman_user_id,
      fp.user_id
    FROM farmer_profiles fp
    JOIN farmer_groups fg ON fp.farmer_group_id = fg.id
    WHERE fp.user_id = ?
    LIMIT 1`,
    [userId]
  );

  if (rows.length === 0) {
    return null;
  }

  const info = rows[0];

  // If chairman_user_id is not set yet, automatically set it to this user to bootstrap pengurus role
  if (!info.chairman_user_id) {
    await pool.query('UPDATE farmer_groups SET chairman_user_id = ? WHERE id = ?', [userId, info.group_id]);
    info.chairman_user_id = userId;
  }

  const isChairman = info.chairman_user_id === userId;
  return { ...info, isChairman };
}

/**
 * GET /api/poktan/info
 * Returns the logged-in user's Poktan status and role (pengurus/member)
 */
const getPoktanInfo = async (req, res) => {
  try {
    const userId = req.user.id;
    const poktanInfo = await getUserPoktanInfo(userId);

    if (!poktanInfo) {
      return res.status(404).json({
        success: false,
        message: 'Pengguna belum terdaftar dalam kelompok tani (Poktan).'
      });
    }

    return res.status(200).json({
      success: true,
      data: {
        group_id: poktanInfo.group_id,
        group_name: poktanInfo.group_name,
        is_chairman: poktanInfo.isChairman,
        chairman_user_id: poktanInfo.chairman_user_id
      }
    });
  } catch (error) {
    console.error('[POKTAN] Error fetching poktan info:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal memuat informasi kelompok tani.'
    });
  }
};

/**
 * GET /api/poktan/members
 * Pengurus Poktan views aggregated land area and member details
 */
const getMembers = async (req, res) => {
  try {
    const userId = req.user.id;
    const poktan = await getUserPoktanInfo(userId);

    if (!poktan) {
      return res.status(404).json({
        success: false,
        message: 'Pengguna belum terdaftar dalam kelompok tani manapun.'
      });
    }

    if (!poktan.isChairman && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Akses ditolak. Layanan konsolidasi lahan hanya untuk pengurus Poktan.'
      });
    }

    const [members] = await pool.query(
      `SELECT 
        u.id AS farmer_id,
        u.full_name,
        u.email,
        COALESCE(up.phone, '-') AS phone,
        COALESCE(up.nik_number, '-') AS nik_number,
        COALESCE(f.land_area_ha, 0.00) AS land_area_ha,
        COALESCE(f.soil_type, 'Subur') AS soil_type,
        f.gps_latitude,
        f.gps_longitude,
        (u.id = ?) AS is_chairman
      FROM farmer_profiles fp
      JOIN users u ON fp.user_id = u.id
      LEFT JOIN user_profiles up ON u.id = up.user_id
      LEFT JOIN farms f ON u.id = f.farmer_id
      WHERE fp.farmer_group_id = ?
      ORDER BY u.full_name ASC`,
      [poktan.chairman_user_id, poktan.group_id]
    );

    const totalLandAreaHa = members.reduce(
      (sum, m) => sum + parseFloat(m.land_area_ha || 0),
      0
    );

    return res.status(200).json({
      success: true,
      poktan: {
        id: poktan.group_id,
        group_name: poktan.group_name,
        chairman_user_id: poktan.chairman_user_id
      },
      total_land_area_ha: Number(totalLandAreaHa.toFixed(2)),
      members_count: members.length,
      members
    });
  } catch (error) {
    console.error('[POKTAN] Error fetching members:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal mengambil data konsolidasi lahan anggota Poktan.'
    });
  }
};

/**
 * POST /api/poktan/b2b-orders
 * Pengurus creates a new B2B contract order
 */
const createB2BOrder = async (req, res) => {
  try {
    const userId = req.user.id;
    const poktan = await getUserPoktanInfo(userId);

    if (!poktan) {
      return res.status(404).json({
        success: false,
        message: 'Pengguna belum terdaftar dalam kelompok tani.'
      });
    }

    if (!poktan.isChairman && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Akses ditolak. Hanya pengurus yang dapat membuat pesanan B2B.'
      });
    }

    const { commodity_id, total_quota_kg, buyer_name, deadline } = req.body;

    if (!commodity_id || !total_quota_kg || !buyer_name || !deadline) {
      return res.status(400).json({
        success: false,
        message: 'Data tidak lengkap. Komoditas, total kuota, nama pembeli, dan tenggat wajib diisi.'
      });
    }

    const quotaNum = parseFloat(total_quota_kg);
    if (isNaN(quotaNum) || quotaNum <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Total kuota panen (kg) harus bernilai angka lebih dari 0.'
      });
    }

    // Verify commodity exists
    const [commodities] = await pool.query(
      'SELECT id, specific_name FROM commodities WHERE id = ? LIMIT 1',
      [commodity_id]
    );

    if (commodities.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Komoditas yang dipilih tidak ditemukan dalam sistem.'
      });
    }

    const orderId = uuidv4();
    await pool.query(
      `INSERT INTO b2b_orders 
        (id, farmer_group_id, commodity_id, total_quota_kg, buyer_name, deadline, status) 
       VALUES (?, ?, ?, ?, ?, ?, 'draft')`,
      [orderId, poktan.group_id, commodity_id, quotaNum, buyer_name.trim(), deadline]
    );

    return res.status(201).json({
      success: true,
      message: 'Pesanan B2B berhasil didaftarkan.',
      data: {
        id: orderId,
        farmer_group_id: poktan.group_id,
        commodity_id,
        commodity_name: commodities[0].specific_name,
        total_quota_kg: quotaNum,
        buyer_name: buyer_name.trim(),
        deadline,
        status: 'draft'
      }
    });
  } catch (error) {
    console.error('[POKTAN] Error creating B2B order:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan server saat membuat pesanan B2B.'
    });
  }
};

/**
 * GET /api/poktan/b2b-orders
 * List B2B orders for the user's Poktan with allocation statistics
 */
const getB2BOrders = async (req, res) => {
  try {
    const userId = req.user.id;
    const poktan = await getUserPoktanInfo(userId);

    if (!poktan) {
      return res.status(404).json({
        success: false,
        message: 'Pengguna belum terdaftar dalam kelompok tani.'
      });
    }

    const [orders] = await pool.query(
      `SELECT 
        o.id,
        o.farmer_group_id,
        o.commodity_id,
        COALESCE(c.specific_name, 'Komoditas Pertanian') AS commodity_name,
        CAST(o.total_quota_kg AS DECIMAL(12,2)) AS total_quota_kg,
        CAST(COALESCE(SUM(qa.allocated_kg), 0) AS DECIMAL(12,2)) AS total_allocated_kg,
        CAST((o.total_quota_kg - COALESCE(SUM(qa.allocated_kg), 0)) AS DECIMAL(12,2)) AS remaining_quota_kg,
        o.buyer_name,
        DATE_FORMAT(o.deadline, '%Y-%m-%d') AS deadline,
        o.status,
        o.created_at
      FROM b2b_orders o
      LEFT JOIN commodities c ON o.commodity_id = c.id
      LEFT JOIN quota_allocations qa ON o.id = qa.b2b_order_id AND qa.status != 'cancelled'
      WHERE o.farmer_group_id = ?
      GROUP BY o.id, c.specific_name
      ORDER BY o.created_at DESC`,
      [poktan.group_id]
    );

    return res.status(200).json({
      success: true,
      total: orders.length,
      data: orders
    });
  } catch (error) {
    console.error('[POKTAN] Error fetching B2B orders:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal memuat daftar pesanan B2B Poktan.'
    });
  }
};

/**
 * POST /api/poktan/allocate-quota
 * Distributes B2B quota among members in a single MySQL transaction and notifies farmers
 */
const allocateQuota = async (req, res) => {
  const connection = await pool.getConnection();
  try {
    const userId = req.user.id;
    const poktan = await getUserPoktanInfo(userId);

    if (!poktan) {
      connection.release();
      return res.status(404).json({
        success: false,
        message: 'Pengguna belum terdaftar dalam kelompok tani.'
      });
    }

    if (!poktan.isChairman && req.user.role !== 'admin') {
      connection.release();
      return res.status(403).json({
        success: false,
        message: 'Akses ditolak. Hanya pengurus Poktan yang berhak mengalokasikan kuota.'
      });
    }

    const { b2b_order_id, allocations } = req.body;

    if (!b2b_order_id || !Array.isArray(allocations) || allocations.length === 0) {
      connection.release();
      return res.status(400).json({
        success: false,
        message: 'Permintaan tidak valid. Diperlukan b2b_order_id dan daftar alokasi kuota petani.'
      });
    }

    // 1. Verify B2B order exists and belongs to this Poktan
    const [orderRows] = await connection.query(
      `SELECT o.*, c.specific_name AS commodity_name 
       FROM b2b_orders o 
       LEFT JOIN commodities c ON o.commodity_id = c.id 
       WHERE o.id = ? AND o.farmer_group_id = ? LIMIT 1`,
      [b2b_order_id, poktan.group_id]
    );

    if (orderRows.length === 0) {
      connection.release();
      return res.status(404).json({
        success: false,
        message: 'Pesanan B2B tidak ditemukan pada kelompok tani Anda.'
      });
    }

    const order = orderRows[0];
    const totalOrderQuota = parseFloat(order.total_quota_kg);

    // 2. Fetch existing allocated sum (excluding cancelled)
    const [existingAllocRows] = await connection.query(
      `SELECT COALESCE(SUM(allocated_kg), 0) AS current_allocated 
       FROM quota_allocations 
       WHERE b2b_order_id = ? AND status != 'cancelled'`,
      [b2b_order_id]
    );
    const alreadyAllocated = parseFloat(existingAllocRows[0].current_allocated || 0);

    // 3. Fetch all active members in this group to validate membership
    const [memberRows] = await connection.query(
      'SELECT user_id FROM farmer_profiles WHERE farmer_group_id = ?',
      [poktan.group_id]
    );
    const validMemberIds = new Set(memberRows.map((m) => m.user_id));

    // 4. Validate each allocation entry
    let requestedAllocTotal = 0;
    for (const alloc of allocations) {
      const { farmer_id, allocated_kg } = alloc;
      const kg = parseFloat(allocated_kg);

      if (!farmer_id || !validMemberIds.has(farmer_id)) {
        connection.release();
        return res.status(400).json({
          success: false,
          message: `Petani dengan ID ${farmer_id || 'kosong'} bukan anggota resmi kelompok tani ${poktan.group_name}.`
        });
      }

      if (isNaN(kg) || kg <= 0) {
        connection.release();
        return res.status(400).json({
          success: false,
          message: 'Jumlah alokasi kuota setiap petani harus lebih besar dari 0 kg.'
        });
      }

      requestedAllocTotal += kg;
    }

    if (alreadyAllocated + requestedAllocTotal > totalOrderQuota + 0.001) {
      connection.release();
      return res.status(400).json({
        success: false,
        message: `Total alokasi (${alreadyAllocated + requestedAllocTotal} kg) melebihi kuota pesanan B2B (${totalOrderQuota} kg). Sisa kuota tersedia: ${totalOrderQuota - alreadyAllocated} kg.`
      });
    }

    // 5. Execute in single MySQL transaction
    await connection.beginTransaction();

    const createdAllocations = [];
    for (const alloc of allocations) {
      const allocId = uuidv4();
      const notifId = uuidv4();
      const kg = parseFloat(alloc.allocated_kg);
      const plantingDeadline = alloc.planting_deadline || null;
      const harvestDeadline = alloc.harvest_deadline || order.deadline;

      // Insert allocation record
      await connection.query(
        `INSERT INTO quota_allocations 
          (id, b2b_order_id, farmer_id, allocated_kg, planting_deadline, harvest_deadline, status) 
         VALUES (?, ?, ?, ?, ?, ?, 'pending')`,
        [allocId, b2b_order_id, alloc.farmer_id, kg, plantingDeadline, harvestDeadline]
      );

      // Create notification for farmer
      const notifTitle = 'Tugas Kuota Panen B2B Baru';
      const formattedKg = new Intl.NumberFormat('id-ID').format(kg);
      const notifMessage = `Kelompok tani menugaskan kuota panen ${order.commodity_name || 'Komoditas'} sebesar ${formattedKg} kg untuk pesanan ${order.buyer_name}. Segera persiapkan lahan Anda.`;

      await connection.query(
        `INSERT INTO notifications (id, user_id, title, message, type, is_read) 
         VALUES (?, ?, ?, ?, 'quota_task', FALSE)`,
        [notifId, alloc.farmer_id, notifTitle, notifMessage]
      );

      createdAllocations.push({
        id: allocId,
        farmer_id: alloc.farmer_id,
        allocated_kg: kg,
        planting_deadline: plantingDeadline,
        harvest_deadline: harvestDeadline
      });
    }

    // Update order status to allocated
    await connection.query(
      "UPDATE b2b_orders SET status = 'allocated' WHERE id = ?",
      [b2b_order_id]
    );

    await connection.commit();
    connection.release();

    return res.status(201).json({
      success: true,
      message: 'Alokasi kuota panen berhasil didistribusikan ke petani anggota.',
      data: {
        b2b_order_id,
        total_allocated_kg: requestedAllocTotal,
        allocations_count: createdAllocations.length,
        allocations: createdAllocations
      }
    });
  } catch (error) {
    await connection.rollback();
    connection.release();
    console.error('[POKTAN] Error allocating quota:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal mengalokasikan kuota panen petani. Transaksi dibatalkan.'
    });
  }
};

/**
 * GET /api/poktan/my-tasks
 * Logged-in farmer checks their assigned production tasks
 */
const getMyTasks = async (req, res) => {
  try {
    const userId = req.user.id;

    const [tasks] = await pool.query(
      `SELECT 
        qa.id AS task_id,
        qa.b2b_order_id,
        qa.farmer_id,
        CAST(qa.allocated_kg AS DECIMAL(12,2)) AS allocated_kg,
        DATE_FORMAT(qa.planting_deadline, '%Y-%m-%d') AS planting_deadline,
        DATE_FORMAT(qa.harvest_deadline, '%Y-%m-%d') AS harvest_deadline,
        qa.status AS task_status,
        qa.created_at,
        o.buyer_name,
        DATE_FORMAT(o.deadline, '%Y-%m-%d') AS contract_deadline,
        c.id AS commodity_id,
        COALESCE(c.specific_name, 'Komoditas Unggulan') AS commodity_name,
        fg.group_name AS poktan_name
      FROM quota_allocations qa
      JOIN b2b_orders o ON qa.b2b_order_id = o.id
      LEFT JOIN commodities c ON o.commodity_id = c.id
      JOIN farmer_groups fg ON o.farmer_group_id = fg.id
      WHERE qa.farmer_id = ?
      ORDER BY qa.created_at DESC`,
      [userId]
    );

    // Also get unread notifications for this user
    const [notifications] = await pool.query(
      `SELECT id, title, message, type, is_read, created_at 
       FROM notifications 
       WHERE user_id = ? 
       ORDER BY created_at DESC LIMIT 10`,
      [userId]
    );

    return res.status(200).json({
      success: true,
      total_tasks: tasks.length,
      tasks,
      notifications
    });
  } catch (error) {
    console.error('[POKTAN] Error fetching my tasks:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal memuat tugas produksi petani.'
    });
  }
};

/**
 * GET /api/poktan/notifications
 * Get user notifications and mark as read
 */
const getNotifications = async (req, res) => {
  try {
    const userId = req.user.id;
    const [rows] = await pool.query(
      `SELECT id, title, message, type, is_read, created_at 
       FROM notifications 
       WHERE user_id = ? 
       ORDER BY created_at DESC LIMIT 20`,
      [userId]
    );

    return res.status(200).json({
      success: true,
      data: rows
    });
  } catch (error) {
    console.error('[POKTAN] Error fetching notifications:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal mengambil data notifikasi.'
    });
  }
};

/**
 * POST /api/poktan/b2b-orders/:id/settle
 * PUT /api/poktan/b2b-orders/:id/status
 * Realistic B2B contract settlement with deficit handling and escrow refund.
 * Status: 'PARTIALLY_FULFILLED' when actual_delivered_kg < target_contract_kg.
 * Status: 'COMPLETED' when actual_delivered_kg >= target_contract_kg.
 * Prevents contract cancellation due to deficit.
 */
const settleB2BOrder = async (req, res) => {
  const connection = await pool.getConnection();
  try {
    const userId = req.user.id;
    const { id } = req.params;
    const {
      actual_delivered_kg,
      agreed_price_per_kg,
      settlement_notes,
      status: requestedStatus
    } = req.body;

    const poktan = await getUserPoktanInfo(userId);
    if (!poktan) {
      connection.release();
      return res.status(404).json({
        success: false,
        message: 'Pengguna belum terdaftar dalam kelompok tani.'
      });
    }

    if (!poktan.isChairman && req.user.role !== 'admin') {
      connection.release();
      return res.status(403).json({
        success: false,
        message: 'Akses ditolak. Hanya ketua Poktan atau admin yang berhak melakukan penyelesaian kontrak B2B.'
      });
    }

    // 1. Verify B2B order exists
    const [orderRows] = await connection.query(
      `SELECT o.*, c.specific_name AS commodity_name
       FROM b2b_orders o
       LEFT JOIN commodities c ON o.commodity_id = c.id
       WHERE o.id = ? AND o.farmer_group_id = ?`,
      [id, poktan.group_id]
    );

    if (orderRows.length === 0) {
      connection.release();
      return res.status(404).json({
        success: false,
        message: 'Pesanan kontrak B2B tidak ditemukan pada kelompok tani Anda.'
      });
    }

    const order = orderRows[0];
    const targetQuotaKg = parseFloat(order.total_quota_kg);
    const deliveredKg = parseFloat(actual_delivered_kg !== undefined ? actual_delivered_kg : targetQuotaKg);
    const pricePerKg = parseFloat(agreed_price_per_kg || order.agreed_price_per_kg || 15000.00);

    if (isNaN(deliveredKg) || deliveredKg < 0) {
      connection.release();
      return res.status(400).json({
        success: false,
        message: 'Jumlah tonase panen aktual (actual_delivered_kg) tidak valid.'
      });
    }

    // Protection rule 2: Deficits MUST NOT abort the entire contract
    if (requestedStatus === 'CANCELLED' && deliveredKg > 0) {
      connection.release();
      return res.status(400).json({
        success: false,
        message: 'Kontrak tidak boleh dibatalkan secara sepihak ketika terdapat panen valid. Sistem mewajibkan partial fulfillment.'
      });
    }

    let finalStatus = 'COMPLETED';
    let deficitKg = 0;
    if (deliveredKg < targetQuotaKg) {
      finalStatus = 'PARTIALLY_FULFILLED';
      deficitKg = targetQuotaKg - deliveredKg;
    }

    // Calculation logic
    const farmerDisbursedAmount = deliveredKg * pricePerKg;
    const buyerRefundAmount = deficitKg * pricePerKg;
    const notes = settlement_notes || (deficitKg > 0
      ? `Deviasi hasil panen sebesar ${deficitKg.toFixed(1)} kg akibat anomali cuaca diverifikasi oleh Poktan ${poktan.group_name}. Kuota terserap ${deliveredKg.toFixed(1)} kg dibayarkan ke petani, sisa escrow dikembalikan ke pembeli.`
      : `Kontrak panen B2B terpenuhi 100% (${deliveredKg.toFixed(1)} kg).`);

    await connection.beginTransaction();

    // 2. Disburse payment to member farmers according to their quota allocations
    const [allocRows] = await connection.query(
      `SELECT qa.id, qa.farmer_id, qa.allocated_kg, u.full_name
       FROM quota_allocations qa
       JOIN users u ON qa.farmer_id = u.id
       WHERE qa.b2b_order_id = ? AND qa.status != 'cancelled'`,
      [order.id]
    );

    const totalAllocated = allocRows.reduce((sum, a) => sum + parseFloat(a.allocated_kg), 0);

    if (allocRows.length > 0 && totalAllocated > 0) {
      for (const alloc of allocRows) {
        const allocKg = parseFloat(alloc.allocated_kg);
        const farmerDeliveredKg = (allocKg / totalAllocated) * deliveredKg;
        const farmerPayment = farmerDeliveredKg * pricePerKg;

        if (farmerPayment > 0) {
          // Credit farmer wallet atomically
          await connection.query(
            'UPDATE users SET wallet_balance = COALESCE(wallet_balance, 0) + ? WHERE id = ?',
            [farmerPayment, alloc.farmer_id]
          );
          await connection.query(
            'UPDATE user_profiles SET wallet_balance = COALESCE(wallet_balance, 0) + ? WHERE user_id = ?',
            [farmerPayment, alloc.farmer_id]
          );

          // Audit log in notifications
          const notifId = uuidv4();
          const notifMsg = `Pencairan dana hasil serap panen kontrak B2B (${order.buyer_name}): ${farmerDeliveredKg.toFixed(1)} kg x Rp ${pricePerKg.toLocaleString('id-ID')} = Rp ${farmerPayment.toLocaleString('id-ID')} telah dikreditkan ke saldo LapakPay Anda.`;
          await connection.query(
            `INSERT INTO notifications (id, user_id, title, message, type, reference_id, is_read, created_at)
             VALUES (?, ?, 'Pencairan Dana Panen Kontrak B2B', ?, 'CONTRACT_DISBURSEMENT', ?, 0, NOW())`,
            [notifId, alloc.farmer_id, notifMsg, order.id]
          );
        }

        // Update allocation task status
        await connection.query(
          "UPDATE quota_allocations SET status = 'delivered', updated_at = NOW() WHERE id = ?",
          [alloc.id]
        );
      }
    } else {
      // Disburse to chairman / group
      await connection.query(
        'UPDATE users SET wallet_balance = COALESCE(wallet_balance, 0) + ? WHERE id = ?',
        [farmerDisbursedAmount, poktan.chairman_user_id || userId]
      );
      await connection.query(
        'UPDATE user_profiles SET wallet_balance = COALESCE(wallet_balance, 0) + ? WHERE user_id = ?',
        [farmerDisbursedAmount, poktan.chairman_user_id || userId]
      );
    }

    // 3. Calculate and disburse refund for buyer if deficit exists
    let buyerUserId = order.buyer_id;
    if (!buyerUserId) {
      const [buyerRows] = await connection.query(
        "SELECT id FROM users WHERE full_name = ? OR email LIKE ? OR role = 'pembeli' ORDER BY role = 'pembeli' DESC LIMIT 1",
        [order.buyer_name, `%${order.buyer_name.split(' ')[0]}%`]
      );
      if (buyerRows.length > 0) {
        buyerUserId = buyerRows[0].id;
      }
    }

    if (buyerRefundAmount > 0 && buyerUserId) {
      // Credit buyer wallet
      await connection.query(
        'UPDATE users SET wallet_balance = COALESCE(wallet_balance, 0) + ? WHERE id = ?',
        [buyerRefundAmount, buyerUserId]
      );
      await connection.query(
        'UPDATE user_profiles SET wallet_balance = COALESCE(wallet_balance, 0) + ? WHERE user_id = ?',
        [buyerRefundAmount, buyerUserId]
      );

      // Audit log notification for buyer
      const notifId = uuidv4();
      const notifMsg = `Pengembalian dana escrow sebesar Rp ${buyerRefundAmount.toLocaleString('id-ID')} untuk kontrak ${order.id} berhasil dicairkan ke saldo dompet Anda karena pemenuhan panen aktual ${deliveredKg} kg dari target ${targetQuotaKg} kg. Catatan: ${notes}`;
      await connection.query(
        `INSERT INTO notifications (id, user_id, title, message, type, reference_id, is_read, created_at)
         VALUES (?, ?, 'Pengembalian Dana Escrow B2B (Defisit Panen)', ?, 'ESCROW_REFUND', ?, 0, NOW())`,
        [notifId, buyerUserId, notifMsg, order.id]
      );
    }

    // 4. Poktan Chairman audit notification
    const chairmanNotifId = uuidv4();
    const chairmanMsg = `Penyelesaian kontrak B2B ${order.id} berhasil diproses dengan status ${finalStatus}. Tonase diserap: ${deliveredKg} kg (Rp ${farmerDisbursedAmount.toLocaleString('id-ID')}), escrow dikembalikan: Rp ${buyerRefundAmount.toLocaleString('id-ID')}.`;
    await connection.query(
      `INSERT INTO notifications (id, user_id, title, message, type, reference_id, is_read, created_at)
       VALUES (?, ?, 'Audit Settlement Kontrak B2B Poktan', ?, 'SETTLEMENT_AUDIT', ?, 0, NOW())`,
      [chairmanNotifId, userId, chairmanMsg, order.id]
    );

    // 5. Update b2b_orders state
    await connection.query(
      `UPDATE b2b_orders 
       SET status = ?,
           actual_delivered_kg = ?,
           agreed_price_per_kg = ?,
           farmer_disbursed_amount = ?,
           buyer_refund_amount = ?,
           settlement_notes = ?,
           buyer_id = COALESCE(buyer_id, ?),
           updated_at = NOW()
       WHERE id = ?`,
      [
        finalStatus,
        deliveredKg,
        pricePerKg,
        farmerDisbursedAmount,
        buyerRefundAmount,
        notes,
        buyerUserId,
        order.id
      ]
    );

    await connection.commit();

    return res.status(200).json({
      success: true,
      message: deficitKg > 0
        ? `Kontrak B2B diselesaikan secara parsial (${finalStatus}). Serapan ${deliveredKg} kg dibayarkan ke petani dan defisit ${deficitKg} kg direfund ke dompet pembeli.`
        : 'Kontrak B2B diselesaikan secara penuh (COMPLETED). Seluruh dana panen telah disalurkan.',
      data: {
        order_id: order.id,
        target_contract_kg: targetQuotaKg,
        actual_delivered_kg: deliveredKg,
        deficit_kg: deficitKg,
        agreed_price_per_kg: pricePerKg,
        farmer_disbursed_amount: farmerDisbursedAmount,
        buyer_refund_amount: buyerRefundAmount,
        status: finalStatus,
        settlement_notes: notes,
        settled_at: new Date().toISOString()
      }
    });
  } catch (error) {
    await connection.rollback();
    console.error('[POKTAN] Error during B2B settlement:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal memproses settlement kontrak B2B.'
    });
  } finally {
    connection.release();
  }
};

module.exports = {
  getPoktanInfo,
  getMembers,
  createB2BOrder,
  getB2BOrders,
  allocateQuota,
  getMyTasks,
  getNotifications,
  settleB2BOrder
};

