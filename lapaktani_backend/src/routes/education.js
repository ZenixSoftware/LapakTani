const express = require('express');
const router = express.Router();
const educationController = require('../controllers/educationController');
const { verifyToken } = require('../middlewares/authMiddleware');

// Articles endpoints (US-18)
// Public reading endpoints
router.get('/articles', educationController.getArticles);
router.get('/articles/:id', educationController.getArticleById);

// Authenticated creation endpoint (Requires valid JWT)
router.post('/articles', verifyToken, educationController.createArticle);

// Direct root fallbacks
router.get('/', educationController.getArticles);
router.get('/:id', educationController.getArticleById);
router.post('/', verifyToken, educationController.createArticle);

module.exports = router;
