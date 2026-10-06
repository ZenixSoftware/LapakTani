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
        up.avatar_url,
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
      message: 'Gagal mengambil daftar permohonan petani.',
      error: error.message
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
        up.avatar_url,
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
      message: 'Gagal mengambil data petani.',
      error: error.message
    });
  }
};

/**
 * PUT /api/penyuluh/verify-farmer/:id
 * Update verification_status to 'verified' or 'rejected'
 */
const verifyFarmer = async (req, res) => {
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
      message: 'Gagal memperbarui status verifikasi petani.',
      error: error.message
    });
  } finally {
    if (connection) {
      connection.release();
    }
  }
};

module.exports = {
  getPendingFarmers,
  getAllFarmers,
  verifyFarmer
};
