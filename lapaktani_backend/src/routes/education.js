const express = require('express');
const router = express.Router();
const educationController = require('../controllers/educationController');

// Articles endpoints (US-18)
router.get('/articles', educationController.getArticles);
router.get('/articles/:id', educationController.getArticleById);
router.post('/articles', educationController.createArticle);

// Direct root fallbacks
router.get('/', educationController.getArticles);
router.get('/:id', educationController.getArticleById);
router.post('/', educationController.createArticle);

module.exports = router;
