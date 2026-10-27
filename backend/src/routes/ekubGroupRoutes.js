const express = require('express');

const {
  getPublicGroups,
  getPublicGroupById,
} = require('../controllers/ekubGroupController');

const {
  applyToEkubGroup,
} = require('../controllers/ekubApplicationController');

const {
  respondToEkubInvitation,
} = require('../controllers/ekubInvitationResponseController');

const {
  getMyEkubInvitations,
} = require('../controllers/myEkubInvitationsController');

const { requireAuth } = require('../middleware/authMiddleware');

const router = express.Router();

// Public: browse public Ekub groups.
router.get('/', getPublicGroups);

// Protected: view invitations belonging to the logged-in member.
router.get('/invitations', requireAuth, getMyEkubInvitations);

// Protected: respond to an invitation belonging to the logged-in member.
router.patch('/invitations/:id', requireAuth, respondToEkubInvitation);

// Protected: apply to join an Ekub group.
router.post('/:id/applications', requireAuth, applyToEkubGroup);

// Public: view a public Ekub group's details.
// Keep this route after the more specific /invitations routes.
router.get('/:id', getPublicGroupById);

module.exports = router;
