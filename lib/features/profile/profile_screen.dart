import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/router.dart';
import '../../data/models/profile.dart';
import '../../data/repositories/auth_repo.dart';
import '../../data/repositories/profile_repo.dart';
import '../../state/auth_provider.dart';
import '../../state/checkup_draft_provider.dart';

/// Provides the current user's profile for the ProfileScreen.
final profileScreenProvider = FutureProvider.autoDispose<Profile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.watch(profileRepositoryProvider).getProfile(user.id);
});

/// Profile screen mirroring Android `ProfileFragment.kt` and `fragment_profile.xml`.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileScreenProvider);
    final user = ref.watch(currentUserProvider);

    final profile = profileAsync.valueOrNull;

    final email = user?.email ?? 'Not available';
    final name = profile?.fullName.trim().isNotEmpty == true
        ? profile!.fullName.trim()
        : (user?.userMetadata?['full_name'] as String? ?? 'User');
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF006B6F),
          onRefresh: () async {
            ref.invalidate(profileScreenProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Screen Title ──────────────────────────────────────────
                const Text(
                  'My Profile',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF12343B),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Manage your personal information and account',
                  style: TextStyle(fontSize: 13, color: Color(0xFF718083)),
                ),
                const SizedBox(height: 20),

                // ── Profile Avatar & Name Card ────────────────────────────
                _buildAvatarCard(initial: initial, name: name, email: email),
                const SizedBox(height: 26),

                // ── Personal Health Details Section ───────────────────────
                const Text(
                  'PERSONAL HEALTH DETAILS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF718083),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 9),
                _buildHealthDetailsCard(profile, user?.userMetadata),
                const SizedBox(height: 13),

                // ── Edit Profile Button ───────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      context.push(
                        '${AppRoutes.patientInfo}?edit_from_profile=true',
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006B6F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Edit Personal Information',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 27),

                // ── Account Details Section ───────────────────────────────
                const Text(
                  'ACCOUNT DETAILS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF718083),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 9),
                _buildAccountDetailsCard(
                  email,
                  profile?.createdAt ?? user?.createdAt,
                ),
                const SizedBox(height: 27),

                // ── Account Settings Section ──────────────────────────────
                const Text(
                  'ACCOUNT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF718083),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 9),
                _buildSettingsCard(context),
                const SizedBox(height: 17),

                // ── Logout Button ─────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => _showLogoutConfirmation(context, ref),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFB3261E),
                      side: const BorderSide(color: Color(0xFFE5B7B3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
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

  // ── Avatar Card ───────────────────────────────────────────────────────────
  Widget _buildAvatarCard({
    required String initial,
    required String name,
    required String email,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E9EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: Color(0xFFEFF4FF),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: Color(0xFF006B6F),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF12343B),
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Health360 User',
                  style: TextStyle(fontSize: 13, color: Color(0xFF718083)),
                ),
                const SizedBox(height: 5),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF006B6F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Health Details Card ───────────────────────────────────────────────────
  Widget _buildHealthDetailsCard(Profile? profile, Map<String, dynamic>? meta) {
    final fullName = profile?.fullName.isNotEmpty == true
        ? profile!.fullName
        : (meta?['full_name'] as String? ?? 'Not available');

    final dob = _formatDob(
      profile?.dateOfBirth ?? meta?['date_of_birth'] as String?,
    );
    final sex = profile?.sex.isNotEmpty == true
        ? profile!.sex
        : (meta?['sex'] as String? ?? 'Not available');

    final height = profile != null
        ? '${_formatNumber(profile.heightCm)} cm'
        : (meta?['height_cm'] != null
              ? '${_formatNumber(_toDouble(meta!['height_cm']))} cm'
              : 'Not available');

    final weight = profile != null
        ? '${_formatNumber(profile.weightKg)} kg'
        : (meta?['weight_kg'] != null
              ? '${_formatNumber(_toDouble(meta!['weight_kg']))} kg'
              : 'Not available');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE2E9EB)),
      ),
      child: Column(
        children: [
          _buildDetailRow(
            icon: Icons.person_outline,
            label: 'Full Name',
            value: fullName,
          ),
          const Divider(height: 1, color: Color(0xFFEDF1F2)),
          _buildDetailRow(
            icon: Icons.calendar_today_outlined,
            label: 'Date of Birth',
            value: dob,
          ),
          const Divider(height: 1, color: Color(0xFFEDF1F2)),
          _buildDetailRow(customIconText: '♀', label: 'Sex', value: sex),
          const Divider(height: 1, color: Color(0xFFEDF1F2)),
          _buildDetailRow(customIconText: '↕', label: 'Height', value: height),
          const Divider(height: 1, color: Color(0xFFEDF1F2)),
          _buildDetailRow(customIconText: '⚖', label: 'Weight', value: weight),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    IconData? icon,
    String? customIconText,
    required String label,
    required String value,
  }) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: Center(
              child: customIconText != null
                  ? Text(
                      customIconText,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF006B6F),
                      ),
                    )
                  : Icon(icon, size: 20, color: const Color(0xFF006B6F)),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF718083)),
            ),
          ),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF12343B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Account Details Card ──────────────────────────────────────────────────
  Widget _buildAccountDetailsCard(String email, String? createdAt) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE2E9EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Email',
            style: TextStyle(fontSize: 12, color: Color(0xFF718083)),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF12343B),
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFEDF1F2)),
          const SizedBox(height: 14),
          const Text(
            'Account Created',
            style: TextStyle(fontSize: 12, color: Color(0xFF718083)),
          ),
          const SizedBox(height: 4),
          Text(
            _formatAccountCreated(createdAt),
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

  // ── Settings Card ─────────────────────────────────────────────────────────
  Widget _buildSettingsCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE2E9EB)),
      ),
      child: Column(
        children: [
          _buildActionRow(
            iconText: '🔒',
            title: 'Privacy & Security',
            subtitle: 'Account and data protection',
            onTap: () => _showPrivacySecurity(context),
          ),
          const Divider(height: 1, color: Color(0xFFEDF1F2)),
          _buildActionRow(
            iconText: 'ⓘ',
            title: 'About Health360',
            subtitle: 'Learn about the application',
            onTap: () => _showAboutHealth360(context),
          ),
          const Divider(height: 1, color: Color(0xFFEDF1F2)),
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF4FF),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'ⓘ',
                    style: TextStyle(fontSize: 17, color: Color(0xFF006B6F)),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'App Version',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF12343B),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Current installed version',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF718083),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF4FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'v1.0.0',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF006B6F),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow({
    required String iconText,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFFEFF4FF),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                iconText,
                style: const TextStyle(fontSize: 17, color: Color(0xFF006B6F)),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF12343B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF718083),
                    ),
                  ),
                ],
              ),
            ),
            const Text(
              '›',
              style: TextStyle(fontSize: 22, color: Color(0xFF718083)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────
  void _showPrivacySecurity(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Privacy & Security'),
        content: const Text(
          'Your Health360 account is protected using Supabase Authentication. '
          'Your personal profile and health checkup information are associated '
          'with your account and stored securely.\n\n'
          'Health360 AI uses your submitted information to provide the health '
          'screening features available in the application.\n\n'
          'Health360 AI is an AI-assisted screening tool and does not replace '
          'professional medical advice.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAboutHealth360(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('About Health360 AI'),
        content: const Text(
          'Health360 AI is a modular AI-powered personal health checkup application.\n\n'
          'The application combines patient information, symptoms, and optional '
          'image analysis to generate an AI-assisted health assessment.\n\n'
          'Health360 AI can analyze different image categories such as skin, '
          'oral, and wound images and combines available information through '
          'a multimodal AI pipeline.\n\n'
          'The results are intended for screening and informational purposes '
          'and should not be considered a medical diagnosis.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text(
          'Are you sure you want to logout from your Health360 account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref.read(authRepositoryProvider).signOut();
                ref.read(checkupDraftProvider.notifier).clear();
                // GoRouter redirect guard handles navigation to /login automatically.
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Logout failed')),
                  );
                }
              }
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Color(0xFFB3261E)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  static String _formatDob(String? date) {
    if (date == null || date.trim().isEmpty) return 'Not available';
    try {
      final parsed = DateTime.parse(date);
      return DateFormat('MMMM d, yyyy').format(parsed);
    } catch (_) {
      return date;
    }
  }

  static String _formatAccountCreated(String? date) {
    if (date == null || date.trim().isEmpty) return 'Not available';
    try {
      final parsed = DateTime.parse(date);
      return DateFormat('MMMM d, yyyy').format(parsed);
    } catch (_) {
      return date;
    }
  }

  static String _formatNumber(double value) {
    if (value % 1.0 == 0.0) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}
