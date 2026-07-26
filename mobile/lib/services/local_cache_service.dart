import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'riot_api_client.dart';

/// Local persistence.
///
/// Auth tokens live in the platform keystore via [FlutterSecureStorage];
/// non-sensitive display data (cached profile) stays in SharedPreferences.
class LocalCacheService {
  static const String _profileKey = 'cached_user_profile';
  static const String _secureTokenKey = 'riot_auth_tokens';

  /// Legacy plaintext token key from pre-1.0 builds; wiped on first access.
  static const String _legacyTokenKey = 'cached_user_tokens';

  /// Riot OAuth access tokens expire after 1 hour. Treat tokens older than
  /// 55 minutes as expired so we never fire requests with a dying token.
  static const int _tokenTtlMs = 3300000;

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static Future<void> saveTokens(String accessToken, String idToken) async {
    try {
      await _secureStorage.write(
        key: _secureTokenKey,
        value: jsonEncode({
          'accessToken': accessToken,
          'idToken': idToken,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }),
      );
    } catch (e) {
      RiotApiClient.logError('saveTokens', e);
    }
  }

  static Future<Map<String, String>?> getValidTokens() async {
    await _wipeLegacyPlaintextTokens();
    try {
      final str = await _secureStorage.read(key: _secureTokenKey);
      if (str != null && str.isNotEmpty) {
        final data = jsonDecode(str) as Map<String, dynamic>;
        final timestamp = data['timestamp'] as int? ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now - timestamp < _tokenTtlMs) {
          return {
            'accessToken': (data['accessToken'] ?? '').toString(),
            'idToken': (data['idToken'] ?? '').toString(),
          };
        }
      }
    } catch (e) {
      RiotApiClient.logError('getValidTokens', e);
    }
    return null;
  }

  static Future<void> clearTokens() async {
    try {
      await _secureStorage.delete(key: _secureTokenKey);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_profileKey);
      await prefs.remove(_legacyTokenKey);
    } catch (e) {
      RiotApiClient.logError('clearTokens', e);
    }
  }

  static Future<void> _wipeLegacyPlaintextTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(_legacyTokenKey)) {
        await prefs.remove(_legacyTokenKey);
      }
    } catch (_) {}
  }

  static Future<void> saveProfile(Map<String, dynamic> profileJson) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profileKey, jsonEncode(profileJson));
    } catch (e) {
      RiotApiClient.logError('saveProfile', e);
    }
  }

  static Future<Map<String, dynamic>?> getCachedProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_profileKey);
      if (str != null && str.isNotEmpty) {
        return jsonDecode(str) as Map<String, dynamic>;
      }
    } catch (e) {
      RiotApiClient.logError('getCachedProfile', e);
    }
    return null;
  }
}
