/**
 * Unit Test / Verification Script for US-19: Pest Reporting & Emergency Alerts
 */
const assert = require('assert');
const {
  createPestReport,
  getPestReports,
  getActivePestAlert,
  updatePestReportStatus,
  findPestAlertTargetRecipients
} = require('./src/controllers/pestReportController');

// Mock Express req & res
function createMockReqRes(body = {}, query = {}, params = {}, user = null) {
  const req = {
    body,
    query,
    params,
    user,
    headers: {}
  };
  let statusCode = 200;
  let responseData = null;

  const res = {
    status(code) {
      statusCode = code;
      return res;
    },
    json(data) {
      responseData = data;
      return res;
    },
    getStatusCode: () => statusCode,
    getData: () => responseData
  };

  return { req, res };
}

async function runTests() {
  console.log('=== [TEST] US-19: Pelaporan & Peringatan Dini Serangan Hama ===\n');
  let passed = 0;

  // Test 1: Validation rejection on missing required fields
  console.log('1. Testing Form Validation (Missing required fields)...');
  const { req: req1, res: res1 } = createMockReqRes({
    pest_name: '', // Empty
    crop_type: 'Padi Ciherang'
  });
  await createPestReport(req1, res1);
  assert.strictEqual(res1.getStatusCode(), 400, 'Expected status 400 for empty form');
  assert.strictEqual(res1.getData().success, false);
  assert(res1.getData().errors.length > 0, 'Expected validation error messages');
  console.log('   ✓ Form validation properly rejected invalid payload with status 400');
  passed++;

  // Test 2: Notification Target Filtering by Poktan / Village
  console.log('\n2. Testing Notification Filter Logic (Poktan / Village / PPL)...');
  const targets = await findPestAlertTargetRecipients(
    'fg-lembang-01',
    'Poktan Tani Makmur',
    1,
    'f-maman' // Reporter ID (should be excluded)
  );
  assert(Array.isArray(targets), 'Targets should be an array');
  assert(!targets.includes('f-maman'), 'Reporter must not receive duplicate notification');
  assert(targets.length > 0, 'Target recipients must be identified for the Poktan');
  console.log(`   ✓ Correctly identified ${targets.length} target recipients for Poktan Tani Makmur`);
  console.log(`   ✓ Confirmed reporter (f-maman) is excluded from alert notifications`);
  passed++;

  // Test 3: Successful Pest Report Creation & Emergency Dispatch
  console.log('\n3. Testing Pest Report Submission (Berat -> Emergency Alert)...');
  const { req: req3, res: res3 } = createMockReqRes({
    pest_name: 'Wereng Batang Coklat (Nilaparvata lugens)',
    crop_type: 'Padi Sawah',
    severity: 'Berat',
    affected_area: '2.5 Hektar',
    farmer_group_name: 'Poktan Tani Makmur',
    farmer_group_id: 'fg-lembang-01',
    village_name: 'Desa Lembang',
    description: 'Rumpun padi menguning kecoklatan seperti terbakar (hopperburn) meluas di 5 petak sawah.',
    handling_recommendation: 'Keringkan lahan sementara, gunakan musuh alami laba-laba serigala dan insektisida berbahan aktif pimetrozin.'
  }, {}, {}, { id: 'f-wayan', full_name: 'Pak Wayan Sudirta', role_id: 1 });

  await createPestReport(req3, res3);
  assert.strictEqual(res3.getStatusCode(), 201, 'Expected status 201 for valid report');
  const createdData = res3.getData().data;
  assert(createdData.id.startsWith('pest-'), 'Report ID should have prefix pest-');
  assert.strictEqual(createdData.severity, 'Berat');
  assert.strictEqual(createdData.emergency_alert, true, 'Severity Berat must trigger emergency_alert = true');
  assert(res3.getData().notifications_sent > 0, 'Notifications must be sent to Poktan recipients');
  console.log(`   ✓ Report created successfully with ID: ${createdData.id}`);
  console.log(`   ✓ Emergency alert automatically activated: ${createdData.emergency_alert}`);
  console.log(`   ✓ Dispatched ${res3.getData().notifications_sent} alert notifications`);
  passed++;

  // Test 4: Active Alert Retrieval for Dashboard Banner
  console.log('\n4. Testing Active Emergency Alert Query for Dashboard Banner...');
  const { req: req4, res: res4 } = createMockReqRes({}, {
    farmer_group_name: 'Poktan Tani Makmur'
  });
  await getActivePestAlert(req4, res4);
  assert.strictEqual(res4.getStatusCode(), 200);
  assert.strictEqual(res4.getData().has_alert, true, 'Active alert should be detected');
  const bannerAlert = res4.getData().data;
  assert(bannerAlert.pest_name.length > 0, 'Alert must have pest name');
  console.log(`   ✓ Banner alert found: "${bannerAlert.pest_name}" at ${bannerAlert.farmer_group_name}`);
  passed++;

  // Test 5: Resolving Pest Alert
  console.log('\n5. Testing Status Update / Resolving Pest Alert...');
  const { req: req5, res: res5 } = createMockReqRes({
    status: 'resolved',
    handling_recommendation: 'Hama wereng telah terkendali setelah penyemprotan serentak.'
  }, {}, { id: createdData.id });
  await updatePestReportStatus(req5, res5);
  assert.strictEqual(res5.getStatusCode(), 200);
  assert.strictEqual(res5.getData().data.status, 'resolved');
  assert.strictEqual(res5.getData().data.emergency_alert, false, 'Resolved report must clear emergency_alert');
  console.log(`   ✓ Report ${createdData.id} status updated to resolved, emergency alert cleared`);
  passed++;

  console.log(`\n========================================`);
  console.log(`🎉 ALL ${passed}/5 US-19 UNIT TESTS PASSED SUCCESSFULLY!`);
  console.log(`========================================\n`);
}

runTests().catch(err => {
  console.error('❌ Test failed:', err);
  process.exit(1);
});

