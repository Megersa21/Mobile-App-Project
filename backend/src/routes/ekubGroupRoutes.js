const express = require('express');
const {
  getPublicGroups,
  getPublicGroupById,
} = require('../controllers/ekubGroupController');

const router = express.Router();

// Browse public Ekub groups.
router.get('/', getPublicGroups);

// View details of a public Ekub group.
router.get('/:id', getPublicGroupById);

module.exports = router;
