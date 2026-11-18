const express = require('express');
const router = express.Router();
const superAdminController = require('../controllers/superAdminController');
const { verifyToken, requireRole } = require('../middlewares/authMiddleware');

router.use(verifyToken, requireRole('superadmin'));

router.get('/overview', superAdminController.getSuperAdminOverview);
router.get('/authorities', superAdminController.getSuperAdminAuthorities);
router.post('/provision-authority', superAdminController.provisionAuthorityAccount);
router.put('/authorities/:id/status', superAdminController.updateAuthorityStatus);
router.get('/stores', superAdminController.getSuperAdminStores);
router.put('/stores/:id/status', superAdminController.updateSuperAdminStoreStatus);
router.get('/fee-ledger', superAdminController.getPlatformFeeLedger);

module.exports = router;
