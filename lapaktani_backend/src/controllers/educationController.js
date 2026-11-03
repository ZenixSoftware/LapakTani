const pool = require('../config/db');
const { v4: uuidv4 } = require('uuid');

/**
 * Helper to map database row to API response structure
 */
const formatArticleRow = (row) => {
  let steps = [];
  if (row.steps_json) {
    if (typeof row.steps_json === 'string') {
      try {
        steps = JSON.parse(row.steps_json);
      } catch (_) {
        steps = [];
      }
    } else if (Array.isArray(row.steps_json)) {
      steps = row.steps_json;
    }
  }

  const isOfficial = Boolean(
    row.is_official_penyuluh === 1 ||
    row.is_official_penyuluh === true ||
    row.role_id === 2 ||
    row.verification_status === 'verified'
  );

  return {
    id: row.id,
    title: row.title,
    category: row.category,
    commodity: row.commodity,
    summary: row.summary,
    content: row.content,
    steps: steps,
    author_id: row.author_id,
    author_name: row.author_name || 'Penyuluh Pertanian',
    author_role: row.role_id === 2 ? 'Penyuluh Pertanian Lapangan' : (row.role_name || 'Petani Ahli'),
    author_avatar: row.avatar_url || null,
    bpp_office: row.bpp_unit || (isOfficial ? 'BPP Lembang' : null),
    is_official_penyuluh: isOfficial,
    nip: row.nip || null,
    image_url: row.image_url || 'https://images.unsplash.com/photo-1551754655-cd27e38d2076?auto=format&fit=crop&w=900&q=80',
    published_at: row.created_at ? new Date(row.created_at).toISOString() : new Date().toISOString(),
    read_duration_minutes: row.read_time_minutes || 5,
    likes_count: row.likes_count || 0,
    comments_count: 0,
    tags: [row.commodity, row.category, isOfficial ? 'Penyuluh Resmi' : 'Komunitas']
  };
};

/**
 * GET /api/education/articles
 */
const getArticles = async (req, res) => {
  try {
    const { verified_only, category, commodity, search } = req.query;

    let query = `
      SELECT ea.*, 
             u.full_name as author_name, 
             u.role_id,
             up.avatar_url, 
             up.bpp_unit, 
             up.nip, 
             up.verification_status,
             CASE 
               WHEN u.role_id = 2 OR up.verification_status = 'verified' THEN 1 
               ELSE 0 
             END AS is_official_penyuluh
      FROM educational_articles ea
      JOIN users u ON ea.author_id = u.id
      LEFT JOIN user_profiles up ON u.id = up.user_id
      WHERE 1=1
    `;
    const params = [];

    if (commodity && commodity !== 'Semua') {
      query += ' AND ea.commodity = ?';
      params.push(commodity.trim());
    }

    if (category && category !== 'Semua') {
      query += ' AND LOWER(ea.category) = LOWER(?)';
      params.push(category.trim());
    }

    if (verified_only === 'true' || verified_only === '1') {
      query += ' AND (u.role_id = 2 OR up.verification_status = \'verified\')';
    }

    if (search && search.trim().length > 0) {
      const q = `%${search.trim().toLowerCase()}%`;
      query += ` AND (
        LOWER(ea.title) LIKE ? OR 
        LOWER(ea.commodity) LIKE ? OR 
        LOWER(ea.summary) LIKE ? OR 
        LOWER(u.full_name) LIKE ?
      )`;
      params.push(q, q, q, q);
    }

    query += ' ORDER BY ea.created_at DESC';

    const [rows] = await pool.query(query, params);
    const data = rows.map(formatArticleRow);

    return res.status(200).json({
      success: true,
      message: 'Materi edukasi pertanian berhasil diambil.',
      total: data.length,
      data: data
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Gagal mengambil data materi edukasi.',
      error: error.message
    });
  }
};

/**
 * GET /api/education/articles/:id
 */
const getArticleById = async (req, res) => {
  try {
    const { id } = req.params;

    const query = `
      SELECT ea.*, 
             u.full_name as author_name, 
             u.role_id,
             up.avatar_url, 
             up.bpp_unit, 
             up.nip, 
             up.verification_status,
             CASE 
               WHEN u.role_id = 2 OR up.verification_status = 'verified' THEN 1 
               ELSE 0 
             END AS is_official_penyuluh
      FROM educational_articles ea
      JOIN users u ON ea.author_id = u.id
      LEFT JOIN user_profiles up ON u.id = up.user_id
      WHERE ea.id = ?
    `;

    const [rows] = await pool.query(query, [id]);

    if (!rows || rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Materi edukasi tidak ditemukan.'
      });
    }

    return res.status(200).json({
      success: true,
      data: formatArticleRow(rows[0])
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Gagal mengambil detail materi.',
      error: error.message
    });
  }
};

/**
 * POST /api/education/articles
 */
const createArticle = async (req, res) => {
  try {
    const userId = req.user && req.user.id;
    if (!userId) {
      return res.status(401).json({
        success: false,
        message: 'Akses ditolak. Sesi login diperlukan untuk mempublikasikan materi.'
      });
    }

    // Verify user in MySQL
    const [userRows] = await pool.query(
      `SELECT u.id, u.full_name, u.role_id, up.verification_status, up.bpp_unit, up.nip 
       FROM users u 
       LEFT JOIN user_profiles up ON u.id = up.user_id 
       WHERE u.id = ?`,
      [userId]
    );

    if (!userRows || userRows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Data pengguna tidak ditemukan.'
      });
    }

    const user = userRows[0];
    const {
      title,
      category,
      commodity,
      summary,
      content,
      steps,
      image_url,
      read_duration_minutes,
      read_time_minutes
    } = req.body;

    if (!title || !category || !content) {
      return res.status(400).json({
        success: false,
        message: 'Judul, kategori, dan isi materi wajib diisi.'
      });
    }

    const articleId = `edu-${uuidv4()}`;
    const parsedSteps = Array.isArray(steps)
      ? steps.filter((s) => typeof s === 'string' && s.trim().length > 0)
      : [];
    const stepsJson = JSON.stringify(parsedSteps);
    const readMinutes = parseInt(read_time_minutes || read_duration_minutes, 10) || 5;
    const finalCommodity = commodity && commodity.trim().length > 0 ? commodity.trim() : 'Umum';
    const finalSummary = summary && summary.trim().length > 0 ? summary.trim() : content.substring(0, 160).trim();
    const finalImageUrl = image_url && image_url.trim().length > 0 
      ? image_url.trim() 
      : 'https://images.unsplash.com/photo-1551754655-cd27e38d2076?auto=format&fit=crop&w=900&q=80';

    await pool.query(
      `INSERT INTO educational_articles (
        id, author_id, title, category, commodity, summary, content, steps_json, image_url, read_time_minutes, likes_count
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0)`,
      [
        articleId,
        userId,
        title.trim(),
        category.trim(),
        finalCommodity,
        finalSummary,
        content.trim(),
        stepsJson,
        finalImageUrl,
        readMinutes
      ]
    );

    // Fetch newly created article with author details
    const [createdRows] = await pool.query(
      `SELECT ea.*, 
             u.full_name as author_name, 
             u.role_id,
             up.avatar_url, 
             up.bpp_unit, 
             up.nip, 
             up.verification_status,
             CASE 
               WHEN u.role_id = 2 OR up.verification_status = 'verified' THEN 1 
               ELSE 0 
             END AS is_official_penyuluh
      FROM educational_articles ea
      JOIN users u ON ea.author_id = u.id
      LEFT JOIN user_profiles up ON u.id = up.user_id
      WHERE ea.id = ?`,
      [articleId]
    );

    return res.status(201).json({
      success: true,
      message: 'Materi edukasi budidaya berhasil dipublikasikan ke database.',
      data: formatArticleRow(createdRows[0])
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Gagal membuat materi edukasi.',
      error: error.message
    });
  }
};

module.exports = {
  getArticles,
  getArticleById,
  createArticle
};
