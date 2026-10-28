const pool = require('../config/db');

const VALID_FREQUENCIES = ['daily', 'every_3_days', 'weekly', 'monthly'];

const VALID_VISIBILITIES = ['public', 'private'];

async function createEkubGroup(req, res) {
  try {
    const {
      name,
      description = null,
      contributionFrequency,
      startDate,
      endDate,
      contributionAmount,
      capacity,
      visibility = 'public',
    } = req.body;

    if (typeof name !== 'string' || !name.trim() || name.trim().length > 150) {
      return res.status(400).json({
        success: false,
        message: 'Group name is required and must not exceed 150 characters.',
      });
    }

    if (!VALID_FREQUENCIES.includes(contributionFrequency)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid contribution frequency.',
      });
    }

    if (!VALID_VISIBILITIES.includes(visibility)) {
      return res.status(400).json({
        success: false,
        message: 'Visibility must be public or private.',
      });
    }

    if (
      typeof startDate !== 'string' ||
      !/^\d{4}-\d{2}-\d{2}$/.test(startDate) ||
      typeof endDate !== 'string' ||
      !/^\d{4}-\d{2}-\d{2}$/.test(endDate)
    ) {
      return res.status(400).json({
        success: false,
        message: 'Start date and end date must use YYYY-MM-DD format.',
      });
    }

    const validDate = (value) => {
      const date = new Date(`${value}T00:00:00.000Z`);
      return (
        !Number.isNaN(date.getTime()) &&
        date.toISOString().slice(0, 10) === value
      );
    };

    if (!validDate(startDate) || !validDate(endDate) || endDate < startDate) {
      return res.status(400).json({
        success: false,
        message:
          'Please provide valid dates; end date must not precede start date.',
      });
    }

    const amount = Number(contributionAmount);
    const groupCapacity = Number(capacity);

    if (
      !Number.isFinite(amount) ||
      amount <= 0 ||
      Math.round(amount * 100) !== amount * 100
    ) {
      return res.status(400).json({
        success: false,
        message:
          'Contribution amount must be greater than zero and have at most two decimal places.',
      });
    }

    if (!Number.isSafeInteger(groupCapacity) || groupCapacity < 1) {
      return res.status(400).json({
        success: false,
        message: 'Capacity must be a positive whole number.',
      });
    }

    if (
      description !== null &&
      (typeof description !== 'string' || description.length > 5000)
    ) {
      return res.status(400).json({
        success: false,
        message: 'Description must be text with at most 5000 characters.',
      });
    }

    const adminId = req.user.userId;

    const result = await pool.query(
      `INSERT INTO ekub_groups (
         name,
         description,
         contribution_frequency,
         start_date,
         end_date,
         contribution_amount,
         currency,
         capacity,
         visibility,
         status,
         created_by
       )
       VALUES ($1, $2, $3, $4, $5, $6, 'ETB', $7, $8, 'draft', $9)
       RETURNING *`,
      [
        name.trim(),
        description?.trim() || null,
        contributionFrequency,
        startDate,
        endDate,
        amount,
        groupCapacity,
        visibility,
        adminId,
      ],
    );

    return res.status(201).json({
      success: true,
      message: 'Ekub group created as a draft.',
      group: result.rows[0],
    });
  } catch (error) {
    console.error('Error creating Ekub group:', error);

    return res.status(500).json({
      success: false,
      message: 'Unable to create the Ekub group right now.',
    });
  }
}

// PATCH /api/admin/ekub-groups/:id/publish
// Publish a draft group so it can accept applications.
async function publishEkubGroup(req, res) {
  try {
    const groupId = Number(req.params.id);

    if (!Number.isSafeInteger(groupId) || groupId <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Invalid Ekub group ID.',
      });
    }

    const result = await pool.query(
      `UPDATE ekub_groups
       SET status = 'open',
           updated_at = NOW()
       WHERE id = $1
         AND status = 'draft'
         AND start_date >= CURRENT_DATE
         AND end_date >= start_date
       RETURNING id, name, visibility, status, start_date, end_date`,
      [groupId],
    );

    if (result.rows.length === 0) {
      return res.status(409).json({
        success: false,
        message:
          'The group cannot be published. Check that it exists, is still a draft, and has valid dates.',
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Ekub group published successfully.',
      group: result.rows[0],
    });
  } catch (error) {
    console.error('Error publishing Ekub group:', error);

    return res.status(500).json({
      success: false,
      message: 'Unable to publish the Ekub group right now.',
    });
  }
}
module.exports = {
  createEkubGroup,
  publishEkubGroup,
};
