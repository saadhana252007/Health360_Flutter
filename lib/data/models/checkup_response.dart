import 'checkup_detail.dart';

// Mirrors the full API response types from `data/remote/ApiModels.kt`.
// The Flutter client parses the response from:
//   POST /api/v1/checkups/analyze
//   POST /api/v1/checkups/analyze-image
//
// Every field is nullable — the API contract says "every field can be
// null/missing, so parse defensively" (migration plan Section 4).

class CheckupResponse {
  const CheckupResponse({
    required this.status,
    required this.assessment,
    this.screening,
    this.imageResult,
    this.symptomResult,
    this.patientResult,
    this.uncertainty,
  });

  final String status;
  final Assessment assessment;
  final ScreeningInterpretation? screening;
  final ImageResult? imageResult;
  final ModelResult? symptomResult;
  final ModelResult? patientResult;
  final UncertaintyResult? uncertainty;

  factory CheckupResponse.fromJson(Map<String, dynamic> json) {
    return CheckupResponse(
      status: json['status'] as String? ?? '',
      assessment: json['assessment'] != null
          ? Assessment.fromJson(json['assessment'] as Map<String, dynamic>)
          : const Assessment(),
      screening: json['screening'] != null
          ? ScreeningInterpretation.fromJson(
              json['screening'] as Map<String, dynamic>,
            )
          : null,
      imageResult: json['image_result'] != null
          ? ImageResult.fromJson(json['image_result'] as Map<String, dynamic>)
          : null,
      symptomResult: json['symptom_result'] != null
          ? ModelResult.fromJson(json['symptom_result'] as Map<String, dynamic>)
          : null,
      patientResult: json['patient_result'] != null
          ? ModelResult.fromJson(json['patient_result'] as Map<String, dynamic>)
          : null,
      uncertainty: json['uncertainty'] != null
          ? UncertaintyResult.fromJson(
              json['uncertainty'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  /// Builds a [CheckupResponse] from a stored Supabase [CheckupDetail] row.
  ///
  /// Replicates `buildCheckupResponse` in Android `ResultActivity.kt`.
  factory CheckupResponse.fromDetail(CheckupDetail detail) {
    final imageResult = detail.imageResult != null
        ? ImageResult.fromJson(detail.imageResult!)
        : null;

    final symptomResult = detail.symptomResult != null
        ? ModelResult.fromJson(detail.symptomResult!)
        : const ModelResult();

    final patientResult = detail.patientResult != null
        ? ModelResult.fromJson(detail.patientResult!)
        : const ModelResult();

    final uncertainty = detail.uncertaintyData != null
        ? UncertaintyResult.fromJson(detail.uncertaintyData!)
        : UncertaintyResult(
            confidence: detail.confidence ?? detail.overallScore,
            uncertainty: detail.uncertainty ?? 0.0,
            completeness: detail.completeness ?? 0.0,
          );

    final screening = detail.screening != null
        ? ScreeningInterpretation.fromJson(detail.screening!)
        : _buildHistoricalScreening(
            detail,
            symptomResult,
            patientResult,
            imageResult,
          );

    final assessment = Assessment(
      imageType: imageResult?.type,
      finding: imageResult?.prediction?.className,
      confidence: imageResult?.prediction?.confidence,
      probabilities: imageResult?.prediction?.probabilities ?? const {},
    );

    return CheckupResponse(
      status: detail.status,
      assessment: assessment,
      screening: screening,
      imageResult: imageResult,
      symptomResult: symptomResult,
      patientResult: patientResult,
      uncertainty: uncertainty,
    );
  }
}

ScreeningInterpretation _buildHistoricalScreening(
  CheckupDetail detail,
  ModelResult symptomResult,
  ModelResult patientResult,
  ImageResult? imageResult,
) {
  final explanations = <String>[];

  if (symptomResult.className != null) {
    final conf = symptomResult.confidence != null
        ? '${(symptomResult.confidence! * 100).toStringAsFixed(0)}%'
        : '—';
    explanations.add(
      'Symptom model: ${_formatHistoricalLabel(symptomResult.className!)} with $conf AI confidence.',
    );
  }

  if (patientResult.className != null) {
    final conf = patientResult.confidence != null
        ? '${(patientResult.confidence! * 100).toStringAsFixed(0)}%'
        : '—';
    explanations.add(
      'Patient-risk model: ${_formatHistoricalLabel(patientResult.className!)} with $conf AI confidence.',
    );
  }

  final imgPred = imageResult?.prediction;
  if (imgPred?.className != null) {
    final conf = imgPred!.confidence != null
        ? '${(imgPred.confidence! * 100).toStringAsFixed(0)}%'
        : '—';
    explanations.add(
      'Image model: ${_formatHistoricalLabel(imgPred.className!)} with $conf AI confidence.',
    );
  }

  if (explanations.isEmpty) {
    explanations.add(
      'The recorded AI model outputs were used as part of this screening.',
    );
  }

  final mainConcern =
      imageResult?.prediction?.className ??
      symptomResult.className ??
      detail.overallCategory ??
      'Health Screening';

  return ScreeningInterpretation(
    mainConcern: _formatHistoricalLabel(mainConcern),
    overallStatus: 'SCREENING_COMPLETED',
    screeningSummary: 'AI-assisted health screening completed using the recorded checkup information.',
    triage: '',
    redFlags: const [],
    vitalsInterpretation: 'The vital signs recorded during this checkup are shown below for reference.',
    modelExplanations: explanations,
    nextSteps: 'Review the screening information and seek professional medical advice if symptoms persist, worsen, or cause concern.',
    overallExplanation: 'This page presents the AI-assisted screening outputs recorded during the selected checkup. These outputs are screening results and are not a medical diagnosis.',
  );
}

String _formatHistoricalLabel(String value) {
  if (value.isEmpty) return value;
  final spaced = value.replaceAll('_', ' ');
  return spaced[0].toUpperCase() + spaced.substring(1);
}

class Assessment {
  const Assessment({
    this.imageType,
    this.finding,
    this.confidence,
    this.probabilities = const {},
  });

  final String? imageType;
  final String? finding;
  final double? confidence;
  final Map<String, double> probabilities;

  factory Assessment.fromJson(Map<String, dynamic> json) {
    return Assessment(
      imageType: json['image_type'] as String?,
      finding: json['finding'] as String?,
      confidence: _toDoubleOpt(json['confidence']),
      probabilities: _toProbMap(json['probabilities']),
    );
  }
}

class ImageResult {
  const ImageResult({this.type, this.prediction});

  final String? type;
  final ImagePrediction? prediction;

  factory ImageResult.fromJson(Map<String, dynamic> json) {
    return ImageResult(
      type: json['type'] as String?,
      prediction: json['prediction'] != null
          ? ImagePrediction.fromJson(json['prediction'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ImagePrediction {
  const ImagePrediction({
    this.classIndex,
    this.className,
    this.confidence,
    this.probabilities = const {},
  });

  final int? classIndex;
  final String? className;
  final double? confidence;
  final Map<String, double> probabilities;

  factory ImagePrediction.fromJson(Map<String, dynamic> json) {
    return ImagePrediction(
      classIndex: json['class_index'] as int?,
      className: json['class_name'] as String?,
      confidence: _toDoubleOpt(json['confidence']),
      probabilities: _toProbMap(json['probabilities']),
    );
  }
}

class ModelResult {
  const ModelResult({
    this.classIndex,
    this.className,
    this.confidence,
    this.probabilities = const {},
  });

  final int? classIndex;
  final String? className;
  final double? confidence;
  final Map<String, double> probabilities;

  factory ModelResult.fromJson(Map<String, dynamic> json) {
    return ModelResult(
      classIndex: json['class_index'] as int?,
      className: json['class_name'] as String?,
      confidence: _toDoubleOpt(json['confidence']),
      probabilities: _toProbMap(json['probabilities']),
    );
  }
}

class UncertaintyResult {
  const UncertaintyResult({
    this.confidence = 0.0,
    this.uncertainty = 0.0,
    this.completeness = 0.0,
    this.imageQuality,
  });

  final double confidence;
  final double uncertainty;
  final double completeness;
  final double? imageQuality;

  factory UncertaintyResult.fromJson(Map<String, dynamic> json) {
    return UncertaintyResult(
      confidence: _toDouble(json['confidence']),
      uncertainty: _toDouble(json['uncertainty']),
      completeness: _toDouble(json['completeness']),
      imageQuality: _toDoubleOpt(json['image_quality']),
    );
  }
}

class ScreeningInterpretation {
  const ScreeningInterpretation({
    this.mainConcern = '',
    this.overallStatus = '',
    this.screeningSummary = '',
    this.triage = '',
    this.redFlags = const [],
    this.vitalsInterpretation = '',
    this.modelExplanations = const [],
    this.nextSteps = '',
    this.overallExplanation = '',
  });

  final String mainConcern;
  final String overallStatus;
  final String screeningSummary;
  final String triage;
  final List<String> redFlags;
  final String vitalsInterpretation;
  final List<String> modelExplanations;
  final String nextSteps;
  final String overallExplanation;

  factory ScreeningInterpretation.fromJson(Map<String, dynamic> json) {
    return ScreeningInterpretation(
      mainConcern: json['main_concern'] as String? ?? '',
      overallStatus: json['overall_status'] as String? ?? '',
      screeningSummary: json['screening_summary'] as String? ?? '',
      triage: json['triage'] as String? ?? '',
      redFlags: _toStringList(json['red_flags']),
      vitalsInterpretation: json['vitals_interpretation'] as String? ?? '',
      modelExplanations: _toStringList(json['model_explanations']),
      nextSteps: json['next_steps'] as String? ?? '',
      overallExplanation: json['overall_explanation'] as String? ?? '',
    );
  }
}

// ── Assistant models ──────────────────────────────────────────────────────────

/// Request body for POST /api/v1/assistant/chat.
///
/// NOTE: `user_id` is intentionally omitted — the backend identifies the user
/// from the Bearer token (migration plan Section 4, rule: "never send user_id").
class AssistantRequest {
  const AssistantRequest({required this.message, this.checkupId});

  final String message;
  final String? checkupId;

  Map<String, dynamic> toJson() => {
    'message': message,
    if (checkupId != null) 'checkup_id': checkupId,
  };
}

/// Response from POST /api/v1/assistant/chat.
class AssistantResponse {
  const AssistantResponse({
    required this.status,
    required this.message,
    this.context,
  });

  final String status;
  final String message;
  final Map<String, dynamic>? context;

  factory AssistantResponse.fromJson(Map<String, dynamic> json) {
    return AssistantResponse(
      status: json['status'] as String? ?? '',
      message: json['message'] as String? ?? '',
      context: _toMap(json['context']),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

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

Map<String, double> _toProbMap(dynamic v) {
  if (v == null) return const {};
  if (v is Map) {
    return {for (final e in v.entries) e.key.toString(): _toDouble(e.value)};
  }
  return const {};
}

List<String> _toStringList(dynamic v) {
  if (v == null) return const [];
  if (v is List) return v.map((e) => e.toString()).toList();
  return const [];
}

Map<String, dynamic>? _toMap(dynamic v) {
  if (v == null) return null;
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return v.cast<String, dynamic>();
  return null;
}
