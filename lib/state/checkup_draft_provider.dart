import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/profile.dart';
import '../data/models/symptoms_vitals.dart';

// ── Draft state ───────────────────────────────────────────────────────────────

/// Immutable snapshot of the in-progress checkup draft.
///
/// Mirrors the fields of Kotlin's `CheckupStateRepository` singleton, which
/// held: `patient`, `vitals`, `symptoms`, `imageUri`, `imageType`.
///
/// In Flutter we use a Riverpod [Notifier] instead of a global object so the
/// state is observable and properly cleared after a successful submit.
class CheckupDraft {
  const CheckupDraft({
    this.patient,
    this.vitals,
    this.symptoms,
    this.imagePath,
    this.imageType,
  });

  /// Patient profile data (prefilled from `profiles` table in item 5a).
  final Profile? patient;

  /// Vitals entered on the Vitals screen (item 5c).
  final VitalsPayload? vitals;

  /// Symptoms entered on the Symptoms screen (item 5b).
  final SymptomsPayload? symptoms;

  /// Absolute path to the picked image file, or null if no image was chosen.
  /// (item 5d uses image_picker which returns a file path on mobile)
  final String? imagePath;

  /// `skin` | `oral` | `wound` — only set when [imagePath] is non-null.
  final String? imageType;

  bool get hasImage => imagePath != null && imageType != null;

  /// Builds the `patient` JSON map for the API request.
  ///
  /// Merges [Profile.toPatientPayload()] with [VitalsPayload.toJson()].
  /// Throws [StateError] if either is missing.
  Map<String, dynamic> buildPatientPayload() {
    final p = patient;
    final v = vitals;
    if (p == null) throw StateError('Patient information is missing');
    if (v == null) throw StateError('Vitals are missing');
    return {...p.toPatientPayload(), ...v.toJson()};
  }

  /// Builds the `symptoms` JSON map for the API request.
  Map<String, dynamic> buildSymptomsPayload() {
    final s = symptoms;
    if (s == null) throw StateError('Symptoms are missing');
    return s.toJson();
  }

  CheckupDraft copyWith({
    Profile? patient,
    VitalsPayload? vitals,
    SymptomsPayload? symptoms,
    String? imagePath,
    String? imageType,
    // Sentinel to allow explicit nulling of optional fields.
    bool clearImage = false,
  }) {
    return CheckupDraft(
      patient: patient ?? this.patient,
      vitals: vitals ?? this.vitals,
      symptoms: symptoms ?? this.symptoms,
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
      imageType: clearImage ? null : (imageType ?? this.imageType),
    );
  }

  /// Returns an empty draft — used after a successful submit.
  static const empty = CheckupDraft();
}

// ── Notifier ──────────────────────────────────────────────────────────────────

/// Riverpod [Notifier] that owns the mutable checkup draft.
///
/// Equivalent to the Kotlin `CheckupStateRepository` object but observable
/// and cleared automatically after a successful submission (item 6a).
class CheckupDraftNotifier extends Notifier<CheckupDraft> {
  @override
  CheckupDraft build() => CheckupDraft.empty;

  // ── Setters called by individual screens ──────────────────────────────────

  void setPatient(Profile patient) {
    state = state.copyWith(patient: patient);
  }

  void setVitals(VitalsPayload vitals) {
    state = state.copyWith(vitals: vitals);
  }

  void setSymptoms(SymptomsPayload symptoms) {
    state = state.copyWith(symptoms: symptoms);
  }

  void setImage({required String path, required String imageType}) {
    state = state.copyWith(imagePath: path, imageType: imageType);
  }

  void clearImage() {
    state = state.copyWith(clearImage: true);
  }

  /// Resets the entire draft after a successful submission.
  ///
  /// Called from the submit action in item 6a once the API returns a result.
  void clear() {
    state = CheckupDraft.empty;
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final checkupDraftProvider =
    NotifierProvider<CheckupDraftNotifier, CheckupDraft>(
  CheckupDraftNotifier.new,
);
