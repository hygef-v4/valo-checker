import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Thrown when Riot rejects our credentials (expired/invalid token).
/// The UI treats this as "please log in again"; every other failure is
/// transient and must NOT log the user out.
class SessionExpiredException implements Exception {
  final String message;
  SessionExpiredException([this.message = 'Your Riot session has expired. Please log in again.']);

  @override
  String toString() => message;
}

/// Thin wrapper around package:http that every Riot/valorant-api call goes
/// through: enforces a timeout, logs failures in debug builds, and caches
/// the Riot client version for the lifetime of the process.
class RiotApiClient {
  static const Duration timeout = Duration(seconds: 15);
  // Used only when valorant-api.com is unreachable; real version as of 2026-07.
  static const String fallbackClientVersion = 'release-13.01-shipping-11-5090349';

  static const String clientPlatform =
      'ew0KCSJwbGF0Zm9ybVR5cGUiOiAiUEMiLA0KCSJwbGF0Zm9ybU9TIjogIldpbmRvd3MiLA0KCSJwbGF0Zm9ybU9TVmVyc2lvbiI6ICIxMC4wLjE5MDQyLjEuMjU2LjY0Yml0IiwNCgkicGxhdGZvcm1CYXNlT1MiOiAiV2luZG93cyINCn0=';

  static String? _cachedClientVersion;
  static Future<String>? _clientVersionRequest;

  /// Riot client version, fetched once per app session from valorant-api.com.
  static Future<String> getClientVersion() {
    if (_cachedClientVersion != null) return Future.value(_cachedClientVersion);
    // Coalesce concurrent callers into a single request.
    _clientVersionRequest ??= _fetchClientVersion();
    return _clientVersionRequest!;
  }

  static Future<String> _fetchClientVersion() async {
    try {
      final res = await get(Uri.parse('https://valorant-api.com/v1/version'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final version = (data['data']?['riotClientVersion'] ?? '').toString();
        if (version.isNotEmpty) {
          _cachedClientVersion = version;
          return version;
        }
      }
    } catch (e) {
      logError('getClientVersion', e);
    }
    _clientVersionRequest = null; // allow a retry on the next call
    return fallbackClientVersion;
  }

  /// Standard headers for the pd player-data endpoints.
  static Future<Map<String, String>> playerHeaders(
    String accessToken,
    String entitlementToken, {
    bool json = false,
  }) async {
    final clientVersion = await getClientVersion();
    return {
      'Authorization': 'Bearer $accessToken',
      'X-Riot-Entitlements-JWT': entitlementToken,
      'X-Riot-ClientVersion': clientVersion,
      'X-Riot-ClientPlatform': clientPlatform,
      if (json) 'Content-Type': 'application/json',
    };
  }

  static Future<http.Response> get(Uri url, {Map<String, String>? headers}) {
    return http.get(url, headers: headers).timeout(timeout);
  }

  static Future<http.Response> post(Uri url, {Map<String, String>? headers, Object? body}) {
    return http.post(url, headers: headers, body: body).timeout(timeout);
  }

  static Future<http.Response> put(Uri url, {Map<String, String>? headers, Object? body}) {
    return http.put(url, headers: headers, body: body).timeout(timeout);
  }

  /// True when the response means "your token is no longer valid".
  static bool isAuthFailure(http.Response res) {
    return res.statusCode == 401 || res.statusCode == 403;
  }

  static void logError(String operation, Object error) {
    if (kDebugMode) {
      debugPrint('[RiotApi] $operation failed: $error');
    }
  }
}
