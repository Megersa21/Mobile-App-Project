const express = require('express');
const { getMyProfile } = require('../controllers/profileController');
const { requireAuth } = require('../middleware/authMiddleware');
const { getMyEkubGroups } = require('../controllers/myEkubGroupsController');
const router = express.Router();

// Only authenticated, active users can access their own profile.
router.get('/me', requireAuth, getMyProfile);
router.get('/me/ekub-groups', getMyEkubGroups);

module.exports = router;
