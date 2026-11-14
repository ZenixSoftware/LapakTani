const { v4: uuidv4 } = require('uuid');
const pool = require('../config/db');

/**
 * Helper: safely post an ADVISORY_CARD to DM conversations with village/target farmers
 */
async function broadcastAdvisoryToFarmerChat(penyuluhId, report) {
  try {
    const [farmers] = await pool.query(
      "SELECT id, full_name FROM users WHERE role_id = 1 OR role = 'petani' ORDER BY CASE WHEN email LIKE '%supardi%' THEN 0 ELSE 1 END LIMIT 5"
    );
    if (!farmers.length) return;

    const metadata = JSON.stringify({
      report_id: report.id,
      desa: report.desa,
      kecamatan: report.kecamatan,
      komoditas: report.komoditas,
      status: report.status
    });
    const bodyText = `[ARAHAN PENYULUH DESA ${String(report.desa).toUpperCase()}] ${report.decision_summary}\n\nLangkah Lapangan:\n${report.action_plan}`;

    for (const farmer of farmers) {
      if (farmer.id === penyuluhId) continue;

      const [existingConvs] = await pool.query(
        `SELECT cc.id FROM chat_conversations cc
         JOIN chat_participants cp1 ON cc.id = cp1.conversation_id AND cp1.user_id = ?
         JOIN chat_participants cp2 ON cc.id = cp2.conversation_id AND cp2.user_id = ?
         WHERE cc.type = 'DIRECT'
         LIMIT 1`,
        [penyuluhId, farmer.id]
      );

      let convId;
      if (existingConvs.length > 0) {
        convId = existingConvs[0].id;
      } else {
        convId = `conv-${uuidv4().slice(0, 12)}`;
        await pool.query(
          `INSERT INTO chat_conversations (id, type, order_id, title) VALUES (?, 'DIRECT', NULL, ?)`,
          [convId, `Konsultasi Penyuluh — ${farmer.full_name || 'Petani'}`]
        );
        await pool.query(
          `INSERT IGNORE INTO chat_participants (conversation_id, user_id) VALUES (?, ?), (?, ?)`,
          [convId, penyuluhId, convId, farmer.id]
        );
      }

      const msgId = `msg-${uuidv4().slice(0, 12)}`;
      await pool.query(
        `INSERT INTO chat_messages (id, conversation_id, sender_id, message_type, body, metadata_json)
         VALUES (?, ?, ?, 'ADVISORY_CARD', ?, ?)`,
        [msgId, convId, penyuluhId, bodyText, metadata]
      );
      await pool.query('UPDATE chat_conversations SET updated_at = NOW() WHERE id = ?', [convId]);

      const notifId = `ntf-${uuidv4().slice(0, 12)}`;
      await pool.query(
        `INSERT INTO notifications (id, user_id, title, message, type, reference_id, is_read)
         VALUES (?, ?, ?, ?, 'rag_advisory', ?, 0)`,
        [notifId, farmer.id, `Arahan Penyuluh Desa ${report.desa}`, report.decision_summary.slice(0, 180), report.id]
      );
    }
  } catch (err) {
    console.warn('[RAG_DISPATCH] Farmer chat/notif broadcast warning:', err.message);
  }
}

/**
 * Helper: deterministic agronomic RAG synthesis grounded in live MySQL telemetry & alerts
 */
function buildDeterministicRagSynthesis(ragContext, queryPrompt = '') {
  const plot = ragContext.primary_plot;
  const desa = ragContext.desa || plot?.nama_desa || 'Dungkek';
  const kecamatan = ragContext.kecamatan || plot?.kecamatan || 'Sumenep';
  const komoditas = ragContext.komoditas || plot?.komoditas || 'Hortikultura & Pangan';

  const ph = Number(plot?.ph ?? 6.2);
  const moisture = Number(plot?.moisture ?? 35);
  const temp = Number(plot?.temp ?? 30);
  const ec = Number(plot?.conductivity ?? 950);
  const n = Number(plot?.nitrogen ?? 90);
  const p = Number(plot?.phosphorus ?? 25);
  const k = Number(plot?.potassium ?? 130);
  const fertility = Number(plot?.fertility ?? 55);
  const air = String(plot?.kondisi_air || 'tersedia').toLowerCase();

  const findings = [];
  const farmerSteps = [];
  const dinasNeeds = [];

  if (ph < 5.5) {
    findings.push(`pH tanah asam kritis (${ph})`);
    farmerSteps.push(`Lakukan pengapuran Dolomit / Kaptan dosis 1.5–2.0 Ton/Ha diaduk merata pada lapisan olah 14 hari sebelum tanam untuk menaikkan pH menuju 6.2–6.5.`);
    dinasNeeds.push(`Droping subsidi kapur pertanian Dolomit 2–3 Ton untuk Poktan Desa ${desa}.`);
  } else if (ph > 7.5) {
    findings.push(`pH tanah alkalis tinggi (${ph})`);
    farmerSteps.push(`Aplikasikan belerang/sulfur pertanian (ZA atau gipsum) dan tingkatkan bahan organik kompos matang 3 Ton/Ha untuk menstabilkan pH.`);
  }

  if (moisture < 15 || air.includes('sulit') || air.includes('kering')) {
    findings.push(`kekeringan & kelembapan kritis (${moisture}%, air: ${air})`);
    farmerSteps.push(`Pasang mulsa organik jerami / plastik perak-hitam, lakukan penyiraman intensif pagi/sore pada zona perakaran, dan tunda pemupukan N dosis tinggi hingga lengas > 25%.`);
    dinasNeeds.push(`Alokasi darurat pompa air sumur bor/submersibel & rehabilitasi jaringan irigasi/embung Kec. ${kecamatan}.`);
  }

  if (ec > 1500) {
    findings.push(`konduktivitas/salinitas tinggi (${ec} uS/cm)`);
    farmerSteps.push(`Lakukan pencucian garam (leaching) bertahap dengan air tawar berkualitas baik dan gunakan pupuk bebas klor (hindari KCl berlebih).`);
  }

  if (n < 70 || p < 20 || k < 100 || fertility < 40) {
    findings.push(`defisit hara makro NPK (N:${n}, P:${p}, K:${k}, Kesuburan:${fertility}/100)`);
    farmerSteps.push(`Berikan pupuk organik/kompos matang 2.5–3.0 Ton/Ha ditambah NPK majemuk 16-16-16 berimbang secara bertahap (tugal/kocor).`);
    dinasNeeds.push(`Prioritas kuota pupuk NPK & organik bersubsidi pada e-RDKK Desa ${desa}.`);
  }

  if (ragContext.pest_alerts.length > 0) {
    const pestNames = ragContext.pest_alerts.map((pt) => `${pt.pest_name} (${pt.severity_level || pt.severity || 'Sedang'})`).join(', ');
    findings.push(`peringatan OPT aktif: ${pestNames}`);
    farmerSteps.push(`Pengendalian OPT terpadu (PHT): sanitasi gulma, pasang perangkap feromon/yellow trap, dan aplikasi agens hayati/nabati secara serempak 1 hamparan Poktan.`);
    dinasNeeds.push(`Dukungan regu Brigade Proteksi Tanaman / pestisida nabati BPTPH untuk ${desa}.`);
  }

  if (findings.length === 0) {
    findings.push(`kondisi tanah relatif stabil (pH ${ph}, kelembapan ${moisture}%, kesuburan ${fertility}/100)`);
    farmerSteps.push(`Pertahankan jadwal pemupukan berimbang dan irigasi rutin; catat perkembangan mingguan pada Laporan Harian Petani.`);
    dinasNeeds.push(`Pertahankan status pendampingan reguler dan kesiapan serapan hasil panen melalui Koperasi Poktan.`);
  }

  const issueHeadline = findings.join('; ');
  const promptNote = queryPrompt ? ` Fokus analisis PPL: "${queryPrompt}".` : '';

  const decisionSummary = `Keputusan Agronomi RAG Desa ${desa} (${kecamatan}) untuk ${komoditas}: Terdeteksi ${issueHeadline}. Diperlukan intervensi pemulihan lahan terkoordinasi antara Petani Poktan dan dukungan sarpras Dinas Pertanian Kab. Sumenep.${promptNote}`;

  const actionPlan = [
    `[INSTRUKSI PETANI & POKTAN DESA ${desa.toUpperCase()}]`,
    ...farmerSteps.map((s, idx) => `${idx + 1}. ${s}`),
    '',
    `[ESKALASI KEBIJAKAN DINAS PERTANIAN KAB. SUMENEP]`,
    ...(dinasNeeds.length > 0 ? dinasNeeds.map((d, idx) => `${idx + 1}. ${d}`) : ['1. Monitoring berkala tingkat kecamatan melalui dashboard BPP Sumenep.'])
  ].join('\n');

  return {
    decision_summary: decisionSummary,
    action_plan: actionPlan,
    dinas_escalation_note: dinasNeeds.join(' '),
    farmer_field_steps: farmerSteps,
    synthesizer_engine: 'LapakTani Deterministic Agronomic RAG Engine v2'
  };
}

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
        COALESCE(fg.group_name, fp.farmer_group_id, 'Poktan Sumber Lestari (Sumenep)') AS poktan,
        COALESCE(v.name, 'Sumenep') AS village,
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
        COALESCE(fg.group_name, fp.farmer_group_id, 'Poktan Sumber Lestari (Sumenep)') AS poktan,
        COALESCE(v.name, 'Sumenep') AS village,
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
  const userRoleId = Number(req.user ? req.user.role_id : 0);
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

    await connection.query(
      'UPDATE user_profiles SET verification_status = ? WHERE user_id = ?',
      [targetStatus, matchedUserId]
    );

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
 * Retrieve spatial soil fertility map coordinates and NPK metrics (Web GIS + Advisory)
 */
const getSoilMap = async (req, res) => {
  try {
    const [farmRows] = await pool.query(`
      SELECT 
        f.id AS farm_id,
        f.farmer_id,
        COALESCE(u.full_name, 'Petani LapakTani') AS farmer_name,
        COALESCE(fg.group_name, 'Poktan Sumber Lestari') AS poktan_name,
        COALESCE(v.name, 'Sumenep') AS village_name,
        f.land_area_ha,
        COALESCE(f.soil_type, 'Aluvial Mediteran') AS soil_type,
        COALESCE(f.commodity, 'Cabai Merah Keriting') AS commodity,
        COALESCE(f.gps_latitude, -6.97715990) AS gps_latitude,
        COALESCE(f.gps_longitude, 113.80453020) AS gps_longitude,
        COALESCE(st.ph_level, 6.40) AS ph_level,
        COALESCE(st.nitrogen_mg_kg, 142.00) AS nitrogen_mg_kg,
        COALESCE(st.phosphorus_mg_kg, 38.00) AS phosphorus_mg_kg,
        COALESCE(st.potassium_mg_kg, 210.00) AS potassium_mg_kg,
        COALESCE(st.moisture_percentage, 72.50) AS moisture_percentage,
        COALESCE(st.temperature_celsius, 29.50) AS temperature_celsius,
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
      kecamatan: String(row.village_name || 'Sumenep'),
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
          submitted_by_role: ml.submitted_by_role || ml.tipe_penginput || 'petani',
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
        conditions.push("(LOWER(kondisi_air) LIKE '%sulit%' OR LOWER(kondisi_air) LIKE '%kering%')");
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
 * Both petani and penyuluh can record 8-in-1 soil telemetry; only penyuluh can authorize agronomic decisions.
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
    const jwtIsPenyuluh =
      req.user && (String(req.user.role || '').toLowerCase() === 'penyuluh' || Number(req.user.role_id) === 2);
    const bodyRoleHint = String(body.submitted_by_role || body.tipe_penginput || '').toLowerCase();
    const actorRole = jwtIsPenyuluh || (!req.user && bodyRoleHint === 'penyuluh') ? 'penyuluh' : 'petani';

    const latitude = Number(body.latitude ?? -6.9771599);
    const longitude = Number(body.longitude ?? 113.8045302);
    const namaDesa = String(body.nama_desa || 'Mandala').trim();
    const kecamatan = String(body.kecamatan || 'Sumenep').trim();
    const ph = Number(body.ph ?? 6.4);
    const moisture = Number(body.moisture ?? 18.0);
    const fertility = parseInt(body.fertility ?? 65, 10);

    const isCritical = ph < 5.5 || ph > 7.5 || moisture < 15 || fertility < 20;
    const statusVerifikasi =
      actorRole === 'penyuluh'
        ? body.status_verifikasi_ppl || (isCritical ? 'needs_action' : 'verified')
        : isCritical
          ? 'needs_action'
          : 'pending';

    // Only penyuluh may set official agronomic decision recommendations on creation
    const authorizedRecommendation = actorRole === 'penyuluh' ? (body.rekomendasi_ppl || null) : null;

    const [result] = await pool.query(
      `INSERT INTO monitoring_lahan (
        farm_id, user_id, latitude, longitude, nama_desa, kecamatan,
        irigasi, listrik, pompa_air, sumber_air, kondisi_air, sumber_energi_pompa,
        pembajak, tadahan_hujan, komoditas, varietas, luas_lahan, status_lahan,
        kelompok_tani, gagal_panen, hasil_panen_lalu, satuan_panen,
        temp, moisture, conductivity, ph, nitrogen, phosphorus, potassium, fertility,
        foto_daun, foto_pohon, foto_tanah, tipe_penginput, submitted_by_role, rekomendasi_ppl, status_verifikasi_ppl
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
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
        actorRole,
        actorRole,
        authorizedRecommendation,
        statusVerifikasi
      ]
    );

    const [createdRows] = await pool.query('SELECT * FROM monitoring_lahan WHERE id = ?', [
      result.insertId
    ]);

    return res.status(201).json({
      success: true,
      status: true,
      message:
        actorRole === 'petani'
          ? 'Telemetri tanah berhasil dikirim ke Penyuluh Desa untuk evaluasi.'
          : 'Data monitoring lahan & telemetri 8-in-1 berhasil disimpan ke cloud.',
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

/**
 * POST /api/penyuluh/rag-decision
 * Retrieve live telemetry, pest alerts & farmer logs, then synthesize agronomic RAG problem-solving output.
 */
const generateRagDecision = async (req, res) => {
  try {
    const { plot_id, desa, kecamatan, komoditas, query_prompt } = req.body || {};

    let plots = [];
    if (plot_id) {
      const [rows] = await pool.query(
        'SELECT * FROM monitoring_lahan WHERE CAST(id AS CHAR) = ? OR farm_id = ? LIMIT 1',
        [String(plot_id), String(plot_id)]
      );
      plots = rows;
    }

    if (plots.length === 0 && desa) {
      const [rows] = await pool.query(
        'SELECT * FROM monitoring_lahan WHERE LOWER(nama_desa) LIKE ? ORDER BY fertility ASC, created_at DESC LIMIT 3',
        [`%${String(desa).trim().toLowerCase()}%`]
      );
      plots = rows;
    }

    if (plots.length === 0) {
      const [rows] = await pool.query(
        'SELECT * FROM monitoring_lahan ORDER BY CASE WHEN ph < 5.5 OR moisture < 15 OR fertility < 20 THEN 0 ELSE 1 END, created_at DESC LIMIT 3'
      );
      plots = rows;
    }

    const primaryPlot = plots[0] || null;
    const resolvedDesa = desa || primaryPlot?.nama_desa || 'Dungkek';
    const resolvedKecamatan = kecamatan || primaryPlot?.kecamatan || 'Sumenep';
    const resolvedKomoditas = komoditas || primaryPlot?.komoditas || 'Hortikultura & Pangan';

    let pestAlerts = [];
    try {
      const [pRows] = await pool.query(
        `SELECT id, pest_name, commodity_name, severity_level, village_name, description, handling_recommendation, status
         FROM pest_reports
         WHERE LOWER(village_name) LIKE ? OR status != 'RESOLVED'
         ORDER BY created_at DESC LIMIT 5`,
        [`%${String(resolvedDesa).toLowerCase()}%`]
      );
      pestAlerts = pRows;
    } catch (_) {}

    let farmerLogs = [];
    try {
      const [lRows] = await pool.query(
        `SELECT farmer_name, desa, komoditas, activity_type, notes, moisture, ph, created_at
         FROM farmer_daily_logs
         WHERE LOWER(desa) LIKE ? OR LOWER(kecamatan) LIKE ?
         ORDER BY created_at DESC LIMIT 5`,
        [`%${String(resolvedDesa).toLowerCase()}%`, `%${String(resolvedKecamatan).toLowerCase()}%`]
      );
      farmerLogs = lRows;
    } catch (_) {}

    const ragContext = {
      retrieved_at: new Date().toISOString(),
      desa: resolvedDesa,
      kecamatan: resolvedKecamatan,
      komoditas: resolvedKomoditas,
      primary_plot: primaryPlot,
      related_plots_count: plots.length,
      pest_alerts: pestAlerts,
      farmer_daily_logs: farmerLogs
    };

    let synthesis = null;
    const geminiKey = process.env.GEMINI_API_KEY;
    if (geminiKey && typeof fetch === 'function') {
      try {
        const promptText = `Anda adalah Agronomis & Penyuluh BPP Kabupaten Sumenep. Analisislah data RAG real-time berikut dan berikan keputusan solusi masalah budidaya & kebijakan teknis dalam JSON valid dengan key: "decision_summary", "action_plan", "dinas_escalation_note", "farmer_field_steps" (array string).
Data Lahan: ${JSON.stringify(primaryPlot)}
Laporan Hama: ${JSON.stringify(pestAlerts)}
Catatan Harian Petani: ${JSON.stringify(farmerLogs)}
Instruksi tambahan PPL: ${query_prompt || 'Buat rekomendasi pemulihan kesuburan, pH, air, dan dukungan Dinas.'}`;

        const resp = await fetch(
          `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${geminiKey}`,
          {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              contents: [{ parts: [{ text: promptText }] }],
              generationConfig: { responseMimeType: 'application/json' }
            })
          }
        );

        if (resp.ok) {
          const json = await resp.json();
          const rawText = json?.candidates?.[0]?.content?.parts?.[0]?.text;
          if (rawText) {
            const parsed = JSON.parse(rawText);
            if (parsed.decision_summary && parsed.action_plan) {
              synthesis = {
                ...parsed,
                synthesizer_engine: 'Gemini 2.5 Flash Grounded Agronomic RAG'
              };
            }
          }
        }
      } catch (llmErr) {
        console.warn('[RAG_DECISION] Gemini fallback activated:', llmErr.message);
      }
    }

    if (!synthesis) {
      synthesis = buildDeterministicRagSynthesis(ragContext, query_prompt);
    }

    return res.status(200).json({
      success: true,
      message: 'Analisis keputusan agronomis berbasis RAG berhasil disintesis.',
      data: {
        plot_id: primaryPlot ? String(primaryPlot.farm_id || primaryPlot.id) : null,
        desa: resolvedDesa,
        kecamatan: resolvedKecamatan,
        komoditas: resolvedKomoditas,
        rag_context: ragContext,
        ...synthesis
      }
    });
  } catch (error) {
    console.error('[RAG_DECISION] Error generating decision:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal menghasilkan sintesis keputusan RAG.'
    });
  }
};

/**
 * POST /api/penyuluh/dispatch-decision
 * Dual-Target dispatch: Save & route RAG decision to Dinas Pertanian and/or Farmers/Poktan
 */
const dispatchRagDecision = async (req, res) => {
  try {
    const body = req.body || {};
    const {
      plot_id,
      desa,
      kecamatan = 'Sumenep',
      poktan_id = null,
      komoditas = 'Hortikultura & Pangan',
      rag_context = null,
      decision_summary,
      action_plan,
      target_scope = 'BOTH'
    } = body;

    if (!desa || !decision_summary || !action_plan) {
      return res.status(400).json({
        success: false,
        message: 'Desa, ringkasan keputusan, dan rencana aksi wajib diisi.'
      });
    }

    const validScopes = ['DINAS_ONLY', 'FARMERS_ONLY', 'BOTH'];
    const normalizedScope = validScopes.includes(String(target_scope).toUpperCase())
      ? String(target_scope).toUpperCase()
      : 'BOTH';

    const reportId = `dec-${uuidv4().slice(0, 12)}`;
    const penyuluhId = req.user?.id || 'usr-ppl-03';

    let penyuluhName = req.user?.full_name || 'Ir. Ahmad Hidayat, M.Agr.';
    try {
      const [uRows] = await pool.query('SELECT full_name FROM users WHERE id = ? LIMIT 1', [penyuluhId]);
      if (uRows.length > 0 && uRows[0].full_name) {
        penyuluhName = uRows[0].full_name;
      }
    } catch (_) {}

    const serializedContext =
      typeof rag_context === 'string' ? rag_context : JSON.stringify(rag_context || {});

    await pool.query(
      `INSERT INTO ppl_decision_reports (
        id, plot_id, penyuluh_id, penyuluh_name, desa, kecamatan, poktan_id, komoditas,
        rag_context_json, decision_summary, action_plan, target_scope, status
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'SENT')`,
      [
        reportId,
        plot_id ? String(plot_id) : null,
        penyuluhId,
        penyuluhName,
        String(desa).trim(),
        String(kecamatan).trim(),
        poktan_id,
        String(komoditas).trim(),
        serializedContext,
        String(decision_summary).trim(),
        String(action_plan).trim(),
        normalizedScope
      ]
    );

    if (plot_id) {
      try {
        await pool.query(
          `UPDATE monitoring_lahan
           SET rekomendasi_ppl = ?, status_verifikasi_ppl = 'verified'
           WHERE CAST(id AS CHAR) = ? OR farm_id = ?`,
          [String(decision_summary).trim(), String(plot_id), String(plot_id)]
        );
      } catch (_) {}
    }

    const [createdRows] = await pool.query('SELECT * FROM ppl_decision_reports WHERE id = ?', [reportId]);
    const createdReport = createdRows[0];

    if (normalizedScope === 'FARMERS_ONLY' || normalizedScope === 'BOTH') {
      await broadcastAdvisoryToFarmerChat(penyuluhId, createdReport);
    }

    if (normalizedScope === 'DINAS_ONLY' || normalizedScope === 'BOTH') {
      try {
        const [dinasUsers] = await pool.query(
          "SELECT id FROM users WHERE role = 'dinas' OR role_id = 5"
        );
        for (const dUser of dinasUsers) {
          await pool.query(
            `INSERT INTO notifications (id, user_id, title, message, type, reference_id, is_read)
             VALUES (?, ?, ?, ?, 'dinas_escalation', ?, 0)`,
            [
              `ntf-${uuidv4().slice(0, 12)}`,
              dUser.id,
              `Eskalasi RAG Penyuluh — Desa ${createdReport.desa}`,
              String(decision_summary).slice(0, 180),
              reportId
            ]
          );
        }
      } catch (notifErr) {
        console.warn('[RAG_DISPATCH] Dinas notif warning:', notifErr.message);
      }
    }

    return res.status(201).json({
      success: true,
      message: `Keputusan RAG Desa ${desa} berhasil dikirim (${normalizedScope}).`,
      data: createdReport
    });
  } catch (error) {
    console.error('[RAG_DISPATCH] Error dispatching decision:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal mengirim keputusan RAG ke tujuan yang dipilih.'
    });
  }
};

/**
 * GET /api/penyuluh/decision-reports
 * Query reports scoped to caller role (dinas | petani | admin | penyuluh)
 */
const getDecisionReports = async (req, res) => {
  try {
    const callerRole = String(req.user?.role || '').toLowerCase();
    const callerRoleId = Number(req.user?.role_id || 0);
    const requestedRole = String(req.query.role || callerRole || '').toLowerCase();
    const { desa, poktan_id, status } = req.query;

    const conditions = [];
    const params = [];

    if (requestedRole === 'dinas' || callerRoleId === 5) {
      conditions.push("target_scope IN ('DINAS_ONLY', 'BOTH')");
    } else if (requestedRole === 'petani' || callerRole === 'petani' || callerRoleId === 1) {
      conditions.push("target_scope IN ('FARMERS_ONLY', 'BOTH')");
    } else if (requestedRole === 'admin' || callerRole === 'admin' || callerRoleId === 3) {
      conditions.push("target_scope IN ('FARMERS_ONLY', 'BOTH')");
    }

    if (desa && String(desa).trim().toLowerCase() !== 'all') {
      conditions.push('(LOWER(desa) LIKE ? OR LOWER(kecamatan) LIKE ?)');
      const term = `%${String(desa).trim().toLowerCase()}%`;
      params.push(term, term);
    }

    if (poktan_id && String(poktan_id).trim() !== 'all') {
      conditions.push('poktan_id = ?');
      params.push(String(poktan_id).trim());
    }

    if (status && ['SENT', 'REVIEWED', 'ACKNOWLEDGED'].includes(String(status).toUpperCase())) {
      conditions.push('status = ?');
      params.push(String(status).toUpperCase());
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';
    const [rows] = await pool.query(
      `SELECT * FROM ppl_decision_reports ${whereClause} ORDER BY created_at DESC LIMIT 50`,
      params
    );

    const parsedRows = rows.map((row) => {
      let parsedContext = null;
      if (row.rag_context_json) {
        try {
          parsedContext = JSON.parse(row.rag_context_json);
        } catch (_) {
          parsedContext = null;
        }
      }
      return {
        ...row,
        rag_context: parsedContext
      };
    });

    return res.status(200).json({
      success: true,
      count: parsedRows.length,
      data: parsedRows
    });
  } catch (error) {
    console.error('[DECISION_REPORTS] Error fetching reports:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal mengambil daftar laporan keputusan Penyuluh.'
    });
  }
};

/**
 * PUT /api/penyuluh/decision-reports/:id/status
 * Allows Dinas Pertanian or Petani to review/acknowledge a dispatched RAG decision
 */
const updateDecisionReportStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status = 'REVIEWED', dinas_notes } = req.body || {};

    const normalizedStatus = ['SENT', 'REVIEWED', 'ACKNOWLEDGED'].includes(String(status).toUpperCase())
      ? String(status).toUpperCase()
      : 'REVIEWED';

    const [result] = await pool.query(
      `UPDATE ppl_decision_reports
       SET status = ?, dinas_notes = COALESCE(?, dinas_notes)
       WHERE id = ?`,
      [normalizedStatus, dinas_notes ?? null, id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({
        success: false,
        message: 'Laporan keputusan Penyuluh tidak ditemukan.'
      });
    }

    const [rows] = await pool.query('SELECT * FROM ppl_decision_reports WHERE id = ?', [id]);
    return res.status(200).json({
      success: true,
      message: `Status laporan keputusan diperbarui menjadi '${normalizedStatus}'.`,
      data: rows[0]
    });
  } catch (error) {
    console.error('[DECISION_REPORTS] Error updating report status:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal memperbarui status laporan keputusan.'
    });
  }
};

/**
 * POST /api/petani/daily-log
 */
const createFarmerDailyLog = async (req, res) => {
  try {
    const userId = req.user?.id || req.body?.user_id;
    const body = req.body || {};
    if (!userId) {
      return res.status(401).json({ success: false, message: 'Token otentikasi diperlukan.' });
    }
    if (!body.notes || String(body.notes).trim().length === 0) {
      return res.status(400).json({ success: false, message: 'Catatan kondisi lahan wajib diisi.' });
    }

    let farmerName = req.user?.full_name || body.farmer_name || 'Petani LapakTani';
    try {
      const [uRows] = await pool.query('SELECT full_name FROM users WHERE id = ? LIMIT 1', [userId]);
      if (uRows.length > 0 && uRows[0].full_name) {
        farmerName = uRows[0].full_name;
      }
    } catch (_) {}

    const logId = `log-${uuidv4().slice(0, 12)}`;
    await pool.query(
      `INSERT INTO farmer_daily_logs (
        id, user_id, farmer_name, desa, kecamatan, poktan_id, komoditas, activity_type, notes, moisture, ph, photo_url
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        logId,
        userId,
        farmerName,
        String(body.desa || 'Dungkek').trim(),
        String(body.kecamatan || 'Sumenep').trim(),
        body.poktan_id || null,
        String(body.komoditas || 'Bawang Merah').trim(),
        String(body.activity_type || 'Laporan Harian Lapangan').trim(),
        String(body.notes).trim(),
        body.moisture !== undefined && body.moisture !== null ? Number(body.moisture) : null,
        body.ph !== undefined && body.ph !== null ? Number(body.ph) : null,
        body.photo_url || null
      ]
    );

    const [rows] = await pool.query('SELECT * FROM farmer_daily_logs WHERE id = ?', [logId]);
    return res.status(201).json({
      success: true,
      message: 'Laporan harian petani berhasil dikirim ke Penyuluh Desa.',
      data: rows[0]
    });
  } catch (error) {
    console.error('[FARMER_LOG] Error creating daily log:', error.message);
    return res.status(500).json({ success: false, message: 'Gagal menyimpan laporan harian petani.' });
  }
};

/**
 * GET /api/petani/daily-log
 */
const getFarmerDailyLogs = async (req, res) => {
  try {
    const { desa, user_id } = req.query;
    const conditions = [];
    const params = [];

    if (desa && String(desa).toLowerCase() !== 'all') {
      conditions.push('(LOWER(desa) LIKE ? OR LOWER(kecamatan) LIKE ?)');
      const term = `%${String(desa).trim().toLowerCase()}%`;
      params.push(term, term);
    }
    if (user_id) {
      conditions.push('user_id = ?');
      params.push(String(user_id));
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';
    const [rows] = await pool.query(
      `SELECT * FROM farmer_daily_logs ${whereClause} ORDER BY created_at DESC LIMIT 50`,
      params
    );

    return res.status(200).json({
      success: true,
      count: rows.length,
      data: rows
    });
  } catch (error) {
    console.error('[FARMER_LOG] Error fetching daily logs:', error.message);
    return res.status(500).json({ success: false, message: 'Gagal mengambil laporan harian petani.' });
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
  updateMonitoringRecommendation,
  generateRagDecision,
  dispatchRagDecision,
  getDecisionReports,
  updateDecisionReportStatus,
  createFarmerDailyLog,
  getFarmerDailyLogs
};
