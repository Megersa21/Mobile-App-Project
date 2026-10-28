const pool = require('../config/db');

// PATCH /api/ekub-groups/invitations/:id
async function respondToEkubInvitation(req, res) {
  const client = await pool.connect();

  try {
    const invitationId = Number(req.params.id);
    const { decision } = req.body;
    const userId = req.user.userId;

    if (!Number.isSafeInteger(invitationId) || invitationId <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Invalid invitation ID.',
      });
    }

    if (!['accepted', 'declined'].includes(decision)) {
      return res.status(400).json({
        success: false,
        message: 'Decision must be accepted or declined.',
      });
    }

    await client.query('BEGIN');

    const invitationResult = await client.query(
      `SELECT id, group_id, invited_user_id, status, expires_at
       FROM ekub_group_invitations
       WHERE id = $1
       FOR UPDATE`,
      [invitationId],
    );

    if (invitationResult.rows.length === 0) {
      await client.query('ROLLBACK');

      return res.status(404).json({
        success: false,
        message: 'Invitation not found.',
      });
    }

    const invitation = invitationResult.rows[0];

    // Members may respond only to their own invitations.
    if (String(invitation.invited_user_id) !== String(userId)) {
      await client.query('ROLLBACK');

      return res.status(403).json({
        success: false,
        message: 'You cannot respond to another member’s invitation.',
      });
    }

    if (invitation.status !== 'pending') {
      await client.query('ROLLBACK');

      return res.status(409).json({
        success: false,
        message: 'This invitation is no longer pending.',
      });
    }

    if (
      invitation.expires_at &&
      new Date(invitation.expires_at) <= new Date()
    ) {
      await client.query(
        `UPDATE ekub_group_invitations
         SET status = 'expired'
         WHERE id = $1`,
        [invitationId],
      );

      await client.query('COMMIT');

      return res.status(410).json({
        success: false,
        message: 'This invitation has expired.',
      });
    }

    const groupResult = await client.query(
      `SELECT
     id,
     visibility,
     status,
     (end_date >= CURRENT_DATE) AS date_is_valid
   FROM ekub_groups
   WHERE id = $1
   FOR UPDATE`,
      [invitation.group_id],
    );

    if (
      groupResult.rows.length === 0 ||
      groupResult.rows[0].visibility !== 'private' ||
      groupResult.rows[0].status !== 'open' ||
      !groupResult.rows[0].date_is_valid
    ) {
      await client.query('ROLLBACK');

      return res.status(409).json({
        success: false,
        message: 'This group is no longer accepting invitations.',
      });
    }

    const updatedResult = await client.query(
      `UPDATE ekub_group_invitations
       SET status = $1,
           responded_at = NOW()
       WHERE id = $2
         AND invited_user_id = $3
         AND status = 'pending'
       RETURNING id, group_id, invited_user_id,
                 status, responded_at`,
      [decision, invitationId, userId],
    );

    if (updatedResult.rows.length === 0) {
      await client.query('ROLLBACK');

      return res.status(409).json({
        success: false,
        message: 'The invitation status has changed.',
      });
    }

    await client.query('COMMIT');

    return res.status(200).json({
      success: true,
      message:
        decision === 'accepted'
          ? 'Invitation accepted. You may now apply to join the group.'
          : 'Invitation declined.',
      invitation: updatedResult.rows[0],
    });
  } catch (error) {
    await client.query('ROLLBACK').catch(() => {});

    console.error('Error responding to Ekub invitation:', error);

    return res.status(500).json({
      success: false,
      message: 'Unable to respond to the invitation right now.',
    });
  } finally {
    client.release();
  }
}

module.exports = {
  respondToEkubInvitation,
};
