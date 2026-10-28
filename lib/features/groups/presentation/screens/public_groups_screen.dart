import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../../core/api_config.dart';

class PublicGroupsScreen extends StatefulWidget {
  const PublicGroupsScreen({super.key});

  @override
  State<PublicGroupsScreen> createState() => _PublicGroupsScreenState();
}

class _PublicGroupsScreenState extends State<PublicGroupsScreen> {
  static const Color forestGreen = Color(0xFF14532D);
  static const Color gold = Color(0xFFD4A72C);

  List<Map<String, dynamic>> _groups = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _page = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http
          .get(ApiConfig.endpoint('ekub-groups?page=$page&limit=20'))
          .timeout(ApiConfig.requestTimeout);

      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(
          data['message']?.toString() ?? 'Unable to load public groups.',
        );
      }

      final rawGroups = data['groups'];
      if (rawGroups is! List) {
        throw Exception('The server returned an unexpected groups response.');
      }

      final groups = rawGroups.whereType<Map<String, dynamic>>().toList();

      if (!mounted) return;

      setState(() {
        _groups = groups;
        _page = (data['page'] as num?)?.toInt() ?? page;
        _totalPages = (data['totalPages'] as num?)?.toInt() ?? 1;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String _formatFrequency(dynamic value) {
    switch (value?.toString()) {
      case 'daily':
        return 'Daily';
      case 'every_3_days':
        return 'Every 3 days';
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      default:
        return value?.toString().replaceAll('_', ' ') ?? 'Not specified';
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return 'Not specified';

    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return value.toString();

    final date = parsed.toLocal();
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatAmount(Map<String, dynamic> group) {
    final amount = group['contribution_amount'];
    final currency = group['currency']?.toString() ?? 'ETB';
    final parsed = amount is num ? amount : num.tryParse('$amount');

    if (parsed == null) return 'Amount unavailable';

    return '${parsed.toStringAsFixed(2)} $currency';
  }

  void _showGroupDetails(Map<String, dynamic> group) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        final description = group['description']?.toString().trim();

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  group['name']?.toString() ?? 'Ekub group',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: forestGreen,
                  ),
                ),
                const SizedBox(height: 12),
                if (description != null && description.isNotEmpty) ...[
                  Text(
                    description,
                    style: const TextStyle(height: 1.5, color: Colors.black87),
                  ),
                  const SizedBox(height: 18),
                ],
                _detailRow('Contribution', _formatAmount(group)),
                _detailRow(
                  'Schedule',
                  _formatFrequency(group['contribution_frequency']),
                ),
                _detailRow(
                  'Group capacity',
                  '${group['capacity'] ?? '—'} members',
                ),
                _detailRow('Starts', _formatDate(group['start_date'])),
                _detailRow('Ends', _formatDate(group['end_date'])),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Review the contribution rules, payout order, and '
                    'membership requirements before applying. Joining '
                    'will be enabled when the application flow is connected.',
                    style: TextStyle(height: 1.5),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    style: FilledButton.styleFrom(
                      backgroundColor: forestGreen,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Close details'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: forestGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _groups.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: forestGreen));
    }

    if (_errorMessage != null && _groups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 48,
                color: Colors.blueGrey,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(height: 1.5),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => _loadGroups(page: _page),
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
                style: FilledButton.styleFrom(backgroundColor: forestGreen),
              ),
            ],
          ),
        ),
      );
    }

    if (_groups.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _loadGroups(page: 1),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 140),
            Icon(Icons.groups_2_outlined, size: 64, color: Colors.blueGrey),
            SizedBox(height: 18),
            Center(
              child: Text(
                'No public Ekub groups are available yet.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: Text(
                'Pull down to refresh later.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadGroups(page: _page),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [forestGreen, Color(0xFF247044)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.groups_rounded, color: gold, size: 32),
                SizedBox(height: 12),
                Text(
                  'Find your Ekub community',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Compare contribution schedules and group rules before '
                  'deciding where to apply.',
                  style: TextStyle(color: Colors.white70, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Available public groups',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: forestGreen,
                  ),
                ),
              ),
              Text(
                '${_groups.length} shown',
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Refresh warning: $_errorMessage',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ..._groups.map(_groupCard),
          if (_totalPages > 1) ...[
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(
                  onPressed: _isLoading || _page <= 1
                      ? null
                      : () => _loadGroups(page: _page - 1),
                  child: const Text('Previous'),
                ),
                Text('Page $_page of $_totalPages'),
                OutlinedButton(
                  onPressed: _isLoading || _page >= _totalPages
                      ? null
                      : () => _loadGroups(page: _page + 1),
                  child: const Text('Next'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _groupCard(Map<String, dynamic> group) {
    return Card(
      margin: const EdgeInsets.only(bottom: 13),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE2E9E2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _showGroupDetails(group),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F0E8),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.groups_rounded,
                      color: forestGreen,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group['name']?.toString() ?? 'Ekub group',
                          style: const TextStyle(
                            color: forestGreen,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _formatFrequency(group['contribution_frequency']),
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.blueGrey),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: forestGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formatAmount(group),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.people_outline,
                    color: Colors.blueGrey,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text('Capacity: ${group['capacity'] ?? '—'} members'),
                  const Spacer(),
                  const Icon(
                    Icons.calendar_month_outlined,
                    color: Colors.blueGrey,
                    size: 19,
                  ),
                  const SizedBox(width: 6),
                  Text(_formatDate(group['start_date'])),
                ],
              ),
              const SizedBox(height: 15),
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'View group details',
                  style: TextStyle(
                    color: forestGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F6),
      appBar: AppBar(
        backgroundColor: forestGreen,
        foregroundColor: Colors.white,
        title: const Text(
          'Public Ekub Groups',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh groups',
            onPressed: _isLoading ? null : () => _loadGroups(page: 1),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }
}
