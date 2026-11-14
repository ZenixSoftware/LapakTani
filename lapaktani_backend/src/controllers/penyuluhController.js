const pool = require('../config/db');

/**
 * GET /api/penyuluh/pending-farmers
 * Retrieve all farmers with verification_status = 'pending'
 */
const getPendingFarmers = async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT 
        up.id AS profile_id,
        up.user_id,
        up.user_id AS id,
        up.full_name AS name,
        up.full_name,
        up.nik_number AS nik,
        up.nik_number,
        up.phone,
        up.detail_address,
        up.birth_date,
        up.avatar_url,
        up.avatar_url AS selfie_image_url,
        up.verification_status,
        COALESCE(fg.group_name, fp.farmer_group_id, 'Poktan Tani Makmur') AS poktan,
        COALESCE(v.name, 'Lembang') AS village,
        COALESCE(f.land_area_ha, 1.0) AS land_area,
        COALESCE(f.land_area_ha, 1.0) AS land_area_ha,
        f.gps_latitude,
        f.gps_longitude,
        f.soil_type,
        fp.ktp_image_url,
        u.email,
        u.created_at
      FROM user_profiles up
      LEFT JOIN farmer_profiles fp ON up.user_id = fp.user_id
      LEFT JOIN farmer_groups fg ON fp.farmer_group_id = fg.id
      LEFT JOIN villages v ON up.village_id = v.id
      LEFT JOIN farms f ON up.user_id = f.farmer_id
      LEFT JOIN users u ON up.user_id = u.id
      WHERE up.verification_status = 'pending'
      ORDER BY u.created_at DESC`
    );

    return res.status(200).json({
      success: true,
      message: 'Daftar permohonan petani berhasil diambil.',
      total: rows.length,
      data: rows
    });
  } catch (error) {
    console.error('[PENYULUH] Error fetching pending farmers:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal mengambil daftar permohonan petani.'
    });
  }
};

/**
 * GET /api/penyuluh/farmers
 * Retrieve farmers with optional status filter (?status=pending|verified|rejected|all)
 */
const getAllFarmers = async (req, res) => {
  try {
    const { status } = req.query;
    let query = `
      SELECT 
        up.id AS profile_id,
        up.user_id,
        up.user_id AS id,
        up.full_name AS name,
        up.full_name,
        up.nik_number AS nik,
        up.nik_number,
        up.phone,
        up.detail_address,
        up.birth_date,
        up.avatar_url,
        up.avatar_url AS selfie_image_url,
        up.verification_status,
        COALESCE(fg.group_name, fp.farmer_group_id, 'Poktan Tani Makmur') AS poktan,
        COALESCE(v.name, 'Lembang') AS village,
        COALESCE(f.land_area_ha, 1.0) AS land_area,
        COALESCE(f.land_area_ha, 1.0) AS land_area_ha,
        f.gps_latitude,
        f.gps_longitude,
        f.soil_type,
        fp.ktp_image_url,
        u.email,
        u.created_at
      FROM user_profiles up
      LEFT JOIN farmer_profiles fp ON up.user_id = fp.user_id
      LEFT JOIN farmer_groups fg ON fp.farmer_group_id = fg.id
      LEFT JOIN villages v ON up.village_id = v.id
      LEFT JOIN farms f ON up.user_id = f.farmer_id
      LEFT JOIN users u ON up.user_id = u.id
    `;
    const params = [];

    if (status && ['pending', 'verified', 'rejected'].includes(status)) {
      query += ' WHERE up.verification_status = ?';
      params.push(status);
    }

    query += ' ORDER BY u.created_at DESC';

    const [rows] = await pool.query(query, params);

    return res.status(200).json({
      success: true,
      message: 'Daftar petani berhasil diambil.',
      total: rows.length,
      data: rows
    });
  } catch (error) {
    console.error('[PENYULUH] Error fetching farmers:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal mengambil data petani.'
    });
  }
};

/**
 * PUT /api/penyuluh/verify-farmer/:id
 * Update verification_status to 'verified' or 'rejected'
 */
const verifyFarmer = async (req, res) => {
  const userRole = (req.user && req.user.role ? req.user.role : '').toLowerCase();
  const userRoleId = req.user ? req.user.role_id : null;
  if (userRole !== 'penyuluh' && userRoleId !== 2) {
    return res.status(403).json({
      success: false,
      message: 'Akses ditolak. Hanya pengguna dengan peran penyuluh yang dapat memverifikasi petani.'
    });
  }

  const { id } = req.params;
  const { status, verification_status, notes } = req.body;

  const targetStatus = status || verification_status;

  if (!targetStatus || !['verified', 'rejected', 'pending'].includes(targetStatus)) {
    return res.status(400).json({
      success: false,
      message: 'Status verifikasi tidak valid. Pilihan: verified, rejected, atau pending.'
    });
  }

  let connection;
  try {
    connection = await pool.getConnection();
    await connection.beginTransaction();

    const [profileRows] = await connection.query(
      'SELECT id, user_id, verification_status FROM user_profiles WHERE id = ? OR user_id = ? LIMIT 1',
      [id, id]
    );

    if (profileRows.length === 0) {
      await connection.rollback();
      return res.status(404).json({
        success: false,
        message: `Petani dengan identifier ${id} tidak ditemukan.`
      });
    }

    const matchedUserId = profileRows[0].user_id;

    // Update user_profiles
    await connection.query(
      'UPDATE user_profiles SET verification_status = ? WHERE user_id = ?',
      [targetStatus, matchedUserId]
    );

    // Update users is_verified
    const isVerifiedBool = targetStatus === 'verified';
    await connection.query(
      'UPDATE users SET is_verified = ? WHERE id = ?',
      [isVerifiedBool, matchedUserId]
    );

    await connection.commit();

    console.log(`[PENYULUH] Farmer verification updated: id=${matchedUserId}, status=${targetStatus}`);

    return res.status(200).json({
      success: true,
      message: `Status verifikasi petani berhasil diperbarui menjadi '${targetStatus}'.`,
      data: {
        id: matchedUserId,
        user_id: matchedUserId,
        verification_status: targetStatus,
        notes: notes || null
      }
    });
  } catch (error) {
    if (connection) {
      await connection.rollback();
    }
    console.error('[PENYULUH] Error updating verification status:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal memperbarui status verifikasi petani.'
    });
  } finally {
    if (connection) {
      connection.release();
    }
  }
};

/**
 * GET /api/penyuluh/soil-map (US-27)
 * Retrieve spatial soil fertility map coordinates and NPK metrics for PPL
 */
const getSoilMap = async (req, res) => {
  try {
    const [farmRows] = await pool.query(`
      SELECT 
        f.id AS farm_id,
        f.farmer_id,
        COALESCE(u.full_name, 'Petani LapakTani') AS farmer_name,
        COALESCE(fg.group_name, 'Poktan Tani Makmur') AS poktan_name,
        COALESCE(v.name, 'Lembang') AS village_name,
        f.land_area_ha,
        COALESCE(f.soil_type, 'Andosol Vulkanik Subur') AS soil_type,
        COALESCE(f.commodity, 'Cabai Merah Keriting') AS commodity,
        COALESCE(f.gps_latitude, -6.81520000) AS gps_latitude,
        COALESCE(f.gps_longitude, 107.61860000) AS gps_longitude,
        COALESCE(st.ph_level, 6.40) AS ph_level,
        COALESCE(st.nitrogen_mg_kg, 142.00) AS nitrogen_mg_kg,
        COALESCE(st.phosphorus_mg_kg, 38.00) AS phosphorus_mg_kg,
        COALESCE(st.potassium_mg_kg, 210.00) AS potassium_mg_kg,
        COALESCE(st.moisture_percentage, 72.50) AS moisture_percentage,
        COALESCE(st.temperature_celsius, 24.50) AS temperature_celsius,
        COALESCE(st.fertility_index, 'Sangat Subur') AS fertility_index
      FROM farms f
      LEFT JOIN users u ON f.farmer_id = u.id
      LEFT JOIN farmer_profiles fp ON f.farmer_id = fp.user_id
      LEFT JOIN farmer_groups fg ON fp.farmer_group_id = fg.id
      LEFT JOIN villages v ON fg.village_id = v.id
      LEFT JOIN (
        SELECT s1.* FROM soil_telemetries s1
        INNER JOIN (
          SELECT farm_id, MAX(measured_at) as max_time FROM soil_telemetries GROUP BY farm_id
        ) s2 ON s1.farm_id = s2.farm_id AND s1.measured_at = s2.max_time
      ) st ON f.id = st.farm_id
    `);

    const enrichedFarmRows = farmRows.map((row) => ({
      ...row,
      conductivity: Math.round(
        (Number(row.nitrogen_mg_kg || 0) +
          Number(row.phosphorus_mg_kg || 0) +
          Number(row.potassium_mg_kg || 0)) * 3.1
      ),
      fertility_score:
        String(row.fertility_index).toLowerCase().includes('sangat')
          ? 92
          : String(row.fertility_index).toLowerCase().includes('optimal')
            ? 84
            : 68,
      kecamatan: String(row.village_name || 'Lembang'),
      irigasi: 'ya',
      pompa_air: 'ya',
      sumber_air: 'irigasi teknis',
      kondisi_air: 'lancar',
      pembajak: 'traktor',
      rekomendasi_ppl: null,
      status_verifikasi_ppl: 'verified'
    }));

    let monitoringPlots = [];
    try {
      const [mlRows] = await pool.query(`
        SELECT * FROM monitoring_lahan
        ORDER BY created_at DESC, id DESC
        LIMIT 50
      `);
      monitoringPlots = mlRows.map((ml) => {
        const fert = Number(ml.fertility ?? 0);
        const fertLabel =
          fert >= 80
            ? 'Sangat Subur'
            : fert >= 60
              ? 'Optimal'
              : fert >= 35
                ? 'Kurang Subur'
                : 'Kritis';
        const poktan =
          ml.kelompok_tani &&
          ml.kelompok_tani !== 'ya' &&
          ml.kelompok_tani !== 'tidak'
            ? ml.kelompok_tani
            : `Poktan ${ml.kecamatan || 'Sumenep'}`;
        return {
          farm_id: ml.farm_id || `smp-${ml.id}`,
          monitoring_id: ml.id,
          farmer_id: ml.user_id || `petani-smp-${ml.id}`,
          farmer_name: poktan,
          poktan_name: poktan,
          village_name: ml.kecamatan
            ? `${ml.nama_desa || 'Mandala'}, Kec. ${ml.kecamatan}`
            : ml.nama_desa || 'Sumenep',
          kecamatan: ml.kecamatan || 'Sumenep',
          land_area_ha: ml.luas_lahan || '0.8 H',
          soil_type: 'Aluvial Mediteran Sumenep',
          commodity: ml.varietas
            ? `${ml.komoditas} (${ml.varietas})`
            : ml.komoditas || 'Jagung',
          gps_latitude: Number(ml.latitude),
          gps_longitude: Number(ml.longitude),
          ph_level: Number(ml.ph),
          nitrogen_mg_kg: Number(ml.nitrogen),
          phosphorus_mg_kg: Number(ml.phosphorus),
          potassium_mg_kg: Number(ml.potassium),
          moisture_percentage: Number(ml.moisture),
          temperature_celsius: Number(ml.temp),
          conductivity: Number(ml.conductivity),
          fertility_score: fert,
          fertility_index: fertLabel,
          irigasi: ml.irigasi,
          pompa_air: ml.pompa_air,
          sumber_air: ml.sumber_air,
          kondisi_air: ml.kondisi_air,
          pembajak: ml.pembajak,
          rekomendasi_ppl: ml.rekomendasi_ppl,
          status_verifikasi_ppl: ml.status_verifikasi_ppl
        };
      });
    } catch (mlErr) {
      console.warn('[PENYULUH] monitoring_lahan union notice:', mlErr.message);
    }

    const combined = [...monitoringPlots, ...enrichedFarmRows];

    return res.status(200).json({
      success: true,
      count: combined.length,
      data: combined
    });
  } catch (error) {
    console.error('[PENYULUH] Error fetching soil map data:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal mengambil data pemetaan geospasial tanah.'
    });
  }
};

/**
 * GET /api/penyuluh/monitoring-lahan | GET /api/soil/monitoring-lahan
 * Retrieve Sumenep land monitoring & 8-in-1 telemetry logs with optional filtering
 */
const getMonitoringLahan = async (req, res) => {
  try {
    const { komoditas, desa, kategori } = req.query;
    const conditions = [];
    const params = [];

    if (komoditas && komoditas !== 'all') {
      conditions.push('LOWER(komoditas) LIKE ?');
      params.push(`%${String(komoditas).trim().toLowerCase()}%`);
    }
    if (desa && desa !== 'all') {
      conditions.push('(LOWER(nama_desa) LIKE ? OR LOWER(kecamatan) LIKE ?)');
      const term = `%${String(desa).trim().toLowerCase()}%`;
      params.push(term, term);
    }

    if (kategori && kategori !== 'all') {
      const cat = String(kategori).toLowerCase();
      if (['padi', 'jagung', 'cabai', 'tembakau', 'bawang', 'singkong', 'kacang'].includes(cat)) {
        conditions.push('LOWER(komoditas) LIKE ?');
        params.push(`%${cat}%`);
      } else if (cat === 'traktor' || cat === 'sapi') {
        conditions.push('LOWER(pembajak) LIKE ?');
        params.push(`%${cat}%`);
      } else if (cat === 'poktan') {
        conditions.push("LOWER(kelompok_tani) != 'tidak' AND kelompok_tani IS NOT NULL AND kelompok_tani != ''");
      } else if (cat === 'irigasi') {
        conditions.push("LOWER(irigasi) = 'ya'");
      } else if (cat === 'pompa') {
        conditions.push("LOWER(pompa_air) = 'ya'");
      } else if (cat === 'air_sulit') {
        conditions.push("LOWER(kondisi_air) LIKE '%sulit%' OR LOWER(kondisi_air) LIKE '%kering%'");
      } else if (cat === 'kritis') {
        conditions.push('(ph < 5.5 OR ph > 7.5 OR moisture < 15 OR fertility < 20)');
      }
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';
    const [rows] = await pool.query(
      `SELECT * FROM monitoring_lahan ${whereClause} ORDER BY created_at DESC, id DESC`,
      params
    );

    return res.status(200).json({
      success: true,
      status: true,
      count: rows.length,
      data: rows
    });
  } catch (error) {
    console.error('[MONITORING_LAHAN] Error fetching rows:', error.message);
    return res.status(500).json({
      success: false,
      status: false,
      message: 'Gagal mengambil data monitoring lahan Sumenep.'
    });
  }
};

/**
 * GET /api/penyuluh/monitoring-summary | GET /api/soil/monitoring-summary
 * Ported from Pens-Agri Model_Monitoring_Lahan analytics & critical-zone queries
 */
const getMonitoringSummary = async (req, res) => {
  try {
    const [summaryRows] = await pool.query(`
      SELECT
        COUNT(*) AS total_titik,
        ROUND(AVG(ph), 2) AS avg_ph,
        ROUND(AVG(moisture), 2) AS avg_moisture,
        ROUND(AVG(temp), 2) AS avg_temp,
        ROUND(AVG(conductivity), 0) AS avg_conductivity,
        ROUND(AVG(nitrogen), 1) AS avg_nitrogen,
        ROUND(AVG(phosphorus), 1) AS avg_phosphorus,
        ROUND(AVG(potassium), 1) AS avg_potassium,
        ROUND(AVG(fertility), 1) AS avg_fertility,
        SUM(CASE WHEN LOWER(irigasi) = 'ya' THEN 1 ELSE 0 END) AS total_irigasi,
        SUM(CASE WHEN LOWER(pompa_air) = 'ya' THEN 1 ELSE 0 END) AS total_pompa_air,
        SUM(CASE WHEN LOWER(gagal_panen) = 'ya' THEN 1 ELSE 0 END) AS total_gagal_panen,
        SUM(CASE WHEN ph < 5.5 OR ph > 7.5 OR moisture < 15 OR fertility < 20 THEN 1 ELSE 0 END) AS total_titik_kritis
      FROM monitoring_lahan
    `);

    const [distribusiKomoditas] = await pool.query(`
      SELECT
        COALESCE(NULLIF(TRIM(komoditas), ''), 'Lainnya') AS komoditas,
        COUNT(*) AS jumlah_titik,
        ROUND(AVG(fertility), 1) AS avg_fertility,
        ROUND(AVG(ph), 2) AS avg_ph
      FROM monitoring_lahan
      GROUP BY COALESCE(NULLIF(TRIM(komoditas), ''), 'Lainnya')
      ORDER BY jumlah_titik DESC
    `);

    const [sampelTitikKritis] = await pool.query(`
      SELECT
        id, nama_desa, kecamatan, komoditas, latitude, longitude,
        ph, moisture, fertility, kondisi_air, rekomendasi_ppl, status_verifikasi_ppl
      FROM monitoring_lahan
      WHERE ph < 5.5 OR ph > 7.5 OR moisture < 15 OR fertility < 20
      ORDER BY fertility ASC, ph ASC
      LIMIT 15
    `);

    const [recentLogs] = await pool.query(`
      SELECT * FROM monitoring_lahan
      ORDER BY created_at DESC, id DESC
      LIMIT 10
    `);

    return res.status(200).json({
      success: true,
      status: true,
      data: {
        ringkasan_umum: summaryRows[0] || {},
        distribusi_komoditas: distribusiKomoditas,
        sampel_titik_kritis: sampelTitikKritis,
        recent_logs: recentLogs
      }
    });
  } catch (error) {
    console.error('[MONITORING_SUMMARY] Error computing stats:', error.message);
    return res.status(500).json({
      success: false,
      status: false,
      message: 'Gagal memuat ringkasan statistik monitoring lahan.'
    });
  }
};

/**
 * POST /api/soil/monitoring-lahan | POST /api/soil/save | POST /api/penyuluh/monitoring-lahan
 * Save 8-in-1 precision probe telemetry + Sumenep land conditions + optional 3 evidence photos
 */
const saveMonitoringLahan = async (req, res) => {
  try {
    const body = req.body || {};
    const files = req.files || {};

    const toFileUrl = (field) => {
      if (files[field] && Array.isArray(files[field]) && files[field][0]) {
        return `/uploads/soil/${files[field][0].filename}`;
      }
      return body[field] || null;
    };

    const userId = req.user?.id || body.user_id || null;
    const defaultRoleInput = req.user?.role === 'penyuluh' ? 'penyuluh' : 'petani';
    const latitude = Number(body.latitude ?? -6.9771599);
    const longitude = Number(body.longitude ?? 113.8045302);
    const namaDesa = String(body.nama_desa || 'Mandala').trim();
    const kecamatan = String(body.kecamatan || 'Sumenep').trim();
    const ph = Number(body.ph ?? 6.4);
    const moisture = Number(body.moisture ?? 18.0);
    const fertility = parseInt(body.fertility ?? 65, 10);

    const statusVerifikasi =
      body.status_verifikasi_ppl ||
      (ph < 5.5 || ph > 7.5 || moisture < 15 || fertility < 20
        ? 'needs_action'
        : req.user?.role === 'penyuluh'
          ? 'verified'
          : 'pending');

    const [result] = await pool.query(
      `INSERT INTO monitoring_lahan (
        farm_id, user_id, latitude, longitude, nama_desa, kecamatan,
        irigasi, listrik, pompa_air, sumber_air, kondisi_air, sumber_energi_pompa,
        pembajak, tadahan_hujan, komoditas, varietas, luas_lahan, status_lahan,
        kelompok_tani, gagal_panen, hasil_panen_lalu, satuan_panen,
        temp, moisture, conductivity, ph, nitrogen, phosphorus, potassium, fertility,
        foto_daun, foto_pohon, foto_tanah, tipe_penginput, rekomendasi_ppl, status_verifikasi_ppl
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        body.farm_id || null,
        userId,
        Number.isFinite(latitude) ? latitude : -6.9771599,
        Number.isFinite(longitude) ? longitude : 113.8045302,
        namaDesa,
        kecamatan,
        String(body.irigasi || 'tidak'),
        String(body.listrik || 'tidak'),
        String(body.pompa_air || 'ya'),
        String(body.sumber_air || 'sumur bor'),
        String(body.kondisi_air || 'tersedia'),
        String(body.sumber_energi_pompa || 'BBM'),
        String(body.pembajak || 'traktor'),
        String(body.tadahan_hujan || 'tidak'),
        String(body.komoditas || 'jagung').trim(),
        String(body.varietas || 'Hibrida').trim(),
        String(body.luas_lahan || '0.8 H'),
        String(body.status_lahan || 'milik sendiri'),
        String(body.kelompok_tani || 'ya'),
        String(body.gagal_panen || 'tidak'),
        Number(body.hasil_panen_lalu ?? 4.2),
        String(body.satuan_panen || 'ton'),
        Number(body.temp ?? 30.2),
        Number.isFinite(moisture) ? moisture : 18.0,
        parseInt(body.conductivity ?? 900, 10),
        Number.isFinite(ph) ? ph : 6.4,
        parseInt(body.nitrogen ?? 85, 10),
        parseInt(body.phosphorus ?? 28, 10),
        parseInt(body.potassium ?? 140, 10),
        Number.isFinite(fertility) ? fertility : 65,
        toFileUrl('foto_daun'),
        toFileUrl('foto_pohon'),
        toFileUrl('foto_tanah'),
        String(body.tipe_penginput || defaultRoleInput),
        body.rekomendasi_ppl || null,
        statusVerifikasi
      ]
    );

    const [createdRows] = await pool.query('SELECT * FROM monitoring_lahan WHERE id = ?', [
      result.insertId
    ]);

    return res.status(201).json({
      success: true,
      status: true,
      message: 'Data monitoring lahan & telemetri 8-in-1 berhasil disimpan ke cloud.',
      data: createdRows[0] || { id: result.insertId }
    });
  } catch (error) {
    console.error('[MONITORING_SAVE] Error saving land monitoring:', error.message);
    return res.status(500).json({
      success: false,
      status: false,
      message: 'Gagal menyimpan data monitoring lahan.'
    });
  }
};

/**
 * PUT /api/penyuluh/monitoring-lahan/:id/recommend
 * Submit PPL agronomic recommendation and verification status for a monitored plot
 */
const updateMonitoringRecommendation = async (req, res) => {
  try {
    const plotId = parseInt(req.params.id, 10);
    const { rekomendasi_ppl, status_verifikasi_ppl } = req.body || {};

    if (!Number.isFinite(plotId)) {
      return res.status(400).json({
        success: false,
        message: 'ID titik monitoring tidak valid.'
      });
    }

    const allowedStatuses = ['pending', 'verified', 'needs_action'];
    const targetStatus = allowedStatuses.includes(status_verifikasi_ppl)
      ? status_verifikasi_ppl
      : 'verified';

    const [result] = await pool.query(
      `UPDATE monitoring_lahan
       SET rekomendasi_ppl = ?, status_verifikasi_ppl = ?
       WHERE id = ?`,
      [rekomendasi_ppl || null, targetStatus, plotId]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({
        success: false,
        message: 'Data monitoring lahan tidak ditemukan.'
      });
    }

    const [updatedRows] = await pool.query('SELECT * FROM monitoring_lahan WHERE id = ?', [plotId]);

    return res.status(200).json({
      success: true,
      message: 'Rekomendasi agronomis PPL berhasil disimpan.',
      data: updatedRows[0]
    });
  } catch (error) {
    console.error('[MONITORING_RECOMMEND] Error updating PPL recommendation:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal menyimpan rekomendasi agronomis PPL.'
    });
  }
};

module.exports = {
  getPendingFarmers,
  getAllFarmers,
  verifyFarmer,
  getSoilMap,
  getMonitoringLahan,
  getMonitoringSummary,
  saveMonitoringLahan,
  updateMonitoringRecommendation
};
