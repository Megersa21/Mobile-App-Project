const pool = require('../config/db');

// POST /api/admin/ekub-groups/:id/invitations
async function inviteMemberToEkubGroup(req, res) {
  try {
    const groupId = Number(req.params.id);
    const { userId, expiresAt = null } = req.body;
    const invitedUserId = Number(userId);
    const inviterId = req.user.userId;

    if (
      !Number.isSafeInteger(groupId) ||
      groupId <= 0 ||
      !Number.isSafeInteger(invitedUserId) ||
      invitedUserId <= 0
    ) {
      return res.status(400).json({
        success: false,
        message: 'Valid group ID and member user ID are required.',
      });
    }

    if (
      expiresAt !== null &&
      (typeof expiresAt !== 'string' ||
        Number.isNaN(Date.parse(expiresAt)) ||
        Date.parse(expiresAt) <= Date.now())
    ) {
      return res.status(400).json({
        success: false,
        message: 'Invitation expiry must be a valid future date.',
      });
    }

    const groupResult = await pool.query(
      `SELECT id, visibility, status
       FROM ekub_groups
       WHERE id = $1`,
      [groupId],
    );

    if (groupResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Ekub group not found.',
      });
    }

    const group = groupResult.rows[0];

    if (group.visibility !== 'private') {
      return res.status(400).json({
        success: false,
        message:
          'Invitations through this endpoint are for private groups only.',
      });
    }

    if (group.status !== 'open') {
      return res.status(409).json({
        success: false,
        message: 'Only open Ekub groups can send invitations.',
      });
    }

    const memberResult = await pool.query(
      `SELECT id
       FROM users
       WHERE id = $1
         AND account_status = 'active'
         AND verification_status = 'verified'`,
      [invitedUserId],
    );

    if (memberResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Eligible member not found.',
      });
    }

    const invitationResult = await pool.query(
      `INSERT INTO ekub_group_invitations (
     group_id,
     invited_user_id,
     invited_by,
     status,
     expires_at
   )
   VALUES ($1, $2, $3, 'pending', $4)
   ON CONFLICT (group_id, invited_user_id)
     WHERE status = 'pending'
   DO UPDATE
   SET expires_at = EXCLUDED.expires_at,
       invited_by = EXCLUDED.invited_by,
       created_at = NOW()
   WHERE ekub_group_invitations.expires_at IS NOT NULL
     AND ekub_group_invitations.expires_at <= NOW()
   RETURNING id, group_id, invited_user_id,
             invited_by, status, expires_at, created_at`,
      [groupId, invitedUserId, inviterId, expiresAt],
    );

    if (invitationResult.rows.length === 0) {
      return res.status(409).json({
        success: false,
        message: 'This member already has a pending invitation.',
      });
    }

    const existingMembership = await pool.query(
      `SELECT id
   FROM ekub_group_memberships
   WHERE group_id = $1
     AND user_id = $2
     AND status = 'active'
   LIMIT 1`,
      [groupId, invitedUserId],
    );

    if (existingMembership.rows.length > 0) {
      return res.status(409).json({
        success: false,
        message: 'This user is already an active member of the group.',
      });
    }

    return res.status(201).json({
      success: true,
      message: 'Private-group invitation created.',
      invitation: invitationResult.rows[0],
    });
  } catch (error) {
    console.error('Error inviting member to Ekub group:', error);

    return res.status(500).json({
      success: false,
      message: 'Unable to create the invitation right now.',
    });
  }
}

module.exports = {
  inviteMemberToEkubGroup,
};
