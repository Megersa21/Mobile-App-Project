const bcrypt = require('bcryptjs');
const userModel = require('../models/userModel');
const jwt = require('jsonwebtoken');

async function registerUser(req, res) {
  try {
    let { fullName, email, phone, password } = req.body;

    // Validate required fields, including empty strings.
    if (
      typeof fullName !== 'string' ||
      !fullName.trim() ||
      typeof phone !== 'string' ||
      !phone.trim() ||
      typeof password !== 'string' ||
      !password
    ) {
      return res.status(400).json({
        message: 'Full name, phone, and password are required.',
      });
    }

    fullName = fullName.trim();
    phone = phone.trim();
    email =
      typeof email === 'string' && email.trim()
        ? email.trim().toLowerCase()
        : null;

    if (fullName.length < 2 || fullName.length > 150) {
      return res.status(400).json({
        message: 'Full name must be between 2 and 150 characters.',
      });
    }

    if (!/^\+?[0-9]{7,20}$/.test(phone)) {
      return res.status(400).json({
        message: 'Enter a valid phone number.',
      });
    }

    if (email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      return res.status(400).json({
        message: 'Enter a valid email address.',
      });
    }

    if (password.length < 8 || password.length > 72) {
      return res.status(400).json({
        message: 'Password must be between 8 and 72 characters.',
      });
    }

    if (await userModel.findUserByPhone(phone)) {
      return res.status(409).json({
        message: 'An account with this phone number already exists.',
      });
    }

    if (email && (await userModel.findUserByEmail(email))) {
      return res.status(409).json({
        message: 'An account with this email already exists.',
      });
    }

    const passwordHash = await bcrypt.hash(password, 12);

    const user = await userModel.createUser({
      fullName,
      email,
      phone,
      passwordHash,
    });

    return res.status(201).json({
      message:
        'Registration successful. Verification and approval are still required.',
      user,
    });
  } catch (error) {
    console.error('Registration error:', error.message);

    return res.status(500).json({
      message: 'Unable to register your account right now.',
    });
  }
}

async function loginUser(req, res) {
  try {
    const { phone, password } = req.body;

    if (
      typeof phone !== 'string' ||
      !phone.trim() ||
      typeof password !== 'string' ||
      !password
    ) {
      return res.status(400).json({
        message: 'Phone number and password are required.',
      });
    }

    const user = await userModel.findUserByPhoneForLogin(phone.trim());

    if (!user || !(await bcrypt.compare(password, user.password_hash))) {
      return res.status(401).json({
        message: 'Invalid phone number or password.',
      });
    }

    if (user.account_status !== 'active') {
      return res.status(403).json({
        message:
          'Your account is not active yet. Verification and approval may be required.',
        accountStatus: user.account_status,
      });
    }

    if (!process.env.JWT_SECRET) {
      console.error('JWT_SECRET is not configured.');
      return res.status(500).json({
        message: 'Login is temporarily unavailable.',
      });
    }

    const token = jwt.sign(
      { userId: user.id.toString(), role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: '1h' },
    );

    return res.status(200).json({
      message: 'Login successful.',
      token,
      user: {
        id: user.id,
        fullName: user.full_name,
        email: user.email,
        phone: user.phone,
        role: user.role,
        accountStatus: user.account_status,
      },
    });
  } catch (error) {
    console.error('Login error:', error.message);

    return res.status(500).json({
      message: 'Unable to log in right now.',
    });
  }
}

module.exports = {
  registerUser,
  loginUser,
};
