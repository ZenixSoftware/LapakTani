const { v4: uuidv4 } = require('uuid');
const pool = require('../config/db');

/**
 * Normalizes severity string into ENUM ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')
 * and Indonesian label ('Ringan', 'Sedang', 'Berat')
 */
const normalizeSeverity = (input) => {
  const str = (input || '').toString().toUpperCase();
  if (str.includes('CRITICAL') || str === 'BERAT' || str === 'TINGGI' || str === 'HIGH') {
    return { level: str === 'CRITICAL' ? 'CRITICAL' : 'HIGH', label: 'Berat', isEmergency: true };
  }
  if (str === 'SEDANG' || str === 'MEDIUM') {
    return { level: 'MEDIUM', label: 'Sedang', isEmergency: false };
  }
  return { level: 'LOW', label: 'Ringan', isEmergency: false };
};

/**
 * Map database record to standard JSON structure expected by Flutter client
 */
const formatPestRow = (row) => {
  return {
    id: row.id,
    reporter_id: row.reporter_user_id || row.reporter_id,
    reporter_name: row.reporter_name || 'Petani LapakTani',
    reporter_role: row.reporter_role || 'Petani',
    pest_name: row.pest_name,
    crop_type: row.commodity_name || row.crop_type,
    commodity_name: row.commodity_name || row.crop_type,
    severity: row.severity_label || (row.severity_level === 'CRITICAL' || row.severity_level === 'HIGH' ? 'Berat' : (row.severity_level === 'LOW' ? 'Ringan' : 'Sedang')),
    severity_level: row.severity_level || 'MEDIUM',
    affected_area: row.affected_area || `${parseFloat(row.attack_area_hectares || 0).toFixed(1)} Hektar`,
    attack_area_hectares: parseFloat(row.attack_area_hectares || 0),
    farmer_group_id: row.farmer_group_id || null,
    farmer_group_name: row.farmer_group_name || 'Kelompok Tani',
    village_id: row.village_id || 1,
    village_name: row.village_name || 'Desa Lembang',
    location_address: row.location_address || `${row.farmer_group_name || ''}, ${row.village_name || ''}`.trim(),
    latitude: row.latitude ? parseFloat(row.latitude) : null,
    longitude: row.longitude ? parseFloat(row.longitude) : null,
    photo_url: row.photo_url || row.image_url || null,
    image_url: row.photo_url || row.image_url || null,
    description: row.description || '',
    handling_recommendation: row.handling_recommendation || null,
    verified_by_penyuluh_id: row.verified_by_penyuluh_id || null,
    penyuluh_name: row.penyuluh_name || null,
    status: row.status || 'SUBMITTED',
    legacy_status: row.legacy_status || 'active',
    emergency_alert: Boolean(row.emergency_alert === 1 || row.emergency_alert === true || row.severity_level === 'CRITICAL' || row.severity_level === 'HIGH'),
    warning_title: row.warning_title || null,
    warning_message: row.warning_message || null,
    recommended_action: row.recommended_action || null,
    affected_radius_km: row.affected_radius_km || 5,
    created_at: row.created_at ? new Date(row.created_at).toISOString() : new Date().toISOString(),
    updated_at: row.updated_at ? new Date(row.updated_at).toISOString() : new Date().toISOString()
  };
};

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
    let userId = req.user ? req.user.id : (req.body.reporter_id || req.body.reporter_user_id);
    let userName = req.user ? (req.user.full_name || req.user.name) : (req.body.reporter_name || 'Petani LapakTani');
    let userRole = req.user && req.user.role_id === 2 ? 'Penyuluh Pertanian' : (req.body.reporter_role || 'Petani');

    // If userId provided or from JWT, verify in MySQL
    if (userId) {
      const [userRows] = await pool.query(
        `SELECT u.id, u.full_name, u.role_id, up.verification_status 
         FROM users u 
         LEFT JOIN user_profiles up ON u.id = up.user_id 
         WHERE u.id = ?`,
        [userId]
      );
      if (userRows && userRows.length > 0) {
        userName = userRows[0].full_name || userName;
        userRole = userRows[0].role_id === 2 ? 'Penyuluh Pertanian Lapangan' : 'Petani';
      }
    } else {
      // Fallback to active demo farmer in DB
      const [defaultUser] = await pool.query(`SELECT id, full_name FROM users WHERE role_id = 1 LIMIT 1`);
      if (defaultUser.length > 0) {
        userId = defaultUser[0].id;
        userName = defaultUser[0].full_name;
      } else {
        userId = '08bed81d-df3f-41ed-81a4-cc582f745aa5';
      }
    }

    const {
      pest_name,
      crop_type,
      commodity_name,
      severity,
      severity_level,
      affected_area,
      attack_area_hectares,
      farmer_group_name,
      farmer_group_id,
      village_name,
      village_id,
      location_address,
      latitude,
      longitude,
      description,
      handling_recommendation,
      emergency_alert
    } = req.body;

    // Field validation
    const targetCrop = commodity_name || crop_type;
    const errors = [];
    if (!pest_name || !pest_name.trim()) errors.push('Nama hama atau gejala serangan wajib diisi.');
    if (!targetCrop || !targetCrop.trim()) errors.push('Jenis tanaman / komoditas terdampak wajib diisi.');
    if (!description || !description.trim()) errors.push('Catatan deskripsi kondisi serangan wajib diisi.');

    if (errors.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Validasi form pelaporan hama gagal.',
        errors
      });
    }

    // Determine image URL: from uploaded file, multipart, or request body
    let finalImageUrl = req.body.image_url || req.body.photo_url || null;
    if (req.file) {
      finalImageUrl = `/uploads/products/${req.file.filename}`;
    } else if (!finalImageUrl || !finalImageUrl.trim()) {
      finalImageUrl = 'https://images.unsplash.com/photo-1592417817098-8f3d6910985c?auto=format&fit=crop&w=800&q=80';
    }

    const sev = normalizeSeverity(severity_level || severity);
    const isEmergency = emergency_alert === true || emergency_alert === 'true' || sev.isEmergency;
    const reportId = `pest-${uuidv4()}`;
    const cleanCrop = targetCrop.trim();
    const cleanGroup = (farmer_group_name || 'Poktan Tani Makmur').trim();
    const cleanAreaStr = (affected_area || '1.0 Hektar').trim();
    const areaHa = parseFloat(attack_area_hectares) || parseFloat(cleanAreaStr) || 1.0;
    const cleanLoc = (location_address || `${cleanGroup}, ${village_name || 'Desa Lembang'}`).trim();

    // Insert directly into MySQL pest_reports
    await pool.query(
      `INSERT INTO pest_reports (
        id, reporter_user_id, farmer_group_id, farmer_group_name, village_id, village_name,
        commodity_name, pest_name, severity_level, severity_label, attack_area_hectares,
        affected_area, location_address, latitude, longitude, photo_url, description,
        handling_recommendation, status, legacy_status, emergency_alert
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        reportId,
        userId,
        farmer_group_id || null,
        cleanGroup,
        village_id ? parseInt(village_id, 10) : 1,
        village_name ? village_name.trim() : 'Desa Lembang',
        cleanCrop,
        pest_name.trim(),
        sev.level,
        sev.label,
        areaHa,
        cleanAreaStr,
        cleanLoc,
        latitude ? parseFloat(latitude) : null,
        longitude ? parseFloat(longitude) : null,
        finalImageUrl,
        description.trim(),
        handling_recommendation && handling_recommendation.trim() ? handling_recommendation.trim() : null,
        isEmergency ? 'EARLY_WARNING_ISSUED' : 'SUBMITTED',
        'active',
        isEmergency ? 1 : 0
      ]
    );

    // If emergency or high severity, insert into pest_early_warnings
    if (isEmergency) {
      const warnId = `warn-${uuidv4()}`;
      const warnTitle = `WASPADA: Serangan ${pest_name.trim()} (${sev.label}) di ${cleanGroup}`;
      const warnMsg = `Ditemukan serangan hama ${pest_name.trim()} pada tanaman ${cleanCrop} seluas ${cleanAreaStr} di ${cleanLoc}. Berpotensi menular ke lahan sekitar.`;
      const recAction = handling_recommendation && handling_recommendation.trim() 
        ? handling_recommendation.trim() 
        : 'Lakukan sanitasi lahan segera, pasang perangkap hama, dan koordinasikan dengan Penyuluh BPP setempat.';

      await pool.query(
        `INSERT INTO pest_early_warnings (
          id, pest_report_id, warning_title, warning_message, affected_radius_km, recommended_action, issued_by_user_id
        ) VALUES (?, ?, ?, ?, ?, ?, ?)`,
        [warnId, reportId, warnTitle, warnMsg, 5, recAction, userId]
      );
    }

    // Distribute notifications to Poktan and PPL members
    let notifiedUsersCount = 0;
    const targetRecipientIds = await findPestAlertTargetRecipients(
      farmer_group_id,
      cleanGroup,
      village_id ? parseInt(village_id, 10) : 1,
      userId
    );

    const alertTitle = `⚠️ Peringatan Hama ${sev.label.toUpperCase()}: ${pest_name.trim()}`;
    const alertMessage = `WASPADA! Serangan ${pest_name.trim()} menyerang tanaman ${cleanCrop} di ${cleanGroup}. Luas terdampak: ${cleanAreaStr}.`;

    for (const recipientId of targetRecipientIds) {
      const notifId = `notif-${uuidv4()}`;
      try {
        await pool.query(
          `INSERT INTO notifications (id, user_id, title, message, type, reference_id, is_read)
           VALUES (?, ?, ?, ?, 'pest_alert', ?, 0)`,
          [notifId, recipientId, alertTitle, alertMessage, reportId]
        );
        notifiedUsersCount++;
      } catch (_) {}
    }

    // Fetch the newly inserted row to return
    const [insertedRows] = await pool.query(
      `SELECT pr.*, u.full_name AS reporter_name, pew.warning_title, pew.warning_message, pew.recommended_action
       FROM pest_reports pr
       JOIN users u ON pr.reporter_user_id = u.id
       LEFT JOIN pest_early_warnings pew ON pr.id = pew.pest_report_id
       WHERE pr.id = ?`,
      [reportId]
    );

    const formatted = formatPestRow(insertedRows[0]);

    return res.status(201).json({
      success: true,
      message: 'Laporan serangan hama berhasil disimpan ke database dan peringatan dini didistribusikan.',
      data: formatted,
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
 * Fetch list of pest reports with filters directly from MySQL
 */
const getPestReports = async (req, res) => {
  try {
    const { farmer_group_id, farmer_group_name, severity, status, emergency_only } = req.query;

    let sql = `
      SELECT pr.*, 
             u.full_name AS reporter_name,
             penyuluh.full_name AS penyuluh_name,
             pew.warning_title, pew.warning_message, pew.recommended_action
      FROM pest_reports pr
      JOIN users u ON pr.reporter_user_id = u.id
      LEFT JOIN users penyuluh ON pr.verified_by_penyuluh_id = penyuluh.id
      LEFT JOIN pest_early_warnings pew ON pr.id = pew.pest_report_id
      WHERE 1=1
    `;
    const params = [];

    if (farmer_group_id) {
      sql += ' AND pr.farmer_group_id = ?';
      params.push(farmer_group_id);
    }
    if (farmer_group_name) {
      sql += ' AND LOWER(pr.farmer_group_name) = LOWER(?)';
      params.push(farmer_group_name.trim());
    }
    if (severity) {
      const sev = normalizeSeverity(severity);
      sql += ' AND (pr.severity_level = ? OR pr.severity_label = ?)';
      params.push(sev.level, sev.label);
    }
    if (status) {
      sql += ' AND (pr.status = ? OR pr.legacy_status = ?)';
      params.push(status, status);
    }
    if (emergency_only === 'true' || emergency_only === '1') {
      sql += ' AND (pr.emergency_alert = 1 OR pr.severity_level IN (\'CRITICAL\', \'HIGH\'))';
    }

    sql += ' ORDER BY pr.created_at DESC LIMIT 50';

    const [rows] = await pool.query(sql, params);
    const data = rows.map(formatPestRow);

    return res.status(200).json({
      success: true,
      total: data.length,
      data: data
    });
  } catch (error) {
    console.error('[PEST_ALERT] Error fetching pest reports:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal mengambil data laporan hama dari database.',
      error: error.message
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

    let sql = `
      SELECT pr.*, 
             u.full_name AS reporter_name,
             pew.warning_title, pew.warning_message, pew.recommended_action
      FROM pest_reports pr
      JOIN users u ON pr.reporter_user_id = u.id
      LEFT JOIN pest_early_warnings pew ON pr.id = pew.pest_report_id
      WHERE pr.legacy_status = 'active'
        AND (pr.emergency_alert = 1 OR pr.severity_level IN ('CRITICAL', 'HIGH'))
    `;
    const params = [];

    if (farmer_group_id || farmer_group_name) {
      sql += ' AND (pr.farmer_group_id = ? OR LOWER(pr.farmer_group_name) = LOWER(?))';
      params.push(farmer_group_id || '', (farmer_group_name || '').trim());
    } else if (village_id) {
      sql += ' AND pr.village_id = ?';
      params.push(parseInt(village_id, 10));
    }

    sql += ` ORDER BY 
      CASE WHEN pr.severity_level = 'CRITICAL' THEN 1 WHEN pr.severity_level = 'HIGH' THEN 2 ELSE 3 END ASC,
      pr.created_at DESC LIMIT 1`;

    const [rows] = await pool.query(sql, params);
    if (rows && rows.length > 0) {
      return res.status(200).json({
        success: true,
        has_alert: true,
        data: formatPestRow(rows[0])
      });
    }

    // If no specific Poktan alert, check overall regional emergency
    const [generalRows] = await pool.query(`
      SELECT pr.*, 
             u.full_name AS reporter_name,
             pew.warning_title, pew.warning_message, pew.recommended_action
      FROM pest_reports pr
      JOIN users u ON pr.reporter_user_id = u.id
      LEFT JOIN pest_early_warnings pew ON pr.id = pew.pest_report_id
      WHERE pr.legacy_status = 'active' AND pr.emergency_alert = 1
      ORDER BY pr.created_at DESC LIMIT 1
    `);

    if (generalRows && generalRows.length > 0) {
      return res.status(200).json({
        success: true,
        has_alert: true,
        data: formatPestRow(generalRows[0])
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
      message: 'Gagal memeriksa status peringatan hama aktif.',
      error: error.message
    });
  }
};

/**
 * GET /api/pest-reports/:id
 * Retrieve detail of single pest report from MySQL
 */
const getPestReportById = async (req, res) => {
  try {
    const { id } = req.params;

    const [rows] = await pool.query(
      `SELECT pr.*, 
             u.full_name AS reporter_name,
             penyuluh.full_name AS penyuluh_name,
             pew.warning_title, pew.warning_message, pew.recommended_action, pew.affected_radius_km
       FROM pest_reports pr
       JOIN users u ON pr.reporter_user_id = u.id
       LEFT JOIN users penyuluh ON pr.verified_by_penyuluh_id = penyuluh.id
       LEFT JOIN pest_early_warnings pew ON pr.id = pew.pest_report_id
       WHERE pr.id = ? LIMIT 1`,
      [id]
    );

    if (!rows || rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Laporan serangan hama tidak ditemukan di database.'
      });
    }

    return res.status(200).json({
      success: true,
      data: formatPestRow(rows[0])
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Gagal memuat detail laporan hama.',
      error: error.message
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
    const { status, legacy_status, handling_recommendation, verified_by_penyuluh_id } = req.body;

    const updates = [];
    const params = [];

    if (status) {
      updates.push('status = ?');
      params.push(status);
      if (status === 'RESOLVED') {
        updates.push('legacy_status = ?');
        params.push('resolved');
        updates.push('emergency_alert = 0');
      } else if (status === 'VERIFIED_PPL') {
        updates.push('legacy_status = ?');
        params.push('contained');
      }
    }

    if (legacy_status) {
      updates.push('legacy_status = ?');
      params.push(legacy_status);
      if (legacy_status === 'resolved') {
        updates.push('status = ?');
        params.push('RESOLVED');
        updates.push('emergency_alert = 0');
      }
    }

    if (handling_recommendation) {
      updates.push('handling_recommendation = ?');
      params.push(handling_recommendation.trim());
    }

    const penyuluhId = verified_by_penyuluh_id || (req.user && req.user.role_id === 2 ? req.user.id : null);
    if (penyuluhId) {
      updates.push('verified_by_penyuluh_id = ?');
      params.push(penyuluhId);
      if (!status) {
        updates.push('status = ?');
        params.push('VERIFIED_PPL');
      }
    }

    if (updates.length > 0) {
      params.push(id);
      await pool.query(`UPDATE pest_reports SET ${updates.join(', ')} WHERE id = ?`, params);
    }

    const [updatedRows] = await pool.query(
      `SELECT pr.*, u.full_name AS reporter_name, penyuluh.full_name AS penyuluh_name,
              pew.warning_title, pew.warning_message, pew.recommended_action
       FROM pest_reports pr
       JOIN users u ON pr.reporter_user_id = u.id
       LEFT JOIN users penyuluh ON pr.verified_by_penyuluh_id = penyuluh.id
       LEFT JOIN pest_early_warnings pew ON pr.id = pew.pest_report_id
       WHERE pr.id = ?`,
      [id]
    );

    if (!updatedRows || updatedRows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Laporan hama tidak ditemukan.'
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Status laporan hama berhasil diperbarui di database.',
      data: formatPestRow(updatedRows[0])
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Gagal memperbarui status laporan hama.',
      error: error.message
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
