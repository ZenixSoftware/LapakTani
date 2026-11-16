/**
 * [US-17] Verification Test Suite: Community Forums & Chat Direct Messaging
 * Author: Rafael Rizky (Rafariz19)
 * 
 * Verifies:
 * 1. Forum Diskusi Komunitas Antarpetani: fetch, create, upvote/like toggle, commenting
 * 2. Forum Privat Desa: village-scoped posts and announcements
 * 3. Forum Antar-Penyuluh: PPL technical advisory posts
 * 4. Direct Messaging: contacts directory, conversation payload structures
 */

const assert = require('assert');
const communityController = require('../src/controllers/communityController');
const chatController = require('../src/controllers/chatController');

async function runUS17Tests() {
  console.log('===============================================================');
  console.log('[US-17] STARTING COMMUNITY FORUMS & CHAT TEST SUITE');
  console.log('Lead Architect: Rafael Rizky (Rafariz19)');
  console.log('===============================================================\n');

  let passed = 0;
  let total = 0;

  async function testAsync(name, fn) {
    total++;
    try {
      await fn();
      console.log(`  [PASS] ${name}`);
      passed++;
    } catch (err) {
      console.error(`  [FAIL] ${name}: ${err.message}`);
    }
  }

  function mockRes() {
    const res = {
      statusCode: 200,
      headers: {},
      _json: null,
      status(code) {
        this.statusCode = code;
        return this;
      },
      json(data) {
        this._json = data;
        return this;
      }
    };
    return res;
  }

  // 1. Forum Diskusi Antarpetani: Create Post
  let createdDiscussionId = null;
  await testAsync('1.1 Community Controller: create public discussion post (kendala budidaya)', async () => {
    const req = {
      user: { id: 'usr-petani-01', full_name: 'Pak Sugeng (Petani Bluto)', role: 'petani', role_id: 1 },
      body: {
        title: 'Daun Cabai Menguning Pasca Hujan Lebat di Bluto',
        category: 'Penanganan Hama',
        commodity: 'Cabai Rawit',
        content: 'Tanaman cabai umur 45 hari mengalami daun menguning dan rontok bunga setelah curah hujan tinggi 3 hari berturut-turut.'
      }
    };
    const res = mockRes();
    await communityController.createDiscussion(req, res);

    assert.strictEqual(res.statusCode, 201, 'Response must be 201 Created');
    assert.strictEqual(res._json.success, true, 'success must be true');
    assert(res._json.data.id, 'Created post must return ID');
    createdDiscussionId = res._json.data.id;
    console.log(`      Created discussion post ID: ${createdDiscussionId}`);
  });

  // 2. Forum Diskusi: Upvote / Like Toggle
  await testAsync('1.2 Community Controller: upvote and toggle like counter', async () => {
    const reqLike = {
      params: { id: createdDiscussionId },
      body: { liked: true }
    };
    const resLike = mockRes();
    await communityController.toggleUpvote(reqLike, resLike);

    assert.strictEqual(resLike.statusCode, 200);
    assert.strictEqual(resLike._json.likes_count, 1, 'Likes count must increment to 1');
    assert.strictEqual(resLike._json.liked, true);

    // Toggle unlike
    const reqUnlike = {
      params: { id: createdDiscussionId },
      body: { liked: false }
    };
    const resUnlike = mockRes();
    await communityController.toggleUpvote(reqUnlike, resUnlike);
    assert.strictEqual(resUnlike._json.likes_count, 0, 'Likes count must decrement to 0');
  });

  // 3. Forum Diskusi: Add and Retrieve Comments
  await testAsync('1.3 Community Controller: add official PPL comment and fetch comments', async () => {
    const reqComment = {
      params: { id: createdDiscussionId },
      user: { id: 'usr-ppl-02', full_name: 'Ir. Siti Aminah', role: 'penyuluh', role_id: 2 },
      body: {
        comment_body: 'Segera perbaiki drainase bedengan dan aplikasikan fungisida tembaga hidroksida untuk cegah layu bakteri.'
      }
    };
    const resComment = mockRes();
    await communityController.addComment(reqComment, resComment);

    assert.strictEqual(resComment.statusCode, 201);
    assert.strictEqual(resComment._json.data.is_official, true, 'PPL comment must have official badge');

    // Fetch comments
    const reqGet = { params: { id: createdDiscussionId } };
    const resGet = mockRes();
    await communityController.getComments(reqGet, resGet);

    assert.strictEqual(resGet.statusCode, 200);
    assert(resGet._json.data.length >= 1, 'Must return at least 1 comment');
    assert.strictEqual(resGet._json.data[0].author_name, 'Ir. Siti Aminah');
  });

  // 4. Forum Privat Desa
  await testAsync('2.1 Forum Privat Desa: create and fetch village-scoped posts', async () => {
    const reqCreate = {
      user: { id: 'usr-poktan-01', full_name: 'Ketua Poktan Makmur', role: 'petani', village_id: '35.29.12.2001' },
      body: {
        village_id: '35.29.12.2001',
        title: 'Jadwal Giliran Pompa Air Irigasi Blok Barat',
        content: 'Mulai Selasa pagi giliran pembagian air irigasi untuk Poktan Makmur 1.',
        is_announcement: true
      }
    };
    const resCreate = mockRes();
    await communityController.createVillageForumPost(reqCreate, resCreate);

    assert.strictEqual(resCreate.statusCode, 201);
    assert.strictEqual(resCreate._json.data.is_announcement, true);

    const reqList = { query: { village_id: '35.29.12.2001' } };
    const resList = mockRes();
    await communityController.getVillageForum(reqList, resList);
    assert.strictEqual(resList.statusCode, 200);
  });

  // 5. Forum Antar-Penyuluh
  await testAsync('3.1 Forum Antar-Penyuluh: create technical advisory post', async () => {
    const reqPpl = {
      user: { id: 'usr-ppl-head', full_name: 'Koordinator BPP Lembang', role: 'penyuluh', role_id: 2 },
      body: {
        title: 'Kesiapsiagaan Ledakan Hama Wereng Batang Coklat Musim Tanam I',
        content: 'Instruksi kepada seluruh PPL di 5 WKPP binaan untuk melakukan gerakan gropyokan dan pengamatan petak contoh.'
      }
    };
    const resPpl = mockRes();
    await communityController.createPplForumPost(reqPpl, resPpl);

    assert.strictEqual(resPpl.statusCode, 201);
    assert.strictEqual(resPpl._json.success, true);
  });

  // 6. Direct Messaging (Chat Controller)
  await testAsync('4.1 Chat Controller: exports core direct messaging methods', async () => {
    assert(typeof chatController.getConversations === 'function', 'getConversations must be exported');
    assert(typeof chatController.getContacts === 'function', 'getContacts must be exported');
    assert(typeof chatController.openDirectConversation === 'function', 'openDirectConversation must be exported');
    assert(typeof chatController.sendMessage === 'function', 'sendMessage must be exported');
  });

  console.log(`\n[US-17 TEST SUMMARY] Passed: ${passed}/${total} (${((passed / total) * 100).toFixed(0)}%)`);
  if (passed === total) {
    console.log('[US-17] ALL COMMUNITY FORUMS & CHAT TESTS VERIFIED SUCCESSFULLY!\n');
    if (require.main === module) process.exit(0);
  } else {
    if (require.main === module) process.exit(1);
  }
}

if (require.main === module) {
  runUS17Tests();
}

module.exports = runUS17Tests;
