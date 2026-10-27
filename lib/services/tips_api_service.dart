import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/safety_tip.dart';

/// Error from the tips API with a message safe to show to the user.
class TipsApiException implements Exception {
  const TipsApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Fetches safety tips from a REST endpoint (Experiment 9).
///
/// The endpoint is a documented *mock* API (see `mock_api/` and
/// `docs/API.md`), because no suitable public safety-tips API was verified.
/// The URL comes from `--dart-define=TIPS_API_URL=...`; there are no API keys.
class TipsApiService {
  TipsApiService({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  static const Duration _timeout = Duration(seconds: 10);

  /// Default endpoint for local development with `dart run tool/mock_api/server.dart`.
  /// The Android emulator reaches the host computer at 10.0.2.2.
  static String resolveBaseUrl() {
    const fromEnv = String.fromEnvironment('TIPS_API_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080/tips.json';
    }
    return 'http://localhost:8080/tips.json';
  }

  Future<List<SafetyTip>> fetchTips() async {
    try {
      final response = await _client
          .get(Uri.parse(baseUrl), headers: {'Accept': 'application/json'})
          .timeout(_timeout);

      if (response.statusCode != 200) {
        throw TipsApiException(
          'The tips server responded with status ${response.statusCode}.',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['tips'] is! List) {
        throw const TipsApiException('The tips server sent an unexpected format.');
      }

      return (decoded['tips'] as List)
          .map(SafetyTip.tryParse)
          .whereType<SafetyTip>()
          .toList();
    } on TipsApiException {
      rethrow;
    } on TimeoutException {
      throw const TipsApiException('The request timed out. Please try again.');
    } on FormatException {
      throw const TipsApiException('The tips server sent invalid data.');
    } on http.ClientException {
      throw const TipsApiException(
        'Could not reach the tips server. Check that it is running and your network is on.',
      );
    } catch (e) {
      debugPrint('Tips API error: $e');
      throw const TipsApiException('Could not load tips. Please try again.');
    }
  }
}