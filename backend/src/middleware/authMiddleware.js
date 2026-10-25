const jwt = require('jsonwebtoken');
const pool = require('../config/db');

async function requireAuth(req, res, next) {
  const authorization = req.headers.authorization;

  if (!authorization || !authorization.startsWith('Bearer ')) {
    return res.status(401).json({
      message: 'Authentication required.',
    });
  }

  if (!process.env.JWT_SECRET) {
    return res.status(500).json({
      message: 'Authentication configuration error.',
    });
  }

  try {
    const token = authorization.slice(7);
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    if (!decoded.userId) {
      return res.status(401).json({
        message: 'Invalid authentication token.',
      });
    }

    const result = await pool.query(
      `SELECT id, role, account_status
       FROM users
       WHERE id = $1`,
      [decoded.userId],
    );

    const user = result.rows[0];

    if (!user) {
      return res.status(401).json({
        message: 'Account not found.',
      });
    }

    if (user.account_status !== 'active') {
      return res.status(403).json({
        message: 'Your account is not active.',
      });
    }

    req.user = {
      userId: user.id,
      role: user.role,
      accountStatus: user.account_status,
    };

    next();
  } catch (error) {
    if (
      error.name === 'JsonWebTokenError' ||
      error.name === 'TokenExpiredError'
    ) {
      return res.status(401).json({
        message: 'Invalid or expired authentication token.',
      });
    }

    console.error('Authentication error:', error.message);

    return res.status(500).json({
      message: 'Unable to verify your account right now.',
    });
  }
}

function requireAdmin(req, res, next) {
  if (!req.user || req.user.role !== 'admin') {
    return res.status(403).json({
      message: 'Administrator access required.',
    });
  }

  next();
}

module.exports = {
  requireAuth,
  requireAdmin,
};
