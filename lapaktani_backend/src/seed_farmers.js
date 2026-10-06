const pool = require('./config/db');
const { v4: uuidv4 } = require('uuid');

async function seed() {
  const seedFarmers = [
    {
      name: 'Pak Wayan Sudirta',
      nik: '3204120988770001',
      poktan: 'Poktan Manik Sari',
      village: 'Desa Cibogo',
      land_area: 1.8,
      soil: 'Vulkanik Subur',
      phone: '081234567801'
    },
    {
      name: 'H. Maman Suratman',
      nik: '3204121503650003',
      poktan: 'Poktan Tani Makmur',
      village: 'Desa Cibogo',
      land_area: 2.5,
      soil: 'Aluvial',
      phone: '081234567802'
    },
    {
      name: 'Bu Siti Aminah',
      nik: '3204124401820002',
      poktan: 'Poktan Subur Barokah',
      village: 'Desa Lembang',
      land_area: 0.9,
      soil: 'Andosol',
      phone: '081234567803'
    },
    {
      name: 'Bambang Prasetyo',
      nik: '3204122107900004',
      poktan: 'Poktan Alam Lestari',
      village: 'Desa Parongpong',
      land_area: 3.2,
      soil: 'Latosol',
      phone: '081234567804'
    }
  ];

  for (const f of seedFarmers) {
    const [existing] = await pool.query('SELECT user_id FROM user_profiles WHERE nik_number = ?', [f.nik]);
    if (existing.length === 0) {
      const userId = uuidv4();
      const email = f.name.toLowerCase().replace(/[^a-z0-9]/g, '') + '@petani.lapaktani.id';
      await pool.query('INSERT IGNORE INTO users (id, full_name, email, password_hash, role_id, role, is_verified) VALUES (?, ?, ?, ?, 1, "petani", 0)', [
        userId, f.name, email, 'hash_placeholder'
      ]);

      const [vRows] = await pool.query('SELECT id FROM villages WHERE name LIKE ? LIMIT 1', ['%' + f.village.replace('Desa ', '') + '%']);
      const villageId = vRows.length > 0 ? vRows[0].id : 1;

      const groupId = uuidv4();
      await pool.query('INSERT IGNORE INTO farmer_groups (id, group_name, village_id) VALUES (?, ?, ?)', [
        groupId, f.poktan, villageId
      ]);

      const profileId = uuidv4();
      await pool.query('INSERT INTO user_profiles (id, user_id, full_name, nik_number, phone, village_id, verification_status) VALUES (?, ?, ?, ?, ?, ?, "pending")', [
        profileId, userId, f.name, f.nik, f.phone, villageId
      ]);

      await pool.query('INSERT INTO farmer_profiles (user_id, farmer_group_id) VALUES (?, ?)', [
        userId, groupId
      ]);

      const farmId = uuidv4();
      await pool.query('INSERT INTO farms (id, farmer_id, land_area_ha, soil_type, gps_latitude, gps_longitude) VALUES (?, ?, ?, ?, -6.81240100, 107.61892000)', [
        farmId, userId, f.land_area, f.soil
      ]);
    }
  }
  console.log('[SEED] Demo farmers check/seed complete');
  process.exit(0);
}

seed().catch(err => {
  console.error('[SEED] Error:', err.message);
  process.exit(1);
});
