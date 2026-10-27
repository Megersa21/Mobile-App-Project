const pool = require('../config/db');

// GET INVITATIONS FOR THE LOGGED-IN MEMBER
async function getMyEkubInvitations(req, res) {
  try {
    const userId = req.user.userId;

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: 'Authentication is required.',
      });
    }

    const result = await pool.query(
      `SELECT
         i.id AS invitation_id,
         i.status AS invitation_status,
         i.expires_at,
         i.created_at AS invitation_date,
         g.id AS group_id,
         g.name AS group_name,
         g.frequency,
         g.contribution_amount,
         g.currency,
         g.start_date,
         g.end_date,
         g.description
       FROM ekub_group_invitations i
       INNER JOIN ekub_groups g
         ON g.id = i.group_id
       WHERE i.invited_user_id = $1
         AND i.status = 'pending'
         AND (i.expires_at IS NULL OR i.expires_at > NOW())
         AND g.visibility = 'private'
         AND g.status = 'open'
         AND g.end_date >= CURRENT_DATE
       ORDER BY i.created_at DESC`,
      [userId],
    );

    return res.status(200).json({
      success: true,
      count: result.rows.length,
      invitations: result.rows,
    });
  } catch (error) {
    console.error('Get my Ekub invitations error:', error);

    return res.status(500).json({
      success: false,
      message: 'Unable to retrieve your Ekub invitations.',
    });
  }
}

module.exports = {
  getMyEkubInvitations,
};
