import 'package:flutter/material.dart';

import '../../../dashboard/presentation/screens/general_dashboard_screen.dart';

class FaydaVerificationScreen extends StatelessWidget {
  const FaydaVerificationScreen({super.key});

  static const Color forestGreen = Color(0xFF14532D);
  static const Color gold = Color(0xFFD4A72C);

  void _startTestVerification(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.science_outlined, color: forestGreen),
            SizedBox(width: 10),
            Expanded(child: Text('Development Test Mode')),
          ],
        ),
        content: const Text(
          'The official Fayda service is not connected yet.\n\n'
          'For development testing only, you can open the dashboard '
          'to test its interface and other features. This does not '
          'verify your identity, approve your membership, or change '
          'your account status.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: forestGreen,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();

              Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => const GeneralDashboardScreen(),
                ),
              );
            },
            child: const Text('Continue to Dashboard'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fayda Verification'),
        centerTitle: true,
        backgroundColor: forestGreen,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Container(
                width: 88,
                height: 88,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: forestGreen,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  color: gold,
                  size: 46,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Verify your identity',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Official Fayda verification will be integrated later. '
                'For now, you can continue to the dashboard in development '
                'test mode to test the other application features.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: gold.withValues(alpha: 0.6)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.science_outlined, color: forestGreen),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'DEVELOPMENT TEST MODE\n\n'
                        'Fayda verification is not performed. '
                        'Your identity and membership approval remain '
                        'unverified until the official process is completed.',
                        style: TextStyle(height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: () => _startTestVerification(context),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Continue in Test Mode'),
                style: FilledButton.styleFrom(
                  backgroundColor: forestGreen,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Test navigation only; real verification and approval '
                'are not granted.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
