const pool = require('../config/db');

// GET /api/admin/ekub-applications?page=1&limit=20
async function getPendingEkubApplications(req, res) {
  try {
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

    const [applicationsResult, countResult] = await Promise.all([
      pool.query(
        `SELECT
           a.id AS application_id,
           a.status AS application_status,
           a.created_at AS applied_at,
           g.id AS group_id,
           g.name AS group_name,
           g.contribution_frequency,
           g.contribution_amount,
           g.currency,
           u.id AS user_id,
           u.full_name,
           u.email,
           u.phone
         FROM ekub_membership_applications a
         JOIN ekub_groups g ON g.id = a.group_id
         JOIN users u ON u.id = a.user_id
         WHERE a.status = 'pending'
         ORDER BY a.created_at ASC, a.id ASC
         LIMIT $1 OFFSET $2`,
        [limit, offset],
      ),
      pool.query(
        `SELECT COUNT(*)::INTEGER AS total
         FROM ekub_membership_applications
         WHERE status = 'pending'`,
      ),
    ]);

    const total = countResult.rows[0].total;

    return res.status(200).json({
      success: true,
      count: applicationsResult.rows.length,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
      applications: applicationsResult.rows,
    });
  } catch (error) {
    console.error('Error loading pending Ekub applications:', error);

    return res.status(500).json({
      success: false,
      message: 'Unable to load pending applications right now.',
    });
  }
}

module.exports = {
  getPendingEkubApplications,
};
