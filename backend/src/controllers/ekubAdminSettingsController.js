const pool = require('../config/db');

// POST /api/admin/ekub-settings
// Creates the initial central Ekub configuration once.
async function createCentralEkubSettings(req, res) {
  const client = await pool.connect();

  try {
    const { name, contributionAmount } = req.body;

    if (typeof name !== 'string' || !name.trim() || name.trim().length > 150) {
      return res.status(400).json({
        success: false,
        message: 'Name is required and must not exceed 150 characters.',
      });
    }

    const amount = Number(contributionAmount);

    if (
      contributionAmount === undefined ||
      contributionAmount === null ||
      contributionAmount === '' ||
      !Number.isFinite(amount) ||
      amount <= 0 ||
      !/^\d+(\.\d{1,2})?$/.test(String(contributionAmount))
    ) {
      return res.status(400).json({
        success: false,
        message:
          'Contribution amount must be a positive number with at most two decimal places.',
      });
    }

    await client.query('BEGIN');

    // Serialize setup requests to prevent concurrent initialization.
    await client.query('LOCK TABLE ekub_settings IN EXCLUSIVE MODE');

    const existing = await client.query('SELECT id FROM ekub_settings LIMIT 1');

    if (existing.rows.length > 0) {
      await client.query('ROLLBACK');

      return res.status(409).json({
        success: false,
        message: 'Central Ekub settings have already been configured.',
      });
    }

    const result = await client.query(
      `INSERT INTO ekub_settings (
         name,
         contribution_amount,
         created_by
       )
       VALUES ($1, $2, $3)
       RETURNING
         id,
         name,
         currency,
         contribution_frequency,
         contribution_amount,
         min_group_capacity,
         max_group_capacity,
         status,
         created_at`,
      [name.trim(), amount, req.user.id],
    );

    await client.query('COMMIT');

    return res.status(201).json({
      success: true,
      message: 'Central Ekub settings created successfully.',
      settings: result.rows[0],
    });
  } catch (error) {
    try {
      await client.query('ROLLBACK');
    } catch (rollbackError) {
      console.error('Central settings rollback failed:', rollbackError);
    }

    console.error('Error creating central Ekub settings:', error);

    return res.status(500).json({
      success: false,
      message: 'Unable to create central Ekub settings right now.',
    });
  } finally {
    client.release();
  }
}

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
  createCentralEkubSettings,
  updateGroupCapacitySettings,
};
