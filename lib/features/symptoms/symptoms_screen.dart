// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../data/models/symptoms_vitals.dart';
import '../../state/checkup_draft_provider.dart';

/// Symptoms screen replicating Android `SymptomsActivity.kt` and `activity_symptoms.xml`.
class SymptomsScreen extends ConsumerStatefulWidget {
  const SymptomsScreen({super.key});

  @override
  ConsumerState<SymptomsScreen> createState() => _SymptomsScreenState();
}

class _SymptomsScreenState extends ConsumerState<SymptomsScreen> {
  final _severityController = TextEditingController();
  final _durationController = TextEditingController();

  double? _frequency;
  double? _progression;
  String? _complaintType;
  String? _selectedSite;
  double? _character;

  final Set<String> _selectedTriggers = {};
  final Set<String> _associatedSymptoms = {};
  final Set<String> _preSymptoms = {};
  final Set<String> _postSymptoms = {};

  @override
  void initState() {
    super.initState();
    _loadFromDraft();
  }

  void _loadFromDraft() {
    final draft = ref.read(checkupDraftProvider).symptoms;
    if (draft != null) {
      _severityController.text = draft.severity % 1 == 0
          ? draft.severity.toInt().toString()
          : draft.severity.toString();
      _durationController.text = draft.durationDays % 1 == 0
          ? draft.durationDays.toInt().toString()
          : draft.durationDays.toString();
      _frequency = draft.frequency;
      _progression = draft.progression;
      _complaintType = draft.complaintType;
      _selectedSite = draft.site;
      _character = draft.character;
      _associatedSymptoms.addAll(draft.associatedSymptoms);
      _preSymptoms.addAll(draft.preSymptoms);
      _postSymptoms.addAll(draft.postSymptoms);
    }
  }

  @override
  void dispose() {
    _severityController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _onComplaintTypeChanged(String type) {
    setState(() {
      _complaintType = type;
      _selectedSite = null; // Clear previous site selection
    });
  }

  void _saveSymptoms() {
    final severity = double.tryParse(_severityController.text.trim());
    final duration = double.tryParse(_durationController.text.trim());

    if (severity == null || severity < 0.0 || severity > 10.0) {
      _showError('Enter a severity between 0 and 10');
      return;
    }

    if (duration == null || duration < 0) {
      _showError('Enter a valid duration');
      return;
    }

    if (_complaintType == null) {
      _showError('Select the type of concern');
      return;
    }

    if (_frequency == null) {
      _showError('Select how often you experience the symptom');
      return;
    }

    if (_progression == null) {
      _showError('Select how the symptom is changing');
      return;
    }

    if (_selectedSite == null) {
      _showError('Select the location of the concern');
      return;
    }

    if (_character == null) {
      _showError('Select what the symptom feels like');
      return;
    }

    final trigger = _selectedTriggers.length.toDouble();

    final payload = SymptomsPayload(
      complaintType: _complaintType!,
      severity: severity,
      durationDays: duration,
      frequency: _frequency!,
      progression: _progression!,
      site: _selectedSite!,
      character: _character!,
      trigger: trigger,
      associatedSymptoms: _associatedSymptoms.toList(),
      preSymptoms: _preSymptoms.toList(),
      postSymptoms: _postSymptoms.toList(),
    );

    ref.read(checkupDraftProvider.notifier).setSymptoms(payload);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Symptoms saved'),
        duration: Duration(seconds: 2),
      ),
    );

    context.push(AppRoutes.vitals);
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
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Title & Icon ─────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.medical_services_outlined,
                    size: 32,
                    color: Color(0xFF006B6F),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Symptoms',
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Tell us about your current symptoms',
                style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 28),

              // ── Question 1: Severity ────────────────────────────────────
              const Text(
                'How severe is your symptom?',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF4FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _severityController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  maxLength: 4,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF111827),
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Rate from 0 to 10',
                    hintStyle: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 15,
                    ),
                    counterText: '',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Question 2: Duration ────────────────────────────────────
              const Text(
                'How long have you had it?',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF4FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF111827),
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Number of days',
                    hintStyle: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Question 3: Frequency ───────────────────────────────────
              const Text(
                'How often are you experiencing it?',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              _buildRadioGroup<double>(
                selectedValue: _frequency,
                options: const [
                  _Option(label: 'Rarely', value: 1.0),
                  _Option(label: 'Occasionally', value: 2.0),
                  _Option(label: 'Frequently', value: 3.0),
                  _Option(label: 'Almost constantly', value: 4.0),
                ],
                onChanged: (val) => setState(() => _frequency = val),
              ),
              const SizedBox(height: 20),

              // ── Question 4: Progression ─────────────────────────────────
              const Text(
                'How is the symptom changing?',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              _buildRadioGroup<double>(
                selectedValue: _progression,
                options: const [
                  _Option(label: 'Getting better', value: 0.0),
                  _Option(label: 'Staying the same', value: 1.0),
                  _Option(label: 'Getting worse', value: 2.0),
                ],
                onChanged: (val) => setState(() => _progression = val),
              ),
              const SizedBox(height: 20),

              // ── Question 5: Complaint Type ──────────────────────────────
              const Text(
                'What type of concern are you describing?',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              _buildRadioGroup<String>(
                selectedValue: _complaintType,
                options: const [
                  _Option(label: 'General symptom', value: 'general'),
                  _Option(label: 'Skin concern', value: 'skin'),
                  _Option(label: 'Oral / Dental concern', value: 'oral'),
                  _Option(label: 'Wound concern', value: 'wound'),
                ],
                onChanged: (val) {
                  if (val != null) _onComplaintTypeChanged(val);
                },
              ),
              const SizedBox(height: 20),

              // ── Question: Dynamic Site Group ────────────────────────────
              if (_complaintType != null) ...[
                Text(
                  _getSiteQuestionTitle(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                _buildRadioGroup<String>(
                  selectedValue: _selectedSite,
                  options: _getSiteOptions(),
                  onChanged: (val) => setState(() => _selectedSite = val),
                ),
                const SizedBox(height: 20),
              ],

              // ── Question 6: Character ───────────────────────────────────
              const Text(
                'What does the symptom feel like?',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              _buildRadioGroup<double>(
                selectedValue: _character,
                options: const [
                  _Option(label: 'Sharp', value: 1.0),
                  _Option(label: 'Dull', value: 2.0),
                  _Option(label: 'Burning', value: 3.0),
                  _Option(label: 'Throbbing', value: 4.0),
                  _Option(label: 'Cramping', value: 5.0),
                  _Option(label: 'Pressure', value: 6.0),
                ],
                onChanged: (val) => setState(() => _character = val),
              ),
              const SizedBox(height: 20),

              // ── Question 7: Triggers ────────────────────────────────────
              const Text(
                'Does anything make it worse or bring it on?',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Select all that apply',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 8),
              _buildCheckboxList(
                options: const [
                  'Movement',
                  'Food',
                  'Exercise',
                  'Stress',
                  'Light',
                  'Nothing specific',
                ],
                selectedSet: _selectedTriggers,
              ),
              const SizedBox(height: 24),

              // ── Question 8: Associated Symptoms ─────────────────────────
              const Text(
                'Associated symptoms',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              _buildCheckboxList(
                options: const [
                  'Nausea',
                  'Fatigue',
                  'Dizziness',
                  'Light sensitivity',
                  'Headache',
                ],
                selectedSet: _associatedSymptoms,
              ),
              const SizedBox(height: 24),

              // ── Question 9: Pre Symptoms ────────────────────────────────
              const Text(
                'Symptoms before it',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              _buildCheckboxList(
                options: const ['Fatigue', 'Dizziness', 'Nausea'],
                selectedSet: _preSymptoms,
              ),
              const SizedBox(height: 24),

              // ── Question 10: Post Symptoms ──────────────────────────────
              const Text(
                'Symptoms after it',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              _buildCheckboxList(
                options: const ['Fatigue', 'Dizziness', 'Nausea'],
                selectedSet: _postSymptoms,
              ),
              const SizedBox(height: 32),

              // ── Save and Continue Button ────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveSymptoms,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006B6F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Save and Continue',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

  String _getSiteQuestionTitle() {
    switch (_complaintType) {
      case 'general':
        return 'Where are you experiencing the symptom?';
      case 'skin':
        return 'Where is the skin concern?';
      case 'oral':
        return 'Where is the oral concern?';
      case 'wound':
        return 'Where is the wound?';
      default:
        return 'Where are you experiencing the symptom?';
    }
  }

  List<_Option<String>> _getSiteOptions() {
    switch (_complaintType) {
      case 'general':
        return const [
          _Option(label: 'Head', value: 'head'),
          _Option(label: 'Chest', value: 'chest'),
          _Option(label: 'Abdomen', value: 'abdomen'),
          _Option(label: 'Back', value: 'back'),
          _Option(label: 'Arms', value: 'arms'),
          _Option(label: 'Legs', value: 'legs'),
          _Option(label: 'Other', value: 'other'),
        ];
      case 'skin':
        return const [
          _Option(label: 'Face', value: 'face'),
          _Option(label: 'Scalp', value: 'scalp'),
          _Option(label: 'Neck', value: 'neck'),
          _Option(label: 'Chest', value: 'chest'),
          _Option(label: 'Back', value: 'back'),
          _Option(label: 'Arms', value: 'arms'),
          _Option(label: 'Hands', value: 'hands'),
          _Option(label: 'Legs', value: 'legs'),
          _Option(label: 'Feet', value: 'feet'),
          _Option(label: 'Other', value: 'other'),
        ];
      case 'oral':
        return const [
          _Option(label: 'Teeth', value: 'teeth'),
          _Option(label: 'Gums', value: 'gums'),
          _Option(label: 'Tongue', value: 'tongue'),
          _Option(label: 'Inner cheek', value: 'inner_cheek'),
          _Option(label: 'Lips', value: 'lips'),
          _Option(label: 'Roof of mouth', value: 'roof_of_mouth'),
          _Option(label: 'Jaw', value: 'jaw'),
          _Option(label: 'Throat', value: 'throat'),
          _Option(label: 'Multiple areas', value: 'multiple_areas'),
          _Option(label: 'Other', value: 'other'),
        ];
      case 'wound':
        return const [
          _Option(label: 'Head', value: 'head'),
          _Option(label: 'Arm', value: 'arm'),
          _Option(label: 'Hand', value: 'hand'),
          _Option(label: 'Chest', value: 'chest'),
          _Option(label: 'Abdomen', value: 'abdomen'),
          _Option(label: 'Back', value: 'back'),
          _Option(label: 'Leg', value: 'leg'),
          _Option(label: 'Foot', value: 'foot'),
          _Option(label: 'Other', value: 'other'),
        ];
      default:
        return const [];
    }
  }

  Widget _buildRadioGroup<T>({
    required T? selectedValue,
    required List<_Option<T>> options,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: options.map((opt) {
          final isSelected = selectedValue == opt.value;
          return InkWell(
            onTap: () => onChanged(opt.value),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Radio<T>(
                    value: opt.value,
                    groupValue: selectedValue,
                    activeColor: const Color(0xFF006B6F),
                    onChanged: onChanged,
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    opt.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: const Color(0xFF111827),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCheckboxList({
    required List<String> options,
    required Set<String> selectedSet,
  }) {
    return Column(
      children: options.map((label) {
        final isChecked = selectedSet.contains(label);
        return Container(
          height: 52,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF4FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: InkWell(
            onTap: () {
              setState(() {
                if (isChecked) {
                  selectedSet.remove(label);
                } else {
                  selectedSet.add(label);
                }
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                Checkbox(
                  value: isChecked,
                  activeColor: const Color(0xFF006B6F),
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        selectedSet.add(label);
                      } else {
                        selectedSet.remove(label);
                      }
                    });
                  },
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _Option<T> {
  const _Option({required this.label, required this.value});
  final String label;
  final T value;
}
