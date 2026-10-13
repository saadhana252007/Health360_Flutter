import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/router.dart';
import '../../data/models/checkup_summary.dart';
import '../../data/models/profile.dart';
import '../../data/repositories/checkup_repo.dart';
import '../../data/repositories/profile_repo.dart';
import '../../state/auth_provider.dart';
import '../shell/home_shell.dart';

/// Provides the current user's profile from the database.
final homeProfileProvider = FutureProvider.autoDispose<Profile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.watch(profileRepositoryProvider).getProfile(user.id);
});

/// Provides the current user's most recent checkup summary from the database.
final homeLatestCheckupProvider = FutureProvider.autoDispose<CheckupSummary?>((
  ref,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.watch(checkupRepositoryProvider).getLatestCheckup(user.id);
});

/// Home screen mirroring Android `HomeFragment.kt` and `fragment_home.xml`.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(homeProfileProvider);
    final checkupAsync = ref.watch(homeLatestCheckupProvider);

    final profile = profileAsync.valueOrNull;
    final checkup = checkupAsync.valueOrNull;

    final greeting = _getGreeting();
    final name = profile?.fullName.trim() ?? '';
    final greetingText = name.isNotEmpty ? '$greeting, $name' : greeting;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF006B6F),
          onRefresh: () async {
            ref.invalidate(homeProfileProvider);
            ref.invalidate(homeLatestCheckupProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header Greeting & Avatar ──────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            greetingText,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF12343B),
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            "Let's check in on your health today.",
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF718083),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: () {
                        ref.read(activeTabProvider.notifier).state = 3;
                      },
                      borderRadius: BorderRadius.circular(25),
                      child: Container(
                        width: 50,
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF4FF),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFD5E5E7),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF006B6F),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // ── Start Checkup Screening Card ──────────────────────────
                _buildScreeningCard(context),
                const SizedBox(height: 28),

                // ── Your Health Overview ──────────────────────────────────
                const Text(
                  'Your Health Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF12343B),
                  ),
                ),
                const SizedBox(height: 12),
                _buildOverviewGrid(checkup),
                const SizedBox(height: 28),

                // ── Recent Checkup ────────────────────────────────────────
                const Text(
                  'Recent Checkup',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF12343B),
                  ),
                ),
                const SizedBox(height: 12),
                _buildRecentCheckupCard(context, checkup),
                const SizedBox(height: 14),

                // ── Health360 AI Assistant Card ───────────────────────────
                _buildAssistantCard(context, ref),
                const SizedBox(height: 28),

                // ── Today's Health Tip ────────────────────────────────────
                const Text(
                  "Today's Health Tip",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF12343B),
                  ),
                ),
                const SizedBox(height: 12),
                _buildHealthTipCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Screening Card ────────────────────────────────────────────────────────
  Widget _buildScreeningCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD5E5E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF4FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'AI-POWERED MULTIMODAL SCREENING',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF006B6F),
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 13),
          const Text(
            'Start a Health Checkup',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF12343B),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Assess your current health using your symptoms, vital information and optional image analysis.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF718083),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _FeatureChip(
                icon: Icons.medical_services_outlined,
                label: 'Symptoms',
              ),
              _FeatureChip(icon: Icons.monitor_heart_outlined, label: 'Vitals'),
              _FeatureChip(icon: Icons.image_outlined, label: 'Images'),
            ],
          ),
          const SizedBox(height: 17),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () => _onStartCheckup(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006B6F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Start Health Checkup  →',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Overview 2x2 Grid ─────────────────────────────────────────────────────
  Widget _buildOverviewGrid(CheckupSummary? checkup) {
    final overallHealthText = checkup != null
        ? '${(checkup.overallScore.clamp(0.0, 1.0) * 100).toStringAsFixed(0)}%'
        : 'Not assessed';

    final lastCheckupText = checkup != null
        ? _formatDate(checkup.createdAt)
        : 'No checkups yet';

    final symptomsText = checkup != null ? 'Completed' : 'Not recorded';

    final riskStatusText = checkup != null
        ? (checkup.overallCategory != null &&
                  checkup.overallCategory!.trim().isNotEmpty
              ? _capitalize(checkup.overallCategory!.trim())
              : 'Screening complete')
        : 'Not assessed';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _OverviewTile(
                title: 'Overall Health',
                value: overallHealthText,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _OverviewTile(
                title: 'Last Checkup',
                value: lastCheckupText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _OverviewTile(title: 'Symptoms', value: symptomsText),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _OverviewTile(title: 'Risk Status', value: riskStatusText),
            ),
          ],
        ),
      ],
    );
  }

  // ── Recent Checkup Card ───────────────────────────────────────────────────
  Widget _buildRecentCheckupCard(
    BuildContext context,
    CheckupSummary? checkup,
  ) {
    final hasCheckup = checkup != null;
    final title = hasCheckup ? 'Latest health checkup' : 'No checkups yet';
    final desc = hasCheckup
        ? 'Completed on ${_formatDate(checkup.createdAt)}'
        : 'Complete your first health checkup to see your results here.';
    final actionText = hasCheckup
        ? 'Start another checkup  →'
        : 'Start your first checkup  →';

    return InkWell(
      onTap: () => _onStartCheckup(context),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE1E9EB)),
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Color(0xFFEFF4FF),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text(
                '✓',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF006B6F),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF12343B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF718083)),
            ),
            const SizedBox(height: 11),
            Text(
              actionText,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF006B6F),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Assistant Card ────────────────────────────────────────────────────────
  Widget _buildAssistantCard(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD9E5F4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Health360 AI Assistant',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF12343B),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Have questions about your health assessment? Ask the AI assistant to understand your results.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF718083),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              ref.read(activeTabProvider.notifier).state = 2;
            },
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF006B6F),
              side: const BorderSide(color: Color(0xFFC8DDE1)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              elevation: 0,
            ),
            child: const Text(
              'Ask Assistant',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ── Health Tip Card ───────────────────────────────────────────────────────
  Widget _buildHealthTipCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE1E9EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFEFF4FF),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text(
              '♡',
              style: TextStyle(fontSize: 22, color: Color(0xFF006B6F)),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Stay hydrated and remember to take regular breaks during the day.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF12343B),
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'General wellness information • Non-diagnostic',
                  style: TextStyle(fontSize: 10, color: Color(0xFF718083)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Handlers & Helpers ────────────────────────────────────────────────────
  void _onStartCheckup(BuildContext context) {
    context.push(AppRoutes.patientInfo);
  }

  static String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static String _formatDate(String isoString) {
    try {
      final parsed = DateTime.parse(isoString);
      return DateFormat('dd MMM yyyy').format(parsed);
    } catch (_) {
      return isoString.length >= 10 ? isoString.substring(0, 10) : isoString;
    }
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF006B6F)),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF006B6F),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewTile extends StatelessWidget {
  const _OverviewTile({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 105,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E9EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: Color(0xFF718083)),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF12343B),
            ),
          ),
        ],
      ),
    );
  }
}
