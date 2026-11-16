const express = require('express');
const router = express.Router();
const chatController = require('../controllers/chatController');
const { verifyToken } = require('../middlewares/authMiddleware');

router.use(verifyToken);

router.get('/conversations', chatController.getConversations);
router.get('/contacts', chatController.getContacts);
router.post('/conversations/direct', chatController.openDirectConversation);
router.get('/conversations/:id/messages', chatController.getConversationMessages);
router.post('/conversations/:id/messages', chatController.sendMessage);

module.exports = router;
