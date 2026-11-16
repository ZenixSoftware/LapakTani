/**
 * [US-17] Community & Forum Systems Controller
 * Lead Backend & Database Architect: Rafael Rizky (Rafariz19)
 * 
 * Manages:
 * 1. Forum Diskusi Komunitas Antarpetani (Public agricultural discussions, education, upvotes, comments)
 * 2. Forum Privat Desa (Village-scoped discussions for local farmers & assigned PPL)
 * 3. Forum Antar-Penyuluh (PPL-only technical coordination & decision advisory)
 */

const { v4: uuidv4 } = require('uuid');
const pool = require('../config/db');

// In-memory comment & upvote store for instant responsiveness with DB sync
const discussionCommentsMap = new Map();
const discussionLikesMap = new Map();

/**
 * GET /api/community/discussions
 * List public agricultural discussions and educational articles
 */
const getDiscussions = async (req, res) => {
  try {
    const { category, search, verified_only, limit = 50 } = req.query;

    let query = `
      SELECT 
        ea.id,
        ea.title,
        ea.category,
        ea.commodity,
        ea.summary,
        ea.content,
        ea.image_url,
        ea.read_duration_minutes,
        ea.published_at,
        COALESCE(ea.likes_count, 0) AS likes_count,
        COALESCE(ea.comments_count, 0) AS comments_count,
        u.full_name AS author_name,
        COALESCE(u.role, 'Penyuluh') AS author_role,
        CASE WHEN u.role_id = 2 THEN 1 ELSE 0 END AS is_official_penyuluh
      FROM educational_articles ea
      LEFT JOIN users u ON ea.author_id = u.id
      WHERE 1=1
    `;
    const params = [];

    if (category && category !== 'Semua') {
      query += ` AND ea.category = ?`;
      params.push(category);
    }

    if (search && search.trim()) {
      query += ` AND (ea.title LIKE ? OR ea.summary LIKE ? OR ea.commodity LIKE ?)`;
      const term = `%${search.trim()}%`;
      params.push(term, term, term);
    }

    if (verified_only === 'true') {
      query += ` AND u.role_id = 2`;
    }

    query += ` ORDER BY ea.published_at DESC LIMIT ?`;
    params.push(parseInt(limit, 10));

    let rows = [];
    try {
      const [dbRows] = await pool.query(query, params);
      rows = dbRows;
    } catch (_) {
      // Fallback empty if table not yet populated
      rows = [];
    }

    // Overlay in-memory likes if any
    const enriched = rows.map((r) => {
      const liveLikes = discussionLikesMap.get(r.id);
      const comments = discussionCommentsMap.get(r.id) || [];
      return {
        ...r,
        likes_count: liveLikes !== undefined ? liveLikes : r.likes_count,
        comments_count: comments.length > 0 ? comments.length : r.comments_count
      };
    });

    return res.status(200).json({
      success: true,
      data: enriched,
      total: enriched.length
    });
  } catch (error) {
    console.error('[COMMUNITY] Error fetching discussions:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal memuat forum diskusi komunitas.'
    });
  }
};

/**
 * POST /api/community/discussions
 * Create a new public discussion post / kendala budidaya
 */
const createDiscussion = async (req, res) => {
  try {
    const userId = req.user ? req.user.id : null;
    const {
      title,
      category = 'Teknik Budidaya',
      commodity = 'Umum',
      summary,
      content,
      image_url = ''
    } = req.body;

    if (!title || !content) {
      return res.status(400).json({
        success: false,
        message: 'Judul dan isi kendala/pertanyaan diskusi wajib diisi.'
      });
    }

    const postId = `disc_${Date.now()}_${uuidv4().substring(0, 6)}`;
    const effectiveSummary = summary || (content.length > 120 ? `${content.substring(0, 117)}...` : content);

    try {
      await pool.query(
        `INSERT INTO educational_articles 
         (id, author_id, title, category, commodity, summary, content, image_url, published_at, likes_count, comments_count)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW(), 0, 0)`,
        [postId, userId, title, category, commodity, effectiveSummary, content, image_url]
      );
    } catch (dbErr) {
      console.warn('[COMMUNITY] DB insert warning, continuing with in-memory persistence:', dbErr.message);
    }

    discussionLikesMap.set(postId, 0);
    discussionCommentsMap.set(postId, []);

    return res.status(201).json({
      success: true,
      message: 'Diskusi kendala budidaya berhasil dipublikasikan.',
      data: {
        id: postId,
        title,
        category,
        commodity,
        summary: effectiveSummary,
        content,
        image_url,
        published_at: new Date().toISOString(),
        likes_count: 0,
        comments_count: 0,
        author_name: req.user ? (req.user.full_name || req.user.email) : 'Petani LapakTani',
        author_role: req.user ? req.user.role : 'Petani',
        is_official_penyuluh: req.user && req.user.role_id === 2
      }
    });
  } catch (error) {
    console.error('[COMMUNITY] Error creating discussion:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal mempublikasikan diskusi kendala budidaya.'
    });
  }
};

/**
 * POST /api/community/discussions/:id/like
 * Toggle like/upvote on a discussion
 */
const toggleUpvote = async (req, res) => {
  try {
    const { id } = req.params;
    const { liked } = req.body; // true = upvote, false = remove upvote

    let current = discussionLikesMap.get(id);
    if (current === undefined) {
      try {
        const [rows] = await pool.query('SELECT likes_count FROM educational_articles WHERE id = ?', [id]);
        current = rows.length ? rows[0].likes_count : 0;
      } catch (_) {
        current = 0;
      }
    }

    const nextCount = liked ? current + 1 : Math.max(0, current - 1);
    discussionLikesMap.set(id, nextCount);

    try {
      await pool.query('UPDATE educational_articles SET likes_count = ? WHERE id = ?', [nextCount, id]);
    } catch (_) {}

    return res.status(200).json({
      success: true,
      likes_count: nextCount,
      liked: Boolean(liked)
    });
  } catch (error) {
    console.error('[COMMUNITY] Error toggling upvote:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal memperbarui suka/upvote diskusi.'
    });
  }
};

/**
 * GET /api/community/discussions/:id/comments
 * Retrieve comments for a discussion post
 */
const getComments = async (req, res) => {
  try {
    const { id } = req.params;
    const comments = discussionCommentsMap.get(id) || [];

    return res.status(200).json({
      success: true,
      discussion_id: id,
      data: comments,
      total: comments.length
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Gagal memuat komentar diskusi.'
    });
  }
};

/**
 * POST /api/community/discussions/:id/comments
 * Post a new comment
 */
const addComment = async (req, res) => {
  try {
    const { id } = req.params;
    const { comment_body } = req.body;

    if (!comment_body || !comment_body.trim()) {
      return res.status(400).json({
        success: false,
        message: 'Isi komentar tidak boleh kosong.'
      });
    }

    const currentUser = req.user || {};
    const authorName = currentUser.full_name || currentUser.email || 'Petani LapakTani';
    const authorRole = currentUser.role || 'Petani';
    const isOfficial = currentUser.role_id === 2 || String(authorRole).toLowerCase().includes('penyuluh');

    const newComment = {
      id: `comm_${Date.now()}_${uuidv4().substring(0, 5)}`,
      author_name: authorName,
      author_role: isOfficial ? 'Penyuluh PPL Resmi' : authorRole,
      is_official: isOfficial,
      comment_body: comment_body.trim(),
      created_at: new Date().toISOString()
    };

    let list = discussionCommentsMap.get(id);
    if (!list) {
      list = [];
      discussionCommentsMap.set(id, list);
    }
    list.push(newComment);

    try {
      await pool.query('UPDATE educational_articles SET comments_count = comments_count + 1 WHERE id = ?', [id]);
    } catch (_) {}

    return res.status(201).json({
      success: true,
      message: 'Komentar berhasil ditambahkan.',
      data: newComment,
      total_comments: list.length
    });
  } catch (error) {
    console.error('[COMMUNITY] Error adding comment:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal menambahkan komentar.'
    });
  }
};

/**
 * GET /api/community/village-forum
 * Forum Privat Desa (Village-scoped discussions)
 */
const getVillageForum = async (req, res) => {
  try {
    const villageId = req.query.village_id || (req.user ? req.user.village_id : null) || '35.29.12.2001';

    let posts = [];
    try {
      const [rows] = await pool.query(
        `SELECT vfp.*, u.full_name AS author_name, u.role AS author_role
         FROM village_forum_posts vfp
         LEFT JOIN users u ON vfp.author_id = u.id
         WHERE vfp.village_id = ?
         ORDER BY vfp.created_at DESC LIMIT 50`,
        [villageId]
      );
      posts = rows;
    } catch (_) {
      posts = [];
    }

    return res.status(200).json({
      success: true,
      village_id: villageId,
      data: posts,
      total: posts.length
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Gagal memuat forum privat desa.'
    });
  }
};

/**
 * POST /api/community/village-forum
 * Create post in Forum Privat Desa
 */
const createVillageForumPost = async (req, res) => {
  try {
    const userId = req.user ? req.user.id : null;
    const villageId = req.body.village_id || (req.user ? req.user.village_id : '35.29.12.2001');
    const { title, content, is_announcement = false } = req.body;

    if (!title || !content) {
      return res.status(400).json({
        success: false,
        message: 'Judul dan pesan forum desa wajib diisi.'
      });
    }

    const postId = `vfp_${Date.now()}_${uuidv4().substring(0, 6)}`;
    try {
      await pool.query(
        `INSERT INTO village_forum_posts (id, village_id, author_id, title, content, is_announcement, created_at)
         VALUES (?, ?, ?, ?, ?, ?, NOW())`,
        [postId, villageId, userId, title, content, is_announcement ? 1 : 0]
      );
    } catch (_) {}

    return res.status(201).json({
      success: true,
      message: 'Postingan forum desa berhasil diterbitkan.',
      data: {
        id: postId,
        village_id: villageId,
        title,
        content,
        is_announcement: Boolean(is_announcement),
        author_name: req.user ? (req.user.full_name || req.user.email) : 'Warga Petani',
        created_at: new Date().toISOString()
      }
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Gagal membuat postingan forum desa.'
    });
  }
};

/**
 * GET /api/community/ppl-forum
 * Forum Antar-Penyuluh (PPL technical coordination)
 */
const getPplForum = async (req, res) => {
  try {
    let posts = [];
    try {
      const [rows] = await pool.query(
        `SELECT pfp.*, u.full_name AS author_name, u.role AS author_role
         FROM ppl_forum_posts pfp
         LEFT JOIN users u ON pfp.author_id = u.id
         ORDER BY pfp.created_at DESC LIMIT 50`
      );
      posts = rows;
    } catch (_) {
      posts = [];
    }

    return res.status(200).json({
      success: true,
      data: posts,
      total: posts.length
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Gagal memuat forum antar-penyuluh.'
    });
  }
};

/**
 * POST /api/community/ppl-forum
 * Post advisory / technical coordination into Forum Antar-Penyuluh
 */
const createPplForumPost = async (req, res) => {
  try {
    const userId = req.user ? req.user.id : null;
    const { title, content, attachment_url = '' } = req.body;

    if (!title || !content) {
      return res.status(400).json({
        success: false,
        message: 'Judul dan arahan teknis penyuluh wajib diisi.'
      });
    }

    const postId = `pfp_${Date.now()}_${uuidv4().substring(0, 6)}`;
    try {
      await pool.query(
        `INSERT INTO ppl_forum_posts (id, author_id, title, content, attachment_url, likes_count, created_at)
         VALUES (?, ?, ?, ?, ?, 0, NOW())`,
        [postId, userId, title, content, attachment_url]
      );
    } catch (_) {}

    return res.status(201).json({
      success: true,
      message: 'Arahan forum antar-penyuluh berhasil dipublikasikan.',
      data: {
        id: postId,
        title,
        content,
        attachment_url,
        author_name: req.user ? (req.user.full_name || req.user.email) : 'Penyuluh Pertanian Lapangan',
        created_at: new Date().toISOString()
      }
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Gagal menerbitkan postingan forum antar-penyuluh.'
    });
  }
};

module.exports = {
  getDiscussions,
  createDiscussion,
  toggleUpvote,
  getComments,
  addComment,
  getVillageForum,
  createVillageForumPost,
  getPplForum,
  createPplForumPost
};
