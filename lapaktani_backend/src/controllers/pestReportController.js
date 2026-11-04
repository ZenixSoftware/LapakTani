const { v4: uuidv4 } = require('uuid');
const pool = require('../config/db');

// In-memory fallback data for resilience when MySQL is offline or initializing
const memoryPestReports = [
  {
    id: 'pest-alert-init-01',
    reporter_id: 'f-maman',
    reporter_name: 'H. Maman Suratman',
    reporter_role: 'Ketua Poktan',
    pest_name: 'Ulat Grayak (Spodoptera frugiperda)',
    crop_type: 'Jagung & Cabai Merah',
    severity: 'Berat',
    affected_area: '1.2 Hektar',
    farmer_group_id: 'fg-lembang-01',
    farmer_group_name: 'Poktan Tani Makmur',
    village_id: 1,
    village_name: 'Desa Lembang',
    image_url: 'https://images.unsplash.com/photo-1592417817098-8f3d6910985c?auto=format&fit=crop&w=800&q=80',
    description: 'Ditemukan serangan ulat grayak instar 3-4 memakan daun muda dan tongkol jagung seluas kurang lebih 1.2 ha di blok timur. Penularan cepat karena angin kencang.',
    handling_recommendation: 'Segera lakukan penyemprotan insektisida nabati mimba atau Bacillus thuringiensis pada pagi hari (06.00-08.00 WIB). Pasang perangkap feromon di sekeliling blok lahan.',
    emergency_alert: true,
    status: 'active',
    created_at: new Date(Date.now() - 3600000 * 2).toISOString(),
    updated_at: new Date(Date.now() - 3600000 * 2).toISOString()
  },
  {
    id: 'pest-alert-demo-02',
    reporter_id: 'f-wayan',
    reporter_name: 'Pak Wayan Sudirta',
    reporter_role: 'Anggota Poktan',
    pest_name: 'Hawar Daun (Phytophthora infestans)',
    crop_type: 'Kentang Granola',
    severity: 'Sedang',
    affected_area: '0.5 Hektar',
    farmer_group_id: 'fg-lembang-01',
    farmer_group_name: 'Poktan Tani Makmur',
    village_id: 1,
    village_name: 'Desa Lembang',
    image_url: 'https://images.unsplash.com/photo-1599818816942-88ec0c39f03d?auto=format&fit=crop&w=800&q=80',
    description: 'Bercak basah kehitaman pada tepi daun bagian bawah mulai menyebar akibat kelembaban tinggi dan embun pagi tebal.',
    handling_recommendation: 'Pangkas daun yang terinfeksi dan bakar jauh dari lahan. Kurangi kelembaban gulma dan semprot fungisida tembaga hidroksida terdaftar.',
    emergency_alert: false,
    status: 'active',
    created_at: new Date(Date.now() - 3600000 * 18).toISOString(),
    updated_at: new Date(Date.now() - 3600000 * 18).toISOString()
  }
];

const memoryNotifications = [];

/**
 * Helper: Find recipient users based on Poktan, Village, and Extension Officer (PPL) roles
 */
async function findPestAlertTargetRecipients(farmerGroupId, farmerGroupName, villageId, reporterId) {
  const recipientIds = new Set();

  try {
    // 1. Members of the same Poktan
    if (farmerGroupId || farmerGroupName) {
      const [poktanMembers] = await pool.query(
        `SELECT DISTINCT fp.user_id 
         FROM farmer_profiles fp
         LEFT JOIN farmer_groups fg ON fp.farmer_group_id = fg.id
         WHERE (fp.farmer_group_id = ? OR fg.group_name = ?) AND fp.user_id IS NOT NULL`,
        [farmerGroupId || '', farmerGroupName || '']
      );
      poktanMembers.forEach(row => recipientIds.add(row.user_id));
    }

    // 2. Farmers/residents in the same village
    if (villageId) {
      const [villageFarmers] = await pool.query(
        `SELECT DISTINCT up.user_id 
         FROM user_profiles up
         WHERE up.village_id = ? AND up.user_id IS NOT NULL`,
        [villageId]
      );
      villageFarmers.forEach(row => recipientIds.add(row.user_id));
    }

    // 3. Official Agricultural Extension Officers (PPL) in the region
    const [officers] = await pool.query(
      `SELECT DISTINCT u.id AS user_id 
       FROM users u
       LEFT JOIN user_profiles up ON u.id = up.user_id
       WHERE (u.role_id = 2 OR up.verification_status = 'verified') AND u.id IS NOT NULL`
    );
    officers.forEach(row => recipientIds.add(row.user_id));
  } catch (err) {
    console.warn('[PEST_ALERT] Database lookup warning for recipients:', err.message);
    // In-memory fallback recipients
    const fallbackRecipients = ['f-maman', 'f-wayan', 'f-siti', 'user-ppl-01', 'user-ppl-02'];
    fallbackRecipients.forEach(id => recipientIds.add(id));
  }

  // Never notify the reporter themselves with a duplicate alert
  if (reporterId) {
    recipientIds.delete(reporterId);
  }

  return Array.from(recipientIds);
}

/**
 * POST /api/pest-reports
 * Create a new pest attack report and dispatch emergency pest alerts
 */
const createPestReport = async (req, res) => {
  try {
    const userId = req.user ? req.user.id : (req.body.reporter_id || 'f-maman');
    const userName = req.user ? (req.user.full_name || req.user.name) : (req.body.reporter_name || 'Petani LapakTani');
    const userRole = req.user && req.user.role_id === 2 ? 'Penyuluh Pertanian' : (req.body.reporter_role || 'Petani');

    const {
      pest_name,
      crop_type,
      severity,
      affected_area,
      farmer_group_name,
      farmer_group_id,
      village_name,
      village_id,
      description,
      handling_recommendation
    } = req.body;

    // Validation
    const errors = [];
    if (!pest_name || !pest_name.trim()) errors.push('Nama hama atau gejala serangan wajib diisi.');
    if (!crop_type || !crop_type.trim()) errors.push('Jenis tanaman terdampak wajib diisi.');
    if (!severity || !['Ringan', 'Sedang', 'Berat'].includes(severity.trim())) {
      errors.push('Tingkat keparahan harus dipilih (Ringan, Sedang, atau Berat).');
    }
    if (!affected_area || !affected_area.trim()) errors.push('Estimasi luas lahan terdampak wajib diisi.');
    if (!farmer_group_name || !farmer_group_name.trim()) errors.push('Wilayah Poktan wajib dipilih.');
    if (!description || !description.trim()) errors.push('Catatan deskripsi kondisi serangan wajib diisi.');

    if (errors.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Validasi form pelaporan hama gagal.',
        errors
      });
    }

    // Determine image URL: from uploaded multer file or request body or fallback
    let finalImageUrl = req.body.image_url || null;
    if (req.file) {
      finalImageUrl = `/uploads/products/${req.file.filename}`;
    } else if (!finalImageUrl || !finalImageUrl.trim()) {
      finalImageUrl = 'https://images.unsplash.com/photo-1592417817098-8f3d6910985c?auto=format&fit=crop&w=800&q=80';
    }

    const cleanSeverity = severity.trim();
    const isEmergency = cleanSeverity === 'Berat' || req.body.emergency_alert === true || req.body.emergency_alert === 'true';
    const reportId = `pest-${uuidv4().substring(0, 8)}`;
    const nowIso = new Date().toISOString();

    const reportData = {
      id: reportId,
      reporter_id: userId,
      reporter_name: userName.trim(),
      reporter_role: userRole,
      pest_name: pest_name.trim(),
      crop_type: crop_type.trim(),
      severity: cleanSeverity,
      affected_area: affected_area.trim(),
      farmer_group_id: farmer_group_id ? farmer_group_id.trim() : 'fg-lembang-01',
      farmer_group_name: farmer_group_name.trim(),
      village_id: village_id ? parseInt(village_id, 10) : 1,
      village_name: village_name ? village_name.trim() : 'Desa Lembang',
      image_url: finalImageUrl,
      description: description.trim(),
      handling_recommendation: handling_recommendation && handling_recommendation.trim() ? handling_recommendation.trim() : null,
      emergency_alert: isEmergency,
      status: 'active',
      created_at: nowIso,
      updated_at: nowIso
    };

    // 1. Persist Report to MySQL if available
    let dbSuccess = false;
    try {
      await pool.query(
        `INSERT INTO pest_reports (
          id, reporter_id, reporter_name, reporter_role, pest_name, crop_type, 
          severity, affected_area, farmer_group_id, farmer_group_name, 
          village_id, village_name, image_url, description, 
          handling_recommendation, emergency_alert, status
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          reportData.id,
          reportData.reporter_id,
          reportData.reporter_name,
          reportData.reporter_role,
          reportData.pest_name,
          reportData.crop_type,
          reportData.severity,
          reportData.affected_area,
          reportData.farmer_group_id,
          reportData.farmer_group_name,
          reportData.village_id,
          reportData.village_name,
          reportData.image_url,
          reportData.description,
          reportData.handling_recommendation,
          reportData.emergency_alert,
          reportData.status
        ]
      );
      dbSuccess = true;
    } catch (dbErr) {
      console.warn('[PEST_ALERT] Could not write report to MySQL (falling back to memory):', dbErr.message);
    }

    // Always update in-memory cache for speed and offline testing
    memoryPestReports.unshift(reportData);

    // 2. Notification Distribution based on Poktan / Village Filter
    let notifiedUsersCount = 0;
    const targetRecipientIds = await findPestAlertTargetRecipients(
      reportData.farmer_group_id,
      reportData.farmer_group_name,
      reportData.village_id,
      userId
    );

    const alertTitle = `⚠️ Peringatan Hama ${reportData.severity.toUpperCase()}: ${reportData.pest_name}`;
    const alertMessage = `WASPADA! Serangan ${reportData.pest_name} menyerang tanaman ${reportData.crop_type} di ${reportData.farmer_group_name} (${reportData.village_name}). Luas terdampak: ${reportData.affected_area}.`;

    for (const recipientId of targetRecipientIds) {
      const notifId = `notif-${uuidv4().substring(0, 8)}`;
      const notifItem = {
        id: notifId,
        user_id: recipientId,
        title: alertTitle,
        message: alertMessage,
        type: 'pest_alert',
        reference_id: reportId,
        is_read: false,
        created_at: nowIso
      };

      if (dbSuccess) {
        try {
          await pool.query(
            `INSERT INTO notifications (id, user_id, title, message, type, reference_id, is_read)
             VALUES (?, ?, ?, ?, 'pest_alert', ?, false)`,
            [notifId, recipientId, alertTitle, alertMessage, reportId]
          );
        } catch (_) {}
      }

      memoryNotifications.unshift(notifItem);
      notifiedUsersCount++;
    }

    return res.status(201).json({
      success: true,
      message: 'Laporan serangan hama berhasil dibuat dan peringatan dini telah didistribusikan.',
      data: reportData,
      notifications_sent: notifiedUsersCount,
      target_recipients_count: targetRecipientIds.length
    });
  } catch (error) {
    console.error('[PEST_ALERT] Error creating pest report:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal memproses pelaporan hama.',
      error: error.message
    });
  }
};

/**
 * GET /api/pest-reports
 * Fetch list of pest reports with filters
 */
const getPestReports = async (req, res) => {
  try {
    const { farmer_group_id, farmer_group_name, severity, status, emergency_only } = req.query;

    try {
      let sql = 'SELECT * FROM pest_reports WHERE 1=1';
      const params = [];

      if (farmer_group_id) {
        sql += ' AND farmer_group_id = ?';
        params.push(farmer_group_id);
      }
      if (farmer_group_name) {
        sql += ' AND farmer_group_name = ?';
        params.push(farmer_group_name);
      }
      if (severity) {
        sql += ' AND severity = ?';
        params.push(severity);
      }
      if (status) {
        sql += ' AND status = ?';
        params.push(status);
      }
      if (emergency_only === 'true' || emergency_only === '1') {
        sql += ' AND emergency_alert = TRUE';
      }

      sql += ' ORDER BY created_at DESC LIMIT 50';

      const [rows] = await pool.query(sql, params);
      if (rows && rows.length > 0) {
        return res.status(200).json({
          success: true,
          total: rows.length,
          data: rows
        });
      }
    } catch (dbErr) {
      console.warn('[PEST_ALERT] Using memory fallback for listing:', dbErr.message);
    }

    // Filter in-memory fallback
    let filtered = [...memoryPestReports];
    if (farmer_group_id) {
      filtered = filtered.where ? filtered : filtered.filter(r => r.farmer_group_id === farmer_group_id);
    }
    if (farmer_group_name) {
      filtered = filtered.filter(r => r.farmer_group_name.toLowerCase() === farmer_group_name.toLowerCase());
    }
    if (severity) {
      filtered = filtered.filter(r => r.severity.toLowerCase() === severity.toLowerCase());
    }
    if (status) {
      filtered = filtered.filter(r => r.status === status);
    }
    if (emergency_only === 'true') {
      filtered = filtered.filter(r => r.emergency_alert === true);
    }

    return res.status(200).json({
      success: true,
      total: filtered.length,
      data: filtered
    });
  } catch (error) {
    console.error('[PEST_ALERT] Error fetching pest reports:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal mengambil data laporan hama.'
    });
  }
};

/**
 * GET /api/pest-reports/active-alert
 * Returns the highest severity active alert for the user's Poktan or region (for the Banner component)
 */
const getActivePestAlert = async (req, res) => {
  try {
    const { farmer_group_id, farmer_group_name, village_id } = req.query;

    try {
      let sql = `
        SELECT * FROM pest_reports 
        WHERE status = 'active' AND (emergency_alert = TRUE OR severity IN ('Berat', 'Sedang'))
      `;
      const params = [];

      if (farmer_group_id || farmer_group_name) {
        sql += ' AND (farmer_group_id = ? OR farmer_group_name = ?)';
        params.push(farmer_group_id || '', farmer_group_name || '');
      } else if (village_id) {
        sql += ' AND village_id = ?';
        params.push(village_id);
      }

      sql += ` ORDER BY 
        CASE WHEN severity = 'Berat' THEN 1 WHEN severity = 'Sedang' THEN 2 ELSE 3 END ASC,
        created_at DESC LIMIT 1`;

      const [rows] = await pool.query(sql, params);
      if (rows && rows.length > 0) {
        return res.status(200).json({
          success: true,
          has_alert: true,
          data: rows[0]
        });
      }
    } catch (dbErr) {
      console.warn('[PEST_ALERT] Using memory fallback for active alert:', dbErr.message);
    }

    // Memory fallback search
    const active = memoryPestReports.find(r => 
      r.status === 'active' && 
      (r.emergency_alert === true || r.severity === 'Berat' || r.severity === 'Sedang') &&
      (!farmer_group_name || r.farmer_group_name.toLowerCase().includes(farmer_group_name.toLowerCase()) || r.farmer_group_id === farmer_group_id)
    ) || memoryPestReports.find(r => r.status === 'active' && r.emergency_alert === true);

    if (active) {
      return res.status(200).json({
        success: true,
        has_alert: true,
        data: active
      });
    }

    return res.status(200).json({
      success: true,
      has_alert: false,
      data: null
    });
  } catch (error) {
    console.error('[PEST_ALERT] Error getting active alert:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal memeriksa status peringatan hama aktif.'
    });
  }
};

/**
 * GET /api/pest-reports/:id
 * Retrieve detail of single pest report
 */
const getPestReportById = async (req, res) => {
  try {
    const { id } = req.params;

    try {
      const [rows] = await pool.query('SELECT * FROM pest_reports WHERE id = ? LIMIT 1', [id]);
      if (rows && rows.length > 0) {
        return res.status(200).json({
          success: true,
          data: rows[0]
        });
      }
    } catch (_) {}

    const found = memoryPestReports.find(r => r.id === id);
    if (!found) {
      return res.status(404).json({
        success: false,
        message: 'Laporan serangan hama tidak ditemukan.'
      });
    }

    return res.status(200).json({
      success: true,
      data: found
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Gagal memuat detail laporan hama.'
    });
  }
};

/**
 * PATCH /api/pest-reports/:id/status
 * Update handling status or add recommendations (by Penyuluh or Poktan leader)
 */
const updatePestReportStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, handling_recommendation } = req.body;

    if (status && !['active', 'contained', 'resolved'].includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'Status harus salah satu dari: active, contained, resolved.'
      });
    }

    const updates = [];
    const params = [];

    if (status) {
      updates.push('status = ?');
      params.push(status);
      if (status === 'resolved') {
        updates.push('emergency_alert = FALSE');
      }
    }
    if (handling_recommendation) {
      updates.push('handling_recommendation = ?');
      params.push(handling_recommendation);
    }

    if (updates.length > 0) {
      params.push(id);
      try {
        await pool.query(`UPDATE pest_reports SET ${updates.join(', ')} WHERE id = ?`, params);
      } catch (_) {}
    }

    const found = memoryPestReports.find(r => r.id === id);
    if (found) {
      if (status) {
        found.status = status;
        if (status === 'resolved') found.emergency_alert = false;
      }
      if (handling_recommendation) {
        found.handling_recommendation = handling_recommendation;
      }
      found.updated_at = new Date().toISOString();
    }

    return res.status(200).json({
      success: true,
      message: 'Status laporan hama berhasil diperbarui.',
      data: found || { id, status }
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Gagal memperbarui status laporan hama.'
    });
  }
};

/**
 * GET /api/pest-reports/poktan-targets
 * Helper endpoint to simulate and inspect targeted users for a Poktan
 */
const getPoktanNotificationTargets = async (req, res) => {
  try {
    const { farmer_group_id, farmer_group_name, village_id, reporter_id } = req.query;
    const recipients = await findPestAlertTargetRecipients(
      farmer_group_id,
      farmer_group_name,
      village_id ? parseInt(village_id, 10) : 1,
      reporter_id
    );

    return res.status(200).json({
      success: true,
      target_count: recipients.length,
      recipients
    });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
};

module.exports = {
  createPestReport,
  getPestReports,
  getActivePestAlert,
  getPestReportById,
  updatePestReportStatus,
  getPoktanNotificationTargets,
  findPestAlertTargetRecipients
};

