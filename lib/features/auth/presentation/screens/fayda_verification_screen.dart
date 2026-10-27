import 'package:flutter/material.dart';

class FaydaVerificationScreen extends StatelessWidget {
  const FaydaVerificationScreen({super.key});

  static const Color forestGreen = Color(0xFF14532D);
  static const Color gold = Color(0xFFD4A72C);

  void _startVerification(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Fayda Verification'),
        content: const Text(
          'The official Fayda verification service is not connected yet. '
          'Your identity has not been verified. Please try again after '
          'the authorized integration has been configured.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
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
                'To continue with Sagni Digital Ekub, you must verify '
                'your identity through the authorized Fayda verification '
                'process. After successful verification, your application '
                'will be sent to an administrator for approval.',
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
                    Icon(Icons.info_outline, color: forestGreen),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Official verification is not connected yet. '
                        'No identity information has been verified.',
                        style: TextStyle(height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: () => _startVerification(context),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Start Fayda Verification'),
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
                'The official verification service must be configured '
                'before your identity can be verified.',
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
