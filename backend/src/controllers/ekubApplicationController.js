const pool = require('../config/db');

// POST /api/ekub-groups/:id/applications
async function applyToEkubGroup(req, res) {
  const client = await pool.connect();

  try {
    const groupId = Number(req.params.id);
    const userId = req.user.userId;

    if (!Number.isSafeInteger(groupId) || groupId <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Invalid Ekub group ID.',
      });
    }

    await client.query('BEGIN');

    // Only eligible, active, verified accounts may apply.
    const userResult = await client.query(
      `SELECT id
       FROM users
       WHERE id = $1
         AND account_status = 'active'
         AND verification_status = 'verified'`,
      [userId],
    );

    if (userResult.rows.length === 0) {
      await client.query('ROLLBACK');

      return res.status(403).json({
        success: false,
        message: 'Your account must be active and verified before applying.',
      });
    }

    // Lock the group while checking its status and capacity.
    const groupResult = await client.query(
      `SELECT
     id,
     visibility,
     status,
     capacity,
     (end_date >= CURRENT_DATE) AS date_is_valid
   FROM ekub_groups
   WHERE id = $1
   FOR UPDATE`,
      [groupId],
    );

    if (groupResult.rows.length === 0) {
      await client.query('ROLLBACK');

      return res.status(404).json({
        success: false,
        message: 'Ekub group not found.',
      });
    }

    const group = groupResult.rows[0];

    if (group.status !== 'open' || !group.date_is_valid) {
      await client.query('ROLLBACK');

      return res.status(400).json({
        success: false,
        message: 'This Ekub group is not accepting applications.',
      });
    }

    // Check whether the group has reached its capacity.
    const capacityResult = await client.query(
      `SELECT COUNT(*)::INTEGER AS active_count
       FROM ekub_group_memberships
       WHERE group_id = $1
         AND status = 'active'`,
      [groupId],
    );

    if (capacityResult.rows[0].active_count >= group.capacity) {
      await client.query('ROLLBACK');

      return res.status(409).json({
        success: false,
        message: 'This Ekub group has reached its capacity.',
      });
    }

    // Private groups require an accepted, unexpired invitation.
    if (group.visibility === 'private') {
      const invitationResult = await client.query(
        `SELECT id
         FROM ekub_group_invitations
         WHERE group_id = $1
           AND invited_user_id = $2
           AND status = 'accepted'
           AND (expires_at IS NULL OR expires_at > NOW())
         LIMIT 1`,
        [groupId, userId],
      );

      if (invitationResult.rows.length === 0) {
        await client.query('ROLLBACK');

        return res.status(403).json({
          success: false,
          message: 'An accepted invitation is required for this private group.',
        });
      }
    }

    // Prevent duplicate applications or applying again while already a member.
    const existingResult = await client.query(
      `SELECT id, status
       FROM ekub_membership_applications
       WHERE group_id = $1
         AND user_id = $2
         AND status IN ('pending', 'approved')
       LIMIT 1`,
      [groupId, userId],
    );

    if (existingResult.rows.length > 0) {
      await client.query('ROLLBACK');

      return res.status(409).json({
        success: false,
        message:
          'You already have a pending or approved application for this group.',
      });
    }

    const membershipResult = await client.query(
      `SELECT id
       FROM ekub_group_memberships
       WHERE group_id = $1
         AND user_id = $2
         AND status = 'active'
       LIMIT 1`,
      [groupId, userId],
    );

    if (membershipResult.rows.length > 0) {
      await client.query('ROLLBACK');

      return res.status(409).json({
        success: false,
        message: 'You are already an active member of this group.',
      });
    }

    const applicationResult = await client.query(
      `INSERT INTO ekub_membership_applications (
         group_id,
         user_id,
         status
       )
       VALUES ($1, $2, 'pending')
       RETURNING id, group_id, user_id, status, created_at`,
      [groupId, userId],
    );

    await client.query('COMMIT');

    return res.status(201).json({
      success: true,
      message: 'Your application has been submitted for administrator review.',
      application: applicationResult.rows[0],
    });
  } catch (error) {
    await client.query('ROLLBACK').catch(() => {});

    console.error('Error applying to Ekub group:', error);

    return res.status(500).json({
      success: false,
      message: 'Unable to submit your application right now.',
    });
  } finally {
    client.release();
  }
}

module.exports = {
  applyToEkubGroup,
};
