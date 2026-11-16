/**
 * [US-17] Community & Forum Routes
 * Lead Backend & Database Architect: Rafael Rizky (Rafariz19)
 */

const express = require('express');
const router = express.Router();
const communityController = require('../controllers/communityController');
const { optionalVerifyToken, verifyToken } = require('../middlewares/authMiddleware');

// Public agricultural discussions & education
router.get('/discussions', communityController.getDiscussions);
router.post('/discussions', optionalVerifyToken, communityController.createDiscussion);

// Upvote & Comments
router.post('/discussions/:id/like', optionalVerifyToken, communityController.toggleUpvote);
router.get('/discussions/:id/comments', communityController.getComments);
router.post('/discussions/:id/comments', optionalVerifyToken, communityController.addComment);

// Forum Privat Desa (Village-scoped)
router.get('/village-forum', optionalVerifyToken, communityController.getVillageForum);
router.post('/village-forum', optionalVerifyToken, communityController.createVillageForumPost);

// Forum Antar-Penyuluh (PPL Coordination)
router.get('/ppl-forum', optionalVerifyToken, communityController.getPplForum);
router.post('/ppl-forum', optionalVerifyToken, communityController.createPplForumPost);

module.exports = router;
