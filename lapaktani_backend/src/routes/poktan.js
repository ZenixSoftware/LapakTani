const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middlewares/authMiddleware');
const poktanController = require('../controllers/poktanController');

// All poktan endpoints require authentication
router.use(verifyToken);

// User status & poktan info
router.get('/info', poktanController.getPoktanInfo);

// Pengurus: Aggregated member land and members list
router.get('/members', poktanController.getMembers);

// Pengurus: Create B2B order
router.post('/b2b-orders', poktanController.createB2BOrder);

// Pengurus/Member: List Poktan B2B orders
router.get('/b2b-orders', poktanController.getB2BOrders);

// Pengurus: Allocate quota to members
router.post('/allocate-quota', poktanController.allocateQuota);

// Farmer: List assigned production tasks & task notifications
router.get('/my-tasks', poktanController.getMyTasks);

// Farmer: Notifications list
router.get('/notifications', poktanController.getNotifications);

module.exports = router;

