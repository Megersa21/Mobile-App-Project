const userModel = require('../models/userModel');

async function getMyProfile(req, res) {
  try {
    const user = await userModel.findUserById(req.user.userId);

    if (!user) {
      return res.status(404).json({
        message: 'User profile not found.',
      });
    }

    return res.status(200).json({
      message: 'Profile retrieved successfully.',
      user: {
        id: user.id,
        fullName: user.full_name,
        email: user.email,
        phone: user.phone,
        role: user.role,
        accountStatus: user.account_status,
        verificationStatus: user.verification_status,
        emailVerified: user.email_verified,
        phoneVerified: user.phone_verified,
        createdAt: user.created_at,
        updatedAt: user.updated_at,
      },
    });
  } catch (error) {
    console.error('Get profile error:', error.message);

    return res.status(500).json({
      message: 'Unable to retrieve your profile right now.',
    });
  }
}

module.exports = {
  getMyProfile,
};
