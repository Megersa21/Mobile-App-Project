const express = require('express');
const { getMyProfile } = require('../controllers/profileController');
const { requireAuth } = require('../middleware/authMiddleware');

const router = express.Router();

// Only authenticated, active users can access their own profile.
router.get('/me', requireAuth, getMyProfile);

module.exports = router;
