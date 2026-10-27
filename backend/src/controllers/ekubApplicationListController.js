const pool = require('../config/db');

// GET /api/admin/ekub-applications
async function getPendingEkubApplications(req, res) {
  try {
    const result = await pool.query(
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
       ORDER BY a.created_at ASC, a.id ASC`,
    );

    return res.status(200).json({
      success: true,
      count: result.rows.length,
      applications: result.rows,
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
