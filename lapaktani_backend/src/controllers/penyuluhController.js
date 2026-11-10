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
    const [rows] = await pool.query(`
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

    return res.status(200).json({
      success: true,
      count: rows.length,
      data: rows
    });
  } catch (error) {
    console.error('[PENYULUH] Error fetching soil map data:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal mengambil data pemetaan geospasial tanah.'
    });
  }
};

module.exports = {
  getPendingFarmers,
  getAllFarmers,
  verifyFarmer,
  getSoilMap
};
