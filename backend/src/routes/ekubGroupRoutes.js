const express = require('express');
const {
  getPublicGroups,
  getPublicGroupById,
} = require('../controllers/ekubGroupController');
const {
  applyToEkubGroup,
} = require('../controllers/ekubApplicationController');

const router = express.Router();

// Browse public Ekub groups.
router.get('/', getPublicGroups);

// View details of a public Ekub group.
router.get('/:id', getPublicGroupById);
router.post('/:id/applications', applyToEkubGroup);

module.exports = router;
