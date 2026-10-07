const { v4: uuidv4 } = require('uuid');
const pool = require('../config/db');

/**
 * Setup Farmer Profile and Legalities (US-05)
 * Endpoint: POST /api/profiles/farmer
 */
const setupFarmerProfile = async (req, res) => {
  const userId = req.user ? req.user.id : null;

  if (!userId) {
    return res.status(401).json({
      success: false,
      message: 'Akses ditolak. Pengguna belum diautentikasi.'
    });
  }

  const {
    nik_number,
    nik,
    land_area_ha,
    land_area,
    village_id,
    village,
    farmer_group_id,
    farmer_group,
    ktp_image_url,
    selfie_image_url
  } = req.body;

  const rawNik = nik_number || nik;
  const rawLandArea = land_area_ha !== undefined ? land_area_ha : land_area;
  const rawVillageId = village_id || village;
  const rawFarmerGroupId = farmer_group_id || farmer_group;

  if (!rawNik || rawLandArea === undefined || rawLandArea === null || rawLandArea === '' || !rawVillageId || !rawFarmerGroupId) {
    return res.status(400).json({
      success: false,
      message: 'Data tidak lengkap. NIK, luas lahan, desa domisili, dan kelompok tani wajib diisi.'
    });
  }

  const sanitizedNik = String(rawNik).trim();
  if (sanitizedNik.length !== 16) {
    return res.status(400).json({
      success: false,
      message: 'Nomor Induk Kependudukan (NIK) harus terdiri dari 16 digit.'
    });
  }

  const landAreaNumber = parseFloat(rawLandArea);
  if (isNaN(landAreaNumber) || landAreaNumber <= 0) {
    return res.status(400).json({
      success: false,
      message: 'Luas lahan harus berupa angka desimal positif.'
    });
  }

  let connection;
  try {
    connection = await pool.getConnection();
    await connection.beginTransaction();

    // Verify user exists
    const [userRows] = await connection.query(
      'SELECT id, full_name, email FROM users WHERE id = ? LIMIT 1',
      [userId]
    );

    if (userRows.length === 0) {
      await connection.rollback();
      return res.status(404).json({
        success: false,
        message: 'Pengguna tidak ditemukan dalam sistem.'
      });
    }

    const fallbackName = userRows[0].full_name || userRows[0].email.split('@')[0] || 'Petani LapakTani';

    // Resolve village_id for FK constraint
    let resolvedVillageId = null;
    const [villageRows] = await connection.query(
      'SELECT id FROM villages WHERE id = ? OR name LIKE ? LIMIT 1',
      [rawVillageId, `%${rawVillageId}%`]
    );

    if (villageRows.length > 0) {
      resolvedVillageId = villageRows[0].id;
    } else {
      const [firstVillage] = await connection.query('SELECT id FROM villages LIMIT 1');
      resolvedVillageId = firstVillage.length > 0 ? firstVillage[0].id : null;
    }

    // Resolve farmer_group_id for FK constraint
    let resolvedFarmerGroupId = null;
    const [groupRows] = await connection.query(
      'SELECT id FROM farmer_groups WHERE id = ? OR group_name LIKE ? LIMIT 1',
      [rawFarmerGroupId, `%${rawFarmerGroupId}%`]
    );

    if (groupRows.length > 0) {
      resolvedFarmerGroupId = groupRows[0].id;
    } else {
      try {
        const newGroupId = typeof rawFarmerGroupId === 'string' && rawFarmerGroupId.length <= 36
          ? rawFarmerGroupId
          : uuidv4();
        await connection.query(
          'INSERT INTO farmer_groups (id, group_name, village_id) VALUES (?, ?, ?)',
          [newGroupId, String(rawFarmerGroupId).substring(0, 150), resolvedVillageId || 1]
        );
        resolvedFarmerGroupId = newGroupId;
      } catch (_) {
        const [firstGroup] = await connection.query('SELECT id FROM farmer_groups LIMIT 1');
        resolvedFarmerGroupId = firstGroup.length > 0 ? firstGroup[0].id : null;
      }
    }

    const profileId = uuidv4();

    // Query 1: Insert or update user_profiles
    await connection.query(
      `INSERT INTO user_profiles (id, user_id, full_name, nik_number, village_id, avatar_url, verification_status)
       VALUES (?, ?, COALESCE((SELECT full_name FROM users WHERE id = ?), ?), ?, ?, ?, 'pending')
       ON DUPLICATE KEY UPDATE
         nik_number = VALUES(nik_number),
         village_id = VALUES(village_id),
         avatar_url = COALESCE(VALUES(avatar_url), avatar_url),
         verification_status = 'pending'`,
      [profileId, userId, userId, fallbackName, sanitizedNik, resolvedVillageId, selfie_image_url || null]
    );

    // Query 2: Insert or update farmer_profiles
    await connection.query(
      `INSERT INTO farmer_profiles (user_id, farmer_group_id, ktp_image_url)
       VALUES (?, ?, ?)
       ON DUPLICATE KEY UPDATE
         farmer_group_id = VALUES(farmer_group_id),
         ktp_image_url = COALESCE(VALUES(ktp_image_url), ktp_image_url)`,
      [userId, resolvedFarmerGroupId, ktp_image_url || null]
    );

    // Query 3: Save farm area details
    const farmId = uuidv4();
    await connection.query(
      `INSERT INTO farms (id, farmer_id, land_area_ha)
       VALUES (?, ?, ?)
       ON DUPLICATE KEY UPDATE
         land_area_ha = VALUES(land_area_ha)`,
      [farmId, userId, landAreaNumber]
    );

    // Update user role to petani if not already set
    await connection.query(
      "UPDATE users SET role = 'petani', role_id = 1 WHERE id = ?",
      [userId]
    );

    await connection.commit();

    console.log(`[PROFILE] Farmer profile created successfully for user_id=${userId}`);

    return res.status(201).json({
      success: true,
      message: 'Profil petani dan legalitas berhasil disimpan.',
      data: {
        profile_id: profileId,
        user_id: userId,
        nik_number: sanitizedNik,
        land_area_ha: landAreaNumber,
        village_id: resolvedVillageId,
        farmer_group_id: resolvedFarmerGroupId,
        verification_status: 'pending'
      }
    });
  } catch (error) {
    if (connection) {
      await connection.rollback();
    }
    console.error('[PROFILE] Error setting up farmer profile:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal menyimpan profil petani.',
      error: error.message
    });
  } finally {
    if (connection) {
      connection.release();
    }
  }
};

module.exports = {
  setupFarmerProfile
};
