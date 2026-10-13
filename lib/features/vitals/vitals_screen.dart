import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../data/models/symptoms_vitals.dart';
import '../../state/checkup_draft_provider.dart';

/// Vitals screen replicating Android `VitalsActivity.kt` and `activity_vitals.xml`.
class VitalsScreen extends ConsumerStatefulWidget {
  const VitalsScreen({super.key});

  @override
  ConsumerState<VitalsScreen> createState() => _VitalsScreenState();
}

class _VitalsScreenState extends ConsumerState<VitalsScreen> {
  final _heartRateController = TextEditingController();
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _spo2Controller = TextEditingController();
  final _temperatureController = TextEditingController();

  String? _activityLevel;
  String? _tobacco;
  String? _alcohol;

  final List<String> _activityOptions = const ['Low', 'Moderate', 'High'];
  final List<String> _yesNoOptions = const ['No', 'Yes'];

  @override
  void initState() {
    super.initState();
    _loadFromDraft();
  }

  void _loadFromDraft() {
    final draft = ref.read(checkupDraftProvider).vitals;
    if (draft != null) {
      _heartRateController.text = draft.heartRate % 1 == 0
          ? draft.heartRate.toInt().toString()
          : draft.heartRate.toString();
      _systolicController.text = draft.systolicBp % 1 == 0
          ? draft.systolicBp.toInt().toString()
          : draft.systolicBp.toString();
      _diastolicController.text = draft.diastolicBp % 1 == 0
          ? draft.diastolicBp.toInt().toString()
          : draft.diastolicBp.toString();
      _spo2Controller.text = draft.spo2 % 1 == 0
          ? draft.spo2.toInt().toString()
          : draft.spo2.toString();
      _temperatureController.text = draft.temperature.toString();
      _activityLevel = draft.activityLevel == 0
          ? 'Low'
          : (draft.activityLevel == 1 ? 'Moderate' : 'High');
      _tobacco = draft.tobacco == 1 ? 'Yes' : 'No';
      _alcohol = draft.alcohol == 1 ? 'Yes' : 'No';
    }
  }

  @override
  void dispose() {
    _heartRateController.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    _spo2Controller.dispose();
    _temperatureController.dispose();
    super.dispose();
  }

  void _saveVitals() {
    final heartRateText = _heartRateController.text.trim();
    final systolicText = _systolicController.text.trim();
    final diastolicText = _diastolicController.text.trim();
    final spo2Text = _spo2Controller.text.trim();
    final temperatureText = _temperatureController.text.trim();
    final activity = _activityLevel?.trim() ?? '';
    final tobacco = _tobacco?.trim() ?? '';
    final alcohol = _alcohol?.trim() ?? '';

    // 1. Check all completed
    if (heartRateText.isEmpty ||
        systolicText.isEmpty ||
        diastolicText.isEmpty ||
        spo2Text.isEmpty ||
        temperatureText.isEmpty ||
        activity.isEmpty ||
        tobacco.isEmpty ||
        alcohol.isEmpty) {
      _showError('Please complete all vital information');
      return;
    }

    // 2. Parse numbers
    final heartRate = double.tryParse(heartRateText);
    final systolic = double.tryParse(systolicText);
    final diastolic = double.tryParse(diastolicText);
    final spo2 = double.tryParse(spo2Text);
    final temperature = double.tryParse(temperatureText);

    if (heartRate == null ||
        systolic == null ||
        diastolic == null ||
        spo2 == null ||
        temperature == null) {
      _showError('Please enter valid numeric values');
      return;
    }

    // 3. Heart rate 30..220
    if (heartRate < 30.0 || heartRate > 220.0) {
      _showError('Please enter a valid heart rate');
      return;
    }

    // 4. Systolic 70..250
    if (systolic < 70.0 || systolic > 250.0) {
      _showError('Please enter a valid systolic blood pressure');
      return;
    }

    // 5. Diastolic 40..150
    if (diastolic < 40.0 || diastolic > 150.0) {
      _showError('Please enter a valid diastolic blood pressure');
      return;
    }

    // 6. SpO2 70..100
    if (spo2 < 70.0 || spo2 > 100.0) {
      _showError('SpO₂ must be between 70% and 100%');
      return;
    }

    // 7. Temperature 30..45
    if (temperature < 30.0 || temperature > 45.0) {
      _showError('Please enter a valid body temperature between 30°C and 45°C');
      return;
    }

    final activityLevelCode = activity == 'Low'
        ? 0
        : (activity == 'Moderate' ? 1 : 2);
    final tobaccoCode = tobacco == 'Yes' ? 1 : 0;
    final alcoholCode = alcohol == 'Yes' ? 1 : 0;

    final vitals = VitalsPayload(
      heartRate: heartRate,
      systolicBp: systolic,
      diastolicBp: diastolic,
      spo2: spo2,
      temperature: temperature,
      activityLevel: activityLevelCode,
      tobacco: tobaccoCode,
      alcohol: alcoholCode,
    );

    ref.read(checkupDraftProvider.notifier).setVitals(vitals);

    context.push(AppRoutes.imageInput);
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
                    Icons.monitor_heart_outlined,
                    size: 32,
                    color: Color(0xFF006B6F),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Vital Information',
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
                'Record your current vital signs and lifestyle information.',
                style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 28),

              // Heart Rate
              _buildVitalInput(
                title: 'Heart Rate',
                controller: _heartRateController,
                hint: 'e.g. 72',
                unit: 'bpm',
              ),
              const SizedBox(height: 16),

              // Blood Pressure Row
              Row(
                children: [
                  Expanded(
                    child: _buildVitalInput(
                      title: 'Systolic BP',
                      controller: _systolicController,
                      hint: 'e.g. 120',
                      unit: 'mmHg',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildVitalInput(
                      title: 'Diastolic BP',
                      controller: _diastolicController,
                      hint: 'e.g. 80',
                      unit: 'mmHg',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Oxygen Saturation (SpO2)
              _buildVitalInput(
                title: 'Oxygen Saturation (SpO₂)',
                controller: _spo2Controller,
                hint: 'e.g. 98',
                unit: '%',
              ),
              const SizedBox(height: 16),

              // Body Temperature
              _buildVitalInput(
                title: 'Body Temperature',
                controller: _temperatureController,
                hint: 'e.g. 36.6',
                unit: '°C',
              ),
              const SizedBox(height: 20),

              // Activity Level Dropdown
              const Text(
                'Activity Level',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 5),
              _buildDropdown(
                value: _activityLevel,
                hint: 'Select activity level',
                items: _activityOptions,
                onChanged: (val) => setState(() => _activityLevel = val),
              ),
              const SizedBox(height: 16),

              // Lifestyle Information Section
              const Text(
                'Lifestyle Information',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 12),

              // Tobacco Use Dropdown
              const Text(
                'Tobacco Use',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 5),
              _buildDropdown(
                value: _tobacco,
                hint: 'Select tobacco use',
                items: _yesNoOptions,
                onChanged: (val) => setState(() => _tobacco = val),
              ),
              const SizedBox(height: 16),

              // Alcohol Consumption Dropdown
              const Text(
                'Alcohol Consumption',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 5),
              _buildDropdown(
                value: _alcohol,
                hint: 'Select alcohol consumption',
                items: _yesNoOptions,
                onChanged: (val) => setState(() => _alcohol = val),
              ),
              const SizedBox(height: 32),

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveVitals,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006B6F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Continue',
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

  Widget _buildVitalInput({
    required String title,
    required TextEditingController controller,
    required String hint,
    required String unit,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
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
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF111827),
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(
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
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF006064),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(
            hint,
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
          ),
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF6B7280)),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
