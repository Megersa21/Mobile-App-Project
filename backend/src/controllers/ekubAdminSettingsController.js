const pool = require('../config/db');

// PATCH /api/admin/ekub-settings/group-capacity
async function updateGroupCapacitySettings(req, res) {
  try {
    const { minGroupCapacity, maxGroupCapacity } = req.body;

    if (
      !Number.isSafeInteger(minGroupCapacity) ||
      !Number.isSafeInteger(maxGroupCapacity) ||
      minGroupCapacity < 1 ||
      maxGroupCapacity < minGroupCapacity
    ) {
      return res.status(400).json({
        success: false,
        message:
          'Minimum capacity must be at least 1, and maximum capacity must be greater than or equal to the minimum.',
      });
    }

    const result = await pool.query(
      `UPDATE ekub_settings
       SET min_group_capacity = $1,
           max_group_capacity = $2,
           updated_at = NOW()
       RETURNING min_group_capacity, max_group_capacity`,
      [minGroupCapacity, maxGroupCapacity],
    );

    if (result.rows.length === 0) {
      return res.status(409).json({
        success: false,
        message: 'Central Ekub settings have not been configured yet.',
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Group capacity settings updated successfully.',
      settings: {
        minGroupCapacity: Number(result.rows[0].min_group_capacity),
        maxGroupCapacity: Number(result.rows[0].max_group_capacity),
      },
    });
  } catch (error) {
    console.error('Error updating group capacity settings:', error);

    return res.status(500).json({
      success: false,
      message: 'Unable to update group capacity settings right now.',
    });
  }
}

module.exports = {
  updateGroupCapacitySettings,
};
