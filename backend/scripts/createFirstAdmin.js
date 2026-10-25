require('dotenv').config();

const bcrypt = require('bcryptjs');
const pool = require('../src/config/db');
const readline = require('readline');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
});

function ask(question) {
  return new Promise((resolve) => {
    rl.question(question, resolve);
  });
}

async function createFirstAdmin() {
  try {
    if (!process.env.JWT_SECRET) {
      throw new Error('JWT_SECRET is not configured in .env.');
    }

    const existingAdmin = await pool.query(
      "SELECT id FROM users WHERE role = 'admin' LIMIT 1",
    );

    if (existingAdmin.rowCount > 0) {
      throw new Error(
        'An administrator already exists. First-admin setup is disabled.',
      );
    }

    const phone = (await ask('Enter the phone number for the first admin: '))
      .trim()
      .replace(/[\s()+-]/g, '');

    const password = await ask('Enter a strong admin password: ');

    if (!/^\d{9,15}$/.test(phone)) {
      throw new Error('Phone must contain 9 to 15 digits.');
    }

    if (password.length < 12) {
      throw new Error('Use an admin password of at least 12 characters.');
    }

    const userResult = await pool.query(
      `SELECT id, full_name, phone, account_status, verification_status
FROM users
WHERE phone = $1`,
      [phone],
    );

    if (userResult.rowCount === 0) {
      throw new Error(
        'No account found for that phone. Register the account first.',
      );
    }

    const user = userResult.rows[0];

    if (
      user.account_status !== 'active' ||
      user.verification_status !== 'verified'
    ) {
      throw new Error(
        'The account must be legitimately verified and approved before becoming an admin.',
      );
    }

    const confirm = await ask(
      `Promote ${user.full_name} (${user.phone}) to administrator? Type YES to confirm: `,
    );

    if (confirm.trim() !== 'YES') {
      console.log('Cancelled. No changes were made.');
      return;
    }

    const passwordHash = await bcrypt.hash(password, 12);

    const result = await pool.query(
      `UPDATE users
       SET role = 'admin',
           password_hash = $1,
           updated_at = NOW()
       WHERE id = $2
         AND role = 'member'
         AND account_status = 'active'
       RETURNING id, full_name, phone, role, account_status`,
      [passwordHash, user.id],
    );

    if (result.rowCount !== 1) {
      throw new Error('Account changed during setup. No promotion completed.');
    }

    console.log('First administrator created successfully:');
    console.table(result.rows);
  } catch (error) {
    console.error('Setup failed:', error.message);
    process.exitCode = 1;
  } finally {
    rl.close();
    await pool.end();
  }
}

createFirstAdmin();
