const { v4: uuidv4 } = require('uuid');
const pool = require('../config/db');
const redisClient = require('../config/redis');
const jobQueue = require('./jobQueue');

const recentNotifications = [];
const recentIncidents = [];
let listenersAttached = false;

const stats = {
  transactionNotificationsSent: 0,
  serverLossAlertsHandled: 0,
  lastIncidentAt: null,
};

function pushBounded(list, item, maxLen = 50) {
  list.unshift(item);
  if (list.length > maxLen) {
    list.length = maxLen;
  }
}

/**
 * Material 9A: Transaction Lifecycle Notification Dispatcher
 * Persists database notification records and enqueues async delivery jobs via LapakTaniJobQueue.
 */
async function notifyTransactionEvent({
  eventType = 'ORDER_CREATED',
  orderId,
  invoiceNumber,
  buyerId = null,
  sellerId = null,
  totalAmount = 0,
  status = '',
  message = '',
  metadata = {},
} = {}) {
  const cleanEvent = String(eventType || 'ORDER_UPDATE').toUpperCase();
  const notifType = `transaction_${cleanEvent.toLowerCase()}`;
  const cleanMsg =
    message ||
    `Update Transaksi ${invoiceNumber || orderId || ''}: status ${status || cleanEvent} (Rp ${Number(totalAmount || 0).toLocaleString('id-ID')}).`;

  const targets = [...new Set([buyerId, sellerId].filter(Boolean))];
  const insertedIds = [];

  for (const targetUserId of targets) {
    const ntfId = `ntf-${uuidv4().slice(0, 12)}`;
    try {
      await pool.query(
        `INSERT INTO notifications (id, user_id, title, message, type, reference_id, is_read)
         VALUES (?, ?, ?, ?, ?, ?, 0)`,
        [
          ntfId,
          targetUserId,
          `Transaksi ${cleanEvent}: ${invoiceNumber || orderId || 'LapakTani'}`,
          cleanMsg.slice(0, 250),
          notifType,
          orderId || invoiceNumber || null,
        ]
      );
      insertedIds.push(ntfId);
    } catch (_) {}
  }

  const orderJob = jobQueue.enqueue('ORDER_NOTIFICATION_DISPATCH', {
    eventType: cleanEvent,
    orderId,
    invoiceNumber,
    buyerId,
    sellerId,
    totalAmount,
    status,
    message: cleanMsg,
    metadata,
  });

  const waJob = jobQueue.enqueue('WHATSAPP_FONNTE_DISPATCH', {
    eventType: cleanEvent,
    orderId,
    invoiceNumber,
    recipientId: buyerId || sellerId || 'buyer',
    text: cleanMsg,
  });

  stats.transactionNotificationsSent += 1;
  const entry = {
    eventType: cleanEvent,
    orderId: orderId || null,
    invoiceNumber: invoiceNumber || null,
    status: status || null,
    targetsCount: targets.length,
    dbInsertedCount: insertedIds.length,
    queuedJobs: [orderJob.id, waJob.id],
    timestamp: new Date().toISOString(),
  };
  pushBounded(recentNotifications, entry, 50);
  return entry;
}

/**
 * Material 9B: Graceful Server-Loss & DB-Disconnect Failover Alert Recorder
 */
async function recordServerIncident({
  type = 'RUNTIME_INCIDENT',
  severity = 'CRITICAL',
  source = 'process',
  errorMessage = '',
  metadata = {},
} = {}) {
  const incident = {
    id: `inc-${uuidv4().slice(0, 10)}`,
    type: String(type),
    severity: String(severity),
    source: String(source),
    errorMessage: String(errorMessage || 'Unknown infrastructure exception'),
    metadata,
    timestamp: new Date().toISOString(),
  };

  stats.serverLossAlertsHandled += 1;
  stats.lastIncidentAt = incident.timestamp;
  pushBounded(recentIncidents, incident, 30);

  console.error(
    `[SERVER-LOSS-GUARD] [${incident.severity}] ${incident.type} (${incident.source}): ${incident.errorMessage}`
  );

  jobQueue.enqueue('SERVER_LOSS_RECOVERY_ALERT', incident);

  // Best-effort DB alert to admins when connection is still available
  try {
    const [admins] = await pool.query(
      "SELECT id FROM users WHERE role = 'admin' OR role_id = 3 LIMIT 3"
    );
    for (const adm of admins) {
      await pool.query(
        `INSERT INTO notifications (id, user_id, title, message, type, reference_id, is_read)
         VALUES (?, ?, ?, ?, 'server_loss_alert', ?, 0)`,
        [
          `ntf-${uuidv4().slice(0, 12)}`,
          adm.id,
          `[ALERT] ${incident.type}`,
          incident.errorMessage.slice(0, 220),
          incident.id,
        ]
      );
    }
  } catch (_) {}

  return incident;
}

/**
 * Attach process-level server-loss & pool-disconnect guard listeners (idempotent).
 */
function registerServerLossHandlers({ pool: dbPool = pool, redisClient: rClient = redisClient } = {}) {
  if (listenersAttached) {
    return;
  }
  listenersAttached = true;

  process.on('uncaughtException', (err) => {
    recordServerIncident({
      type: 'UNCAUGHT_EXCEPTION',
      severity: 'CRITICAL',
      source: 'node.process',
      errorMessage: err && err.message ? err.message : String(err),
      metadata: { stackSnippet: err && err.stack ? String(err.stack).slice(0, 300) : null },
    }).catch(() => {});
  });

  process.on('unhandledRejection', (reason) => {
    recordServerIncident({
      type: 'UNHANDLED_REJECTION',
      severity: 'HIGH',
      source: 'node.promise',
      errorMessage: reason && reason.message ? reason.message : String(reason),
    }).catch(() => {});
  });

  if (dbPool && typeof dbPool.on === 'function') {
    dbPool.on('error', (dbErr) => {
      recordServerIncident({
        type: 'MYSQL_POOL_DISCONNECT',
        severity: 'CRITICAL',
        source: 'mysql2.pool',
        errorMessage: dbErr && dbErr.message ? dbErr.message : String(dbErr),
        metadata: { code: dbErr && dbErr.code ? dbErr.code : null },
      }).catch(() => {});
    });
  }

  if (rClient && typeof rClient.on === 'function') {
    rClient.on('error', (redisErr) => {
      const msg = redisErr && redisErr.message ? redisErr.message : String(redisErr);
      if (
        msg.toLowerCase().includes("unknown command 'hello'") ||
        msg.toLowerCase().includes('unknown command `hello`') ||
        msg.toLowerCase().includes('unknown command hello')
      ) {
        return;
      }
      recordServerIncident({
        type: 'REDIS_CONNECTION_DEGRADED',
        severity: 'WARN',
        source: 'redis.client',
        errorMessage: msg,
      }).catch(() => {});
    });
  }
}

async function checkInfrastructureHealth({ pool: dbPool = pool, redisClient: rClient = redisClient } = {}) {
  let dbHealthy = false;
  let redisHealthy = false;

  try {
    const conn = await dbPool.getConnection();
    await conn.ping();
    conn.release();
    dbHealthy = true;
  } catch (err) {
    await recordServerIncident({
      type: 'DB_HEALTH_CHECK_FAILED',
      severity: 'CRITICAL',
      source: 'health.probe',
      errorMessage: err.message,
    });
  }

  try {
    if (rClient && rClient.isOpen) {
      await rClient.ping();
      redisHealthy = true;
    }
  } catch (_) {}

  return {
    dbHealthy,
    redisHealthy,
    checkedAt: new Date().toISOString(),
  };
}

function getNotificationStats() {
  return {
    service: 'LapakTaniNotificationAndFailoverService',
    listenersAttached,
    transactionEventsSupported: [
      'ORDER_CREATED',
      'ORDER_PAID',
      'ORDER_SHIPPED',
      'ORDER_COMPLETED',
      'ORDER_CANCELLED',
    ],
    serverLossHandlers: [
      'uncaughtException',
      'unhandledRejection',
      'mysqlPoolError',
      'redisDisconnectGuard',
    ],
    stats: { ...stats },
    recentNotifications: recentNotifications.slice(0, 10),
    recentIncidents: recentIncidents.slice(0, 10),
  };
}

module.exports = {
  notifyTransactionEvent,
  recordServerIncident,
  registerServerLossHandlers,
  checkInfrastructureHealth,
  getNotificationStats,
};
