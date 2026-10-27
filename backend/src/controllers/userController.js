const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const userModel = require('../models/userModel');

async function registerUser(req, res) {
  try {
    const { fullName, email, phone, password } = req.body;

    if (
      typeof fullName !== 'string' ||
      typeof email !== 'string' ||
      typeof phone !== 'string' ||
      typeof password !== 'string' ||
      !fullName.trim() ||
      !email.trim() ||
      !phone.trim() ||
      !password
    ) {
      return res.status(400).json({
        message: 'Full name, email, phone number, and password are required.',
      });
    }

    const normalizedName = fullName.trim();
    const normalizedEmail = email.trim().toLowerCase();

    // Accept only local 10-digit numbers beginning with 09 or 07.
    const normalizedPhone = phone.trim();

    const emailPattern = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;
    const phonePattern = /^(09|07)\d{8}$/;

    if (!emailPattern.test(normalizedEmail)) {
      return res.status(400).json({
        message: 'Please provide a valid email address.',
      });
    }

    if (!phonePattern.test(normalizedPhone)) {
      return res.status(400).json({
        message:
          'Phone number must contain exactly 10 digits and start with 09 or 07.',
      });
    }

    if (password.length < 8) {
      return res.status(400).json({
        message: 'Password must be at least 8 characters long.',
      });
    }

    const [existingEmail, existingPhone] = await Promise.all([
      userModel.findUserByEmail(normalizedEmail),
      userModel.findUserByPhone(normalizedPhone),
    ]);

    if (existingEmail) {
      return res.status(409).json({
        message: 'An account with this email already exists.',
      });
    }

    if (existingPhone) {
      return res.status(409).json({
        message: 'An account with this phone number already exists.',
      });
    }

    const passwordHash = await bcrypt.hash(password, 12);

    const user = await userModel.createUser({
      fullName: normalizedName,
      email: normalizedEmail,
      phone: normalizedPhone,
      passwordHash,
    });

    return res.status(201).json({
      message:
        'Registration successful. Please complete your required verification.',
      user: {
        id: user.id,
        fullName: user.full_name,
        email: user.email,
        phone: user.phone,
        role: user.role,
        accountStatus: user.account_status,
        verificationStatus: user.verification_status,
        createdAt: user.created_at,
      },
    });
  } catch (error) {
    if (error.code === '23505') {
      return res.status(409).json({
        message: 'An account with these details already exists.',
      });
    }

    console.error('Registration error:', error.message);

    return res.status(500).json({
      message: 'Unable to register right now. Please try again.',
    });
  }
}

async function loginUser(req, res) {
  try {
    const identifier =
      typeof req.body.identifier === 'string'
        ? req.body.identifier.trim()
        : typeof req.body.phone === 'string'
          ? req.body.phone.trim()
          : '';

    const { password } = req.body;

    if (!identifier || typeof password !== 'string' || !password) {
      return res.status(400).json({
        message: 'Email or phone number and password are required.',
      });
    }

    const user = await userModel.findUserByIdentifierForLogin(identifier);

    if (!user || !(await bcrypt.compare(password, user.password_hash))) {
      return res.status(401).json({
        message: 'Invalid email/phone or password.',
      });
    }

    if (!process.env.JWT_SECRET) {
      console.error('JWT_SECRET is not configured.');

      return res.status(500).json({
        message: 'Login is temporarily unavailable.',
      });
    }

    const accountStatus = user.account_status;
    const verificationStatus = user.verification_status;

    let nextStep;
    let message;

    switch (accountStatus) {
      case 'pending_verification':
        nextStep = 'FAYDA_VERIFICATION';
        message = 'Please complete your required verification.';
        break;

      case 'pending_approval':
        nextStep = 'GENERAL_DASHBOARD';
        message = 'Your account is awaiting administrator approval.';
        break;

      case 'active':
        if (verificationStatus !== 'verified') {
          nextStep = 'FAYDA_VERIFICATION';
          message = 'Please complete your required verification.';
        } else {
          nextStep = 'MEMBER_DASHBOARD';
          message = 'Login successful.';
        }
        break;

      case 'rejected':
        nextStep = 'GENERAL_DASHBOARD';
        message =
          'Your application was rejected. Review the reason and reapply.';
        break;

      case 'suspended':
        nextStep = 'SUSPENDED_NOTICE';
        message =
          'Your account is suspended. Please contact the administrator.';
        break;

      default:
        return res.status(403).json({
          message:
            'Your account status is not recognized. Please contact support.',
          accountStatus,
        });
    }

    const token = jwt.sign(
      {
        userId: user.id.toString(),
        role: user.role,
      },
      process.env.JWT_SECRET,
      { expiresIn: '1h' },
    );

    return res.status(200).json({
      message,
      token,
      nextStep,
      user: {
        id: user.id,
        fullName: user.full_name,
        email: user.email,
        phone: user.phone,
        role: user.role,
        accountStatus,
        verificationStatus,
        reviewNote: accountStatus === 'rejected' ? user.review_note : null,
        canAccessMemberDashboard: nextStep === 'MEMBER_DASHBOARD',
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
