const express = require('express');

const {
  listPendingApprovals,
  approveUser,
  rejectUser,
} = require('../controllers/adminController');

const { createEkubGroup } = require('../controllers/ekubAdminGroupController');

const {
  getPendingEkubApplications,
} = require('../controllers/ekubApplicationListController');

const {
  reviewEkubApplication,
} = require('../controllers/ekubApplicationReviewController');

const {
  inviteMemberToEkubGroup,
} = require('../controllers/ekubInvitationController');

const { requireAuth, requireAdmin } = require('../middleware/authMiddleware');

const router = express.Router();

// Every route requires an authenticated, active administrator.
router.use(requireAuth, requireAdmin);

router.get('/pending-approvals', listPendingApprovals);
router.patch('/users/:id/approve', approveUser);
router.patch('/users/:id/reject', rejectUser);

router.get('/ekub-applications', getPendingEkubApplications);
router.post('/ekub-groups', createEkubGroup);
router.patch('/ekub-applications/:id', reviewEkubApplication);

router.post('/ekub-groups/:id/invitations', inviteMemberToEkubGroup);

module.exports = router;
