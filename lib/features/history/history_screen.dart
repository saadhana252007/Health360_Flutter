import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/router.dart';
import '../../core/providers.dart';
import '../../data/models/checkup_summary.dart';
import '../../data/repositories/checkup_repo.dart';
import '../../state/auth_provider.dart';

/// Checkup History screen replicating Android `HistoryFragment.kt`,
/// `fragment_history.xml`, and `item_checkup_history.xml`.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  List<CheckupSummary> _history = const [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(checkupRepositoryProvider);
      final userId =
          ref.read(currentUserProvider)?.id ??
          ref.read(supabaseClientProvider).auth.currentUser?.id;

      if (userId == null || userId.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Please log in to view your checkup history.';
          });
        }
        return;
      }

      final history = await repository.getCheckupHistory(userId);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _history = history;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  String _formatDate(String value) {
    try {
      final date = DateTime.parse(value);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (_) {
      return value.length >= 10 ? value.substring(0, 10) : value;
    }
  }

  String _formatPercentage(double? value) {
    if (value == null) return '—';
    return '${(value * 100).toInt()}%';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Title & Subtitle ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Checkup History',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF12343B),
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'View your previous health checkups',
                    style: TextStyle(fontSize: 14, color: Color(0xFF718083)),
                  ),
                ],
              ),
            ),

            // ── Main Content Area ─────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF006B6F),
                      ),
                    )
                  : _errorMessage != null
                  ? _buildErrorState()
                  : _history.isEmpty
                  ? _buildEmptyState()
                  : _buildHistoryList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: const Color(0xFF006B6F),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.18),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEFF4FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.history,
                      size: 32,
                      color: Color(0xFF006B6F),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'No checkups yet',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF12343B),
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Complete a health checkup and your results will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Color(0xFF718083)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 52, color: Color(0xFFA32222)),
            const SizedBox(height: 16),
            const Text(
              'Unable to load history',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF12343B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Please try again later.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF718083)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadHistory,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006B6F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: const Color(0xFF006B6F),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        itemCount: _history.length,
        itemBuilder: (context, index) {
          final item = _history[index];
          return _buildHistoryCard(item);
        },
      ),
    );
  }

  Widget _buildHistoryCard(CheckupSummary item) {
    final statusText = item.status.isNotEmpty
        ? (item.status[0].toUpperCase() + item.status.substring(1))
        : 'Completed';

    final titleText = item.overallCategory?.isNotEmpty == true
        ? item.overallCategory!
        : 'Health Screening';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FCFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFB9DDDB), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openResult(item.id),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Date & Status Header ──────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDate(item.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF718083),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          titleText,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF12343B),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE4F3F1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusText,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF006B6F),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Summary Text ──────────────────────────────────────────
                const Text(
                  'AI-assisted health screening completed.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF4F6266)),
                ),
                const SizedBox(height: 16),

                // ── Confidence & Completeness Metrics ─────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AI Confidence',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF718083),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _formatPercentage(item.confidence),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF006B6F),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Completeness',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF718083),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _formatPercentage(item.completeness),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF006B6F),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Result Info Badge ─────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'AI screening result available',
                    style: TextStyle(fontSize: 12, color: Color(0xFF006B6F)),
                  ),
                ),
                const SizedBox(height: 15),

                // ── Action Link ───────────────────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'View screening result  →',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF006B6F),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openResult(String checkupId) {
    context.push('${AppRoutes.result}?checkup_id=$checkupId');
  }
}
