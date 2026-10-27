const pool = require('../config/db');

async function findUserByEmail(email) {
  const result = await pool.query(
    `SELECT id, full_name, email, phone, password_hash, role,
            account_status, verification_status, review_note
     FROM users
     WHERE email = $1`,
    [email],
  );

  return result.rows[0] || null;
}

async function findUserByPhone(phone) {
  const result = await pool.query(
    `SELECT id, full_name, email, phone, password_hash, role,
            account_status, verification_status, review_note
     FROM users
     WHERE phone = $1`,
    [phone],
  );

  return result.rows[0] || null;
}

async function createUser({ fullName, email, phone, passwordHash }) {
  const result = await pool.query(
    `INSERT INTO users (
       full_name,
       email,
       phone,
       password_hash,
       role,
       account_status,
       verification_status
     )
     VALUES ($1, $2, $3, $4, 'member', 'pending_verification', 'pending')
     RETURNING
       id,
       full_name,
       email,
       phone,
       role,
       account_status,
       verification_status,
       created_at`,
    [fullName, email, phone, passwordHash],
  );

  return result.rows[0];
}

async function findUserByIdentifierForLogin(identifier) {
  const result = await pool.query(
    `SELECT
       id,
       full_name,
       email,
       phone,
       password_hash,
       role,
       account_status,
       verification_status,
       review_note
     FROM users
     WHERE phone = $1
        OR LOWER(email) = LOWER($1)
     LIMIT 1`,
    [identifier],
  );

  return result.rows[0] || null;
}
async function findUserById(id) {
  const result = await pool.query(
    `SELECT
       id,
       full_name,
       email,
       phone,
       role,
       account_status,
       verification_status,
       email_verified,
       phone_verified,
       created_at,
       updated_at
     FROM users
     WHERE id = $1`,
    [id],
  );

  return result.rows[0] || null;
}
module.exports = {
  findUserByEmail,
  findUserByPhone,
  findUserByIdentifierForLogin,
  createUser,
  findUserById,
};
