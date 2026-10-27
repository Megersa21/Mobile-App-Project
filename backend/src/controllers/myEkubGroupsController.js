const pool = require('../config/db');

// GET /api/users/me/ekub-groups
async function getMyEkubGroups(req, res) {
  try {
    const userId = req.user.userId;

    const result = await pool.query(
      `SELECT
         a.id AS application_id,
         a.status AS application_status,
         a.created_at AS applied_at,
         a.reviewed_at,
         a.review_note,
         g.id AS group_id,
         g.name AS group_name,
         g.description,
         g.contribution_frequency,
         g.start_date,
         g.end_date,
         g.contribution_amount,
         g.currency,
         g.visibility,
         m.id AS membership_id,
         m.status AS membership_status,
         m.joined_at
       FROM ekub_membership_applications a
       JOIN ekub_groups g ON g.id = a.group_id
       LEFT JOIN ekub_group_memberships m
         ON m.application_id = a.id
        AND m.status = 'active'
       WHERE a.user_id = $1
       ORDER BY a.created_at DESC, a.id DESC`,
      [userId],
    );

    return res.status(200).json({
      success: true,
      count: result.rows.length,
      groups: result.rows,
    });
  } catch (error) {
    console.error('Error loading member Ekub groups:', error);

    return res.status(500).json({
      success: false,
      message: 'Unable to load your Ekub groups right now.',
    });
  }
}

module.exports = {
  getMyEkubGroups,
};
