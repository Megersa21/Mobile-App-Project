const express = require('express');

const { getMyProfile } = require('../controllers/profileController');
const { getMyEkubGroups } = require('../controllers/myEkubGroupsController');
const { requireAuth } = require('../middleware/authMiddleware');

const router = express.Router();

// Only authenticated, active users can access their own profile and groups.
router.get('/me', requireAuth, getMyProfile);
router.get('/me/ekub-groups', requireAuth, getMyEkubGroups);

module.exports = router;
