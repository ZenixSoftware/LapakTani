const express = require('express');
const router = express.Router();
const profileController = require('../controllers/profileController');
const { verifyToken } = require('../middlewares/authMiddleware');

router.get('/me', verifyToken, profileController.getMyProfile);
router.post('/farmer', verifyToken, profileController.setupFarmerProfile);

module.exports = router;
