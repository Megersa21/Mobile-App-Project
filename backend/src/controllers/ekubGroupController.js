const pool = require('../config/db');

// GET /api/ekub-groups
// Browse public groups that are open for applications.
async function getPublicGroups(req, res) {
  try {
    const result = await pool.query(
      `SELECT
         id,
         name,
         description,
         contribution_frequency,
         start_date,
         end_date,
         contribution_amount,
         currency,
         capacity
       FROM ekub_groups
       WHERE visibility = 'public'
         AND status = 'open'
         AND end_date >= CURRENT_DATE
       ORDER BY start_date ASC, id ASC`,
    );

    return res.status(200).json({
      success: true,
      groups: result.rows,
    });
  } catch (error) {
    console.error('Error fetching public Ekub groups:', error);

    return res.status(500).json({
      success: false,
      message: 'Unable to load Ekub groups right now.',
    });
  }
}

// GET /api/ekub-groups/:id
// View details of a public group.
async function getPublicGroupById(req, res) {
  try {
    const groupId = Number(req.params.id);

    if (!Number.isSafeInteger(groupId) || groupId <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Invalid Ekub group ID.',
      });
    }

    const result = await pool.query(
      `SELECT
         id,
         name,
         description,
         contribution_frequency,
         start_date,
         end_date,
         contribution_amount,
         currency,
         capacity
       FROM ekub_groups
       WHERE id = $1
         AND visibility = 'public'
         AND status = 'open'
         AND end_date >= CURRENT_DATE`,
      [groupId],
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Ekub group not found or unavailable.',
      });
    }

    return res.status(200).json({
      success: true,
      group: result.rows[0],
    });
  } catch (error) {
    console.error('Error fetching Ekub group details:', error);

    return res.status(500).json({
      success: false,
      message: 'Unable to load Ekub group details right now.',
    });
  }
}

module.exports = {
  getPublicGroups,
  getPublicGroupById,
};
