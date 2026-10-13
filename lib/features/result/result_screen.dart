import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../data/models/checkup_detail.dart';
import '../../data/models/checkup_response.dart';
import '../../data/models/symptoms_vitals.dart';
import '../../data/repositories/checkup_repo.dart';
import '../../state/auth_provider.dart';
import '../assistant/assistant_screen.dart';
import '../shell/home_shell.dart';

/// Arguments bundle passed to [ResultScreen] via GoRouter `extra`.
class ResultScreenArgs {
  const ResultScreenArgs({
    this.response,
    this.checkupId,
    this.vitals,
    this.symptoms,
  });

  final CheckupResponse? response;
  final String? checkupId;
  final Map<String, dynamic>? vitals;
  final SymptomsPayload? symptoms;
}

/// Result screen replicating Android `ResultActivity.kt` and `activity_result.xml`.
///
/// Supports both:
/// - Live submission response (passed directly via [response])
/// - Historical checkup detail (fetched by [checkupId] from Supabase)
class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({
    super.key,
    this.response,
    this.checkupId,
    this.vitals,
    this.symptoms,
  });

  final CheckupResponse? response;
  final String? checkupId;
  final Map<String, dynamic>? vitals;
  final SymptomsPayload? symptoms;

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  CheckupResponse? _response;
  Map<String, dynamic>? _vitals;
  Map<String, dynamic>? _symptomsMap;
  bool _isHistorical = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() {
    if (widget.checkupId != null && widget.checkupId!.isNotEmpty) {
      _isHistorical = true;
      _loadHistorical(widget.checkupId!);
    } else if (widget.response != null) {
      _isHistorical = false;
      _response = widget.response;
      _vitals = widget.vitals;
      _symptomsMap = widget.symptoms?.toJson();
    } else {
      _errorMessage = 'Checkup result not available';
    }
  }

  Future<void> _loadHistorical(String checkupId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(checkupRepositoryProvider);
      final userId = ref.read(currentUserProvider)?.id;

      final CheckupDetail? detail = await repository.getCheckupDetail(
        checkupId: checkupId,
        userId: userId,
      );

      if (detail == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Checkup result not available';
          });
        }
        return;
      }

      final response = CheckupResponse.fromDetail(detail);

      final vitals = <String, dynamic>{};
      if (detail.patientData != null) {
        for (final key in [
          'heart_rate',
          'systolic_bp',
          'diastolic_bp',
          'spo2',
          'temperature',
        ]) {
          if (detail.patientData![key] != null) {
            vitals[key] = detail.patientData![key];
          }
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _response = response;
          _vitals = vitals;
          _symptomsMap = detail.symptoms;
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

  // ── Formatting helpers mirroring ResultActivity.kt ─────────────────────────

  String _formatOverallStatus(String status) {
    if (status.isEmpty) return 'Screening completed';
    final spaced = status.replaceAll('_', ' ').toLowerCase();
    return spaced[0].toUpperCase() + spaced.substring(1);
  }

  String _formatSymptomFinding(String value) {
    if (value.isEmpty) return 'Not available';
    final spaced = value.replaceAll('_', ' ');
    return spaced[0].toUpperCase() + spaced.substring(1);
  }

  String _formatLabel(String value) {
    if (value.isEmpty) return 'Not available';
    final spaced = value.replaceAll('_', ' ');
    return spaced[0].toUpperCase() + spaced.substring(1);
  }

  String _formatPercentage(double? value) {
    if (value == null) return '—';
    return '${(value * 100).toStringAsFixed(0)}%';
  }

  String _formatDecimal(double value) => value.toStringAsFixed(2);

  String _formatVital(dynamic value, String unit) {
    if (value == null) return '—';
    return '$value $unit';
  }

  String _formatBloodPressure(dynamic systolic, dynamic diastolic) {
    if (systolic == null || diastolic == null) return '—';
    return '$systolic/$diastolic mmHg';
  }

  String _formatProbabilities(Map<String, double> probabilities) {
    if (probabilities.isEmpty) {
      return 'Class probabilities are not available for this recorded result.';
    }
    final entries = probabilities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries
        .map((e) => '${_formatLabel(e.key)}: ${_formatPercentage(e.value)}')
        .join('\n');
  }

  String _buildSymptomDetails() {
    final s = _symptomsMap;
    if (s == null || s.isEmpty) {
      return 'No symptom details available.';
    }

    final complaint = s['complaint_type']?.toString() ?? '';
    final severity = s['severity'];
    final duration = s['duration_days'];
    final frequency = s['frequency'];
    final progression = s['progression'];
    final site = s['site']?.toString() ?? '';

    return [
      'Complaint: ${complaint.isNotEmpty ? _formatLabel(complaint) : "Not available"}',
      'Severity: ${severity ?? "—"}',
      'Duration: ${duration ?? "—"} days',
      'Frequency: ${frequency ?? "—"}',
      'Progression: ${progression ?? "—"}',
      'Site: ${site.isNotEmpty ? _formatLabel(site) : "Not available"}',
    ].join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5FAFA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF17202A)),
          onPressed: () {
            if (_isHistorical) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF006B6F)),
              )
            : _errorMessage != null && _response == null
            ? _buildErrorView()
            : _buildContent(_response!),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Color(0xFFA32222)),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Unable to load checkup result',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF17202A),
              ),
            ),
            const SizedBox(height: 24),
            if (widget.checkupId != null)
              ElevatedButton(
                onPressed: () => _loadHistorical(widget.checkupId!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006B6F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Retry'),
              ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                if (_isHistorical) {
                  context.pop();
                } else {
                  context.go(AppRoutes.home);
                }
              },
              child: Text(
                _isHistorical ? 'Back to History' : 'Back to Home',
                style: const TextStyle(color: Color(0xFF006B6F)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(CheckupResponse result) {
    final screening = result.screening ?? const ScreeningInterpretation();
    final vitals = _vitals ?? const {};
    final imageResult = result.imageResult;

    final patientExplanation = screening.modelExplanations.firstWhere(
      (e) => e.startsWith('Patient-risk model:'),
      orElse: () => 'The patient-risk model was evaluated separately and contributed to the screening.',
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Title & Subtitle ─────────────────────────────────────
          const Text(
            'Your Health Screening',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Color(0xFF155E63),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'A summary of your symptoms, vital signs and AI-assisted screening results.',
            style: TextStyle(fontSize: 16, color: Color(0xFF607078)),
          ),
          const SizedBox(height: 28),

          // ── Overall Screening ───────────────────────────────────────────
          const Text(
            'OVERALL SCREENING',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF155E63),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _formatOverallStatus(
              screening.overallStatus.isNotEmpty
                  ? screening.overallStatus
                  : (screening.mainConcern.isNotEmpty
                        ? screening.mainConcern
                        : 'Screening completed'),
            ),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF17202A),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFE4F3F1),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(18),
            child: Text(
              screening.screeningSummary.isNotEmpty
                  ? screening.screeningSummary
                  : 'AI-assisted health screening completed.',
              style: const TextStyle(
                color: Color(0xFF155E63),
                fontSize: 17,
                height: 1.4,
              ),
            ),
          ),
          if (screening.triage.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(18),
              child: Text(
                screening.triage,
                style: const TextStyle(
                  color: Color(0xFF17202A),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          const SizedBox(height: 30),

          // ── What We Found ───────────────────────────────────────────────
          const Text(
            'WHAT WE FOUND',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF155E63),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _formatSymptomFinding(
              result.symptomResult?.className ?? 'Not available',
            ),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF17202A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'AI confidence: ${_formatPercentage(result.symptomResult?.confidence)}',
            style: const TextStyle(fontSize: 15, color: Color(0xFF607078)),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(18),
            child: Text(
              _buildSymptomDetails(),
              style: const TextStyle(
                color: Color(0xFF17202A),
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ),

          // ── Warning Signs (Red Flags) ───────────────────────────────────
          if (screening.redFlags.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F0),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'WARNING SIGNS',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFA32222),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'The following warning signs were identified from the information provided:\n\n'
                    '${screening.redFlags.map((flag) => '• $flag').join('\n')}\n\n'
                    'Please seek prompt medical attention based on these warning signs.',
                    style: const TextStyle(
                      color: Color(0xFF5F2020),
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 30),

          // ── Recorded Vitals ─────────────────────────────────────────────
          const Text(
            'RECORDED VITALS',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF155E63),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildVitalRow(
                  'Heart Rate',
                  _formatVital(vitals['heart_rate'], 'bpm'),
                ),
                const SizedBox(height: 15),
                _buildVitalRow(
                  'Blood Pressure',
                  _formatBloodPressure(
                    vitals['systolic_bp'],
                    vitals['diastolic_bp'],
                  ),
                ),
                const SizedBox(height: 15),
                _buildVitalRow('SpO₂', _formatVital(vitals['spo2'], '%')),
                const SizedBox(height: 15),
                _buildVitalRow(
                  'Temperature',
                  _formatVital(vitals['temperature'], '°C'),
                ),
                if (screening.vitalsInterpretation.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text(
                    screening.vitalsInterpretation,
                    style: const TextStyle(
                      color: Color(0xFF155E63),
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 30),

          // ── Cardiovascular Risk Screening ───────────────────────────────
          const Text(
            'CARDIOVASCULAR RISK SCREENING',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF155E63),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.patientResult?.className ?? 'Not available',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF17202A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'AI confidence: ${_formatPercentage(result.patientResult?.confidence)}',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF607078),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  patientExplanation,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF46545C),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          // ── Image Screening (if image analysis present) ─────────────────
          if (imageResult?.prediction != null) ...[
            const SizedBox(height: 30),
            const Text(
              'IMAGE SCREENING',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF155E63),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _formatLabel(imageResult?.type ?? 'Image'),
              style: const TextStyle(fontSize: 15, color: Color(0xFF607078)),
            ),
            const SizedBox(height: 4),
            Text(
              _formatLabel(
                imageResult?.prediction?.className ?? 'Not available',
              ),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF17202A),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'AI confidence: ${_formatPercentage(imageResult?.prediction?.confidence)}',
              style: const TextStyle(fontSize: 15, color: Color(0xFF607078)),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(18),
              child: Text(
                _formatProbabilities(
                  imageResult?.prediction?.probabilities ?? const {},
                ),
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF17202A),
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(18),
              child: Text(
                'The image model classified the uploaded image as '
                '${_formatLabel(imageResult?.prediction?.className ?? "not available")}. '
                'The confidence shown above represents the model\'s classification confidence.',
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF46545C),
                  height: 1.4,
                ),
              ),
            ),
          ],
          const SizedBox(height: 30),

          // ── How the AI Reached This Result ──────────────────────────────
          const Text(
            'HOW THE AI REACHED THIS RESULT',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF155E63),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(18),
            child: Text(
              screening.modelExplanations.isNotEmpty
                  ? screening.modelExplanations.join('\n\n')
                  : 'The recorded AI outputs were used to generate this screening.',
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF46545C),
                height: 1.5,
              ),
            ),
          ),
          if (screening.overallExplanation.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFE4F3F1),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(18),
              child: Text(
                screening.overallExplanation,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF155E63),
                  height: 1.4,
                ),
              ),
            ),
          ],
          const SizedBox(height: 30),

          // ── Assessment Quality ──────────────────────────────────────────
          const Text(
            'ASSESSMENT QUALITY',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF155E63),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildVitalRow(
                  'Required input completeness',
                  _formatPercentage(result.uncertainty?.completeness),
                ),
                const SizedBox(height: 15),
                _buildVitalRow(
                  'Model uncertainty',
                  _formatDecimal(result.uncertainty?.uncertainty ?? 0.0),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // ── What To Do Next ─────────────────────────────────────────────
          const Text(
            'WHAT TO DO NEXT',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF155E63),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(18),
            child: Text(
              screening.nextSteps.isNotEmpty ? screening.nextSteps : 'Review the screening information and consult a healthcare provider.',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF17202A),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Disclaimer ──────────────────────────────────────────────────
          const Text(
            'Health360 AI provides AI-assisted screening information for informational '
            'purposes only. It is not a medical diagnosis or a replacement for professional '
            'medical advice.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF607078),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // ── Action Buttons ──────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                final id = widget.checkupId;
                ref.read(assistantCheckupIdProvider.notifier).state = id;
                ref.read(activeTabProvider.notifier).state = 2;
                context.go(AppRoutes.home);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF087C83),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Ask Health360 AI',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                if (_isHistorical) {
                  context.pop();
                } else {
                  context.go(AppRoutes.home);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D7A7F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 0,
              ),
              child: Text(
                _isHistorical ? 'Back to History' : 'Back to Home',
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
    );
  }

  Widget _buildVitalRow(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 15, color: Color(0xFF607078)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF17202A),
          ),
        ),
      ],
    );
  }
}
