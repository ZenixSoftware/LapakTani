/**
 * Seed Realistic Farmer Product Catalog for LapakTani
 * Seeds commodities, categories, and products associated with verified farmer profile
 */
const { v4: uuidv4 } = require('uuid');
const pool = require('./src/config/db');
const redisClient = require('./src/config/redis');

async function seedCatalog() {
  console.log('[SEED] Starting realistic catalog seeding...');

  try {
    // 1. Verify or create farmer profile
    let [farmers] = await pool.query(
      `SELECT fp.user_id, fp.farmer_group_id, u.full_name, u.is_verified 
       FROM farmer_profiles fp 
       JOIN users u ON fp.user_id = u.id 
       JOIN farmer_groups fg ON fp.farmer_group_id = fg.id
       WHERE u.role = 'petani' AND u.is_verified = 1 
       LIMIT 1`
    );

    let farmerId;
    let farmerGroupId;

    if (farmers.length > 0) {
      farmerId = farmers[0].user_id;
      // Prefer Poktan Tani Makmur if current group is generic like '99'
      const [taniMakmur] = await pool.query("SELECT id FROM farmer_groups WHERE group_name = 'Poktan Tani Makmur' LIMIT 1");
      if (taniMakmur.length > 0) {
        farmerGroupId = taniMakmur[0].id;
        await pool.query('UPDATE farmer_profiles SET farmer_group_id = ? WHERE user_id = ?', [farmerGroupId, farmerId]);
      } else {
        farmerGroupId = farmers[0].farmer_group_id;
      }
      console.log(`[SEED] Using verified farmer: ${farmers[0].full_name} (${farmerId}) with group ${farmerGroupId}`);
    } else {
      // Find any farmer group
      const [groups] = await pool.query('SELECT id FROM farmer_groups LIMIT 1');
      if (groups.length === 0) {
        throw new Error('No farmer groups found in database.');
      }
      farmerGroupId = groups[0].id;

      // Check if user exists
      const [users] = await pool.query("SELECT id FROM users WHERE role = 'petani' LIMIT 1");
      if (users.length > 0) {
        farmerId = users[0].id;
        await pool.query('UPDATE users SET is_verified = 1 WHERE id = ?', [farmerId]);
      } else {
        farmerId = uuidv4();
        await pool.query(
          `INSERT INTO users (id, full_name, email, password_hash, role_id, role, is_verified) 
           VALUES (?, 'Pak Maman Petani Teladan', 'maman.petani@lapaktani.id', 'dummy_hash', 1, 'petani', 1)`,
          [farmerId]
        );
      }

      await pool.query(
        `INSERT INTO farmer_profiles (user_id, farmer_group_id) 
         VALUES (?, ?) 
         ON DUPLICATE KEY UPDATE farmer_group_id = VALUES(farmer_group_id)`,
        [farmerId, farmerGroupId]
      );
      console.log(`[SEED] Created/Updated farmer profile for user ${farmerId}`);
    }

    // 2. Ensure categories exist in commodity_categories
    const categories = [
      { id: 'cat-sayurbuah', name: 'Sayur Buah' },
      { id: 'cat-sayurdaun', name: 'Sayur Daun' },
      { id: 'cat-umbiumbian', name: 'Umbi-umbian' },
      { id: 'cat-rempah', name: 'Rempah & Bumbu' }
    ];

    const categoryMap = {};
    for (const cat of categories) {
      const [existing] = await pool.query('SELECT id FROM commodity_categories WHERE category_name = ? LIMIT 1', [cat.name]);
      if (existing.length > 0) {
        categoryMap[cat.name] = existing[0].id;
      } else {
        await pool.query('INSERT INTO commodity_categories (id, category_name) VALUES (?, ?)', [cat.id, cat.name]);
        categoryMap[cat.name] = cat.id;
      }
    }

    // 3. Ensure commodities exist
    const commodities = [
      { id: 'com-tomat', category_name: 'Sayur Buah', name: 'Sayur Buah' },
      { id: 'com-kangkung', category_name: 'Sayur Daun', name: 'Sayur Daun' },
      { id: 'com-kentang', category_name: 'Umbi-umbian', name: 'Umbi-umbian' },
      { id: 'com-cabai', category_name: 'Rempah & Bumbu', name: 'Rempah & Bumbu' }
    ];

    for (const com of commodities) {
      const catId = categoryMap[com.category_name];
      await pool.query(
        `INSERT INTO commodities (id, category_id, specific_name) 
         VALUES (?, ?, ?) 
         ON DUPLICATE KEY UPDATE category_id = VALUES(category_id), specific_name = VALUES(specific_name)`,
        [com.id, catId, com.name]
      );
    }

    // 4. Ensure grade and unit exist
    await pool.query(
      `INSERT INTO product_grades (id, grade_label) 
       VALUES ('grade-1', 'Grade A / Super') 
       ON DUPLICATE KEY UPDATE grade_label = VALUES(grade_label)`
    );

    await pool.query(
      `INSERT INTO commodity_units (id, unit_name, description) 
       VALUES ('unit-kg', 'Per Kilogram', '1 Kg baku timbangan') 
       ON DUPLICATE KEY UPDATE unit_name = VALUES(unit_name)`
    );

    // 5. Seed 4 realistic catalog products
    const seedProducts = [
      {
        id: 'prod-tomat-lembang-001',
        title: 'Tomat Merah Segar Lembang 1 Kg',
        stock_kg: 50.0,
        price_per_kg: 12000.0,
        commodity_id: 'com-tomat',
        grade_id: 'grade-1',
        unit_id: 'unit-kg',
        image_url: 'uploads/products/tomat.jpg',
        description: 'Tomat merah segar dipanen subuh langsung dari perkebunan Lembang. Kulit kencang, kaya vitamin C, tanpa pestisida kimia berlebih.'
      },
      {
        id: 'prod-kangkung-hidro-002',
        title: 'Kangkung Organik Hidroponik Akar Utuh',
        stock_kg: 40.0,
        price_per_kg: 6000.0,
        commodity_id: 'com-kangkung',
        grade_id: 'grade-1',
        unit_id: 'unit-kg',
        image_url: 'uploads/products/kangkung.jpg',
        description: 'Kangkung hidroponik air pegunungan dengan akar basah utuh. Lebih renyah, tahan simpan 3 hari lebih lama, bebas residu lumpur.'
      },
      {
        id: 'prod-kentang-dieng-003',
        title: 'Kentang Dieng Super Grade A (Kulit Bersih)',
        stock_kg: 100.0,
        price_per_kg: 16000.0,
        commodity_id: 'com-kentang',
        grade_id: 'grade-1',
        unit_id: 'unit-kg',
        image_url: 'uploads/products/kentang.jpg',
        description: 'Kentang kuning varietas Granola dataran tinggi Dieng. Tekstur pulen, padat, cocok untuk perkedel, sup, atau kentang goreng renyah.'
      },
      {
        id: 'prod-cabai-rawit-004',
        title: 'Cabai Rawit Merah Super 1 Kg',
        stock_kg: 30.0,
        price_per_kg: 35000.0,
        commodity_id: 'com-cabai',
        grade_id: 'grade-1',
        unit_id: 'unit-kg',
        image_url: 'uploads/products/cabai.jpg',
        description: 'Cabai rawit merah petik pohon tingkat kematangan 95%. Pedas maksimal, kesegaran terjamin dengan rantai pasok dingin LapakTani.'
      }
    ];

    for (const item of seedProducts) {
      await pool.query(
        `INSERT INTO products 
         (id, farmer_id, commodity_id, grade_id, unit_id, title, description, price_per_kg, stock_kg, price, stock, image_url, created_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())
         ON DUPLICATE KEY UPDATE 
           farmer_id = VALUES(farmer_id),
           commodity_id = VALUES(commodity_id),
           grade_id = VALUES(grade_id),
           unit_id = VALUES(unit_id),
           title = VALUES(title),
           description = VALUES(description),
           price_per_kg = VALUES(price_per_kg),
           stock_kg = VALUES(stock_kg),
           price = VALUES(price),
           stock = VALUES(stock),
           image_url = VALUES(image_url)`,
        [
          item.id,
          farmerId,
          item.commodity_id,
          item.grade_id,
          item.unit_id,
          item.title,
          item.description,
          item.price_per_kg,
          item.stock_kg,
          item.price_per_kg,
          Math.floor(item.stock_kg),
          item.image_url
        ]
      );

      // Also ensure product_images has primary entry
      await pool.query(
        `INSERT INTO product_images (id, product_id, image_url, is_primary)
         VALUES (?, ?, ?, 1)
         ON DUPLICATE KEY UPDATE image_url = VALUES(image_url)`,
        [`img-${item.id}`, item.id, item.image_url]
      );

      console.log(`[SEED] Product seeded: ${item.title} (ID: ${item.id})`);
    }

    // Invalidate Redis cache if available
    try {
      if (redisClient.isOpen) {
        await redisClient.del('lapaktani_catalog');
        console.log('[SEED] Redis lapaktani_catalog cache invalidated.');
      }
    } catch (rErr) {
      console.warn('[SEED] Redis warning:', rErr.message);
    }

    console.log('[SEED] Realistic farmer catalog seeding completed successfully.');
    process.exit(0);
  } catch (error) {
    console.error('[SEED] Fatal error seeding catalog:', error);
    process.exit(1);
  }
}

seedCatalog();
