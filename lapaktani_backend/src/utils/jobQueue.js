const { v4: uuidv4 } = require('uuid');
const redisClient = require('../config/redis');

const REDIS_QUEUE_KEY = 'lapaktani:job_queue';

/**
 * Material 6: Asynchronous Background Job Queue (LapakTaniJobQueue)
 * Supports dual Redis list + in-memory non-blocking worker execution with retries and backoff.
 */
class LapakTaniJobQueue {
  constructor() {
    this.handlers = new Map();
    this.memoryQueue = [];
    this.recentJobs = [];
    this.isProcessing = false;
    this.stats = {
      totalEnqueued: 0,
      totalCompleted: 0,
      totalFailed: 0,
      totalRetried: 0,
    };

    this._registerDefaultHandlers();
  }

  _registerDefaultHandlers() {
    this.registerHandler('ORDER_NOTIFICATION_DISPATCH', async (payload) => {
      return {
        dispatched: true,
        orderId: payload?.orderId || null,
        invoiceNumber: payload?.invoiceNumber || null,
        eventType: payload?.eventType || 'ORDER_CREATED',
        processedAt: new Date().toISOString(),
      };
    });

    this.registerHandler('HARVEST_BROADCAST_FANOUT', async (payload) => {
      const pool = require('../config/db');
      const reportId = payload?.reportId || null;
      const komoditas = String(payload?.komoditas || 'Komoditas').trim();
      const statusTanam = String(payload?.statusTanam || 'SIAP_PANEN').toUpperCase();
      const farmerName = payload?.farmerName || 'Petani Mitra';
      const villageName = payload?.villageName || 'Sumenep';
      const weightKg = Number(payload?.estimasiBeratKg || 0);

      let recipientIds = Array.isArray(payload?.recipientIds) ? payload.recipientIds : [];
      if (recipientIds.length === 0) {
        try {
          const [recipients] = await pool.query(
            "SELECT id FROM users WHERE role IN ('penyuluh','admin') OR role_id IN (2, 3) LIMIT 20"
          );
          recipientIds = recipients.map((r) => r.id);
        } catch (_) {
          recipientIds = [];
        }
      }

      let deliveredCount = 0;
      for (const uid of recipientIds) {
        try {
          await pool.query(
            `INSERT INTO notifications (id, user_id, title, message, type, reference_id, is_read)
             VALUES (?, ?, ?, ?, 'harvest_broadcast', ?, 0)`,
            [
              `ntf-${uuidv4().slice(0, 12)}`,
              uid,
              `Siaran ${statusTanam}: ${komoditas}`,
              `${farmerName} (${villageName}) melaporkan ${weightKg} kg.`,
              reportId,
            ]
          );
          deliveredCount += 1;
        } catch (_) {}
      }

      return {
        fannedOutTo: deliveredCount,
        reportId,
        komoditas,
      };
    });

    this.registerHandler('WHATSAPP_FONNTE_DISPATCH', async (payload) => {
      const hasToken = Boolean((process.env.FONNTE_TOKEN || '').trim());
      return {
        channel: 'WhatsApp/Fonnte',
        mode: hasToken ? 'gateway_ready' : 'sandbox_simulation',
        recipient: payload?.recipientPhone || payload?.recipientId || 'system_subscriber',
        invoiceNumber: payload?.invoiceNumber || null,
        sentAt: new Date().toISOString(),
      };
    });

    this.registerHandler('SERVER_LOSS_RECOVERY_ALERT', async (payload) => {
      console.warn(
        `[QUEUE:SERVER_LOSS_ALERT] Type=${payload?.type || 'UNKNOWN'} Severity=${payload?.severity || 'CRITICAL'} Source=${payload?.source || 'runtime'} Msg=${payload?.errorMessage || ''}`
      );
      return {
        acknowledged: true,
        type: payload?.type || 'UNKNOWN',
        recordedAt: new Date().toISOString(),
      };
    });
  }

  registerHandler(type, handlerFn) {
    if (typeof handlerFn === 'function') {
      this.handlers.set(String(type), handlerFn);
    }
  }

  _recordJobSnapshot(job) {
    const idx = this.recentJobs.findIndex((j) => j.id === job.id);
    const snapshot = {
      id: job.id,
      type: job.type,
      status: job.status,
      attempts: job.attempts,
      maxAttempts: job.maxAttempts,
      enqueuedAt: job.enqueuedAt,
      completedAt: job.completedAt || null,
      lastError: job.lastError || null,
      resultSummary: job.resultSummary || null,
    };

    if (idx >= 0) {
      this.recentJobs[idx] = snapshot;
    } else {
      this.recentJobs.unshift(snapshot);
      if (this.recentJobs.length > 30) {
        this.recentJobs.length = 30;
      }
    }
  }

  enqueue(type, payload = {}, options = {}) {
    const job = {
      id: `job-${uuidv4().slice(0, 10)}`,
      type: String(type || 'GENERIC_JOB'),
      payload,
      status: 'QUEUED',
      attempts: 0,
      maxAttempts: Math.max(1, Number(options.maxAttempts) || 3),
      enqueuedAt: new Date().toISOString(),
      completedAt: null,
      lastError: null,
      resultSummary: null,
    };

    this.stats.totalEnqueued += 1;
    this.memoryQueue.push(job);
    this._recordJobSnapshot(job);

    if (redisClient.isOpen) {
      redisClient
        .lPush(
          REDIS_QUEUE_KEY,
          JSON.stringify({ id: job.id, type: job.type, enqueuedAt: job.enqueuedAt })
        )
        .catch(() => {});
    }

    this._scheduleWorker();

    return {
      id: job.id,
      type: job.type,
      status: job.status,
      attempts: job.attempts,
      maxAttempts: job.maxAttempts,
      enqueuedAt: job.enqueuedAt,
    };
  }

  _scheduleWorker() {
    if (this.isProcessing) return;
    setImmediate(() => {
      this._processNext().catch((err) => {
        console.error('[JOB_QUEUE] Worker loop error:', err.message);
        this.isProcessing = false;
      });
    });
  }

  async _processNext() {
    if (this.isProcessing) return;
    if (this.memoryQueue.length === 0) return;

    this.isProcessing = true;
    const job = this.memoryQueue.shift();

    try {
      job.status = 'PROCESSING';
      job.attempts += 1;
      this._recordJobSnapshot(job);

      if (redisClient.isOpen) {
        redisClient.rPop(REDIS_QUEUE_KEY).catch(() => {});
      }

      const handler = this.handlers.get(job.type);
      if (!handler) {
        throw new Error(`No handler registered for job type '${job.type}'`);
      }

      const result = await handler(job.payload, job);
      job.status = 'COMPLETED';
      job.completedAt = new Date().toISOString();
      job.resultSummary = result || { ok: true };
      this.stats.totalCompleted += 1;
      this._recordJobSnapshot(job);
    } catch (err) {
      job.lastError = err && err.message ? err.message : String(err);
      if (job.attempts < job.maxAttempts) {
        job.status = 'RETRY_SCHEDULED';
        this.stats.totalRetried += 1;
        this._recordJobSnapshot(job);
        const delayMs = Math.min(2000, 150 * Math.pow(2, job.attempts - 1));
        setTimeout(() => {
          this.memoryQueue.push(job);
          this._scheduleWorker();
        }, delayMs);
      } else {
        job.status = 'FAILED';
        job.completedAt = new Date().toISOString();
        this.stats.totalFailed += 1;
        this._recordJobSnapshot(job);
      }
    } finally {
      this.isProcessing = false;
      if (this.memoryQueue.length > 0) {
        this._scheduleWorker();
      }
    }
  }

  getQueueStats() {
    return {
      queueName: 'LapakTaniJobQueue',
      backend: redisClient.isOpen ? 'redis+memory_worker' : 'memory_worker',
      redisListKey: REDIS_QUEUE_KEY,
      registeredJobTypes: Array.from(this.handlers.keys()),
      totalEnqueued: this.stats.totalEnqueued,
      totalCompleted: this.stats.totalCompleted,
      totalFailed: this.stats.totalFailed,
      totalRetried: this.stats.totalRetried,
      pendingCount: this.memoryQueue.length,
      recentJobs: this.recentJobs.slice(0, 10),
    };
  }
}

const jobQueue = new LapakTaniJobQueue();

module.exports = jobQueue;
module.exports.LapakTaniJobQueue = LapakTaniJobQueue;
module.exports.jobQueue = jobQueue;
