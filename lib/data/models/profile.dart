import 'package:supabase_flutter/supabase_flutter.dart';

/// Mirrors Kotlin `data class Profile` in `data/model/Profile.kt`.
///
/// Supabase table: `profiles(id, full_name, date_of_birth, sex,
/// height_cm, weight_kg, created_at, updated_at)`.
///
/// Field names are kept snake_case to match the Supabase column names
/// exactly — Supabase's Dart client decodes JSON by key name.
class Profile {
  const Profile({
    required this.id,
    required this.fullName,
    required this.dateOfBirth,
    required this.sex,
    required this.heightCm,
    required this.weightKg,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String fullName;
  final String dateOfBirth; // ISO date string, e.g. "1995-06-15"
  final String sex;
  final double heightCm;
  final double weightKg;
  final String? createdAt;
  final String? updatedAt;

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? '',
      dateOfBirth: json['date_of_birth'] as String? ?? '',
      sex: json['sex'] as String? ?? '',
      heightCm: _toDouble(json['height_cm']),
      weightKg: _toDouble(json['weight_kg']),
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'date_of_birth': dateOfBirth,
        'sex': sex,
        'height_cm': heightCm,
        'weight_kg': weightKg,
      };

  /// Builds the `patient` payload that is sent inside a checkup request body.
  /// Vitals are merged in by [CheckupDraftNotifier] before submission.
  Map<String, dynamic> toPatientPayload() => {
        'full_name': fullName,
        'date_of_birth': dateOfBirth,
        'sex': sex,
        'height_cm': heightCm,
        'weight_kg': weightKg,
      };

  /// Populate from a Supabase [User]'s metadata (used during onboarding when
  /// the `profiles` row may not exist yet — Q1 fix path).
  factory Profile.fromUserMetadata(User user) {
    final meta = user.userMetadata ?? {};
    return Profile(
      id: user.id,
      fullName: meta['full_name'] as String? ?? '',
      dateOfBirth: meta['date_of_birth'] as String? ?? '',
      sex: meta['sex'] as String? ?? '',
      heightCm: _toDouble(meta['height_cm']),
      weightKg: _toDouble(meta['weight_kg']),
    );
  }

  Profile copyWith({
    String? fullName,
    String? dateOfBirth,
    String? sex,
    double? heightCm,
    double? weightKg,
  }) {
    return Profile(
      id: id,
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      sex: sex ?? this.sex,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Profile &&
          id == other.id &&
          fullName == other.fullName &&
          dateOfBirth == other.dateOfBirth &&
          sex == other.sex &&
          heightCm == other.heightCm &&
          weightKg == other.weightKg;

  @override
  int get hashCode => Object.hash(id, fullName, dateOfBirth, sex, heightCm, weightKg);
}

double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}
