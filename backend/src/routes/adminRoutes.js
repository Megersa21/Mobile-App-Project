const express = require('express');

const {
  listPendingApprovals,
  approveUser,
  rejectUser,
} = require('../controllers/adminController');

const { requireAuth, requireAdmin } = require('../middleware/authMiddleware');

const router = express.Router();

// Every route requires an authenticated, active administrator.
router.use(requireAuth, requireAdmin);

router.get('/pending-approvals', listPendingApprovals);
router.patch('/users/:id/approve', approveUser);
router.patch('/users/:id/reject', rejectUser);

module.exports = router;
