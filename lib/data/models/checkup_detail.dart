/// Mirrors Kotlin `data class CheckupDetail` in `data/model/CheckupDetail.kt`.
///
/// The Kotlin model uses `JsonObject?` for the JSONB columns; here we use
/// `Map<String, dynamic>?` (Dart's equivalent). All fields are nullable/optional
/// because Supabase may return nulls for columns the backend didn't populate.
class CheckupDetail {
  const CheckupDetail({
    required this.id,
    required this.userId,
    required this.status,
    required this.overallScore,
    required this.createdAt,
    this.overallCategory,
    this.confidence,
    this.uncertainty,
    this.completeness,
    this.symptoms,
    this.patientData,
    this.imageResult,
    this.symptomResult,
    this.patientResult,
    this.fusionResult,
    this.screening,
    this.uncertaintyData,
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

  // JSONB columns — parse on demand in the Result screen (item 6b).
  final Map<String, dynamic>? symptoms;
  final Map<String, dynamic>? patientData;
  final Map<String, dynamic>? imageResult;
  final Map<String, dynamic>? symptomResult;
  final Map<String, dynamic>? patientResult;
  final Map<String, dynamic>? fusionResult;
  final Map<String, dynamic>? screening;
  final Map<String, dynamic>? uncertaintyData;

  factory CheckupDetail.fromJson(Map<String, dynamic> json) {
    return CheckupDetail(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? '',
      status: json['status'] as String? ?? '',
      overallScore: _toDouble(json['overall_score']),
      createdAt: json['created_at'] as String? ?? '',
      overallCategory: json['overall_category'] as String?,
      confidence: _toDoubleOpt(json['confidence']),
      uncertainty: _toDoubleOpt(json['uncertainty']),
      completeness: _toDoubleOpt(json['completeness']),
      symptoms: _toMap(json['symptoms']),
      patientData: _toMap(json['patient_data']),
      imageResult: _toMap(json['image_result']),
      symptomResult: _toMap(json['symptom_result']),
      patientResult: _toMap(json['patient_result']),
      fusionResult: _toMap(json['fusion_result']),
      screening: _toMap(json['screening']),
      uncertaintyData: _toMap(json['uncertainty_data']),
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

Map<String, dynamic>? _toMap(dynamic v) {
  if (v == null) return null;
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return v.cast<String, dynamic>();
  return null;
}
