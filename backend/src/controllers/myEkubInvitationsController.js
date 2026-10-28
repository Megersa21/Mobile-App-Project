const pool = require('../config/db');

// GET /api/ekub-groups/invitations
// Get pending invitations for the logged-in member.
async function getMyEkubInvitations(req, res) {
  try {
    const userId = req.user.userId;

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: 'Authentication is required.',
      });
    }

    const page = Number.parseInt(req.query.page ?? '1', 10);
    const limit = Number.parseInt(req.query.limit ?? '20', 10);

    if (
      !Number.isSafeInteger(page) ||
      page < 1 ||
      !Number.isSafeInteger(limit) ||
      limit < 1 ||
      limit > 100
    ) {
      return res.status(400).json({
        success: false,
        message: 'Page must be positive and limit must be between 1 and 100.',
      });
    }

    const offset = (page - 1) * limit;

    const [invitationsResult, countResult] = await Promise.all([
      pool.query(
        `SELECT
           i.id AS invitation_id,
           i.status AS invitation_status,
           i.expires_at,
           i.created_at AS invitation_date,
           g.id AS group_id,
           g.name AS group_name,
           g.contribution_frequency,
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
         ORDER BY i.created_at DESC, i.id DESC
         LIMIT $2 OFFSET $3`,
        [userId, limit, offset],
      ),
      pool.query(
        `SELECT COUNT(*)::INTEGER AS total
         FROM ekub_group_invitations i
         INNER JOIN ekub_groups g
           ON g.id = i.group_id
         WHERE i.invited_user_id = $1
           AND i.status = 'pending'
           AND (i.expires_at IS NULL OR i.expires_at > NOW())
           AND g.visibility = 'private'
           AND g.status = 'open'
           AND g.end_date >= CURRENT_DATE`,
        [userId],
      ),
    ]);

    const total = countResult.rows[0].total;

    return res.status(200).json({
      success: true,
      count: invitationsResult.rows.length,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
      invitations: invitationsResult.rows,
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
