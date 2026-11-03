const express = require('express');
const router = express.Router();
const educationController = require('../controllers/educationController');

router.get('/articles', educationController.getArticles);
router.get('/articles/:id', educationController.getArticleById);
router.post('/articles', educationController.createArticle);

module.exports = router;

