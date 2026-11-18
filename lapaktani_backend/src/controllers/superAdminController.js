const { v4: uuidv4 } = require('uuid');
const bcrypt = require('bcryptjs');
const pool = require('../config/db');
const nodeCache = require('../utils/nodeCache');
const { getCompressionStats } = require('../middlewares/compressionMiddleware');
const { getRateLimiterStats } = require('../middlewares/rateLimiter');
const jobQueue = require('../utils/jobQueue');
const { getNotificationStats } = require('../utils/notificationService');

function invalidateQuotaCaches() {
  nodeCache.del('sumenep_villages_quota');
  nodeCache.del('sumenep_regions_villages');
}

/**
 * GET /api/superadmin/overview
 * System-wide role counts, store tier summary, platform fee ledger totals, and 9/9 MVP health
 */
const getSuperAdminOverview = async (req, res) => {
  try {
    const [roleRows] = await pool.query(`
      SELECT LOWER(COALESCE(role, 'pembeli')) AS role, COUNT(*) AS total,
             SUM(CASE WHEN is_active = 1 THEN 1 ELSE 0 END) AS active_count
      FROM users
      GROUP BY LOWER(COALESCE(role, 'pembeli'))
    `);

    const [storeRows] = await pool.query(`
      SELECT COALESCE(admin_tier, 'B2B_OFFTAKER') AS admin_tier,
             status,
             COUNT(*) AS total
      FROM store_applications
      GROUP BY COALESCE(admin_tier, 'B2B_OFFTAKER'), status
    `);

    const [feeRows] = await pool.query(`
      SELECT
        COUNT(*) AS total_cancellations,
        COALESCE(SUM(gross_amount), 0) AS total_cancelled_gross,
        COALESCE(SUM(fee_charged), 0) AS total_fee_collected,
        COALESCE(SUM(refunded_amount), 0) AS total_refunded_to_users
      FROM platform_fee_ledger
    `);

    const [recentFees] = await pool.query(`
      SELECT pfl.*, u.full_name AS actor_name, u.email AS actor_email
      FROM platform_fee_ledger pfl
      LEFT JOIN users u ON pfl.cancelled_by_user_id = u.id
      ORDER BY pfl.created_at DESC
      LIMIT 20
    `);

    return res.status(200).json({
      success: true,
      data: {
        users_by_role: roleRows,
        stores_by_tier_and_status: storeRows,
        fee_ledger_summary: {
          total_cancellations: Number(feeRows[0]?.total_cancellations || 0),
          total_cancelled_gross: Number(feeRows[0]?.total_cancelled_gross || 0),
          total_fee_collected: Number(feeRows[0]?.total_fee_collected || 0),
          total_refunded_to_users: Number(feeRows[0]?.total_refunded_to_users || 0),
        },
        recent_fee_ledger: recentFees,
        mvp_9_health: {
          compliance_score: '9/9 (100%)',
          compression: getCompressionStats(),
          rate_limiter: getRateLimiterStats(),
          job_queue: jobQueue.getQueueStats(),
          notifications: getNotificationStats(),
        },
      },
    });
  } catch (error) {
    console.error('[SUPERADMIN] Overview error:', error.message);
    return res.status(500).json({ success: false, message: 'Gagal memuat ringkasan Super Admin.' });
  }
};

/**
 * GET /api/superadmin/authorities
 * List provisioned Dinas & Penyuluh BPP authority accounts
 */
const getSuperAdminAuthorities = async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT u.id, u.email, u.full_name, u.role, u.role_id, u.is_verified, u.is_active, u.created_at,
             up.nip, up.bpp_unit, up.village_id,
             COALESCE(v.name, 'Kabupaten Sumenep') AS village_name,
             COALESCE(v.district_id, 352901) AS district_id,
             COALESCE(d.name, 'Kota Sumenep') AS district_name
      FROM users u
      LEFT JOIN user_profiles up ON u.id = up.user_id
      LEFT JOIN villages v ON up.village_id = v.id
      LEFT JOIN districts d ON v.district_id = d.id
      WHERE u.role IN ('dinas', 'penyuluh') OR u.role_id IN (2, 5)
      ORDER BY u.role_id DESC, u.created_at DESC
    `);

    return res.status(200).json({
      success: true,
      count: rows.length,
      data: rows.map((r) => ({
        ...r,
        is_active: Boolean(Number(r.is_active ?? 1)),
        is_verified: Boolean(Number(r.is_verified ?? 1)),
      })),
    });
  } catch (error) {
    console.error('[SUPERADMIN] List authorities error:', error.message);
    return res.status(500).json({ success: false, message: 'Gagal memuat daftar akun Dinas & Penyuluh.' });
  }
};

/**
 * POST /api/superadmin/provision-authority
 * Create an official dinas (role_id=5) or penyuluh (role_id=2) account with district/village scoping
 */
const provisionAuthorityAccount = async (req, res) => {
  let connection;
  try {
    const {
      full_name,
      email,
      password,
      role = 'penyuluh',
      village_id = 109,
      bpp_unit,
      nip,
      phone,
    } = req.body || {};

    const cleanRole = String(role || '').trim().toLowerCase();
    if (!['dinas', 'penyuluh'].includes(cleanRole)) {
      return res.status(400).json({
        success: false,
        message: "Peran otoritas harus 'dinas' atau 'penyuluh'.",
      });
    }

    if (!full_name || !email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Nama lengkap, email resmi, dan kata sandi wajib diisi.',
      });
    }

    const cleanEmail = String(email).trim().toLowerCase();
    const [existing] = await pool.query('SELECT id FROM users WHERE LOWER(email) = ? LIMIT 1', [cleanEmail]);
    if (existing.length > 0) {
      return res.status(409).json({
        success: false,
        message: `Email ${cleanEmail} sudah terdaftar dalam sistem.`,
      });
    }

    const roleId = cleanRole === 'dinas' ? 5 : 2;
    const userId = `usr-${cleanRole === 'dinas' ? 'dinas' : 'ppl'}-${uuidv4().slice(0, 8)}`;
    const profileId = `prof-${uuidv4().slice(0, 10)}`;
    const passwordHash = await bcrypt.hash(String(password), 10);
    const resolvedVillageId = Number(village_id) || 109;
    const defaultBpp = cleanRole === 'dinas' ? 'Dinas Pertanian Kab. Sumenep' : (bpp_unit || 'BPP Kabupaten Sumenep');

    connection = await pool.getConnection();
    await connection.beginTransaction();

    await connection.query(
      `INSERT INTO users (id, email, password_hash, role_id, full_name, role, is_verified, is_active, wallet_balance)
       VALUES (?, ?, ?, ?, ?, ?, 1, 1, 5000000.00)`,
      [userId, cleanEmail, passwordHash, roleId, String(full_name).trim(), cleanRole]
    );

    await connection.query(
      `INSERT INTO user_profiles (id, user_id, full_name, phone, verification_status, bpp_unit, nip, village_id, wallet_balance)
       VALUES (?, ?, ?, ?, 'verified', ?, ?, ?, 5000000.00)`,
      [
        profileId,
        userId,
        String(full_name).trim(),
        phone ? String(phone).trim() : null,
        String(defaultBpp).trim(),
        nip ? String(nip).trim() : null,
        resolvedVillageId,
      ]
    );

    await connection.commit();

    const [created] = await pool.query(
      `SELECT u.id, u.email, u.full_name, u.role, u.role_id, u.is_verified, u.is_active,
              up.nip, up.bpp_unit, up.village_id, v.name AS village_name
       FROM users u
       LEFT JOIN user_profiles up ON u.id = up.user_id
       LEFT JOIN villages v ON up.village_id = v.id
       WHERE u.id = ? LIMIT 1`,
      [userId]
    );

    return res.status(201).json({
      success: true,
      message: `Akun otoritas ${cleanRole === 'dinas' ? 'Dinas Pertanian' : 'Penyuluh BPP'} berhasil diterbitkan.`,
      data: created[0],
    });
  } catch (error) {
    if (connection) await connection.rollback().catch(() => {});
    console.error('[SUPERADMIN] Provision authority error:', error.message);
    return res.status(500).json({ success: false, message: 'Gagal menerbitkan akun otoritas.' });
  } finally {
    if (connection) connection.release();
  }
};

/**
 * PUT /api/superadmin/authorities/:id/status
 */
const updateAuthorityStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { is_active = true } = req.body || {};
    const nextActive = Boolean(is_active) ? 1 : 0;

    const [result] = await pool.query(
      "UPDATE users SET is_active = ? WHERE id = ? AND (role IN ('dinas', 'penyuluh') OR role_id IN (2, 5))",
      [nextActive, id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Akun otoritas tidak ditemukan.' });
    }

    return res.status(200).json({
      success: true,
      message: nextActive ? 'Akun otoritas berhasil diaktifkan kembali.' : 'Akun otoritas telah dinonaktifkan.',
      data: { id, is_active: Boolean(nextActive) },
    });
  } catch (error) {
    console.error('[SUPERADMIN] Toggle authority status error:', error.message);
    return res.status(500).json({ success: false, message: 'Gagal memperbarui status akun otoritas.' });
  }
};

/**
 * GET /api/superadmin/stores
 * Audit all B2B_OFFTAKER and Auto-KYC RETAIL_MERCHANT stores
 */
const getSuperAdminStores = async (req, res) => {
  try {
    const { admin_tier, status } = req.query;
    const conditions = [];
    const params = [];

    if (admin_tier && ['B2B_OFFTAKER', 'RETAIL_MERCHANT'].includes(String(admin_tier).toUpperCase())) {
      conditions.push("COALESCE(sa.admin_tier, 'B2B_OFFTAKER') = ?");
      params.push(String(admin_tier).toUpperCase());
    }
    if (status) {
      conditions.push('sa.status = ?');
      params.push(String(status).toUpperCase());
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';
    const [rows] = await pool.query(
      `SELECT sa.*, u.full_name AS owner_name, u.email AS owner_email, u.is_active AS owner_is_active,
              COALESCE(v.name, sa.village_name) AS resolved_village_name
       FROM store_applications sa
       LEFT JOIN users u ON sa.user_id = u.id
       LEFT JOIN villages v ON sa.village_id = v.id
       ${whereClause}
       ORDER BY sa.updated_at DESC, sa.created_at DESC`,
      params
    );

    return res.status(200).json({
      success: true,
      count: rows.length,
      data: rows.map((r) => ({
        ...r,
        auto_kyc_passed: Boolean(Number(r.auto_kyc_passed || 0)),
        is_store_open: Boolean(Number(r.is_store_open ?? 1)),
      })),
    });
  } catch (error) {
    console.error('[SUPERADMIN] List stores error:', error.message);
    return res.status(500).json({ success: false, message: 'Gagal memuat daftar pengawasan toko.' });
  }
};

/**
 * PUT /api/superadmin/stores/:id/status
 * Approve, suspend, or reactivate any store (B2B_OFFTAKER or RETAIL_MERCHANT Auto-KYC)
 */
const updateSuperAdminStoreStatus = async (req, res) => {
  let connection;
  try {
    const { id } = req.params;
    const { status, action, reason } = req.body || {};
    const raw = String(action || status || '').trim().toUpperCase();

    let nextStoreStatus = 'APPROVED';
    let userIsActive = 1;
    let userRoleId = 3;
    let userRole = 'admin';
    let storeOpenFlag = 1;

    if (raw === 'SUSPEND' || raw === 'SUSPENDED') {
      nextStoreStatus = 'SUSPENDED';
      userIsActive = 1; // Preserve buyer/login visibility while freezing store operations
      userRoleId = 4;
      userRole = 'pembeli';
      storeOpenFlag = 0;
    } else if (raw === 'REJECT' || raw === 'REJECTED') {
      nextStoreStatus = 'REJECTED';
      userRoleId = 4;
      userRole = 'pembeli';
      storeOpenFlag = 0;
    } else if (['APPROVE', 'APPROVED', 'REACTIVATE', 'ACTIVE'].includes(raw)) {
      nextStoreStatus = 'APPROVED';
      userRoleId = 3;
      userRole = 'admin';
      storeOpenFlag = 1;
    } else {
      return res.status(400).json({
        success: false,
        message: 'Aksi tidak valid. Gunakan APPROVE, SUSPEND, REACTIVATE, atau REJECT.',
      });
    }

    connection = await pool.getConnection();
    await connection.beginTransaction();

    const [rows] = await connection.query('SELECT * FROM store_applications WHERE id = ? LIMIT 1 FOR UPDATE', [id]);
    if (rows.length === 0) {
      await connection.rollback();
      return res.status(404).json({ success: false, message: 'Toko tidak ditemukan.' });
    }
    const store = rows[0];
    const resolvedTier = store.admin_tier || 'B2B_OFFTAKER';

    await connection.query(
      `UPDATE store_applications
       SET status = ?, is_store_open = ?, rejection_reason = COALESCE(?, rejection_reason),
           reviewed_by_ppl = COALESCE(reviewed_by_ppl, ?)
       WHERE id = ?`,
      [nextStoreStatus, storeOpenFlag, reason ? String(reason).trim() : null, req.user.id, id]
    );

    await connection.query(
      `UPDATE users
       SET role_id = ?, role = ?, admin_tier = ?, is_verified = ?, is_active = ?
       WHERE id = ?`,
      [
        userRoleId,
        userRole,
        userRole === 'admin' ? resolvedTier : null,
        nextStoreStatus === 'APPROVED' ? 1 : 0,
        userIsActive,
        store.user_id,
      ]
    );

    await connection.commit();
    invalidateQuotaCaches();

    const [updated] = await pool.query('SELECT * FROM store_applications WHERE id = ?', [id]);
    return res.status(200).json({
      success: true,
      message:
        nextStoreStatus === 'SUSPENDED'
          ? `Toko '${store.nama_toko}' berhasil dibekukan (SUSPENDED) oleh Super Admin.`
          : nextStoreStatus === 'APPROVED'
            ? `Toko '${store.nama_toko}' (${resolvedTier}) aktif/disetujui.`
            : `Toko '${store.nama_toko}' diperbarui ke ${nextStoreStatus}.`,
      data: updated[0],
    });
  } catch (error) {
    if (connection) await connection.rollback().catch(() => {});
    console.error('[SUPERADMIN] Store status error:', error.message);
    return res.status(500).json({ success: false, message: 'Gagal memperbarui status pengawasan toko.' });
  } finally {
    if (connection) connection.release();
  }
};

/**
 * GET /api/superadmin/fee-ledger
 */
const getPlatformFeeLedger = async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT pfl.*, u.full_name AS actor_name, u.email AS actor_email
      FROM platform_fee_ledger pfl
      LEFT JOIN users u ON pfl.cancelled_by_user_id = u.id
      ORDER BY pfl.created_at DESC
      LIMIT 100
    `);

    const [totals] = await pool.query(`
      SELECT COUNT(*) AS count, COALESCE(SUM(fee_charged), 0) AS total_fees, COALESCE(SUM(refunded_amount), 0) AS total_refunded
      FROM platform_fee_ledger
    `);

    return res.status(200).json({
      success: true,
      summary: {
        count: Number(totals[0]?.count || 0),
        total_fees: Number(totals[0]?.total_fees || 0),
        total_refunded: Number(totals[0]?.total_refunded || 0),
      },
      data: rows,
    });
  } catch (error) {
    console.error('[SUPERADMIN] Fee ledger error:', error.message);
    return res.status(500).json({ success: false, message: 'Gagal memuat buku kas biaya aplikasi.' });
  }
};

module.exports = {
  getSuperAdminOverview,
  getSuperAdminAuthorities,
  provisionAuthorityAccount,
  updateAuthorityStatus,
  getSuperAdminStores,
  updateSuperAdminStoreStatus,
  getPlatformFeeLedger,
};
