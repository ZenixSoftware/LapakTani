const { v4: uuidv4 } = require('uuid');
const pool = require('../config/db');

const ROLE_ID_MAP = {
  1: 'petani',
  2: 'penyuluh',
  3: 'admin',
  4: 'pembeli',
  5: 'dinas',
  6: 'superadmin'
};

function normalizeUserRow(u) {
  const canonicalRole = ROLE_ID_MAP[Number(u.role_id)] || u.role || 'petani';
  return {
    id: u.id,
    full_name: u.full_name || u.email || 'Pengguna LapakTani',
    email: u.email,
    role_id: u.role_id,
    role: canonicalRole,
    village_id: u.village_id ?? null,
    village_name: u.village_name ?? null
  };
}

function parseMetadata(raw) {
  if (!raw) return null;
  if (typeof raw === 'object') return raw;
  try {
    return JSON.parse(raw);
  } catch (_) {
    return null;
  }
}

async function enrichConversation(conversationId, currentUserId) {
  const [convRows] = await pool.query('SELECT * FROM chat_conversations WHERE id = ? LIMIT 1', [conversationId]);
  if (!convRows.length) return null;
  const conv = convRows[0];

  const [partRows] = await pool.query(
    `SELECT cp.last_read_at, u.id, u.full_name, u.email, u.role_id, u.role
     FROM chat_participants cp
     JOIN users u ON cp.user_id = u.id
     WHERE cp.conversation_id = ?`,
    [conversationId]
  );

  const participants = partRows.map(normalizeUserRow);
  const myPart = partRows.find((p) => p.id === currentUserId);
  const otherParticipant = participants.find((p) => p.id !== currentUserId) || participants[0] || null;

  const [lastMsgRows] = await pool.query(
    `SELECT m.*, u.full_name AS sender_name, u.role_id AS sender_role_id, u.role AS sender_role
     FROM chat_messages m
     LEFT JOIN users u ON m.sender_id = u.id
     WHERE m.conversation_id = ?
     ORDER BY m.created_at DESC
     LIMIT 1`,
    [conversationId]
  );

  let unreadCount = 0;
  try {
    const lastRead = myPart?.last_read_at || new Date(0);
    const [unreadRows] = await pool.query(
      `SELECT COUNT(*) AS cnt FROM chat_messages
       WHERE conversation_id = ? AND sender_id != ? AND created_at > ?`,
      [conversationId, currentUserId, lastRead]
    );
    unreadCount = Number(unreadRows[0]?.cnt || 0);
  } catch (_) {}

  const lastMsg = lastMsgRows[0]
    ? {
        id: lastMsgRows[0].id,
        sender_id: lastMsgRows[0].sender_id,
        sender_name: lastMsgRows[0].sender_name || 'Sistem',
        message_type: lastMsgRows[0].message_type,
        body: lastMsgRows[0].body,
        metadata: parseMetadata(lastMsgRows[0].metadata_json),
        created_at: lastMsgRows[0].created_at
      }
    : null;

  return {
    ...conv,
    participants,
    other_participant: otherParticipant,
    last_message: lastMsg,
    unread_count: unreadCount
  };
}

/**
 * GET /api/chat/conversations
 * Returns DIRECT conversations for all 5 roles, and ORDER conversations strictly to pembeli/admin.
 */
const getConversations = async (req, res) => {
  try {
    const userId = req.user.id;
    const callerRole = ROLE_ID_MAP[Number(req.user.role_id)] || String(req.user.role || 'petani').toLowerCase();
    const canSeeOrders = callerRole === 'pembeli' || callerRole === 'admin';
    const requestedType = String(req.query.type || '').trim().toUpperCase();

    const conditions = ['cp.user_id = ?'];
    const params = [userId];

    if (!canSeeOrders) {
      conditions.push("cc.type = 'DIRECT'");
    } else if (requestedType === 'DIRECT' || requestedType === 'ORDER') {
      conditions.push('cc.type = ?');
      params.push(requestedType);
    }

    const [convIds] = await pool.query(
      `SELECT cc.id
       FROM chat_conversations cc
       JOIN chat_participants cp ON cc.id = cp.conversation_id
       WHERE ${conditions.join(' AND ')}
       ORDER BY cc.updated_at DESC`,
      params
    );

    const enriched = [];
    for (const row of convIds) {
      const item = await enrichConversation(row.id, userId);
      if (item) enriched.push(item);
    }

    return res.status(200).json({
      success: true,
      count: enriched.length,
      data: enriched
    });
  } catch (error) {
    console.error('[CHAT] Error fetching conversations:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal memuat daftar percakapan.'
    });
  }
};

/**
 * GET /api/chat/contacts
 * Returns 5-role DM contacts (dinas, penyuluh, admin, petani, pembeli).
 * When caller is penyuluh, petani contacts are scoped to the Penyuluh's village_id (or prioritized).
 */
const getContacts = async (req, res) => {
  try {
    const userId = req.user.id;
    const callerRole = ROLE_ID_MAP[Number(req.user.role_id)] || String(req.user.role || 'petani').toLowerCase();

    let callerVillageId = null;
    try {
      const [meRows] = await pool.query(
        'SELECT village_id FROM user_profiles WHERE user_id = ? LIMIT 1',
        [userId]
      );
      if (meRows.length > 0 && meRows[0].village_id) {
        callerVillageId = Number(meRows[0].village_id);
      }
    } catch (_) {}

    let querySql = `
      SELECT u.id, u.full_name, u.email, u.role_id, u.role,
             up.village_id, v.name AS village_name
      FROM users u
      LEFT JOIN user_profiles up ON u.id = up.user_id
      LEFT JOIN villages v ON up.village_id = v.id
      WHERE u.id != ?
        AND (u.is_verified = 1 OR u.role_id IN (2, 3, 4, 5, 6) OR u.role IN ('penyuluh', 'admin', 'pembeli', 'dinas', 'superadmin'))
        AND (u.role_id IN (1, 2, 3, 4, 5, 6) OR u.role IN ('petani', 'penyuluh', 'admin', 'pembeli', 'dinas', 'superadmin'))
    `;
    const params = [userId];

    if (callerRole === 'penyuluh' && callerVillageId) {
      querySql += `
        AND (
          (u.role_id != 1 AND u.role != 'petani')
          OR up.village_id = ?
          OR up.village_id IS NULL
        )
      `;
      params.push(callerVillageId);
    }

    querySql += `
      ORDER BY CASE
        WHEN u.role_id = 5 OR u.role = 'dinas' THEN 0
        WHEN u.role_id = 2 OR u.role = 'penyuluh' THEN 1
        WHEN u.role_id = 3 OR u.role = 'admin' THEN 2
        WHEN u.role_id = 1 OR u.role = 'petani' THEN 3
        ELSE 4
      END, u.full_name ASC
      LIMIT 40
    `;

    const [rows] = await pool.query(querySql, params);

    return res.status(200).json({
      success: true,
      count: rows.length,
      data: rows.map(normalizeUserRow)
    });
  } catch (error) {
    console.error('[CHAT] Error fetching contacts:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal memuat daftar kontak.'
    });
  }
};

/**
 * POST /api/chat/conversations/direct
 * Find or create a 1-on-1 DIRECT or ORDER conversation with another user
 */
const openDirectConversation = async (req, res) => {
  try {
    const currentUserId = req.user.id;
    const {
      target_user_id,
      target_email,
      target_role,
      target_name,
      order_id,
      title,
      initial_message,
      message_type = 'TEXT',
      metadata = null
    } = req.body || {};

    let targetUser = null;

    if (target_user_id) {
      const [rows] = await pool.query(
        'SELECT id, full_name, email, role_id, role FROM users WHERE id = ? LIMIT 1',
        [String(target_user_id)]
      );
      if (rows.length > 0 && rows[0].id !== currentUserId) {
        targetUser = rows[0];
      }
    }

    if (!targetUser && target_email) {
      const [rows] = await pool.query(
        'SELECT id, full_name, email, role_id, role FROM users WHERE LOWER(email) = ? LIMIT 1',
        [String(target_email).trim().toLowerCase()]
      );
      if (rows.length > 0 && rows[0].id !== currentUserId) {
        targetUser = rows[0];
      }
    }

    if (!targetUser && target_role) {
      const r = String(target_role).trim().toLowerCase();
      let roleFilter = "u.role = 'penyuluh' OR u.role_id = 2";
      if (r === 'dinas' || r === 'pemerintah' || r === 'disperta') {
        roleFilter = "u.role = 'dinas' OR u.role_id = 5";
      } else if (r === 'superadmin') {
        roleFilter = "u.role = 'superadmin' OR u.role_id = 6";
      } else if (r === 'admin' || r === 'poktan' || r === 'ketua poktan' || r === 'toko') {
        roleFilter = "u.role = 'admin' OR u.role_id = 3";
      } else if (r === 'petani') {
        roleFilter = "u.role = 'petani' OR u.role_id = 1";
      } else if (r === 'pembeli') {
        roleFilter = "u.role = 'pembeli' OR u.role_id = 4";
      }

      let callerVillageId = null;
      if (r === 'petani') {
        try {
          const [vRows] = await pool.query('SELECT village_id FROM user_profiles WHERE user_id = ? LIMIT 1', [currentUserId]);
          callerVillageId = vRows[0]?.village_id ? Number(vRows[0].village_id) : null;
        } catch (_) {}
      }

      const [rows] = await pool.query(
        `SELECT u.id, u.full_name, u.email, u.role_id, u.role, up.village_id
         FROM users u
         LEFT JOIN user_profiles up ON u.id = up.user_id
         WHERE u.id != ? AND (${roleFilter})
         ORDER BY ${callerVillageId ? 'CASE WHEN up.village_id = ? THEN 0 ELSE 1 END,' : ''}
                  CASE WHEN u.email LIKE '%@lapaktani.id' THEN 0 ELSE 1 END
         LIMIT 1`,
        callerVillageId ? [currentUserId, callerVillageId] : [currentUserId]
      );
      if (rows.length > 0) {
        targetUser = rows[0];
      }
    }

    if (!targetUser && target_name) {
      const [rows] = await pool.query(
        'SELECT id, full_name, email, role_id, role FROM users WHERE id != ? AND LOWER(full_name) LIKE ? LIMIT 1',
        [currentUserId, `%${String(target_name).trim().toLowerCase()}%`]
      );
      if (rows.length > 0) {
        targetUser = rows[0];
      }
    }

    if (!targetUser) {
      return res.status(404).json({
        success: false,
        message: 'Pengguna tujuan obrolan tidak ditemukan.'
      });
    }

    const callerRole = ROLE_ID_MAP[Number(req.user.role_id)] || String(req.user.role || 'petani').toLowerCase();
    const targetCanonicalRole = ROLE_ID_MAP[Number(targetUser.role_id)] || String(targetUser.role || 'petani').toLowerCase();
    const wantsOrderConv = Boolean(order_id);
    if (wantsOrderConv && !['pembeli', 'admin'].includes(callerRole)) {
      return res.status(403).json({
        success: false,
        message: 'Chat penjualan (ORDER) hanya tersedia untuk Pembeli dan Penjual.'
      });
    }

    let conversationId = null;
    const convType = wantsOrderConv ? 'ORDER' : 'DIRECT';

    if (order_id) {
      const [existingOrderConvs] = await pool.query(
        `SELECT cc.id FROM chat_conversations cc
         JOIN chat_participants cp1 ON cc.id = cp1.conversation_id AND cp1.user_id = ?
         WHERE cc.type = 'ORDER' AND cc.order_id = ?
         LIMIT 1`,
        [currentUserId, String(order_id)]
      );
      if (existingOrderConvs.length > 0) {
        conversationId = existingOrderConvs[0].id;
      } else if (['pembeli', 'admin'].includes(targetCanonicalRole)) {
        const [pairOrderConvs] = await pool.query(
          `SELECT cc.id FROM chat_conversations cc
           JOIN chat_participants cp1 ON cc.id = cp1.conversation_id AND cp1.user_id = ?
           JOIN chat_participants cp2 ON cc.id = cp2.conversation_id AND cp2.user_id = ?
           WHERE cc.type = 'ORDER'
           ORDER BY cc.updated_at DESC
           LIMIT 1`,
          [currentUserId, targetUser.id]
        );
        if (pairOrderConvs.length > 0) {
          conversationId = pairOrderConvs[0].id;
        }
      }
    } else {
      const [existingDirectConvs] = await pool.query(
        `SELECT cc.id FROM chat_conversations cc
         JOIN chat_participants cp1 ON cc.id = cp1.conversation_id AND cp1.user_id = ?
         JOIN chat_participants cp2 ON cc.id = cp2.conversation_id AND cp2.user_id = ?
         WHERE cc.type = 'DIRECT'
         LIMIT 1`,
        [currentUserId, targetUser.id]
      );
      if (existingDirectConvs.length > 0) {
        conversationId = existingDirectConvs[0].id;
      }
    }

    if (!conversationId) {
      conversationId = `conv-${uuidv4().slice(0, 12)}`;
      const convTitle =
        title ||
        (order_id
          ? `Pesanan #${order_id}`
          : `DM — ${targetUser.full_name || targetUser.email}`);

      await pool.query(
        `INSERT INTO chat_conversations (id, type, order_id, title) VALUES (?, ?, ?, ?)`,
        [conversationId, convType, order_id ? String(order_id) : null, convTitle]
      );
      await pool.query(
        `INSERT IGNORE INTO chat_participants (conversation_id, user_id) VALUES (?, ?), (?, ?)`,
        [conversationId, currentUserId, conversationId, targetUser.id]
      );
    }

    if (initial_message && String(initial_message).trim().length > 0) {
      const allowedTypes = ['TEXT', 'ORDER_CARD', 'ADVISORY_CARD'];
      const msgType = allowedTypes.includes(String(message_type).toUpperCase())
        ? String(message_type).toUpperCase()
        : 'TEXT';
      await pool.query(
        `INSERT INTO chat_messages (id, conversation_id, sender_id, message_type, body, metadata_json)
         VALUES (?, ?, ?, ?, ?, ?)`,
        [
          `msg-${uuidv4().slice(0, 12)}`,
          conversationId,
          currentUserId,
          msgType,
          String(initial_message).trim(),
          metadata ? JSON.stringify(metadata) : null
        ]
      );
      await pool.query('UPDATE chat_conversations SET updated_at = NOW() WHERE id = ?', [conversationId]);
    }

    const enriched = await enrichConversation(conversationId, currentUserId);
    return res.status(200).json({
      success: true,
      data: enriched
    });
  } catch (error) {
    console.error('[CHAT] Error opening direct conversation:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal membuka ruang obrolan.'
    });
  }
};

/**
 * GET /api/chat/conversations/:id/messages
 */
const getConversationMessages = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    const [memberRows] = await pool.query(
      `SELECT cc.type FROM chat_participants cp
       JOIN chat_conversations cc ON cp.conversation_id = cc.id
       WHERE cp.conversation_id = ? AND cp.user_id = ? LIMIT 1`,
      [id, userId]
    );

    if (!memberRows.length) {
      return res.status(403).json({
        success: false,
        message: 'Anda bukan peserta dalam percakapan ini.'
      });
    }

    const callerRole = ROLE_ID_MAP[Number(req.user.role_id)] || String(req.user.role || 'petani').toLowerCase();
    if (memberRows[0].type === 'ORDER' && !['pembeli', 'admin'].includes(callerRole)) {
      return res.status(403).json({
        success: false,
        message: 'Chat penjualan hanya dapat diakses oleh Pembeli dan Penjual.'
      });
    }

    await pool.query(
      'UPDATE chat_participants SET last_read_at = NOW() WHERE conversation_id = ? AND user_id = ?',
      [id, userId]
    );

    const [rows] = await pool.query(
      `SELECT m.*, u.full_name AS sender_name, u.role_id AS sender_role_id, u.role AS sender_role
       FROM chat_messages m
       LEFT JOIN users u ON m.sender_id = u.id
       WHERE m.conversation_id = ?
       ORDER BY m.created_at ASC, m.id ASC`,
      [id]
    );

    const messages = rows.map((row) => ({
      id: row.id,
      conversation_id: row.conversation_id,
      sender_id: row.sender_id,
      sender_name: row.sender_name || 'Pengguna LapakTani',
      sender_role: ROLE_ID_MAP[Number(row.sender_role_id)] || row.sender_role || 'petani',
      message_type: row.message_type,
      body: row.body,
      metadata: parseMetadata(row.metadata_json),
      created_at: row.created_at
    }));

    return res.status(200).json({
      success: true,
      count: messages.length,
      data: messages
    });
  } catch (error) {
    console.error('[CHAT] Error loading messages:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal mengambil riwayat pesan.'
    });
  }
};

/**
 * POST /api/chat/conversations/:id/messages
 */
const sendMessage = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;
    const { body, message_type = 'TEXT', metadata = null } = req.body || {};

    if (!body || String(body).trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Isi pesan tidak boleh kosong.'
      });
    }

    const [memberRows] = await pool.query(
      'SELECT 1 FROM chat_participants WHERE conversation_id = ? AND user_id = ? LIMIT 1',
      [id, userId]
    );

    if (!memberRows.length) {
      return res.status(403).json({
        success: false,
        message: 'Anda tidak memiliki akses ke percakapan ini.'
      });
    }

    const allowedTypes = ['TEXT', 'ORDER_CARD', 'ADVISORY_CARD'];
    const msgType = allowedTypes.includes(String(message_type).toUpperCase())
      ? String(message_type).toUpperCase()
      : 'TEXT';

    const msgId = `msg-${uuidv4().slice(0, 12)}`;
    await pool.query(
      `INSERT INTO chat_messages (id, conversation_id, sender_id, message_type, body, metadata_json)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [msgId, id, userId, msgType, String(body).trim(), metadata ? JSON.stringify(metadata) : null]
    );

    await pool.query('UPDATE chat_conversations SET updated_at = NOW() WHERE id = ?', [id]);
    await pool.query(
      'UPDATE chat_participants SET last_read_at = NOW() WHERE conversation_id = ? AND user_id = ?',
      [id, userId]
    );

    const [created] = await pool.query(
      `SELECT m.*, u.full_name AS sender_name, u.role_id AS sender_role_id, u.role AS sender_role
       FROM chat_messages m
       LEFT JOIN users u ON m.sender_id = u.id
       WHERE m.id = ? LIMIT 1`,
      [msgId]
    );

    const row = created[0];
    return res.status(201).json({
      success: true,
      data: {
        id: row.id,
        conversation_id: row.conversation_id,
        sender_id: row.sender_id,
        sender_name: row.sender_name || 'Anda',
        sender_role: ROLE_ID_MAP[Number(row.sender_role_id)] || row.sender_role || 'petani',
        message_type: row.message_type,
        body: row.body,
        metadata: parseMetadata(row.metadata_json),
        created_at: row.created_at
      }
    });
  } catch (error) {
    console.error('[CHAT] Error sending message:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal mengirim pesan.'
    });
  }
};

module.exports = {
  getConversations,
  getContacts,
  openDirectConversation,
  getConversationMessages,
  sendMessage
};
