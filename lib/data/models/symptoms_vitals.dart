/// Mirrors Kotlin `data class Symptom` in `data/model/Symptom.kt`.
///
/// All numeric fields mirror the encodings from the migration plan Section 4
/// and VitalsActivity.kt / SymptomsActivity.kt. Field names exactly match
/// the JSON keys expected by the FastAPI backend.
class SymptomsPayload {
  const SymptomsPayload({
    required this.complaintType,
    required this.severity,
    required this.durationDays,
    required this.frequency,
    required this.progression,
    required this.site,
    required this.character,
    required this.trigger,
    required this.associatedSymptoms,
    required this.preSymptoms,
    required this.postSymptoms,
  });

  /// `general` | `skin` | `oral` | `wound`
  final String complaintType;

  /// 0–10 (sent as double; validated in SymptomsScreen)
  final double severity;

  /// ≥ 0
  final double durationDays;

  /// Rarely=1, Occasionally=2, Frequently=3, Constantly=4
  final double frequency;

  /// Better=0, Same=1, Worse=2
  final double progression;

  final String site;

  /// Sharp=1, Dull=2, Burning=3, Throbbing=4, Cramping=5, Pressure=6
  final double character;

  /// Count of triggers ticked (Movement, Food, Exercise, Stress, Light, None),
  /// sent as a double. The model was trained on this value — do not change it.
  final double trigger;

  final List<String> associatedSymptoms;
  final List<String> preSymptoms;
  final List<String> postSymptoms;

  /// Converts to the JSON map sent in the `symptoms` key of the API request.
  Map<String, dynamic> toJson() => {
        'complaint_type': complaintType,
        'severity': severity,
        'duration_days': durationDays,
        'frequency': frequency,
        'progression': progression,
        'site': site,
        'character': character,
        'trigger': trigger,
        'associated_symptoms': associatedSymptoms,
        'pre_symptoms': preSymptoms,
        'post_symptoms': postSymptoms,
      };
}

/// Vitals data, included inside the `patient` payload (merged with
/// [Profile.toPatientPayload]).
///
/// Numeric encodings (from VitalsActivity.kt and migration plan Section 4):
/// - activity_level: Low=0, Moderate=1, High=2
/// - tobacco / alcohol: Yes=1, No=0
class VitalsPayload {
  const VitalsPayload({
    required this.heartRate,
    required this.systolicBp,
    required this.diastolicBp,
    required this.spo2,
    required this.temperature,
    required this.activityLevel,
    required this.tobacco,
    required this.alcohol,
  });

  final double heartRate;    // 30–220
  final double systolicBp;   // 70–250
  final double diastolicBp;  // 40–150
  final double spo2;         // 70–100
  final double temperature;  // 30–45 °C
  final int activityLevel;   // 0=Low, 1=Moderate, 2=High
  final int tobacco;         // 0=No, 1=Yes
  final int alcohol;         // 0=No, 1=Yes

  /// Converts to the JSON map merged into the `patient` key.
  Map<String, dynamic> toJson() => {
        'heart_rate': heartRate,
        'systolic_bp': systolicBp,
        'diastolic_bp': diastolicBp,
        'spo2': spo2,
        'temperature': temperature,
        'activity_level': activityLevel,
        'tobacco': tobacco,
        'alcohol': alcohol,
      };
}
