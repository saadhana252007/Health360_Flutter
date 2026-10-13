import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide MultipartFile;

import '../models/checkup_summary.dart';
import '../models/checkup_detail.dart';
import '../models/checkup_response.dart';
import '../../core/supabase_client.dart';
import '../../core/providers.dart';
import '../../core/api_client.dart';
import '../../state/checkup_draft_provider.dart';

/// Handles Supabase reads from the `checkups` table and delegates
/// API submissions to [ApiClient].
///
/// Mirrors the read logic of Kotlin `CheckupRepository.kt` and
/// `CheckupDetailRepository.kt`.
///
/// ⚠️  The client does NOT write to `checkups`; the backend writes all rows.
class CheckupRepository {
  const CheckupRepository({
    required this.supabaseClient,
    required this.apiClient,
  });

  final SupabaseClient supabaseClient;
  final ApiClient apiClient;

  // ── Supabase reads ────────────────────────────────────────────────────────────

  /// Returns the most recent checkup for [userId], or null if none exists.
  ///
  /// Mirrors: `getLatestCheckup(userId)` — filter user_id, order created_at
  /// DESC, limit 1.
  Future<CheckupSummary?> getLatestCheckup(String userId) async {
    final rows = await supabaseClient
        .from('checkups')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1);

    if (rows.isEmpty) return null;
    return CheckupSummary.fromJson(rows.first);
  }

  /// Returns all checkups for [userId], newest first.
  ///
  /// Mirrors: `getCheckupHistory(userId)`.
  Future<List<CheckupSummary>> getCheckupHistory(String userId) async {
    final rows = await supabaseClient
        .from('checkups')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return rows.map((r) => CheckupSummary.fromJson(r)).toList();
  }

  /// Returns the full detail row for [checkupId], optionally filtered by [userId].
  ///
  /// Mirrors: `getCheckupDetail(checkupId, userId)`.
  Future<CheckupDetail?> getCheckupDetail({
    required String checkupId,
    String? userId,
  }) async {
    var query = supabaseClient.from('checkups').select().eq('id', checkupId);
    if (userId != null && userId.isNotEmpty) {
      query = query.eq('user_id', userId);
    }
    final rows = await query.limit(1);

    if (rows.isEmpty) return null;
    return CheckupDetail.fromJson(rows.first);
  }

  // ── API submissions ──────────────────────────────────────────────────────────

  /// Submits the in-progress [CheckupDraft] to the backend.
  ///
  /// - If [draft.hasImage] is true, calls `POST /api/v1/checkups/analyze-image` (multipart).
  /// - If [draft.hasImage] is false, calls `POST /api/v1/checkups/analyze` (JSON).
  ///
  /// Neither sends `user_id` in the payload; the backend identifies the user
  /// from the Bearer token.
  Future<CheckupResponse> submitCheckup(
    CheckupDraft draft, {
    MultipartFile? imageFileOverride,
  }) async {
    final symptoms = draft.buildSymptomsPayload();
    final patient = draft.buildPatientPayload();

    if (draft.hasImage) {
      final MultipartFile imageFile;
      if (imageFileOverride != null) {
        imageFile = imageFileOverride;
      } else {
        final path = draft.imagePath!;
        if (File(path).existsSync()) {
          imageFile = await MultipartFile.fromFile(
            path,
            filename: 'health360_image.jpg',
          );
        } else {
          imageFile = MultipartFile.fromBytes(
            const [],
            filename: 'health360_image.jpg',
          );
        }
      }

      return apiClient.analyzeCheckupWithImage(
        symptoms: symptoms,
        patient: patient,
        imageType: draft.imageType!,
        imageFile: imageFile,
      );
    } else {
      return apiClient.analyzeCheckup(symptoms: symptoms, patient: patient);
    }
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final checkupRepositoryProvider = Provider<CheckupRepository>((ref) {
  return CheckupRepository(
    supabaseClient: supabase,
    apiClient: ref.watch(apiClientProvider),
  );
});
