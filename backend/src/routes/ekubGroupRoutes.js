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

// Browse public Ekub groups.
router.get('/', getPublicGroups);

// View details of a public Ekub group.
router.get('/:id', getPublicGroupById);
router.post('/:id/applications', applyToEkubGroup);
router.patch('/invitations/:id', respondToEkubInvitation);
router.get('/invitations', requireAuth, getMyEkubInvitations);
router.post('/:id/applications', requireAuth, applyToEkubGroup);
router.patch('/invitations/:id', requireAuth, respondToEkubInvitation);

module.exports = router;
