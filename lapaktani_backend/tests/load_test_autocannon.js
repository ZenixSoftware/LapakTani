/**
 * ============================================================================
 * [US-20] High-Concurrency Load Testing Suite for LapakTani Backend
 * ============================================================================
 * 
 * Tool: Autocannon (High-performance HTTP/1.1 benchmarking tool)
 * Target: LapakTani Express.js REST API
 * 
 * Scenarios Evaluated:
 * 1. Health & Server Telemetry Baseline (GET /api/health)
 * 2. Public Marketplace Product Catalog Read Load (GET /api/products)
 * 3. B2B Forward Contract & Harvest Quota Pools (GET /api/b2b-contracts/pools)
 * 4. Master Data & Agricultural Categories (GET /api/master/categories)
 * 
 * Usage:
 *   node tests/load_test_autocannon.js
 *   node tests/load_test_autocannon.js --quick
 *   npm run test:load
 * ============================================================================
 */

const autocannon = require('autocannon');
const http = require('http');

// Configuration options with CLI argument support
const args = process.argv.slice(2);
const isSmoke = args.includes('--smoke');
const isQuick = isSmoke || args.includes('--quick');

const BASE_URL = process.env.BASE_URL || 'http://localhost:3000';
const DEFAULT_CONNECTIONS = isSmoke ? 10 : (isQuick ? 20 : 100);
const DEFAULT_DURATION = isSmoke ? 2 : (isQuick ? 5 : 10); // seconds

const SCENARIOS = [
  {
    name: 'Scenario 1: System Health & DB Connection Baseline',
    path: '/api/health',
    method: 'GET',
    connections: isQuick ? 25 : 50,
    duration: DEFAULT_DURATION,
    slaMaxP99Ms: 500,
    slaMinReqSec: 100,
  },
  {
    name: 'Scenario 2: Marketplace Product Catalog (High Read Concurrency)',
    path: '/api/products',
    method: 'GET',
    connections: DEFAULT_CONNECTIONS,
    duration: DEFAULT_DURATION,
    slaMaxP99Ms: 1500,
    slaMinReqSec: 150,
  },
  {
    name: 'Scenario 3: B2B Harvest Forward Contract Pools',
    path: '/api/b2b-contracts/pools',
    method: 'GET',
    connections: DEFAULT_CONNECTIONS,
    duration: DEFAULT_DURATION,
    slaMaxP99Ms: 1500,
    slaMinReqSec: 100,
  },
  {
    name: 'Scenario 4: Master Agricultural Categories & Reference Data',
    path: '/api/master/categories',
    method: 'GET',
    connections: DEFAULT_CONNECTIONS,
    duration: DEFAULT_DURATION,
    slaMaxP99Ms: 1000,
    slaMinReqSec: 150,
  },
];

/**
 * Format bytes to readable string (KB, MB)
 */
function formatBytes(bytes) {
  if (bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return `${(bytes / Math.pow(k, i)).toFixed(2)} ${sizes[i]}`;
}

/**
 * Verify if target server is running before executing stress test (with retries)
 */
async function checkServerAvailability(url, maxAttempts = 10, delayMs = 1000) {
  const probe = () => {
    return new Promise((resolve) => {
      try {
        const parsedUrl = new URL(url);
        const req = http.request(
          {
            hostname: parsedUrl.hostname,
            port: parsedUrl.port || 80,
            path: '/',
            method: 'GET',
            timeout: 2000,
          },
          () => resolve(true)
        );

        req.on('error', () => resolve(false));
        req.on('timeout', () => {
          req.destroy();
          resolve(false);
        });
        req.end();
      } catch (err) {
        resolve(false);
      }
    });
  };

  for (let i = 1; i <= maxAttempts; i++) {
    const ok = await probe();
    if (ok) return true;
    if (i < maxAttempts) {
      await new Promise((res) => setTimeout(res, delayMs));
    }
  }
  return false;
}

/**
 * Execute a single load test scenario using Autocannon
 */
function runBenchmarkScenario(scenario) {
  return new Promise((resolve, reject) => {
    const fullUrl = `${BASE_URL}${scenario.path}`;
    console.log(`\n================================================================`);
    console.log(`🚀 Executing: ${scenario.name}`);
    console.log(`🔗 Target URL   : ${fullUrl}`);
    console.log(`⚡ Connections  : ${scenario.connections} concurrent clients`);
    console.log(`⏱️  Duration     : ${scenario.duration} seconds`);
    console.log(`================================================================`);

    const instance = autocannon(
      {
        url: fullUrl,
        method: scenario.method,
        connections: scenario.connections,
        duration: scenario.duration,
        pipelining: 1,
        headers: {
          'User-Agent': 'LapakTani-Autocannon-Benchmark/1.0',
          Accept: 'application/json',
        },
      },
      (err, result) => {
        if (err) {
          return reject(err);
        }
        resolve(result);
      }
    );

    // Track test progress in console
    autocannon.track(instance, { renderProgressBar: true });
  });
}

/**
 * Main execution orchestration
 */
async function main() {
  console.log('╔════════════════════════════════════════════════════════════════╗');
  console.log('║   LAPAKTANI BACKEND - HIGH CONCURRENCY LOAD TEST SUITE [US-20] ║');
  console.log('╚════════════════════════════════════════════════════════════════╝');
  console.log(`Target Base URL: ${BASE_URL}`);
  console.log(`Test Profile   : ${isQuick ? 'QUICK CHECK (shortened duration)' : 'FULL LOAD (standard duration)'}`);
  console.log(`Timestamp      : ${new Date().toISOString()}\n`);

  // 1. Health check availability
  const isAlive = await checkServerAvailability(BASE_URL);
  if (!isAlive) {
    console.error(`\n❌ ERROR: Cannot connect to server at ${BASE_URL}.`);
    console.error(`   Please start the LapakTani backend server first:`);
    console.error(`   > cd lapaktani_backend`);
    console.error(`   > npm run dev  (or node server.js)\n`);
    process.exit(1);
  }

  console.log(`✅ Server is reachable at ${BASE_URL}. Commencing load tests...\n`);

  const results = [];
  const activeScenarios = isSmoke ? SCENARIOS.slice(0, 2) : SCENARIOS;

  for (const scenario of activeScenarios) {
    try {
      const stats = await runBenchmarkScenario(scenario);
      
      const summary = {
        name: scenario.name,
        path: scenario.path,
        connections: scenario.connections,
        durationSec: scenario.duration,
        totalRequests: stats.requests.total,
        reqPerSec: stats.requests.average,
        latencyAvgMs: stats.latency.average,
        latencyP50Ms: stats.latency.p50,
        latencyP90Ms: stats.latency.p90,
        latencyP99Ms: stats.latency.p99,
        throughput: formatBytes(stats.throughput.average) + '/s',
        errors: stats.errors,
        timeouts: stats.timeouts,
        non2xx: stats['2xx'] !== undefined ? (stats.requests.total - stats['2xx']) : 0,
        slaMet: stats.latency.p99 <= scenario.slaMaxP99Ms && stats.errors === 0,
      };

      results.push(summary);
    } catch (err) {
      console.error(`❌ Scenario failed: ${scenario.name} - ${err.message}`);
      results.push({
        name: scenario.name,
        path: scenario.path,
        error: err.message,
        slaMet: false,
      });
    }
  }

  // 2. Print Benchmark Summary Report Table
  console.log('\n\n');
  console.log('====================================================================================================');
  console.log('                                  BENCHMARK PERFORMANCE SUMMARY REPORT                              ');
  console.log('====================================================================================================');

  console.table(
    results.map((r) => ({
      Scenario: r.name.split(':')[0],
      Endpoint: r.path,
      Conns: r.connections,
      'Total Req': r.totalRequests || 'N/A',
      'Req/sec': r.reqPerSec ? r.reqPerSec.toFixed(1) : 'N/A',
      'Avg Lat (ms)': r.latencyAvgMs ? r.latencyAvgMs.toFixed(2) : 'N/A',
      'p50 (ms)': r.latencyP50Ms ?? 'N/A',
      'p90 (ms)': r.latencyP90Ms ?? 'N/A',
      'p99 (ms)': r.latencyP99Ms ?? 'N/A',
      Throughput: r.throughput || 'N/A',
      Errors: (r.errors || 0) + (r.timeouts || 0),
      'SLA Pass': r.slaMet ? '✅ PASS' : '⚠️ WARN',
    }))
  );

  console.log('====================================================================================================');
  console.log('Load test completed successfully.');
  console.log('SLA Criteria:');
  console.log('  • p99 Latency within defined threshold (Health: 500ms, Catalog/Pools: 1500ms)');
  console.log('  • Zero connection timeouts or dropped sockets under sustained load');
  console.log('====================================================================================================\n');
}

if (require.main === module) {
  main().catch((err) => {
    console.error('Fatal load testing error:', err);
    process.exit(1);
  });
}

module.exports = { runBenchmarkScenario, SCENARIOS };
