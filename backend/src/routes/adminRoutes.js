const express = require('express');

const {
  listPendingApprovals,
  approveUser,
  rejectUser,
} = require('../controllers/adminController');

const {
  createEkubGroup,
  publishEkubGroup,
} = require('../controllers/ekubAdminGroupController');
const {
  getPendingEkubApplications,
} = require('../controllers/ekubApplicationListController');

const {
  reviewEkubApplication,
} = require('../controllers/ekubApplicationReviewController');

const {
  inviteMemberToEkubGroup,
} = require('../controllers/ekubInvitationController');
const {
  createCentralEkubSettings,
  updateGroupCapacitySettings,
} = require('../controllers/ekubAdminSettingsController');
const { requireAuth, requireAdmin } = require('../middleware/authMiddleware');

const router = express.Router();

// Every route requires an authenticated, active administrator.
router.use(requireAuth, requireAdmin);

router.get('/pending-approvals', listPendingApprovals);
router.patch('/users/:id/approve', approveUser);
router.patch('/users/:id/reject', rejectUser);
router.post('/ekub-settings', createCentralEkubSettings);
router.patch('/ekub-settings/group-capacity', updateGroupCapacitySettings);
router.get('/ekub-applications', getPendingEkubApplications);
router.post('/ekub-groups', createEkubGroup);
router.patch('/ekub-applications/:id', reviewEkubApplication);
router.patch('/ekub-groups/:id/publish', publishEkubGroup);
router.post('/ekub-groups/:id/invitations', inviteMemberToEkubGroup);

module.exports = router;
