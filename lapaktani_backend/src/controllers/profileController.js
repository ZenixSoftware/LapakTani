const fs = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('uuid');
const pool = require('../config/db');

/**
 * Helper to delete uploaded files on disk during transaction rollback
 */
const deleteUploadedFile = (fileUrl) => {
  if (!fileUrl || typeof fileUrl !== 'string') return;
  try {
    let relativePath = fileUrl.trim();
    if (relativePath.includes('/uploads/')) {
      relativePath = relativePath.substring(relativePath.indexOf('/uploads/'));
    }
    const cleanPath = relativePath.startsWith('/') ? relativePath.slice(1) : relativePath;
    const baseUploadsDir = path.resolve(__dirname, '../../public/uploads');
    const fullPath = path.resolve(__dirname, '../../public', cleanPath);
    if (fullPath.startsWith(baseUploadsDir) && fs.existsSync(fullPath)) {
      fs.unlinkSync(fullPath);
      console.log(`[PROFILE] Rolled back orphan uploaded file: ${fullPath}`);
    }
  } catch (_) {
    // Silently catch fs errors as specified
  }
};

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
    selfie_image_url,
    birth_date
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

  let formattedBirthDate = null;
  if (birth_date) {
    const d = new Date(birth_date);
    if (!isNaN(d.getTime())) {
      formattedBirthDate = d.toISOString().split('T')[0];
    }
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
      deleteUploadedFile(ktp_image_url);
      deleteUploadedFile(selfie_image_url);
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

    // 1. Standard UPDATE operation since user_profiles is guaranteed to exist from registration
    await connection.query(
      `UPDATE user_profiles 
       SET nik_number = ?,
           village_id = ?,
           detail_address = ?,
           avatar_url = ?,
           birth_date = ?,
           verification_status = 'pending'
       WHERE user_id = ?`,
      [
        sanitizedNik,
        resolvedVillageId,
        req.body.home_address || req.body.address || req.body.detail_address || null,
        selfie_image_url || null,
        formattedBirthDate,
        userId
      ]
    );

    const [profileRows] = await connection.query(
      'SELECT id FROM user_profiles WHERE user_id = ? LIMIT 1',
      [userId]
    );
    const profileId = profileRows.length > 0 ? profileRows[0].id : userId;

    // 2. Insert or update farmer_profiles
    await connection.query(
      `INSERT INTO farmer_profiles (user_id, farmer_group_id, ktp_image_url)
       VALUES (?, ?, ?)
       ON DUPLICATE KEY UPDATE
         farmer_group_id = VALUES(farmer_group_id),
         ktp_image_url = COALESCE(VALUES(ktp_image_url), ktp_image_url)`,
      [userId, resolvedFarmerGroupId, ktp_image_url || null]
    );

    // 3. Save farm area details
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
        birth_date: formattedBirthDate,
        land_area_ha: landAreaNumber,
        village_id: resolvedVillageId,
        farmer_group_id: resolvedFarmerGroupId,
        verification_status: 'pending'
      }
    });
  } catch (error) {
    if (connection) {
      try {
        await connection.rollback();
      } catch (_) {}
    }
    // Delete orphan uploaded files on failure
    deleteUploadedFile(ktp_image_url);
    deleteUploadedFile(selfie_image_url);

    console.error('[PROFILE] Error setting up farmer profile:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal menyimpan profil petani.'
    });
  } finally {
    if (connection) {
      connection.release();
    }
  }
};

/**
 * Get current authenticated user profile
 * Endpoint: GET /api/profiles/me
 */
const getMyProfile = async (req, res) => {
  const userId = req.user ? req.user.id : null;
  if (!userId) {
    return res.status(401).json({
      success: false,
      message: 'Akses ditolak. Pengguna belum diautentikasi.'
    });
  }

  try {
    const [rows] = await pool.query(
      `SELECT 
        u.id, 
        u.email, 
        u.role, 
        u.role_id, 
        u.is_verified,
        COALESCE(up.full_name, u.full_name) AS full_name,
        up.nik_number, 
        up.village_id, 
        up.detail_address,
        up.avatar_url, 
        up.birth_date, 
        COALESCE(up.verification_status, 'pending') AS verification_status,
        fp.ktp_image_url, 
        fp.farmer_group_id, 
        COALESCE(f.land_area_ha, 0) AS farm_area_hectares,
        COALESCE(f.land_area_ha, 0) AS land_area_ha
      FROM users u
      LEFT JOIN user_profiles up ON u.id = up.user_id
      LEFT JOIN farmer_profiles fp ON u.id = fp.user_id
      LEFT JOIN farms f ON u.id = f.farmer_id
      WHERE u.id = ? 
      LIMIT 1`,
      [userId]
    );

    if (rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Pengguna tidak ditemukan.'
      });
    }

    return res.status(200).json({
      success: true,
      data: rows[0]
    });
  } catch (error) {
    console.error('[PROFILE] Error fetching profile:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal mengambil data profil.'
    });
  }
};

module.exports = {
  setupFarmerProfile,
  getMyProfile
};
