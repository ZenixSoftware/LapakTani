/**
 * [US-02] Verification Test Suite: Relational MySQL Schema (24+ Tables) & Migrations
 * Author: Rafael Rizky (Rafariz19)
 * 
 * Verifies:
 * 1. Total relational MySQL schema entities exceed 24 tables requirement
 * 2. Integrity of primary key constraints and functional domain categorization
 * 3. Migration scripts and idempotent schema creation functions
 */

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const { SCHEMA_CATALOG, getSchemaStats } = require('../src/config/schemaRegistry');

async function runUS02Tests() {
  console.log('===============================================================');
  console.log('[US-02] STARTING RELATIONAL DATABASE SCHEMA & MIGRATION TEST SUITE');
  console.log('Lead Database Architect: Rafael Rizky (Rafariz19)');
  console.log('===============================================================\n');

  let passed = 0;
  let total = 0;

  function test(name, fn) {
    total++;
    try {
      fn();
      console.log(`  [PASS] ${name}`);
      passed++;
    } catch (err) {
      console.error(`  [FAIL] ${name}: ${err.message}`);
    }
  }

  // 1. Table Count Verification
  test('1.1 Schema catalog must contain at least 24 relational tables', () => {
    const stats = getSchemaStats();
    console.log(`      Total registered tables: ${stats.totalTables} (Requirement: >= ${stats.minRequired})`);
    assert(stats.totalTables >= 24, `Must have at least 24 tables, found ${stats.totalTables}`);
    assert.strictEqual(stats.meetsRequirement, true, 'Meets requirement flag must be true');
  });

  // 2. Schema Structure Verification
  test('1.2 Every table must have a primary key and valid domain', () => {
    const validDomains = new Set(['AUTH', 'GEO', 'POKTAN', 'COMMODITY', 'COMMERCE', 'ORDERS', 'B2B', 'IOT', 'COMMUNITY', 'SYSTEM', 'FINANCE', 'SUPPLY_CHAIN', 'CHAT']);
    for (const table of SCHEMA_CATALOG.tables) {
      assert(table.name && table.name.length > 0, 'Table name must be defined');
      assert(table.pk && table.pk.length > 0, `Table ${table.name} must have a primary key`);
      assert(validDomains.has(table.domain), `Table ${table.name} has invalid domain: ${table.domain}`);
      assert(table.description && table.description.length > 0, `Table ${table.name} must have description`);
    }
    console.log(`      Validated ${SCHEMA_CATALOG.tables.length} tables for PK and domain consistency.`);
  });

  // 3. Functional Domain Distribution
  test('1.3 Domain coverage must span core agricultural and marketplace pillars', () => {
    const stats = getSchemaStats();
    const requiredDomains = ['AUTH', 'POKTAN', 'COMMERCE', 'ORDERS', 'B2B', 'COMMUNITY', 'CHAT'];
    for (const dom of requiredDomains) {
      assert(stats.domains[dom] > 0, `Domain ${dom} must have at least one table`);
    }
    console.log('      Domain table counts:', JSON.stringify(stats.domains));
  });

  // 4. Migration Files Verification
  test('1.4 Migration scripts exist and export callable runner functions', () => {
    const migrationFiles = [
      '../src/config/migrate_pest_alert.js',
      '../src/config/migrate_monitoring_lahan.js',
      '../src/config/migrate_streamlined_agro_flow.js',
      '../src/config/migrate_telemetry.js'
    ];

    for (const relPath of migrationFiles) {
      const fullPath = path.resolve(__dirname, relPath);
      assert(fs.existsSync(fullPath), `Migration file must exist: ${relPath}`);
      const runner = require(fullPath);
      assert(typeof runner === 'function', `Migration runner in ${relPath} must be a function`);
    }
    console.log(`      Verified ${migrationFiles.length} migration runner modules.`);
  });

  // 5. SQL Migrations Directory
  test('1.5 SQL migration directory exists with sequential migration steps', () => {
    const migrationsDir = path.resolve(__dirname, '../migrations');
    assert(fs.existsSync(migrationsDir), 'lapaktani_backend/migrations/ must exist');
    const sqlFiles = fs.readdirSync(migrationsDir).filter(f => f.endsWith('.sql'));
    assert(sqlFiles.length >= 8, `Expected at least 8 SQL migration files, found ${sqlFiles.length}`);
    console.log(`      Found ${sqlFiles.length} SQL migration files in migrations/.`);
  });

  console.log(`\n[US-02 TEST SUMMARY] Passed: ${passed}/${total} (${((passed / total) * 100).toFixed(0)}%)`);
  if (passed === total) {
    console.log('[US-02] ALL RELATIONAL DATABASE SCHEMA & MIGRATION TESTS VERIFIED SUCCESSFULLY!\n');
    if (require.main === module) process.exit(0);
  } else {
    if (require.main === module) process.exit(1);
  }
}

if (require.main === module) {
  runUS02Tests();
}

module.exports = runUS02Tests;
