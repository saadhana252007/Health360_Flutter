/// Mirrors Kotlin `data class CheckupSummary` + nested types from
/// `data/model/CheckupSummary.kt`.
///
/// Read from Supabase `checkups` table. The backend writes all rows;
/// the Flutter client only reads.
class CheckupSummary {
  const CheckupSummary({
    required this.id,
    required this.userId,
    required this.status,
    required this.overallScore,
    required this.createdAt,
    this.overallCategory,
    this.confidence,
    this.uncertainty,
    this.completeness,
    this.screening,
    this.imageResult,
    this.symptomResult,
    this.patientResult,
  });

  final String id;
  final String userId;
  final String status;
  final double overallScore;
  final String createdAt; // ISO timestamp
  final String? overallCategory;
  final double? confidence;
  final double? uncertainty;
  final double? completeness;
  final ScreeningSummary? screening;
  final ImageHistoryResult? imageResult;
  final ModelHistoryResult? symptomResult;
  final ModelHistoryResult? patientResult;

  factory CheckupSummary.fromJson(Map<String, dynamic> json) {
    return CheckupSummary(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? '',
      status: json['status'] as String? ?? '',
      overallScore: _toDouble(json['overall_score']),
      createdAt: json['created_at'] as String? ?? '',
      overallCategory: json['overall_category'] as String?,
      confidence: _toDoubleOpt(json['confidence']),
      uncertainty: _toDoubleOpt(json['uncertainty']),
      completeness: _toDoubleOpt(json['completeness']),
      screening: json['screening'] != null
          ? ScreeningSummary.fromJson(
              (json['screening'] as Map<String, dynamic>),
            )
          : null,
      imageResult: json['image_result'] != null
          ? ImageHistoryResult.fromJson(
              json['image_result'] as Map<String, dynamic>,
            )
          : null,
      symptomResult: json['symptom_result'] != null
          ? ModelHistoryResult.fromJson(
              json['symptom_result'] as Map<String, dynamic>,
            )
          : null,
      patientResult: json['patient_result'] != null
          ? ModelHistoryResult.fromJson(
              json['patient_result'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class ScreeningSummary {
  const ScreeningSummary({
    this.mainConcern,
    this.overallStatus,
    this.screeningSummary,
    this.triage,
    this.redFlags = const [],
    this.vitalsInterpretation,
    this.nextSteps,
  });

  final String? mainConcern;
  final String? overallStatus;
  final String? screeningSummary;
  final String? triage;
  final List<String> redFlags;
  final String? vitalsInterpretation;
  final String? nextSteps;

  factory ScreeningSummary.fromJson(Map<String, dynamic> json) {
    return ScreeningSummary(
      mainConcern: json['main_concern'] as String?,
      overallStatus: json['overall_status'] as String?,
      screeningSummary: json['screening_summary'] as String?,
      triage: json['triage'] as String?,
      redFlags: _toStringList(json['red_flags']),
      vitalsInterpretation: json['vitals_interpretation'] as String?,
      nextSteps: json['next_steps'] as String?,
    );
  }
}

class ImageHistoryResult {
  const ImageHistoryResult({this.type, this.prediction});

  final String? type;
  final ImageHistoryPrediction? prediction;

  factory ImageHistoryResult.fromJson(Map<String, dynamic> json) {
    return ImageHistoryResult(
      type: json['type'] as String?,
      prediction: json['prediction'] != null
          ? ImageHistoryPrediction.fromJson(
              json['prediction'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class ImageHistoryPrediction {
  const ImageHistoryPrediction({this.className, this.confidence});

  final String? className;
  final double? confidence;

  factory ImageHistoryPrediction.fromJson(Map<String, dynamic> json) {
    return ImageHistoryPrediction(
      className: json['class_name'] as String?,
      confidence: _toDoubleOpt(json['confidence']),
    );
  }
}

class ModelHistoryResult {
  const ModelHistoryResult({this.className, this.confidence});

  final String? className;
  final double? confidence;

  factory ModelHistoryResult.fromJson(Map<String, dynamic> json) {
    return ModelHistoryResult(
      className: json['class_name'] as String?,
      confidence: _toDoubleOpt(json['confidence']),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

double? _toDoubleOpt(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString());
}

List<String> _toStringList(dynamic v) {
  if (v == null) return const [];
  if (v is List) return v.map((e) => e.toString()).toList();
  return const [];
}
