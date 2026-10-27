import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class MemberProfileScreen extends StatefulWidget {
  const MemberProfileScreen({super.key});

  @override
  State<MemberProfileScreen> createState() => _MemberProfileScreenState();
}

class _MemberProfileScreenState extends State<MemberProfileScreen> {
  static const Color forestGreen = Color(0xFF14532D);
  static const Color gold = Color(0xFFD4A72C);
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // Use the same backend host as the login screen.
  static const String _apiUrl = 'http://192.168.137.5:5000/api/users/me';

  Map<String, dynamic>? _user;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _storage.read(key: 'auth_token');

      if (token == null || token.isEmpty) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Please sign in again to view your profile.';
          _isLoading = false;
        });
        return;
      }

      final response = await http
          .get(
            Uri.parse(_apiUrl),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 20));

      final dynamic decoded = jsonDecode(response.body);
      final data = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{};

      if (!mounted) return;

      if (response.statusCode == 200 && data['user'] is Map<String, dynamic>) {
        setState(() {
          _user = data['user'] as Map<String, dynamic>;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              response.statusCode == 401 || response.statusCode == 403
              ? 'Your session may have expired, or your account may not be active. Please sign in again or contact support.'
              : data['message']?.toString() ??
                    'Unable to load your profile. Please try again.';
          _isLoading = false;
        });
      }
    } catch (error) {
      if (!mounted) return;

      debugPrint('Profile loading error: $error');
      setState(() {
        _errorMessage = 'Could not connect to the server. Check your connection and try again.';
        _isLoading = false;
      });
    }
  }

  String _formatStatus(String? value) {
    if (value == null || value.trim().isEmpty) return 'Not available';

    return value
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F6),
      appBar: AppBar(
        backgroundColor: forestGreen,
        foregroundColor: Colors.white,
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh profile',
            onPressed: _isLoading ? null : _loadProfile,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: forestGreen))
            : _errorMessage != null
            ? _buildError()
            : _buildProfile(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.account_circle_outlined,
              size: 72,
              color: forestGreen,
            ),
            const SizedBox(height: 18),
            const Text(
              'Profile unavailable',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF647067), height: 1.5),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: _loadProfile,
              style: FilledButton.styleFrom(
                backgroundColor: forestGreen,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfile() {
    final user = _user!;

    final fullName = user['fullName']?.toString() ?? 'Member';
    final email = user['email']?.toString() ?? 'Not available';
    final phone = user['phone']?.toString() ?? 'Not available';

    return RefreshIndicator(
      onRefresh: _loadProfile,
      color: forestGreen,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: forestGreen,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: Colors.white,
                  child: Text(
                    fullName.trim().isEmpty
                        ? 'M'
                        : fullName.trim()[0].toUpperCase(),
                    style: const TextStyle(
                      color: forestGreen,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  fullName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: gold,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    _formatStatus(user['role']?.toString()),
                    style: const TextStyle(
                      color: forestGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          const Text(
            'Personal Information',
            style: TextStyle(
              color: forestGreen,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _infoCard(
            icon: Icons.person_outline,
            label: 'Full name',
            value: fullName,
          ),
          _infoCard(
            icon: Icons.email_outlined,
            label: 'Email address',
            value: email,
          ),
          _infoCard(
            icon: Icons.phone_outlined,
            label: 'Phone number',
            value: phone,
          ),
          const SizedBox(height: 24),
          const Text(
            'Account & Verification',
            style: TextStyle(
              color: forestGreen,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _infoCard(
            icon: Icons.verified_user_outlined,
            label: 'Account status',
            value: _formatStatus(user['accountStatus']?.toString()),
          ),
          _infoCard(
            icon: Icons.fact_check_outlined,
            label: 'Identity verification',
            value: _formatStatus(user['verificationStatus']?.toString()),
          ),
          _infoCard(
            icon: Icons.mark_email_read_outlined,
            label: 'Email verified',
            value: user['emailVerified'] == true ? 'Yes' : 'No',
          ),
          _infoCard(
            icon: Icons.phone_android_outlined,
            label: 'Phone verified',
            value: user['phoneVerified'] == true ? 'Yes' : 'No',
          ),
          const SizedBox(height: 12),
          const Text(
            'Your information is retrieved from the Digital Ekub server.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF718075),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: Color(0xFFE5EBE5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: forestGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: forestGreen),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF718075),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Color(0xFF24382A),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
