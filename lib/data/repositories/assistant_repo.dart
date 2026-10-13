import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/assistant.dart';
import '../../core/providers.dart';
import '../../core/api_client.dart';

/// Handles calls to the FastAPI assistant endpoint.
///
/// Mirrors the Kotlin `assistantChat` call in `Health360ApiService.kt`.
/// Note: `user_id` is NOT sent — the backend identifies the user from the
/// Bearer token (migration plan rule).
class AssistantRepository {
  const AssistantRepository(this._apiClient);

  final ApiClient _apiClient;

  /// POST /api/v1/assistant/chat
  ///
  /// [message] — the user's chat message.
  /// [checkupId] — optional; pass when the chat is opened from a result screen
  ///   so the assistant has context about that specific checkup.
  Future<AssistantResponse> chat({required String message, String? checkupId}) {
    return _apiClient.assistantChat(message: message, checkupId: checkupId);
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final assistantRepositoryProvider = Provider<AssistantRepository>((ref) {
  return AssistantRepository(ref.watch(apiClientProvider));
});
