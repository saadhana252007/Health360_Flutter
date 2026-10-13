import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
// Hide MultipartFile because supabase_flutter also exports one.
import 'package:supabase_flutter/supabase_flutter.dart' hide MultipartFile;

import '../app/config.dart';
import '../data/models/checkup_response.dart';

// ── Exception types ──────────────────────────────────────────────────────────

/// Typed API error surfaced to the UI layer.
class ApiException implements Exception {
  const ApiException({required this.statusCode, required this.message});

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

// ── Dio client factory ────────────────────────────────────────────────────────

/// Creates and returns the configured [Dio] instance.
///
/// - Base URL from [AppConfig.apiBaseUrl] (injected via --dart-define).
/// - Connect timeout 30 s; send/receive timeout 60 s (images can be slow).
/// - Bearer token read from the current Supabase session on every request.
/// - On HTTP 401: refresh the session once and retry.
/// - Request/response bodies are only logged in debug builds to avoid
///   leaking health data in release logs (mirrors RetrofitClient.kt).
/// - The `Authorization` header is never printed.
Dio buildApiClient() {
  final baseUrl = AppConfig.apiBaseUrl.endsWith('/')
      ? AppConfig.apiBaseUrl
      : '${AppConfig.apiBaseUrl}/';

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
    ),
  );

  // 1. Auth interceptor — adds Bearer token; retries once on 401.
  dio.interceptors.add(_AuthInterceptor(dio));

  // 2. Debug-only logger — no health data or tokens in release.
  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        // Suppress the Authorization header value from logs.
        requestHeader: false,
        responseHeader: false,
        logPrint: (o) {
          // Extra guard: skip any line that might contain a token.
          final line = o.toString();
          if (line.toLowerCase().contains('authorization') ||
              line.toLowerCase().contains('bearer')) {
            return; // Never print the token.
          }
          debugPrint(line);
        },
      ),
    );
  }

  return dio;
}

// ── Auth interceptor ──────────────────────────────────────────────────────────

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._dio);

  final Dio _dio;
  bool _isRetrying = false;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_isRetrying) {
      _isRetrying = true;
      try {
        // Refresh the Supabase session and retry the original request.
        await Supabase.instance.client.auth.refreshSession();
        final newToken =
            Supabase.instance.client.auth.currentSession?.accessToken;
        if (newToken == null) {
          handler.next(err);
          return;
        }

        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer $newToken';

        final retried = await _dio.fetch(opts);
        handler.resolve(retried);
        return;
      } catch (_) {
        handler.next(err);
        return;
      } finally {
        _isRetrying = false;
      }
    }
    handler.next(err);
  }
}

// ── HTTP error mapping ────────────────────────────────────────────────────────

/// Converts a [DioException] into a human-readable [ApiException].
///
/// Error messages mirror the plan Section 4 requirement: show `detail` from
/// the response body for 400/413/503; generic messages for 401/500/timeout.
ApiException mapDioError(DioException e) {
  final status = e.response?.statusCode ?? 0;
  final detail = _extractDetail(e.response?.data);

  return switch (status) {
    401 => const ApiException(
      statusCode: 401,
      message: 'Your session has expired. Please log in again.',
    ),
    400 => ApiException(
      statusCode: 400,
      message: detail ?? 'Invalid request. Please check your input.',
    ),
    413 => ApiException(
      statusCode: 413,
      message: detail ?? 'Image file is too large (max 10 MB).',
    ),
    503 => ApiException(
      statusCode: 503,
      message:
          detail ??
          'AI model is temporarily unavailable. Please try again shortly.',
    ),
    500 => const ApiException(
      statusCode: 500,
      message: 'Server error. Please try again later.',
    ),
    _ => switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => const ApiException(
        statusCode: 0,
        message: 'Request timed out. Check your connection and try again.',
      ),
      DioExceptionType.connectionError => const ApiException(
        statusCode: 0,
        message: 'Could not reach the server. Check your connection.',
      ),
      _ => ApiException(
        statusCode: status,
        message: e.message ?? 'An unexpected error occurred.',
      ),
    },
  };
}

// ── API methods ───────────────────────────────────────────────────────────────

/// Thin wrapper around [Dio] that exposes typed API calls.
///
/// This class is instantiated once via the Riverpod [apiClientProvider].
class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  /// GET /health — no auth required.
  Future<Map<String, dynamic>> healthCheck() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('health');
      return res.data ?? {};
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// POST /api/v1/checkups/analyze — JSON body, no image.
  ///
  /// NOTE: `user_id` is NOT sent. The backend identifies the user from the
  /// Bearer token (migration plan rule: "The Flutter app must not send user_id").
  Future<CheckupResponse> analyzeCheckup({
    required Map<String, dynamic> symptoms,
    required Map<String, dynamic> patient,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        'api/v1/checkups/analyze',
        data: {'symptoms': symptoms, 'patient': patient},
      );
      return CheckupResponse.fromJson(res.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// POST /api/v1/checkups/analyze-image — multipart.
  ///
  /// Max image size: 10 MB (enforced by backend, which also resizes to 1024 px).
  Future<CheckupResponse> analyzeCheckupWithImage({
    required Map<String, dynamic> symptoms,
    required Map<String, dynamic> patient,
    required String imageType,
    required MultipartFile imageFile,
  }) async {
    try {
      final formData = FormData.fromMap({
        'symptoms': jsonEncodeCompact(symptoms),
        'patient': jsonEncodeCompact(patient),
        'image_type': imageType,
        'image': imageFile,
      });

      final res = await _dio.post<Map<String, dynamic>>(
        'api/v1/checkups/analyze-image',
        data: formData,
      );
      return CheckupResponse.fromJson(res.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// POST /api/v1/assistant/chat.
  Future<AssistantResponse> assistantChat({
    required String message,
    String? checkupId,
  }) async {
    try {
      final body = AssistantRequest(message: message, checkupId: checkupId);
      final res = await _dio.post<Map<String, dynamic>>(
        'api/v1/assistant/chat',
        data: body.toJson(),
      );
      return AssistantResponse.fromJson(res.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String? _extractDetail(dynamic data) {
  if (data == null) return null;
  if (data is Map) return data['detail']?.toString();
  return null;
}

/// Encodes [map] to a compact JSON string for multipart form fields.
String jsonEncodeCompact(Map<String, dynamic> map) => jsonEncode(map);
