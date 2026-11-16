const { v4: uuidv4 } = require('uuid');
const pool = require('../config/db');
const redisClient = require('../config/redis');
const {
  generateRagDecision,
  dispatchRagDecision,
  getDecisionReports,
} = require('./penyuluhController');

async function resolveUserSummary(userId) {
  const [rows] = await pool.query(
    `SELECT u.id, u.full_name, u.email, u.role_id, u.role,
            up.village_id, COALESCE(v.name, 'Dungkek') AS village_name,
            COALESCE(v.district_id, 352917) AS district_id,
            fp.farmer_group_id
     FROM users u
     LEFT JOIN user_profiles up ON u.id = up.user_id
     LEFT JOIN villages v ON up.village_id = v.id
     LEFT JOIN farmer_profiles fp ON u.id = fp.user_id
     WHERE u.id = ? LIMIT 1`,
    [userId]
  );
  return rows[0] || null;
}

async function resolveVillagesWithQuota() {
  const [rows] = await pool.query(`
    SELECT
      v.id,
      v.district_id,
      v.name,
      COALESCE(d.name, 'Sumenep') AS district_name,
      COALESCE(v.postal_code, '69471') AS postal_code,
      COALESCE(v.is_store_quota_enabled, 0) AS is_store_quota_enabled,
      COALESCE(v.max_stores_quota, 5) AS max_stores_quota,
      COALESCE(sa.approved_count, 0) AS approved_stores_count,
      COALESCE(sa.pending_count, 0) AS pending_stores_count
    FROM villages v
    LEFT JOIN districts d ON v.district_id = d.id
    LEFT JOIN (
      SELECT village_id,
             SUM(CASE WHEN status = 'APPROVED' THEN 1 ELSE 0 END) AS approved_count,
             SUM(CASE WHEN status = 'PENDING_PPL' THEN 1 ELSE 0 END) AS pending_count
      FROM store_applications
      GROUP BY village_id
    ) sa ON v.id = sa.village_id
    ORDER BY v.id ASC
  `);

  return rows.map((r) => {
    const quotaEnabled = Boolean(Number(r.is_store_quota_enabled));
    const maxQuota = Number(r.max_stores_quota || 5);
    const approvedCount = Number(r.approved_stores_count || 0);
    return {
      ...r,
      is_store_quota_enabled: quotaEnabled,
      max_stores_quota: maxQuota,
      approved_stores_count: approvedCount,
      pending_stores_count: Number(r.pending_stores_count || 0),
      is_quota_full: quotaEnabled && approvedCount >= maxQuota,
      remaining_quota: quotaEnabled ? Math.max(0, maxQuota - approvedCount) : null,
    };
  });
}

// ============================================================================
// 1. DINAS PERTANIAN CONTROLLERS
// ============================================================================

const getDinasGisOverview = async (req, res) => {
  try {
    const [plots] = await pool.query('SELECT * FROM monitoring_lahan ORDER BY created_at DESC LIMIT 100');
    const [fertilizerRows] = await pool.query(
      'SELECT * FROM fertilizer_allocations ORDER BY updated_at DESC LIMIT 50'
    );
    const villages = await resolveVillagesWithQuota();

    return res.status(200).json({
      success: true,
      data: {
        plots,
        villages,
        fertilizer_allocations: fertilizerRows,
      },
    });
  } catch (error) {
    console.error('[DINAS] Error loading GIS overview:', error.message);
    return res.status(500).json({ success: false, message: 'Gagal memuat ringkasan GIS Dinas.' });
  }
};

const getFertilizerSubsidies = async (req, res) => {
  try {
    const { village_id, status } = req.query;
    const conditions = [];
    const params = [];

    if (village_id) {
      conditions.push('village_id = ?');
      params.push(Number(village_id));
    }
    if (status) {
      conditions.push('status = ?');
      params.push(String(status).toUpperCase());
    }

    const where = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';
    const [rows] = await pool.query(
      `SELECT * FROM fertilizer_allocations ${where} ORDER BY updated_at DESC, created_at DESC LIMIT 100`,
      params
    );

    return res.status(200).json({ success: true, count: rows.length, data: rows });
  } catch (error) {
    console.error('[FERTILIZER] Error loading allocations:', error.message);
    return res.status(500).json({ success: false, message: 'Gagal memuat data pupuk subsidi.' });
  }
};

const proposeFertilizerSubsidy = async (req, res) => {
  try {
    const userId = req.user.id;
    const {
      village_id = 109,
      village_name,
      jenis_pupuk,
      jumlah_ton = 2.0,
      alasan_kebutuhan,
      titik_ambil_desa,
    } = req.body || {};

    if (!jenis_pupuk || String(jenis_pupuk).trim().length === 0) {
      return res.status(400).json({ success: false, message: 'Jenis pupuk wajib diisi.' });
    }

    const [vRows] = await pool.query('SELECT id, district_id, name FROM villages WHERE id = ? LIMIT 1', [
      Number(village_id),
    ]);
    const vInfo = vRows[0] || { id: Number(village_id), district_id: 352917, name: village_name || 'Dungkek' };
    const sender = await resolveUserSummary(userId);
    const allocId = `fert-${uuidv4().slice(0, 10)}`;

    await pool.query(
      `INSERT INTO fertilizer_allocations
       (id, village_id, district_id, village_name, penyuluh_id, penyuluh_name, jenis_pupuk, jumlah_ton, alasan_kebutuhan, status, titik_ambil_desa)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'USULAN_PPL', ?)`,
      [
        allocId,
        vInfo.id,
        vInfo.district_id,
        village_name || vInfo.name,
        userId,
        sender?.full_name || 'Penyuluh BPP Sumenep',
        String(jenis_pupuk).trim(),
        Math.max(0.1, Number(jumlah_ton) || 1),
        alasan_kebutuhan ? String(alasan_kebutuhan).trim() : null,
        titik_ambil_desa ? String(titik_ambil_desa).trim() : null,
      ]
    );

    const [created] = await pool.query('SELECT * FROM fertilizer_allocations WHERE id = ?', [allocId]);
    return res.status(201).json({
      success: true,
      message: 'Usulan kebutuhan pupuk subsidi desa berhasil dikirim ke Dinas Pertanian.',
      data: created[0],
    });
  } catch (error) {
    console.error('[FERTILIZER] Error proposing allocation:', error.message);
    return res.status(500).json({ success: false, message: 'Gagal mengajukan pupuk subsidi.' });
  }
};

const confirmFertilizerSubsidy = async (req, res) => {
  try {
    const {
      allocation_id,
      village_id = 109,
      village_name,
      jenis_pupuk,
      jumlah_ton = 2.5,
      titik_ambil_desa,
      catatan_dinas,
      status = 'KONFIRMASI_DINAS',
    } = req.body || {};

    const validStatuses = ['USULAN_PPL', 'KONFIRMASI_DINAS', 'DIKIRIM_DINAS', 'DITERIMA_DESA'];
    const targetStatus = validStatuses.includes(String(status).toUpperCase())
      ? String(status).toUpperCase()
      : 'KONFIRMASI_DINAS';

    if (allocation_id) {
      await pool.query(
        `UPDATE fertilizer_allocations
         SET status = ?,
             jumlah_ton = COALESCE(?, jumlah_ton),
             titik_ambil_desa = COALESCE(NULLIF(?, ''), titik_ambil_desa),
             catatan_dinas = COALESCE(NULLIF(?, ''), catatan_dinas)
         WHERE id = ?`,
        [targetStatus, Number(jumlah_ton) || null, titik_ambil_desa || '', catatan_dinas || '', allocation_id]
      );

      const [rows] = await pool.query('SELECT * FROM fertilizer_allocations WHERE id = ?', [allocation_id]);
      if (rows.length === 0) {
        return res.status(404).json({ success: false, message: 'Data alokasi pupuk tidak ditemukan.' });
      }
      return res.status(200).json({
        success: true,
        message: 'Alokasi pupuk subsidi berhasil dikonfirmasi Dinas Pertanian.',
        data: rows[0],
      });
    }

    const [vRows] = await pool.query('SELECT id, district_id, name FROM villages WHERE id = ? LIMIT 1', [
      Number(village_id),
    ]);
    const vInfo = vRows[0] || { id: Number(village_id), district_id: 352917, name: village_name || 'Dungkek' };
    const [pplRows] = await pool.query(
      "SELECT id, full_name FROM users WHERE role = 'penyuluh' OR role_id = 2 LIMIT 1"
    );
    const penyuluhId = pplRows[0]?.id || 'usr-ppl-03';
    const penyuluhName = pplRows[0]?.full_name || 'Ir. Ahmad Hidayat, M.Agr.';
    const allocId = `fert-${uuidv4().slice(0, 10)}`;

    await pool.query(
      `INSERT INTO fertilizer_allocations
       (id, village_id, district_id, village_name, penyuluh_id, penyuluh_name, jenis_pupuk, jumlah_ton, alasan_kebutuhan, status, titik_ambil_desa, catatan_dinas)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'Alokasi langsung oleh Dinas Pertanian Kab. Sumenep.', ?, ?, ?)`,
      [
        allocId,
        vInfo.id,
        vInfo.district_id,
        village_name || vInfo.name,
        penyuluhId,
        penyuluhName,
        jenis_pupuk ? String(jenis_pupuk).trim() : 'NPK Phonska & Dolomit Subsidi',
        Math.max(0.1, Number(jumlah_ton) || 2.5),
        targetStatus,
        titik_ambil_desa || `Balai Desa / Poktan ${vInfo.name}`,
        catatan_dinas || 'Dikonfirmasi Dinas Pertanian & siap koordinasi dengan PPL desa.',
      ]
    );

    const [created] = await pool.query('SELECT * FROM fertilizer_allocations WHERE id = ?', [allocId]);
    return res.status(201).json({
      success: true,
      message: 'Distribusi pupuk subsidi baru berhasil dibuat oleh Dinas.',
      data: created[0],
    });
  } catch (error) {
    console.error('[DINAS_FERTILIZER] Error confirming subsidy:', error.message);
    return res.status(500).json({ success: false, message: 'Gagal mengonfirmasi pupuk subsidi.' });
  }
};

const dispatchFertilizerSubsidy = async (req, res) => {
  try {
    const { id } = req.params;
    const { status = 'DIKIRIM_DINAS', jumlah_ton, titik_ambil_desa, catatan_dinas } = req.body || {};
    const validStatuses = ['USULAN_PPL', 'KONFIRMASI_DINAS', 'DIKIRIM_DINAS', 'DITERIMA_DESA'];
    const nextStatus = validStatuses.includes(String(status).toUpperCase())
      ? String(status).toUpperCase()
      : 'DIKIRIM_DINAS';

    const [existing] = await pool.query('SELECT * FROM fertilizer_allocations WHERE id = ? LIMIT 1', [id]);
    if (existing.length === 0) {
      return res.status(404).json({ success: false, message: 'Alokasi pupuk tidak ditemukan.' });
    }

    await pool.query(
      `UPDATE fertilizer_allocations
       SET status = ?,
           jumlah_ton = COALESCE(?, jumlah_ton),
           titik_ambil_desa = COALESCE(NULLIF(?, ''), titik_ambil_desa),
           catatan_dinas = COALESCE(NULLIF(?, ''), catatan_dinas)
       WHERE id = ?`,
      [nextStatus, jumlah_ton ? Number(jumlah_ton) : null, titik_ambil_desa || '', catatan_dinas || '', id]
    );

    const [updated] = await pool.query('SELECT * FROM fertilizer_allocations WHERE id = ?', [id]);
    const row = updated[0];

    // Notify Penyuluh when Dinas updates, and auto-post announcement when received by village
    try {
      if (nextStatus === 'DITERIMA_DESA') {
        await pool.query(
          `INSERT INTO village_forum_posts
           (id, village_id, village_name, author_id, author_name, author_role, kategori, judul, isi_pesan, titik_ambil_pupuk)
           VALUES (?, ?, ?, ?, ?, 'penyuluh', 'INFO_PUPUK', ?, ?, ?)`,
          [
            `vf-${uuidv4().slice(0, 10)}`,
            row.village_id,
            row.village_name || 'Sumenep',
            req.user?.id || row.penyuluh_id,
            req.user?.full_name || row.penyuluh_name,
            `Pupuk Subsidi ${row.jenis_pupuk} (${row.jumlah_ton} Ton) Telah Tiba di Desa ${row.village_name}`,
            `Petani anggota Poktan Desa ${row.village_name} dapat mengambil alokasi pupuk subsidi dengan membawa KTP asli. ${row.catatan_dinas || ''}`.trim(),
            row.titik_ambil_desa || `Balai Poktan Desa ${row.village_name}`,
          ]
        );
      } else {
        await pool.query(
          `INSERT INTO notifications (id, user_id, title, message, type, reference_id, is_read)
           VALUES (?, ?, ?, ?, 'fertilizer_dispatch', ?, 0)`,
          [
            `ntf-${uuidv4().slice(0, 12)}`,
            row.penyuluh_id,
            `Update Pupuk Desa ${row.village_name}: ${nextStatus}`,
            `${row.jenis_pupuk} (${row.jumlah_ton} Ton) — Titik ambil: ${row.titik_ambil_desa || 'Balai Desa'}.`,
            row.id,
          ]
        );
      }
    } catch (_) {}

    return res.status(200).json({
      success: true,
      message: `Status distribusi pupuk berhasil diperbarui ke ${nextStatus}.`,
      data: row,
    });
  } catch (error) {
    console.error('[FERTILIZER_DISPATCH] Error updating:', error.message);
    return res.status(500).json({ success: false, message: 'Gagal memperbarui distribusi pupuk.' });
  }
};

// ============================================================================
// 2. PENYULUH: STORE QUOTA, STORE APPROVAL & SCOPED FORUMS
// ============================================================================

const getStoreApplicationsForPpl = async (req, res) => {
  try {
    const { village_id, include_frozen } = req.query;
    const conditions = [];
    const params = [];

    if (include_frozen !== 'true') {
      conditions.push("sa.status != 'DRAFT_FROZEN'");
    }
    if (village_id) {
      conditions.push('sa.village_id = ?');
      params.push(Number(village_id));
    }

    const where = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';
    const [rows] = await pool.query(
      `SELECT sa.*, u.full_name AS applicant_name, u.email AS applicant_email,
              COALESCE(v.name, sa.village_name) AS resolved_village_name,
              COALESCE(v.is_store_quota_enabled, 0) AS is_store_quota_enabled,
              COALESCE(v.max_stores_quota, 5) AS max_stores_quota
       FROM store_applications sa
       LEFT JOIN users u ON sa.user_id = u.id
       LEFT JOIN villages v ON sa.village_id = v.id
       ${where}
       ORDER BY CASE WHEN sa.status = 'PENDING_PPL' THEN 0 ELSE 1 END, sa.updated_at DESC`,
      params
    );

    const villages = await resolveVillagesWithQuota();

    return res.status(200).json({
      success: true,
      count: rows.length,
      data: rows,
      villages,
    });
  } catch (error) {
    console.error('[PPL_STORE] Error listing applications:', error.message);
    return res.status(500).json({ success: false, message: 'Gagal memuat pengajuan pembukaan toko.' });
  }
};

const verifyStoreApplication = async (req, res) => {
  let connection;
  try {
    const { id } = req.params;
    const { status, rejection_reason } = req.body || {};
    const nextStatus = String(status || '').toUpperCase();

    if (!['APPROVED', 'REJECTED'].includes(nextStatus)) {
      return res.status(400).json({
        success: false,
        message: 'Status verifikasi harus APPROVED atau REJECTED.',
      });
    }

    connection = await pool.getConnection();
    await connection.beginTransaction();

    const [appRows] = await connection.query('SELECT * FROM store_applications WHERE id = ? FOR UPDATE', [id]);
    if (appRows.length === 0) {
      await connection.rollback();
      return res.status(404).json({ success: false, message: 'Pengajuan toko tidak ditemukan.' });
    }
    const appRow = appRows[0];

    if (nextStatus === 'APPROVED') {
      const [vRows] = await connection.query(
        'SELECT is_store_quota_enabled, max_stores_quota, name FROM villages WHERE id = ? LIMIT 1',
        [appRow.village_id]
      );
      if (vRows.length > 0 && Number(vRows[0].is_store_quota_enabled) === 1) {
        const [cntRows] = await connection.query(
          "SELECT COUNT(*) AS cnt FROM store_applications WHERE village_id = ? AND status = 'APPROVED' AND id != ?",
          [appRow.village_id, id]
        );
        const currentApproved = Number(cntRows[0]?.cnt || 0);
        const maxQuota = Number(vRows[0].max_stores_quota || 5);
        if (currentApproved >= maxQuota) {
          await connection.rollback();
          return res.status(409).json({
            success: false,
            code: 'VILLAGE_STORE_QUOTA_FULL',
            message: `Kuota toko di Desa ${vRows[0].name} sudah penuh (${currentApproved}/${maxQuota}). Nonaktifkan atau naikkan kuota terlebih dahulu.`,
          });
        }
      }

      // Promote applicant to role admin (Admin Toko)
      await connection.query("UPDATE users SET role_id = 3, role = 'admin', is_verified = 1 WHERE id = ?", [
        appRow.user_id,
      ]);
    }

    await connection.query(
      'UPDATE store_applications SET status = ?, reviewed_by_ppl = ?, rejection_reason = ? WHERE id = ?',
      [nextStatus, req.user.id, rejection_reason ? String(rejection_reason).trim() : null, id]
    );

    await connection.commit();
    const [updated] = await pool.query('SELECT * FROM store_applications WHERE id = ?', [id]);
    return res.status(200).json({
      success: true,
      message:
        nextStatus === 'APPROVED'
          ? `Toko '${appRow.nama_toko}' disetujui! Pemilik kini aktif sebagai Admin Toko.`
          : `Pengajuan toko '${appRow.nama_toko}' ditolak.`,
      data: updated[0],
    });
  } catch (error) {
    if (connection) await connection.rollback().catch(() => {});
    console.error('[PPL_STORE] Error verifying store:', error.message);
    return res.status(500).json({ success: false, message: 'Gagal memproses verifikasi toko.' });
  } finally {
    if (connection) connection.release();
  }
};

const updateVillageStoreQuota = async (req, res) => {
  try {
    const { village_id = 109, is_store_quota_enabled, max_stores_quota, postal_code } = req.body || {};

    const enabledFlag = is_store_quota_enabled === true || Number(is_store_quota_enabled) === 1 ? 1 : 0;
    const maxQuotaNum = Math.max(1, Math.min(100, parseInt(max_stores_quota || 5, 10)));

    await pool.query(
      `UPDATE villages
       SET is_store_quota_enabled = ?,
           max_stores_quota = ?,
           postal_code = COALESCE(NULLIF(?, ''), postal_code)
       WHERE id = ?`,
      [enabledFlag, maxQuotaNum, postal_code ? String(postal_code).trim() : '', Number(village_id)]
    );

    const villages = await resolveVillagesWithQuota();
    const updatedVillage = villages.find((v) => Number(v.id) === Number(village_id)) || null;

    return res.status(200).json({
      success: true,
      message: enabledFlag
        ? `Pembatasan kuota toko desa diaktifkan (Maks. ${maxQuotaNum} toko).`
        : 'Pembatasan kuota toko desa dinonaktifkan.',
      data: updatedVillage,
      villages,
    });
  } catch (error) {
    console.error('[PPL_QUOTA] Error updating village store quota:', error.message);
    return res.status(500).json({ success: false, message: 'Gagal memperbarui pengaturan kuota toko desa.' });
  }
};

const getInterPplForum = async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM ppl_forum_posts ORDER BY created_at DESC LIMIT 50');
    return res.status(200).json({ success: true, count: rows.length, data: rows });
  } catch (error) {
    console.error('[PPL_FORUM] Error fetching inter-ppl posts:', error.message);
    return res.status(500).json({ success: false, message: 'Gagal memuat forum antar penyuluh.' });
  }
};

const createInterPplForumPost = async (req, res) => {
  try {
    const { topik, komoditas = 'Hortikultura', isi_diskusi, rekomendasi_teknis, bpp_kecamatan } = req.body || {};
    if (!topik || !isi_diskusi) {
      return res.status(400).json({ success: false, message: 'Topik dan isi diskusi wajib diisi.' });
    }

    const user = await resolveUserSummary(req.user.id);
    const postId = `ppl-post-${uuidv4().slice(0, 10)}`;

    await pool.query(
      `INSERT INTO ppl_forum_posts
       (id, penyuluh_id, penyuluh_name, bpp_kecamatan, topik, komoditas, isi_diskusi, rekomendasi_teknis)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        postId,
        req.user.id,
        user?.full_name || 'Penyuluh BPP Sumenep',
        bpp_kecamatan || `BPP ${user?.village_name || 'Sumenep'}`,
        String(topik).trim(),
        String(komoditas).trim(),
        String(isi_diskusi).trim(),
        rekomendasi_teknis ? String(rekomendasi_teknis).trim() : null,
      ]
    );

    const [created] = await pool.query('SELECT * FROM ppl_forum_posts WHERE id = ?', [postId]);
    return res.status(201).json({
      success: true,
      message: 'Diskusi berhasil dipublikasikan ke Forum Antar-Penyuluh.',
      data: created[0],
    });
  } catch (error) {
    console.error('[PPL_FORUM] Error creating post:', error.message);
    return res.status(500).json({ success: false, message: 'Gagal membuat diskusi antar penyuluh.' });
  }
};

const getVillageForum = async (req, res) => {
  try {
    const callerRole = String(req.user?.role || '').toLowerCase();
    const userSummary = await resolveUserSummary(req.user.id);
    const requestedVillageId = req.query.village_id ? Number(req.query.village_id) : null;

    // Petani is strictly scoped to their own registered village_id
    const effectiveVillageId =
      callerRole === 'petani' ? Number(userSummary?.village_id || 109) : requestedVillageId || Number(userSummary?.village_id || 109);

    const [rows] = await pool.query(
      'SELECT * FROM village_forum_posts WHERE village_id = ? ORDER BY created_at DESC LIMIT 60',
      [effectiveVillageId]
    );

    return res.status(200).json({
      success: true,
      village_id: effectiveVillageId,
      count: rows.length,
      data: rows,
    });
  } catch (error) {
    console.error('[VILLAGE_FORUM] Error loading posts:', error.message);
    return res.status(500).json({ success: false, message: 'Gagal memuat forum privat desa.' });
  }
};

const createVillageForumPost = async (req, res) => {
  try {
    const callerRole = String(req.user?.role || 'petani').toLowerCase();
    const userSummary = await resolveUserSummary(req.user.id);
    const { village_id, kategori = 'TANYA_JAWAB', judul, isi_pesan, titik_ambil_pupuk } = req.body || {};

    if (!judul || !isi_pesan) {
      return res.status(400).json({ success: false, message: 'Judul dan isi pesan forum desa wajib diisi.' });
    }

    const effectiveVillageId =
      callerRole === 'petani' ? Number(userSummary?.village_id || 109) : Number(village_id || userSummary?.village_id || 109);

    const [vRows] = await pool.query('SELECT id, name FROM villages WHERE id = ? LIMIT 1', [effectiveVillageId]);
    const villageName = vRows[0]?.name || userSummary?.village_name || 'Dungkek';

    const allowedRoles = ['penyuluh', 'petani', 'admin'];
    const authorRole = allowedRoles.includes(callerRole) ? callerRole : 'petani';
    const allowedCategories = ['INFO_PUPUK', 'TANYA_JAWAB', 'PERINGATAN_HAMA', 'ARAHAN_TANAM'];
    const normalizedCat = allowedCategories.includes(String(kategori).toUpperCase())
      ? String(kategori).toUpperCase()
      : 'TANYA_JAWAB';

    const postId = `vf-${uuidv4().slice(0, 10)}`;
    await pool.query(
      `INSERT INTO village_forum_posts
       (id, village_id, village_name, author_id, author_name, author_role, kategori, judul, isi_pesan, titik_ambil_pupuk)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        postId,
        effectiveVillageId,
        villageName,
        req.user.id,
        userSummary?.full_name || 'Pengguna Desa',
        authorRole,
        normalizedCat,
        String(judul).trim(),
        String(isi_pesan).trim(),
        titik_ambil_pupuk ? String(titik_ambil_pupuk).trim() : null,
      ]
    );

    const [created] = await pool.query('SELECT * FROM village_forum_posts WHERE id = ?', [postId]);
    return res.status(201).json({
      success: true,
      message: `Pesan berhasil dikirim ke Forum Privat Desa ${villageName}.`,
      data: created[0],
    });
  } catch (error) {
    console.error('[VILLAGE_FORUM] Error creating post:', error.message);
    return res.status(500).json({ success: false, message: 'Gagal mengirim pesan ke forum desa.' });
  }
};

// ============================================================================
// 3. PETANI HARVEST BROADCASTS & TRANSPARENT PURCHASE OFFERS
// ============================================================================

const getFarmerHarvestReports = async (req, res) => {
  try {
    const callerRole = String(req.user?.role || '').toLowerCase();
    const { status_tanam, village_id } = req.query;
    const conditions = [];
    const params = [];

    if (callerRole === 'petani') {
      const userSummary = await resolveUserSummary(req.user.id);
      conditions.push('(farmer_id = ? OR village_id = ?)');
      params.push(req.user.id, Number(userSummary?.village_id || 109));
    } else if (village_id) {
      conditions.push('village_id = ?');
      params.push(Number(village_id));
    }

    if (status_tanam) {
      conditions.push('status_tanam = ?');
      params.push(String(status_tanam).toUpperCase());
    }

    const where = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';
    const [rows] = await pool.query(`SELECT * FROM harvest_reports ${where} ORDER BY created_at DESC LIMIT 60`, params);
    return res.status(200).json({ success: true, count: rows.length, data: rows });
  } catch (error) {
    console.error('[HARVEST_REPORT] Error fetching reports:', error.message);
    return res.status(500).json({ success: false, message: 'Gagal memuat laporan panen petani.' });
  }
};

const createFarmerHarvestReport = async (req, res) => {
  try {
    const userSummary = await resolveUserSummary(req.user.id);
    const {
      komoditas,
      status_tanam = 'HAMPIR_PANEN',
      estimasi_panen_date,
      estimasi_berat_kg = 0,
      catatan,
      foto_url,
      poktan_id,
    } = req.body || {};

    if (!komoditas || String(komoditas).trim().length === 0) {
      return res.status(400).json({ success: false, message: 'Komoditas tanaman wajib diisi.' });
    }

    // Enforce single Poktan membership per farmer
    let resolvedPoktanId = userSummary?.farmer_group_id || null;
    if (poktan_id && resolvedPoktanId && String(poktan_id) !== String(resolvedPoktanId)) {
      return res.status(409).json({
        success: false,
        code: 'MAX_ONE_POKTAN',
        message: 'Setiap petani maksimal terdaftar pada 1 Poktan resmi, namun bebas menjual panen ke banyak Admin Toko.',
      });
    }
    if (!resolvedPoktanId && poktan_id) {
      resolvedPoktanId = String(poktan_id);
      await pool.query(
        'INSERT INTO farmer_profiles (user_id, farmer_group_id) VALUES (?, ?) ON DUPLICATE KEY UPDATE farmer_group_id = COALESCE(farmer_group_id, VALUES(farmer_group_id))',
        [req.user.id, resolvedPoktanId]
      );
    }

    const validStatuses = ['MULAI_TANAM', 'HAMPIR_PANEN', 'SIAP_PANEN', 'LAPOR_HAMA', 'MINTA_SARAN'];
    const normalizedStatus = validStatuses.includes(String(status_tanam).toUpperCase())
      ? String(status_tanam).toUpperCase()
      : 'HAMPIR_PANEN';

    const villageId = Number(userSummary?.village_id || 109);
    const districtId = Number(userSummary?.district_id || 352917);
    const villageName = userSummary?.village_name || 'Dungkek';
    const reportId = `hr-${uuidv4().slice(0, 10)}`;

    await pool.query(
      `INSERT INTO harvest_reports
       (id, farmer_id, farmer_name, poktan_id, village_id, village_name, district_id, komoditas, status_tanam, estimasi_panen_date, estimasi_berat_kg, catatan, foto_url)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        reportId,
        req.user.id,
        userSummary?.full_name || 'Petani Mitra',
        resolvedPoktanId,
        villageId,
        villageName,
        districtId,
        String(komoditas).trim(),
        normalizedStatus,
        estimasi_panen_date || null,
        Math.max(0, Number(estimasi_berat_kg) || 0),
        catatan ? String(catatan).trim() : null,
        foto_url || null,
      ]
    );

    // Broadcast harvest readiness to Penyuluh & Store Admins
    if (['MULAI_TANAM', 'HAMPIR_PANEN', 'SIAP_PANEN'].includes(normalizedStatus)) {
      try {
        const [recipients] = await pool.query(
          "SELECT id FROM users WHERE role IN ('penyuluh','admin') OR role_id IN (2, 3) LIMIT 20"
        );
        for (const r of recipients) {
          await pool.query(
            `INSERT INTO notifications (id, user_id, title, message, type, reference_id, is_read)
             VALUES (?, ?, ?, ?, 'harvest_broadcast', ?, 0)`,
            [
              `ntf-${uuidv4().slice(0, 12)}`,
              r.id,
              `Siaran ${normalizedStatus}: ${String(komoditas).trim()}`,
              `${userSummary?.full_name || 'Petani'} (${villageName}) melaporkan ${estimasi_berat_kg || 0} kg.`,
              reportId,
            ]
          );
        }
      } catch (_) {}
    }

    const [created] = await pool.query('SELECT * FROM harvest_reports WHERE id = ?', [reportId]);
    return res.status(201).json({
      success: true,
      message: 'Laporan tanam & estimasi panen berhasil disiarkan ke Penyuluh dan Admin Toko sekitar.',
      data: created[0],
    });
  } catch (error) {
    console.error('[HARVEST_REPORT] Error creating report:', error.message);
    return res.status(500).json({ success: false, message: 'Gagal menyimpan laporan tanam petani.' });
  }
};

const getFarmerPurchaseOffers = async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT * FROM harvest_purchase_offers
       WHERE farmer_id = ? OR status != 'TRADITIONAL_WALKIN'
       ORDER BY CASE WHEN farmer_id = ? THEN 0 ELSE 1 END, updated_at DESC LIMIT 50`,
      [req.user.id, req.user.id]
    );
    return res.status(200).json({ success: true, count: rows.length, data: rows });
  } catch (error) {
    console.error('[OFFER] Error fetching farmer offers:', error.message);
    return res.status(500).json({ success: false, message: 'Gagal memuat tawaran pembelian panen.' });
  }
};

const respondToPurchaseOffer = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body || {};
    const nextStatus = String(status || '').toUpperCase();

    if (!['ACCEPTED_CONTRACT', 'REJECTED'].includes(nextStatus)) {
      return res.status(400).json({
        success: false,
        message: 'Pilihan status harus ACCEPTED_CONTRACT atau REJECTED.',
      });
    }

    const [existing] = await pool.query('SELECT * FROM harvest_purchase_offers WHERE id = ? LIMIT 1', [id]);
    if (existing.length === 0) {
      return res.status(404).json({ success: false, message: 'Tawaran pembelian panen tidak ditemukan.' });
    }

    await pool.query('UPDATE harvest_purchase_offers SET status = ? WHERE id = ?', [nextStatus, id]);
    const [updated] = await pool.query('SELECT * FROM harvest_purchase_offers WHERE id = ?', [id]);
    return res.status(200).json({
      success: true,
      message:
        nextStatus === 'ACCEPTED_CONTRACT'
          ? 'Kontrak panen berhasil disepakati! Admin Toko akan melakukan penimbangan ulang di lokasi.'
          : 'Tawaran pembelian ditolak.',
      data: updated[0],
    });
  } catch (error) {
    console.error('[OFFER] Error responding to offer:', error.message);
    return res.status(500).json({ success: false, message: 'Gagal merespon tawaran pembelian.' });
  }
};

// ============================================================================
// 4. STORE REGISTRATION (2-STEP + QUOTA), STORE SETTINGS & HARVEST ACQUISITION
// ============================================================================

const getSumenepRegionsAndVillages = async (req, res) => {
  try {
    const [districts] = await pool.query(
      `SELECT id, regency_id, name FROM districts WHERE regency_id = 3529 ORDER BY name ASC`
    );
    const villages = await resolveVillagesWithQuota();

    return res.status(200).json({
      success: true,
      districts,
      villages,
    });
  } catch (error) {
    console.error('[STORE] Error fetching Sumenep regions:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal memuat daftar kecamatan dan desa Sumenep.',
    });
  }
};

const getMyStoreApplication = async (req, res) => {
  try {
    const [apps] = await pool.query(
      'SELECT * FROM store_applications WHERE user_id = ? ORDER BY updated_at DESC LIMIT 1',
      [req.user.id]
    );
    const villages = await resolveVillagesWithQuota();

    return res.status(200).json({
      success: true,
      data: {
        application: apps[0] || null,
        villages,
      },
    });
  } catch (error) {
    console.error('[STORE] Error fetching my store application:', error.message);
    return res.status(500).json({ success: false, message: 'Gagal memuat status pengajuan toko.' });
  }
};

const applyForStore = async (req, res) => {
  try {
    const userId = req.user.id;
    const {
      nama_toko,
      tipe_pengelola = 'POKTAN',
      nik,
      no_hp,
      province_id = 35,
      province_name = 'Jawa Timur',
      regency_id = 3529,
      regency_name = 'Kabupaten Sumenep',
      district_id = 352901,
      district_name = '',
      village_id = 109,
      village_name = '',
      postal_code,
      alamat_lengkap,
      dokumen_syarat_url,
      default_min_wholesale_kg = 30,
      store_discount_banner,
      mode = 'SUBMIT_TO_PPL',
    } = req.body || {};

    const cleanMode = String(mode || 'SUBMIT_TO_PPL').toUpperCase();
    const isFreeze = cleanMode === 'FREEZE_AS_BUYER' || cleanMode === 'DRAFT_FROZEN';

    if (!nama_toko || String(nama_toko).trim().length === 0) {
      return res.status(400).json({ success: false, message: 'Nama toko wajib diisi.' });
    }

    const parsedProvId = parseInt(province_id, 10) || 35;
    const parsedRegId = parseInt(regency_id, 10) || 3529;
    let parsedDistId = parseInt(district_id, 10) || 352917;
    if (parsedDistId > 2147483647) {
      parsedDistId = 352917;
    }

    const rawVillageNum = Number(village_id);
    const cleanVillageName = String(village_name || '').trim();
    const cleanDistrictName = String(district_name || '').trim();

    let village = null;
    if (Number.isInteger(rawVillageNum) && rawVillageNum > 0 && rawVillageNum <= 2147483647) {
      const [byId] = await pool.query(
        'SELECT id, district_id, name, postal_code, is_store_quota_enabled, max_stores_quota FROM villages WHERE id = ? LIMIT 1',
        [rawVillageNum]
      );
      if (byId.length > 0) village = byId[0];
    }

    if (!village && cleanVillageName) {
      const [byName] = await pool.query(
        `SELECT id, district_id, name, postal_code, is_store_quota_enabled, max_stores_quota
         FROM villages WHERE LOWER(name) LIKE ? LIMIT 1`,
        [`%${cleanVillageName.toLowerCase()}%`]
      );
      if (byName.length > 0) village = byName[0];
    }

    if (!village) {
      // Ensure province -> regency -> district hierarchy exists before inserting dynamic village
      try {
        await pool.query(
          'INSERT IGNORE INTO provinces (id, name) VALUES (?, ?)',
          [parsedProvId, String(province_name || 'Jawa Timur').trim()]
        );
        await pool.query(
          'INSERT IGNORE INTO regencies (id, province_id, name) VALUES (?, ?, ?)',
          [parsedRegId, parsedProvId, String(regency_name || 'Kabupaten Sumenep').trim()]
        );

        let resolvedDistId = parsedDistId;
        if (cleanDistrictName) {
          const [dByName] = await pool.query(
            'SELECT id FROM districts WHERE regency_id = ? AND LOWER(name) LIKE ? LIMIT 1',
            [parsedRegId, `%${cleanDistrictName.toLowerCase()}%`]
          );
          if (dByName.length > 0) {
            resolvedDistId = Number(dByName[0].id);
          }
        }
        await pool.query(
          'INSERT IGNORE INTO districts (id, regency_id, name) VALUES (?, ?, ?)',
          [resolvedDistId, parsedRegId, cleanDistrictName || 'Dungkek']
        );

        const [maxRows] = await pool.query(
          'SELECT COALESCE(MAX(id), 1000) AS max_id FROM villages WHERE id >= 1000 AND id < 2147483647'
        );
        const nextVillageId = Math.max(1001, Number(maxRows[0]?.max_id || 1000) + 1);
        const displayName = cleanVillageName
          ? (cleanDistrictName ? `${cleanVillageName} (Kec. ${cleanDistrictName})` : cleanVillageName)
          : 'Dungkek';

        await pool.query(
          `INSERT INTO villages (id, district_id, name, postal_code, is_store_quota_enabled, max_stores_quota)
           VALUES (?, ?, ?, ?, 0, 5)`,
          [nextVillageId, resolvedDistId, displayName, postal_code || '69471']
        );
        village = {
          id: nextVillageId,
          district_id: resolvedDistId,
          name: displayName,
          postal_code: postal_code || '69471',
          is_store_quota_enabled: 0,
          max_stores_quota: 5,
        };
      } catch (insErr) {
        console.warn('[STORE] Dynamic region upsert notice:', insErr.message);
        village = {
          id: 109,
          district_id: 352917,
          name: cleanVillageName || 'Dungkek',
          postal_code: postal_code || '69474',
          is_store_quota_enabled: 1,
          max_stores_quota: 3,
        };
      }
    }

    if (!isFreeze && Number(village.is_store_quota_enabled) === 1) {
      const [cntRows] = await pool.query(
        "SELECT COUNT(*) AS cnt FROM store_applications WHERE village_id = ? AND status = 'APPROVED' AND user_id != ?",
        [village.id, userId]
      );
      const currentCount = Number(cntRows[0]?.cnt || 0);
      const maxQuota = Number(village.max_stores_quota || 5);
      if (currentCount >= maxQuota) {
        return res.status(409).json({
          success: false,
          code: 'VILLAGE_STORE_QUOTA_FULL',
          message: `Kuota toko di Desa ${village.name} telah penuh (${currentCount}/${maxQuota}). Silakan pilih desa sekitar yang masih memiliki kuota tersedia.`,
        });
      }
    }

    const nextStatus = isFreeze ? 'DRAFT_FROZEN' : 'PENDING_PPL';
    const [existing] = await pool.query('SELECT id FROM store_applications WHERE user_id = ? LIMIT 1', [userId]);
    const appId = existing[0]?.id || `store-${uuidv4().slice(0, 10)}`;

    const validTypes = ['POKTAN', 'KOPERASI', 'PENGEPUL_DESA'];
    const resolvedType = validTypes.includes(String(tipe_pengelola).toUpperCase())
      ? String(tipe_pengelola).toUpperCase()
      : 'POKTAN';

    if (existing.length > 0) {
      await pool.query(
        `UPDATE store_applications
         SET nama_toko = ?, tipe_pengelola = ?, nik = ?, no_hp = ?,
             province_id = ?, regency_id = ?, district_id = ?, village_id = ?, village_name = ?,
             postal_code = ?, alamat_lengkap = ?, dokumen_syarat_url = COALESCE(?, dokumen_syarat_url),
             default_min_wholesale_kg = ?, store_discount_banner = COALESCE(?, store_discount_banner),
             status = ?
         WHERE id = ?`,
        [
          String(nama_toko).trim(),
          resolvedType,
          nik || null,
          no_hp || null,
          parsedProvId,
          parsedRegId,
          Number(village.district_id || parsedDistId),
          Number(village.id),
          village.name,
          postal_code || village.postal_code || '69472',
          alamat_lengkap || null,
          dokumen_syarat_url || null,
          Math.max(1, parseInt(default_min_wholesale_kg || 30, 10)),
          store_discount_banner || null,
          nextStatus,
          appId,
        ]
      );
    } else {
      await pool.query(
        `INSERT INTO store_applications
         (id, user_id, nama_toko, tipe_pengelola, nik, no_hp, province_id, regency_id, district_id, village_id, village_name, postal_code, alamat_lengkap, dokumen_syarat_url, default_min_wholesale_kg, store_discount_banner, status)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          appId,
          userId,
          String(nama_toko).trim(),
          resolvedType,
          nik || null,
          no_hp || null,
          parsedProvId,
          parsedRegId,
          Number(village.district_id || parsedDistId),
          Number(village.id),
          village.name,
          postal_code || village.postal_code || '69472',
          alamat_lengkap || null,
          dokumen_syarat_url || 'uploads/docs/syarat_toko.pdf',
          Math.max(1, parseInt(default_min_wholesale_kg || 30, 10)),
          store_discount_banner || null,
          nextStatus,
        ]
      );
    }

    const [saved] = await pool.query('SELECT * FROM store_applications WHERE id = ?', [appId]);
    return res.status(200).json({
      success: true,
      status: nextStatus,
      message: isFreeze
        ? 'Pengajuan toko dibekukan (Draft). Anda tetap dapat berbelanja sebagai Pembeli dan melanjutkan pengajuan kapan saja.'
        : `Pengajuan pembukaan toko berhasil dikirim ke Penyuluh Desa ${village.name} untuk diverifikasi.`,
      data: saved[0],
    });
  } catch (error) {
    console.error('[STORE] Error applying for store:', error.message);
    return res.status(500).json({ success: false, message: 'Gagal menyimpan pengajuan pembukaan toko.' });
  }
};

const updateStoreSettings = async (req, res) => {
  try {
    const userId = req.user.id;
    const { nama_toko, default_min_wholesale_kg, store_discount_banner, is_store_open } = req.body || {};

    const [existing] = await pool.query('SELECT * FROM store_applications WHERE user_id = ? LIMIT 1', [userId]);
    if (existing.length === 0) {
      const storeId = `store-${uuidv4().slice(0, 10)}`;
      await pool.query(
        `INSERT INTO store_applications
         (id, user_id, nama_toko, default_min_wholesale_kg, store_discount_banner, is_store_open, status)
         VALUES (?, ?, ?, ?, ?, ?, 'APPROVED')`,
        [
          storeId,
          userId,
          nama_toko || 'Toko Mitra Tani',
          Math.max(1, parseInt(default_min_wholesale_kg || 30, 10)),
          store_discount_banner || null,
          is_store_open === false ? 0 : 1,
        ]
      );
    } else {
      await pool.query(
        `UPDATE store_applications
         SET nama_toko = COALESCE(NULLIF(?, ''), nama_toko),
             default_min_wholesale_kg = COALESCE(?, default_min_wholesale_kg),
             store_discount_banner = COALESCE(?, store_discount_banner),
             is_store_open = COALESCE(?, is_store_open)
         WHERE user_id = ?`,
        [
          nama_toko ? String(nama_toko).trim() : '',
          default_min_wholesale_kg ? Math.max(1, parseInt(default_min_wholesale_kg, 10)) : null,
          store_discount_banner !== undefined ? store_discount_banner : null,
          is_store_open === undefined ? null : is_store_open ? 1 : 0,
          userId,
        ]
      );
    }

    const [updated] = await pool.query('SELECT * FROM store_applications WHERE user_id = ? LIMIT 1', [userId]);
    return res.status(200).json({
      success: true,
      message: 'Pengaturan toko berhasil diperbarui.',
      data: updated[0],
    });
  } catch (error) {
    console.error('[STORE_SETTINGS] Error updating settings:', error.message);
    return res.status(500).json({ success: false, message: 'Gagal memperbarui pengaturan toko.' });
  }
};

const getNearbyHarvests = async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT * FROM harvest_reports
       WHERE status_tanam IN ('HAMPIR_PANEN','SIAP_PANEN','MULAI_TANAM')
       ORDER BY CASE status_tanam WHEN 'SIAP_PANEN' THEN 0 WHEN 'HAMPIR_PANEN' THEN 1 ELSE 2 END, created_at DESC
       LIMIT 50`
    );
    return res.status(200).json({ success: true, count: rows.length, data: rows });
  } catch (error) {
    console.error('[STORE_HARVESTS] Error loading nearby harvests:', error.message);
    return res.status(500).json({ success: false, message: 'Gagal memuat daftar panen petani sekitar.' });
  }
};

const getStorePurchaseOffers = async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT * FROM harvest_purchase_offers
       ORDER BY CASE WHEN store_admin_id = ? THEN 0 ELSE 1 END, updated_at DESC LIMIT 60`,
      [req.user.id]
    );
    return res.status(200).json({ success: true, count: rows.length, data: rows });
  } catch (error) {
    console.error('[STORE_OFFERS] Error fetching store offers:', error.message);
    return res.status(500).json({ success: false, message: 'Gagal memuat daftar penawaran serapan panen.' });
  }
};

const createPurchaseOffer = async (req, res) => {
  try {
    const storeAdminId = req.user.id;
    const {
      harvest_report_id,
      farmer_id,
      nama_petani_walkin,
      komoditas,
      estimasi_berat_kg = 100,
      harga_acuan_pasar_per_kg,
      biaya_transport_per_kg = 0,
      biaya_operasional_lain_per_kg = 0,
      rincian_biaya_catatan,
      bukti_harga_pasar_url,
      mode = 'OFFER_SENT',
      add_to_catalog_stock = false,
    } = req.body || {};

    if (!komoditas || harga_acuan_pasar_per_kg === undefined) {
      return res.status(400).json({
        success: false,
        message: 'Komoditas dan harga acuan pasar per kg wajib diisi.',
      });
    }

    const marketPrice = Math.max(0, Number(harga_acuan_pasar_per_kg) || 0);
    const transportCost = Math.max(0, Number(biaya_transport_per_kg) || 0);
    const operationalCost = Math.max(0, Number(biaya_operasional_lain_per_kg) || 0);
    const netPrice = Math.max(0, marketPrice - transportCost - operationalCost);
    const weightKg = Math.max(1, Number(estimasi_berat_kg) || 1);
    const totalContract = netPrice * weightKg;

    const isWalkIn = String(mode).toUpperCase() === 'TRADITIONAL_WALKIN' || Boolean(nama_petani_walkin);
    const offerStatus = isWalkIn ? 'TRADITIONAL_WALKIN' : 'OFFER_SENT';

    const [storeRows] = await pool.query('SELECT nama_toko FROM store_applications WHERE user_id = ? LIMIT 1', [
      storeAdminId,
    ]);
    const storeName = storeRows[0]?.nama_toko || req.user.full_name || 'Toko Mitra Tani';
    const offerId = `hpo-${uuidv4().slice(0, 10)}`;

    await pool.query(
      `INSERT INTO harvest_purchase_offers
       (id, harvest_report_id, store_admin_id, store_name, farmer_id, nama_petani_walkin, komoditas, estimasi_berat_kg, berat_timbang_riil_kg, harga_acuan_pasar_per_kg, biaya_transport_per_kg, biaya_operasional_lain_per_kg, rincian_biaya_catatan, harga_tawar_bersih_per_kg, total_nilai_kontrak, bukti_harga_pasar_url, status)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        offerId,
        harvest_report_id || null,
        storeAdminId,
        storeName,
        farmer_id || null,
        nama_petani_walkin || null,
        String(komoditas).trim(),
        weightKg,
        isWalkIn ? weightKg : null,
        marketPrice,
        transportCost,
        operationalCost,
        rincian_biaya_catatan || `Acuan Pasar Rp ${marketPrice}/kg - Transport Rp ${transportCost}/kg - Ops Rp ${operationalCost}/kg`,
        netPrice,
        totalContract,
        bukti_harga_pasar_url || null,
        offerStatus,
      ]
    );

    // If traditional walk-in purchase & requested, add stock directly to matching product
    if (isWalkIn && add_to_catalog_stock) {
      await pool.query(
        'UPDATE products SET stock_kg = stock_kg + ? WHERE LOWER(title) LIKE ? LIMIT 1',
        [weightKg, `%${String(komoditas).trim().toLowerCase()}%`]
      );
      if (redisClient.isOpen) {
        await redisClient.del('lapaktani_catalog').catch(() => {});
      }
    }

    const [created] = await pool.query('SELECT * FROM harvest_purchase_offers WHERE id = ?', [offerId]);
    return res.status(201).json({
      success: true,
      message: isWalkIn
        ? 'Pembelian langsung petani tradisional (Walk-in) berhasil dicatat.'
        : 'Penawaran harga transparan berhasil dikirim ke petani.',
      data: created[0],
    });
  } catch (error) {
    console.error('[STORE_OFFERS] Error creating purchase offer:', error.message);
    return res.status(500).json({ success: false, message: 'Gagal membuat penawaran pembelian panen.' });
  }
};

const weighAndPayOffer = async (req, res) => {
  try {
    const { id } = req.params;
    const { berat_timbang_riil_kg, notes } = req.body || {};
    const realWeight = Number(berat_timbang_riil_kg);

    if (isNaN(realWeight) || realWeight <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Berat timbang riil (kg) harus angka positif.',
      });
    }

    const [rows] = await pool.query('SELECT * FROM harvest_purchase_offers WHERE id = ? LIMIT 1', [id]);
    if (rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Kontrak pembelian tidak ditemukan.' });
    }
    const offer = rows[0];
    const finalTotal = Number(offer.harga_tawar_bersih_per_kg || 0) * realWeight;

    await pool.query(
      `UPDATE harvest_purchase_offers
       SET berat_timbang_riil_kg = ?,
           total_nilai_kontrak = ?,
           rincian_biaya_catatan = COALESCE(NULLIF(?, ''), rincian_biaya_catatan),
           status = 'WEIGHED_AND_PAID'
       WHERE id = ?`,
      [realWeight, finalTotal, notes ? String(notes).trim() : '', id]
    );

    const [updated] = await pool.query('SELECT * FROM harvest_purchase_offers WHERE id = ?', [id]);
    return res.status(200).json({
      success: true,
      message: `Timbang ulang selesai (${realWeight} kg). Pembayaran bersih Rp ${finalTotal.toLocaleString('id-ID')} dicatat!`,
      data: updated[0],
    });
  } catch (error) {
    console.error('[WEIGH_AND_PAY] Error updating offer:', error.message);
    return res.status(500).json({ success: false, message: 'Gagal memproses timbang ulang & pembayaran.' });
  }
};

module.exports = {
  getDinasGisOverview,
  getFertilizerSubsidies,
  proposeFertilizerSubsidy,
  confirmFertilizerSubsidy,
  dispatchFertilizerSubsidy,
  getStoreApplicationsForPpl,
  verifyStoreApplication,
  updateVillageStoreQuota,
  getInterPplForum,
  createInterPplForumPost,
  getVillageForum,
  createVillageForumPost,
  getFarmerHarvestReports,
  createFarmerHarvestReport,
  getFarmerPurchaseOffers,
  respondToPurchaseOffer,
  getMyStoreApplication,
  applyForStore,
  updateStoreSettings,
  getNearbyHarvests,
  getStorePurchaseOffers,
  createPurchaseOffer,
  weighAndPayOffer,
  generateRagDecision,
  dispatchRagDecision,
  getDecisionReports,
  getSumenepRegionsAndVillages,
};
