const pool = require('../config/db');

// List accounts that have completed identity verification
// and are waiting for an administrator's decision.
async function listPendingApprovals(req, res) {
  try {
    const result = await pool.query(
      `SELECT id, full_name, email, phone,
              account_status, verification_status, created_at
       FROM users
       WHERE account_status = 'pending_approval'
         AND verification_status = 'verified'
       ORDER BY created_at ASC`,
    );

    return res.status(200).json({
      count: result.rows.length,
      users: result.rows,
    });
  } catch (error) {
    console.error('List pending approvals error:', error.message);
    return res.status(500).json({
      message: 'Unable to load pending approvals.',
    });
  }
}

// Approve an account only after verification is confirmed.
async function approveUser(req, res) {
  const userId = Number(req.params.id);

  if (!Number.isSafeInteger(userId) || userId <= 0) {
    return res.status(400).json({
      message: 'Invalid user ID.',
    });
  }

  try {
    const result = await pool.query(
      `UPDATE users
       SET account_status = 'active',
           reviewed_by = $1,
           reviewed_at = NOW(),
           review_note = $2,
           updated_at = NOW()
       WHERE id = $3
         AND account_status = 'pending_approval'
         AND verification_status = 'verified'
       RETURNING id, full_name, phone, account_status`,
      [
        req.user.userId,
        typeof req.body?.note === 'string'
          ? req.body.note.trim().slice(0, 1000)
          : null,
        userId,
      ],
    );

    if (result.rowCount === 0) {
      return res.status(409).json({
        message:
          'Account is not awaiting approval or identity verification is incomplete.',
      });
    }

    return res.status(200).json({
      message: 'Account approved successfully.',
      user: result.rows[0],
    });
  } catch (error) {
    console.error('Approve user error:', error.message);
    return res.status(500).json({
      message: 'Unable to approve this account.',
    });
  }
}

// Reject an account awaiting administrator review.
async function rejectUser(req, res) {
  const userId = Number(req.params.id);
  const note = req.body?.note;

  if (!Number.isSafeInteger(userId) || userId <= 0) {
    return res.status(400).json({
      message: 'Invalid user ID.',
    });
  }

  if (typeof note !== 'string' || !note.trim()) {
    return res.status(400).json({
      message: 'A rejection reason is required.',
    });
  }

  try {
    const result = await pool.query(
      `UPDATE users
       SET account_status = 'rejected',
           reviewed_by = $1,
           reviewed_at = NOW(),
           review_note = $2,
           updated_at = NOW()
       WHERE id = $3
         AND account_status = 'pending_approval'
         AND verification_status = 'verified'
       RETURNING id, full_name, account_status`,
      [req.user.userId, note.trim().slice(0, 1000), userId],
    );

    if (result.rowCount === 0) {
      return res.status(409).json({
        message:
          'Account is not awaiting approval or identity verification is incomplete.',
      });
    }

    return res.status(200).json({
      message: 'Account rejected.',
      user: result.rows[0],
    });
  } catch (error) {
    console.error('Reject user error:', error.message);
    return res.status(500).json({
      message: 'Unable to reject this account.',
    });
  }
}

module.exports = {
  listPendingApprovals,
  approveUser,
  rejectUser,
};
