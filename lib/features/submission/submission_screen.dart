import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/api_client.dart';
import '../../data/repositories/checkup_repo.dart';
import '../../state/checkup_draft_provider.dart';
import '../result/result_screen.dart';

/// Submission review and execution screen for Item 6a.
///
/// Provides a dedicated review screen that submits either:
/// - without image via `POST /api/v1/checkups/analyze`
/// - with image via `POST /api/v1/checkups/analyze-image` (multipart)
class SubmissionScreen extends ConsumerStatefulWidget {
  const SubmissionScreen({super.key});

  @override
  ConsumerState<SubmissionScreen> createState() => _SubmissionScreenState();
}

class _SubmissionScreenState extends ConsumerState<SubmissionScreen> {
  bool _isSubmitting = false;
  String? _errorMessage;

  Future<void> _submit() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final draft = ref.read(checkupDraftProvider);
      final repo = ref.read(checkupRepositoryProvider);

      final response = await repo.submitCheckup(draft);

      final vitals = draft.vitals?.toJson();
      final symptoms = draft.symptoms;

      // Successful submission: clear the draft
      ref.read(checkupDraftProvider.notifier).clear();

      if (mounted) {
        setState(() => _isSubmitting = false);
        context.go(
          AppRoutes.result,
          extra: ResultScreenArgs(
            response: response,
            vitals: vitals,
            symptoms: symptoms,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e is ApiException
              ? e.message
              : e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(checkupDraftProvider);
    final patient = draft.patient;
    final symptoms = draft.symptoms;
    final vitals = draft.vitals;
    final hasImage = draft.hasImage;

    final isDraftReady = patient != null && symptoms != null && vitals != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5FAFA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF17202A)),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Submit Checkup',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF155E63),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Review your details before AI-assisted screening analysis.',
                style: TextStyle(fontSize: 15, color: Color(0xFF607078)),
              ),
              const SizedBox(height: 24),

              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFA32222)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Color(0xFF5F2020),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ── Patient Info Summary ────────────────────────────────────
              _buildSectionCard(
                title: 'Patient',
                content: patient != null
                    ? '${patient.fullName} (${patient.sex}, ${patient.dateOfBirth})\n'
                          'Height: ${patient.heightCm} cm, Weight: ${patient.weightKg} kg'
                    : 'Not entered',
              ),
              const SizedBox(height: 16),

              // ── Symptoms Summary ────────────────────────────────────────
              _buildSectionCard(
                title: 'Symptoms',
                content: symptoms != null
                    ? 'Complaint: ${symptoms.complaintType}\n'
                          'Site: ${symptoms.site}\n'
                          'Severity: ${symptoms.severity} / 10\n'
                          'Duration: ${symptoms.durationDays} days'
                    : 'Not entered',
              ),
              const SizedBox(height: 16),

              // ── Vitals Summary ──────────────────────────────────────────
              _buildSectionCard(
                title: 'Recorded Vitals',
                content: vitals != null
                    ? 'Heart Rate: ${vitals.heartRate} bpm\n'
                          'Blood Pressure: ${vitals.systolicBp}/${vitals.diastolicBp} mmHg\n'
                          'SpO₂: ${vitals.spo2}%\n'
                          'Temperature: ${vitals.temperature} °C'
                    : 'Not entered',
              ),
              const SizedBox(height: 16),

              // ── Image Summary ───────────────────────────────────────────
              _buildSectionCard(
                title: 'Image Analysis',
                content: hasImage
                    ? 'Attached (${draft.imageType?.toUpperCase()})\n'
                          'Path: ${draft.imagePath != null ? File(draft.imagePath!).path.split(Platform.pathSeparator).last : ""}'
                    : 'Skipped (analysis will proceed without image)',
              ),
              const SizedBox(height: 32),

              // ── Submit Button ───────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (!isDraftReady || _isSubmitting) ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006B6F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          _errorMessage != null
                              ? 'Retry Submission'
                              : 'Submit Checkup',
                          style: const TextStyle(
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

  Widget _buildSectionCard({required String title, required String content}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF155E63),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF374151),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
