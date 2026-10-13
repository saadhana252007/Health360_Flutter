import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/router.dart';
import '../../data/models/profile.dart';
import '../../data/repositories/profile_repo.dart';
import '../../state/auth_provider.dart';
import '../../state/checkup_draft_provider.dart';

/// Patient Information screen replicating Android `PatientInformationActivity.kt`
/// and `activity_patient_information.xml`.
class PatientInfoScreen extends ConsumerStatefulWidget {
  const PatientInfoScreen({super.key, this.editFromProfile = false});

  final bool editFromProfile;

  @override
  ConsumerState<PatientInfoScreen> createState() => _PatientInfoScreenState();
}

class _PatientInfoScreenState extends ConsumerState<PatientInfoScreen> {
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  String? _selectedSex;
  Profile? _currentProfile;
  bool _isLoading = false;
  DateTime? _selectedDob;

  final List<String> _sexOptions = const ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final draftPatient = ref.read(checkupDraftProvider).patient;
    if (draftPatient != null) {
      _populateFromProfile(draftPatient);
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final profile = await ref
          .read(profileRepositoryProvider)
          .getProfile(user.id);
      if (profile != null && mounted) {
        _populateFromProfile(profile);
      }
    } catch (_) {
      // Graceful fallback to user metadata or empty inputs
      if (mounted && user.userMetadata != null) {
        final meta = user.userMetadata!;
        _nameController.text = meta['full_name'] as String? ?? '';
        final dobStr = meta['date_of_birth'] as String? ?? '';
        if (dobStr.isNotEmpty) {
          _setDateFromDbString(dobStr);
        }
        final s = meta['sex'] as String? ?? '';
        if (_sexOptions.contains(s)) {
          _selectedSex = s;
        }
        if (meta['height_cm'] != null) {
          _heightController.text = meta['height_cm'].toString();
        }
        if (meta['weight_kg'] != null) {
          _weightController.text = meta['weight_kg'].toString();
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _populateFromProfile(Profile profile) {
    _currentProfile = profile;
    _nameController.text = profile.fullName;
    _setDateFromDbString(profile.dateOfBirth);
    final match = _sexOptions.firstWhere(
      (opt) => opt.toLowerCase() == profile.sex.toLowerCase(),
      orElse: () => profile.sex.isNotEmpty ? profile.sex : 'Other',
    );
    _selectedSex = match;
    _heightController.text = profile.heightCm > 0
        ? (profile.heightCm % 1 == 0
              ? profile.heightCm.toInt().toString()
              : profile.heightCm.toString())
        : '';
    _weightController.text = profile.weightKg > 0
        ? (profile.weightKg % 1 == 0
              ? profile.weightKg.toInt().toString()
              : profile.weightKg.toString())
        : '';
  }

  void _setDateFromDbString(String dateStr) {
    if (dateStr.isEmpty) return;
    try {
      final parsed = DateTime.parse(dateStr);
      _selectedDob = parsed;
      _dobController.text = DateFormat('dd-MM-yyyy').format(parsed);
    } catch (_) {
      _dobController.text = dateStr;
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _selectedDob ?? DateTime(2000, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF006B6F),
              onPrimary: Colors.white,
              onSurface: Color(0xFF101828),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDob = picked;
        _dobController.text = DateFormat('dd-MM-yyyy').format(picked);
      });
    }
  }

  Future<void> _saveAndContinue() async {
    final name = _nameController.text.trim();
    final dobDisplay = _dobController.text.trim();
    final sex = _selectedSex?.trim() ?? '';
    final height = double.tryParse(_heightController.text.trim());
    final weight = double.tryParse(_weightController.text.trim());

    if (name.isEmpty) {
      _showError('Enter your full name');
      return;
    }

    if (dobDisplay.isEmpty) {
      _showError('Select your date of birth');
      return;
    }

    if (sex.isEmpty) {
      _showError('Select your sex');
      return;
    }

    if (height == null || height <= 0) {
      _showError('Enter a valid height');
      return;
    }

    if (weight == null || weight <= 0) {
      _showError('Enter a valid weight');
      return;
    }

    // Convert dd-MM-yyyy to yyyy-MM-dd for storage / API
    String dbDob;
    if (_selectedDob != null) {
      dbDob = DateFormat('yyyy-MM-dd').format(_selectedDob!);
    } else {
      try {
        final parsed = DateFormat('dd-MM-yyyy').parse(dobDisplay);
        dbDob = DateFormat('yyyy-MM-dd').format(parsed);
      } catch (_) {
        dbDob = dobDisplay;
      }
    }

    final user = ref.read(currentUserProvider);
    final profileId = _currentProfile?.id ?? user?.id ?? 'temp-user';

    final updatedProfile = Profile(
      id: profileId,
      fullName: name,
      dateOfBirth: dbDob,
      sex: sex,
      heightCm: height,
      weightKg: weight,
      createdAt: _currentProfile?.createdAt,
      updatedAt: _currentProfile?.updatedAt,
    );

    setState(() => _isLoading = true);

    try {
      await ref.read(profileRepositoryProvider).updateProfile(updatedProfile);
    } catch (_) {
      // In offline / test environments, proceed without breaking checkup draft
    }

    ref.read(checkupDraftProvider.notifier).setPatient(updatedProfile);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (widget.editFromProfile) {
      context.pop();
    } else {
      context.push(AppRoutes.symptoms);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF101828)),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: _isLoading && _currentProfile == null
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF006B6F)),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header Title & Icon ───────────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.badge_outlined,
                          size: 30,
                          color: Color(0xFF006B6F),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Patient Information',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF101828),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Review and update your information before starting the checkup.',
                      style: TextStyle(fontSize: 14, color: Color(0xFF667085)),
                    ),
                    const SizedBox(height: 28),

                    // ── Personal Details Section ──────────────────────────
                    const Text(
                      'Personal Details',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF101828),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Full Name
                    const Text(
                      'Full Name',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF101828),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF4FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 22,
                            color: Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _nameController,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xFF101828),
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Enter your full name',
                                hintStyle: TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 15,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Date of Birth & Sex Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date of Birth
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Date of Birth',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF101828),
                                ),
                              ),
                              const SizedBox(height: 5),
                              InkWell(
                                onTap: _pickDate,
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF4FF),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today_outlined,
                                        size: 20,
                                        color: Color(0xFF6B7280),
                                      ),
                                      const SizedBox(width: 7),
                                      Expanded(
                                        child: Text(
                                          _dobController.text.isNotEmpty
                                              ? _dobController.text
                                              : 'dd-mm-yyyy',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color:
                                                _dobController.text.isNotEmpty
                                                ? const Color(0xFF101828)
                                                : const Color(0xFF6B7280),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Sex Dropdown
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Sex',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF101828),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF4FF),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedSex,
                                    isExpanded: true,
                                    hint: const Text(
                                      'Select sex',
                                      style: TextStyle(
                                        color: Color(0xFF6B7280),
                                        fontSize: 14,
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.keyboard_arrow_down,
                                      color: Color(0xFF6B7280),
                                    ),
                                    items: _sexOptions.map((sex) {
                                      return DropdownMenuItem<String>(
                                        value: sex,
                                        child: Text(
                                          sex,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF101828),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      setState(() => _selectedSex = val);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Height & Weight Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Height
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Height',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF101828),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF4FF),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _heightController,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF101828),
                                        ),
                                        decoration: const InputDecoration(
                                          hintText: '000',
                                          hintStyle: TextStyle(
                                            color: Color(0xFF6B7280),
                                            fontSize: 14,
                                          ),
                                          border: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                      ),
                                    ),
                                    const Text(
                                      'cm',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF006064),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Weight
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Weight',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF101828),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF4FF),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _weightController,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF101828),
                                        ),
                                        decoration: const InputDecoration(
                                          hintText: '00',
                                          hintStyle: TextStyle(
                                            color: Color(0xFF6B7280),
                                            fontSize: 14,
                                          ),
                                          border: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                      ),
                                    ),
                                    const Text(
                                      'kg',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF006064),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Save and Continue Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveAndContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF006B6F),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Save and Continue',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }
}
