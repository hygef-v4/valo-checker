import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/match_summary.dart';
import '../models/saved_account.dart';
import 'riot_api_client.dart';

/// Local persistence.
///
/// Auth tokens live in the platform keystore via [FlutterSecureStorage];
/// non-sensitive display data (cached profile) stays in SharedPreferences.
class LocalCacheService {
  static const String _profileKey = 'cached_user_profile';
  static const String _secureTokenKey = 'riot_auth_tokens';
  static const String _savedAccountsKey = 'saved_riot_accounts';
  static const String _activePuuidKey = 'active_puuid';

  /// Legacy plaintext token key from pre-1.0 builds; wiped on first access.
  static const String _legacyTokenKey = 'cached_user_tokens';

  /// Riot OAuth access tokens expire after 1 hour. Treat tokens older than
  /// 55 minutes as expired so we never fire requests with a dying token.
  static const int _tokenTtlMs = 3300000;

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  // --- Single-Token & Legacy Methods ---

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

  // --- Multi-Account Management Methods ---

  static Future<List<SavedAccount>> getSavedAccounts() async {
    try {
      final str = await _secureStorage.read(key: _savedAccountsKey);
      if (str != null && str.isNotEmpty) {
        final List<dynamic> list = jsonDecode(str);
        return list.map((item) => SavedAccount.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      RiotApiClient.logError('getSavedAccounts', e);
    }
    return [];
  }

  static Future<void> saveAccount(SavedAccount account) async {
    try {
      final accounts = await getSavedAccounts();
      final index = accounts.indexWhere((a) => a.puuid == account.puuid);
      if (index >= 0) {
        accounts[index] = account;
      } else {
        accounts.add(account);
      }
      final jsonList = accounts.map((a) => a.toJson()).toList();
      await _secureStorage.write(key: _savedAccountsKey, value: jsonEncode(jsonList));

      // Mark as active
      await setActivePuuid(account.puuid);
      await saveTokens(account.accessToken, account.idToken);
    } catch (e) {
      RiotApiClient.logError('saveAccount', e);
    }
  }

  static Future<String?> getActivePuuid() async {
    try {
      return await _secureStorage.read(key: _activePuuidKey);
    } catch (e) {
      RiotApiClient.logError('getActivePuuid', e);
      return null;
    }
  }

  static Future<void> setActivePuuid(String puuid) async {
    try {
      await _secureStorage.write(key: _activePuuidKey, value: puuid);
      final accounts = await getSavedAccounts();
      final active = accounts.firstWhere((a) => a.puuid == puuid, orElse: () => accounts.first);
      await saveTokens(active.accessToken, active.idToken);
    } catch (e) {
      RiotApiClient.logError('setActivePuuid', e);
    }
  }

  static Future<SavedAccount?> getActiveAccount() async {
    try {
      final accounts = await getSavedAccounts();
      if (accounts.isEmpty) return null;

      final activePuuid = await getActivePuuid();
      if (activePuuid != null && activePuuid.isNotEmpty) {
        final match = accounts.where((a) => a.puuid == activePuuid).firstOrNull;
        if (match != null) return match;
      }
      return accounts.first;
    } catch (e) {
      RiotApiClient.logError('getActiveAccount', e);
      return null;
    }
  }

  static Future<void> removeAccount(String puuid) async {
    try {
      final accounts = await getSavedAccounts();
      accounts.removeWhere((a) => a.puuid == puuid);
      final jsonList = accounts.map((a) => a.toJson()).toList();
      await _secureStorage.write(key: _savedAccountsKey, value: jsonEncode(jsonList));

      final activePuuid = await getActivePuuid();
      if (activePuuid == puuid) {
        if (accounts.isNotEmpty) {
          await setActivePuuid(accounts.first.puuid);
        } else {
          await _secureStorage.delete(key: _activePuuidKey);
          await clearTokens();
        }
      }
    } catch (e) {
      RiotApiClient.logError('removeAccount', e);
    }
  }

  static Future<void> clearAllAccounts() async {
    try {
      await _secureStorage.delete(key: _savedAccountsKey);
      await _secureStorage.delete(key: _activePuuidKey);
      await clearTokens();
    } catch (e) {
      RiotApiClient.logError('clearAllAccounts', e);
    }
  }

  // --- Wishlist Persistence Methods ---

  static String _wishlistKey(String puuid) => 'wishlist_$puuid';

  static Future<Set<String>> getWishlist(String puuid) async {
    if (puuid.isEmpty) return {};
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_wishlistKey(puuid));
      if (list != null) {
        return list.toSet();
      }
    } catch (e) {
      RiotApiClient.logError('getWishlist', e);
    }
    return {};
  }

  static Future<bool> toggleWishlist(String puuid, String skinUuid) async {
    if (puuid.isEmpty || skinUuid.isEmpty) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final set = (await getWishlist(puuid)).toSet();
      final key = _wishlistKey(puuid);
      bool isAdded;
      if (set.contains(skinUuid)) {
        set.remove(skinUuid);
        isAdded = false;
      } else {
        set.add(skinUuid);
        isAdded = true;
      }
      await prefs.setStringList(key, set.toList());
      return isAdded;
    } catch (e) {
      RiotApiClient.logError('toggleWishlist', e);
      return false;
    }
  }

  static Future<bool> isWishlisted(String puuid, String skinUuid) async {
    if (puuid.isEmpty || skinUuid.isEmpty) return false;
    final wishlist = await getWishlist(puuid);
    return wishlist.contains(skinUuid);
  }

  // --- Match History Cache Methods ---

  static String _matchHistoryKey(String puuid) => 'cached_matches_$puuid';

  static Future<void> saveCachedMatches(String puuid, List<MatchSummary> matches) async {
    if (puuid.isEmpty || matches.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final trimmed = matches.take(60).map((m) => jsonEncode(m.toJson())).toList();
      await prefs.setStringList(_matchHistoryKey(puuid), trimmed);
    } catch (e) {
      RiotApiClient.logError('saveCachedMatches', e);
    }
  }

  static Future<List<MatchSummary>> getCachedMatches(String puuid) async {
    if (puuid.isEmpty) return [];
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_matchHistoryKey(puuid));
      if (list != null && list.isNotEmpty) {
        return list
            .map((str) {
              try {
                return MatchSummary.fromJson(jsonDecode(str) as Map<String, dynamic>);
              } catch (_) {
                return null;
              }
            })
            .whereType<MatchSummary>()
            .toList();
      }
    } catch (e) {
      RiotApiClient.logError('getCachedMatches', e);
    }
    return [];
  }
}

