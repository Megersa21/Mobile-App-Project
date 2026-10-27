const pool = require('../config/db');

// PATCH /api/admin/ekub-applications/:id
async function reviewEkubApplication(req, res) {
  const client = await pool.connect();

  try {
    const applicationId = Number(req.params.id);
    const { decision, reviewNote = null } = req.body;
    const adminId = req.user.userId;

    if (!Number.isSafeInteger(applicationId) || applicationId <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Invalid application ID.',
      });
    }

    if (!['approved', 'rejected'].includes(decision)) {
      return res.status(400).json({
        success: false,
        message: 'Decision must be approved or rejected.',
      });
    }

    if (
      reviewNote !== null &&
      (typeof reviewNote !== 'string' || reviewNote.length > 2000)
    ) {
      return res.status(400).json({
        success: false,
        message: 'Review note must be text with at most 2000 characters.',
      });
    }

    await client.query('BEGIN');

    const applicationResult = await client.query(
      `SELECT
         a.id,
         a.group_id,
         a.user_id,
         a.status,
         g.capacity,
         g.status AS group_status,
         g.end_date
       FROM ekub_membership_applications a
       JOIN ekub_groups g ON g.id = a.group_id
       WHERE a.id = $1
       FOR UPDATE OF a
       FOR SHARE OF g`,
      [applicationId],
    );

    if (applicationResult.rows.length === 0) {
      await client.query('ROLLBACK');

      return res.status(404).json({
        success: false,
        message: 'Application not found.',
      });
    }

    const application = applicationResult.rows[0];

    if (application.status !== 'pending') {
      await client.query('ROLLBACK');

      return res.status(409).json({
        success: false,
        message: 'This application has already been reviewed.',
      });
    }

    if (decision === 'approved') {
      if (
        application.group_status !== 'open' ||
        new Date(application.end_date) <
          new Date(new Date().toISOString().slice(0, 10))
      ) {
        await client.query('ROLLBACK');

        return res.status(409).json({
          success: false,
          message: 'This group is no longer accepting members.',
        });
      }

      // Lock the group row to serialize approvals and protect capacity.
      await client.query(
        'SELECT id FROM ekub_groups WHERE id = $1 FOR UPDATE',
        [application.group_id],
      );

      const capacityResult = await client.query(
        `SELECT COUNT(*)::INTEGER AS active_count
         FROM ekub_group_memberships
         WHERE group_id = $1
           AND status = 'active'`,
        [application.group_id],
      );

      if (capacityResult.rows[0].active_count >= application.capacity) {
        await client.query('ROLLBACK');

        return res.status(409).json({
          success: false,
          message: 'This Ekub group has reached its capacity.',
        });
      }

      const userResult = await client.query(
        `SELECT id
         FROM users
         WHERE id = $1
           AND account_status = 'active'
           AND verification_status = 'verified'`,
        [application.user_id],
      );

      if (userResult.rows.length === 0) {
        await client.query('ROLLBACK');

        return res.status(409).json({
          success: false,
          message: 'The member is no longer eligible for approval.',
        });
      }

      const membershipResult = await client.query(
        `SELECT id
         FROM ekub_group_memberships
         WHERE group_id = $1
           AND user_id = $2
           AND status = 'active'
         LIMIT 1`,
        [application.group_id, application.user_id],
      );

      if (membershipResult.rows.length > 0) {
        await client.query('ROLLBACK');

        return res.status(409).json({
          success: false,
          message: 'This user is already an active member of the group.',
        });
      }

      await client.query(
        `INSERT INTO ekub_group_memberships (
           group_id,
           user_id,
           application_id,
           status
         )
         VALUES ($1, $2, $3, 'active')`,
        [application.group_id, application.user_id, application.id],
      );
    }

    const updatedResult = await client.query(
      `UPDATE ekub_membership_applications
       SET status = $1,
           reviewed_by = $2,
           reviewed_at = NOW(),
           review_note = $3,
           updated_at = NOW()
       WHERE id = $4
         AND status = 'pending'
       RETURNING id, group_id, user_id, status,
                 reviewed_by, reviewed_at, review_note`,
      [decision, adminId, reviewNote?.trim() || null, applicationId],
    );

    if (updatedResult.rows.length === 0) {
      await client.query('ROLLBACK');

      return res.status(409).json({
        success: false,
        message: 'The application has already changed.',
      });
    }

    await client.query('COMMIT');

    return res.status(200).json({
      success: true,
      message:
        decision === 'approved'
          ? 'Membership application approved.'
          : 'Membership application rejected.',
      application: updatedResult.rows[0],
    });
  } catch (error) {
    await client.query('ROLLBACK').catch(() => {});

    console.error('Error reviewing Ekub application:', error);

    return res.status(500).json({
      success: false,
      message: 'Unable to review the application right now.',
    });
  } finally {
    client.release();
  }
}

module.exports = {
  reviewEkubApplication,
};
