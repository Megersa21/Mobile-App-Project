import 'package:flutter/material.dart';

import '../../../profile/presentation/screens/member_profile_screen.dart';

class GeneralDashboardScreen extends StatelessWidget {
  const GeneralDashboardScreen({super.key});

  static const Color forestGreen = Color(0xFF14532D);
  static const Color gold = Color(0xFFD4A72C);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F6),
      appBar: AppBar(
        backgroundColor: forestGreen,
        foregroundColor: Colors.white,
        title: const Text(
          'Sagni Digital Ekub',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Account information',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MemberProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Welcome!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: forestGreen,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Explore savings communities and learn how Ekub works.',
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Color(0xFF647067),
              ),
            ),
            const SizedBox(height: 22),

            // Account and membership status.
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: forestGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.verified_user_outlined, color: gold, size: 32),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your membership journey',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 7),
                        Text(
                          'Explore Ekub communities and apply to join. '
                          'Your actual verification and application status '
                          'will appear here once connected to the server.',
                          style: TextStyle(color: Colors.white70, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),
            const Text(
              'Explore Digital Ekub',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: forestGreen,
              ),
            ),
            const SizedBox(height: 14),

            _DashboardCard(
              icon: Icons.explore_outlined,
              title: 'Explore Ekub Types',
              description: 'Learn about different savings group arrangements.',
              onTap: () => _showDetails(
                context,
                'Explore Ekub Types',
                [
                  'Traditional rotating Ekub',
                  'Weekly contribution groups',
                  'Monthly contribution groups',
                ],
                'These are introductory examples. Available Ekub types '
                    'will be loaded from the backend when the API is ready.',
              ),
            ),

            _DashboardCard(
              icon: Icons.menu_book_outlined,
              title: 'How Ekub Works',
              description:
                  'Understand contributions, payout turns, and group rules.',
              onTap: () => _showDetails(
                context,
                'How Ekub Works',
                [
                  'Members agree to a contribution amount and schedule.',
                  'Contributions are collected for each round.',
                  'The payout is made according to the agreed turn order '
                      'after authorized review.',
                  'Members continue meeting their obligations until '
                      'the agreed cycle ends.',
                ],
                'The rules of a particular Ekub must be confirmed before '
                    'joining.',
              ),
            ),

            _DashboardCard(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Contribution Plans & Amounts',
              description:
                  'Understand payment schedules and contribution options.',
              onTap: () => _showDetails(
                context,
                'Contribution Plans & Amounts',
                [
                  'Weekly or monthly schedules may be offered.',
                  'The contribution amount depends on the specific group.',
                  'Check due dates, penalties, payout rules, and total '
                      'obligations before applying.',
                ],
                'No live contribution amounts are displayed yet. '
                    'Actual plans must come from approved server data.',
              ),
            ),

            _DashboardCard(
              icon: Icons.groups_outlined,
              title: 'Public Community Information',
              description:
                  'Discover available communities and their public details.',
              onTap: () => _showDetails(
                context,
                'Public Community Information',
                [
                  'Community name and description',
                  'Contribution schedule and amount',
                  'Membership availability and joining requirements',
                ],
                'Community listings are placeholders for now. '
                    'Private member information and financial records '
                    'must not be exposed here.',
              ),
            ),

            _DashboardCard(
              icon: Icons.assignment_outlined,
              title: 'My Application Status',
              description:
                  'Learn where to check verification and membership progress.',
              onTap: () => _showDetails(
                context,
                'My Application Status',
                [
                  'Identity verification status',
                  'Ekub membership application status',
                  'Administrator review result and feedback',
                ],
                'Your personal status is not yet connected to the API. '
                    'This screen does not claim that you are verified '
                    'or approved.',
              ),
            ),

            _DashboardCard(
              icon: Icons.add_circle_outline,
              title: 'Apply to Join an Ekub',
              description:
                  'Review joining requirements and start an application.',
              onTap: () => _showDetails(
                context,
                'Apply to Join an Ekub',
                [
                  'Choose an available Ekub.',
                  'Review its contribution amount and rules.',
                  'Submit your membership application.',
                  'Wait for the authorized administrator to review it.',
                ],
                'Application submission will be enabled after the '
                    'backend membership application endpoint is implemented.',
              ),
            ),

            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: gold.withValues(alpha: 0.5)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: forestGreen),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This is the general dashboard. Access to member '
                      'activities requires the server to confirm the '
                      'required verification and membership approvals.',
                      style: TextStyle(height: 1.5),
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

  static void _showDetails(
    BuildContext context,
    String title,
    List<String> items,
    String note,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: forestGreen,
                ),
              ),
              const SizedBox(height: 18),
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: forestGreen,
                        size: 21,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(fontSize: 15, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                note,
                style: const TextStyle(color: Color(0xFF647067), height: 1.5),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: forestGreen,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE5EBE5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF14532D).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: const Color(0xFF14532D), size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF24382A),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: Color(0xFF718075),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Color(0xFF718075)),
            ],
          ),
        ),
      ),
    );
  }
}
