import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/router.dart';
import '../../data/models/profile.dart';
import '../../data/repositories/auth_repo.dart';
import '../../data/repositories/profile_repo.dart';

/// Registration screen recreating the original Android layout from `activity_register.xml`.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedSex;
  bool _termsAccepted = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  final List<String> _sexOptions = const ['Male', 'Female', 'Other'];

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1995, 1, 1),
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF006064),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0B1C30),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatter = DateFormat('yyyy-MM-dd');
      setState(() {
        _dobController.text = formatter.format(picked);
      });
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final dob = _dobController.text.trim();
    final sex = _selectedSex ?? '';
    final heightText = _heightController.text.trim();
    final weightText = _weightController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Validation sequence exactly mirrors RegisterActivity.kt:
    if (name.isEmpty) {
      _showError('Enter your full name');
      return;
    }
    if (dob.isEmpty) {
      _showError('Select your date of birth');
      return;
    }
    if (sex.isEmpty) {
      _showError('Select your sex');
      return;
    }
    if (heightText.isEmpty) {
      _showError('Enter your height');
      return;
    }
    if (weightText.isEmpty) {
      _showError('Enter your weight');
      return;
    }
    if (email.isEmpty) {
      _showError('Enter your email');
      return;
    }
    if (password.length < 8) {
      _showError('Password must contain at least 8 characters');
      return;
    }
    if (password != confirmPassword) {
      _showError('Passwords do not match');
      return;
    }
    if (!_termsAccepted) {
      _showError('Accept the Terms of Service and Privacy Policy');
      return;
    }

    final height = double.tryParse(heightText);
    final weight = double.tryParse(weightText);

    if (height == null || height <= 0) {
      _showError('Enter a valid height');
      return;
    }
    if (weight == null || weight <= 0) {
      _showError('Enter a valid weight');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Q1 Fix: send profile fields inside user_metadata (`data:`) so trigger
      // creates the row even when email verification is on.
      final profileData = {
        'full_name': name,
        'date_of_birth': dob,
        'sex': sex,
        'height_cm': height,
        'weight_kg': weight,
      };

      final response = await ref
          .read(authRepositoryProvider)
          .signUpWithEmail(
            email: email,
            password: password,
            profileData: profileData,
          );

      final user = response.user;

      if (user == null || response.session == null) {
        // Email confirmation is enabled: no active session yet.
        // The metadata is safely stored in Supabase Auth user_metadata.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Account created. Please verify your email and login.',
              ),
              duration: Duration(seconds: 4),
            ),
          );
          context.go(AppRoutes.login);
        }
        return;
      }

      // Email confirmation is disabled / immediate session:
      // Insert/upsert into `profiles` directly using existing schema.
      await ref
          .read(profileRepositoryProvider)
          .upsertProfile(
            Profile(
              id: user.id,
              fullName: name,
              dateOfBirth: dob,
              sex: sex,
              heightCm: height,
              weightKg: weight,
            ),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final message = e is AuthException
            ? e.message
            : (e.toString().isNotEmpty ? e.toString() : 'Registration failed');
        _showError(message);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 12),

              // ── Header logo & Title ────────────────────────────────────────
              Image.asset(
                'assets/images/ic_health360_logo.png',
                width: 62,
                height: 62,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.health_and_safety_rounded,
                  size: 52,
                  color: Color(0xFF006064),
                ),
              ),
              const SizedBox(height: 6),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Health360',
                    style: TextStyle(
                      color: Color(0xFF006064),
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 43,
                    height: 25,
                    decoration: BoxDecoration(
                      color: const Color(0xFF006064),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'AI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),
              const Text(
                'Create your account',
                style: TextStyle(
                  color: Color(0xFF0B1C30),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Set up your profile for personalized health checkups',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF3E4949), fontSize: 13),
              ),

              const SizedBox(height: 18),

              // ── Form Card (#FFFFFF, radius 14, elevation 1) ─────────────────
              Card(
                elevation: 1,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Personal Details
                      const Text(
                        'Personal Details',
                        style: TextStyle(
                          color: Color(0xFF0B1C30),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),

                      const Text(
                        'Full Name',
                        style: TextStyle(
                          color: Color(0xFF0B1C30),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF4FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.person_outline,
                              size: 22,
                              color: Color(0xFF006064),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _nameController,
                                enabled: !_isLoading,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'Enter your full name',
                                  hintStyle: TextStyle(
                                    color: Color(0xFF808080),
                                    fontSize: 16,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Row: Date of Birth & Sex
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Date of Birth',
                                  style: TextStyle(
                                    color: Color(0xFF0B1C30),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                GestureDetector(
                                  onTap: _isLoading ? null : _selectDate,
                                  child: Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF4FF),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today_outlined,
                                          size: 20,
                                          color: Color(0xFF006064),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _dobController.text.isEmpty
                                                ? 'yyyy-MM-dd'
                                                : _dobController.text,
                                            style: TextStyle(
                                              color: _dobController.text.isEmpty
                                                  ? const Color(0xFF808080)
                                                  : Colors.black,
                                              fontSize: 15,
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
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Sex',
                                  style: TextStyle(
                                    color: Color(0xFF0B1C30),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF4FF),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedSex,
                                      hint: const Text(
                                        'Select sex',
                                        style: TextStyle(
                                          color: Color(0xFF808080),
                                          fontSize: 15,
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: Color(0xFF006064),
                                      ),
                                      isExpanded: true,
                                      items: _sexOptions.map((sex) {
                                        return DropdownMenuItem<String>(
                                          value: sex,
                                          child: Text(
                                            sex,
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 15,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: _isLoading
                                          ? null
                                          : (val) {
                                              setState(() {
                                                _selectedSex = val;
                                              });
                                            },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Row: Height & Weight
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Height',
                                  style: TextStyle(
                                    color: Color(0xFF0B1C30),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF4FF),
                                    borderRadius: BorderRadius.circular(8),
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
                                          enabled: !_isLoading,
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 16,
                                          ),
                                          decoration: const InputDecoration(
                                            hintText: '000',
                                            hintStyle: TextStyle(
                                              color: Color(0xFF808080),
                                              fontSize: 16,
                                            ),
                                            border: InputBorder.none,
                                            isDense: true,
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                        ),
                                      ),
                                      const Text(
                                        'cm',
                                        style: TextStyle(
                                          color: Color(0xFF006064),
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Weight',
                                  style: TextStyle(
                                    color: Color(0xFF0B1C30),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF4FF),
                                    borderRadius: BorderRadius.circular(8),
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
                                          enabled: !_isLoading,
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 16,
                                          ),
                                          decoration: const InputDecoration(
                                            hintText: '00',
                                            hintStyle: TextStyle(
                                              color: Color(0xFF808080),
                                              fontSize: 16,
                                            ),
                                            border: InputBorder.none,
                                            isDense: true,
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                        ),
                                      ),
                                      const Text(
                                        'kg',
                                        style: TextStyle(
                                          color: Color(0xFF006064),
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
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

                      const SizedBox(height: 18),

                      // Section 2: Account Credentials
                      const Text(
                        'Account Credentials',
                        style: TextStyle(
                          color: Color(0xFF0B1C30),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),

                      const Text(
                        'Email address',
                        style: TextStyle(
                          color: Color(0xFF0B1C30),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF4FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.mail_outline_rounded,
                              size: 22,
                              color: Color(0xFF006064),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                enabled: !_isLoading,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'Enter your email address',
                                  hintStyle: TextStyle(
                                    color: Color(0xFF808080),
                                    fontSize: 16,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        'Password',
                        style: TextStyle(
                          color: Color(0xFF0B1C30),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF4FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.lock_outline_rounded,
                              size: 22,
                              color: Color(0xFF006064),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                enabled: !_isLoading,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'Create a password',
                                  hintStyle: TextStyle(
                                    color: Color(0xFF808080),
                                    fontSize: 16,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: const Color(0xFF808080),
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              splashRadius: 20,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Must contain at least 8 characters',
                        style: TextStyle(
                          color: Color(0xFF6E797A),
                          fontSize: 11,
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        'Confirm Password',
                        style: TextStyle(
                          color: Color(0xFF0B1C30),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF4FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.lock_outline_rounded,
                              size: 22,
                              color: Color(0xFF006064),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                enabled: !_isLoading,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'Confirm your password',
                                  hintStyle: TextStyle(
                                    color: Color(0xFF808080),
                                    fontSize: 16,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: const Color(0xFF808080),
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                              splashRadius: 20,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Terms of Service checkbox
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Checkbox(
                            value: _termsAccepted,
                            activeColor: const Color(0xFF006064),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: _isLoading
                                ? null
                                : (v) => setState(
                                    () => _termsAccepted = v ?? false,
                                  ),
                          ),
                          const Expanded(
                            child: Text(
                              'I agree to the Terms of Service and Privacy Policy',
                              style: TextStyle(
                                color: Color(0xFF3E4949),
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Create Account Button (#0D7A7F, radius 25, height 50)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D7A7F),
                            disabledBackgroundColor: const Color(0xFF0D7A7F)
                                .withValues(alpha: 0.6),
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
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'Create Account  →',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Link to Login
                      Center(
                        child: GestureDetector(
                          onTap: _isLoading ? null : () => context.pop(),
                          child: const Text(
                            'Already have an account?  Login',
                            style: TextStyle(
                              color: Color(0xFF006064),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
