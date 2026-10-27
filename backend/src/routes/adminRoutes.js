const express = require('express');

const {
  listPendingApprovals,
  approveUser,
  rejectUser,
} = require('../controllers/adminController');
const { createEkubGroup } = require('../controllers/ekubAdminGroupController');

const { requireAuth, requireAdmin } = require('../middleware/authMiddleware');
const {
  reviewEkubApplication,
} = require('../controllers/ekubApplicationReviewController');
const router = express.Router();

// Every route requires an authenticated, active administrator.
router.use(requireAuth, requireAdmin);

router.get('/pending-approvals', listPendingApprovals);
router.patch('/users/:id/approve', approveUser);
router.patch('/users/:id/reject', rejectUser);
router.post('/ekub-groups', createEkubGroup);
const {
  reviewEkubApplication,
} = require('../controllers/ekubApplicationReviewController');

module.exports = router;
