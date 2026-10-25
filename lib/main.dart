import 'package:flutter/material.dart';

import 'app/app_theme.dart';
import 'features/auth/presentation/screens/register_screen.dart';

void main() {
  runApp(const DigitalEkubApp());
}

class DigitalEkubApp extends StatelessWidget {
  const DigitalEkubApp({super.key});

  @override
  Widget build(BuildContext context) {
    const forestGreen = Color(0xFF14532D);
    const gold = Color(0xFFD4A72C);

    return MaterialApp(
      title: 'Sagni Digital Ekub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF14532D);
    const gold = Color(0xFFD4A72C);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(height: 12),

                    Column(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: green,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: green.withValues(alpha: 0.18),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Colors.white,
                            size: 52,
                          ),
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          'SAGNI',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 5,
                            color: green,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'DIGITAL EKUB',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3,
                            color: gold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 42),

                    Column(
                      children: [
                        const Text(
                          'Save Together.\nGrow Together.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 34,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF173D29),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'A smarter way to organize your Equb, '
                          'build trust, and reach your financial goals '
                          'together.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.7,
                            color: Color(0xFF647067),
                          ),
                        ),
                        const SizedBox(height: 30),

                        const _FeatureRow(
                          icon: Icons.groups_rounded,
                          title: 'Community savings',
                          subtitle: 'Save with people you trust.',
                        ),
                        const SizedBox(height: 18),
                        const _FeatureRow(
                          icon: Icons.verified_user_rounded,
                          title: 'Trust and transparency',
                          subtitle: 'Clear rules and verified decisions.',
                        ),
                        const SizedBox(height: 18),
                        const _FeatureRow(
                          icon: Icons.notifications_active_rounded,
                          title: 'Stay informed',
                          subtitle: 'Keep track of contributions and rounds.',
                        ),
                      ],
                    ),

                    const SizedBox(height: 38),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const RegisterScreen(),
                              ),
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: green,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Get Started',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Sign in will be available in the '
                                  'authentication development step.',
                                ),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: green,
                            minimumSize: const Size.fromHeight(56),
                            side: const BorderSide(color: green, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Already have an account? Sign In',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Building stronger savings communities.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF879188),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF14532D);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFE6F0E8),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.check_circle_outline_rounded,
            color: green,
            size: 25,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF24382A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Color(0xFF718075),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
