import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/skin_item.dart';
import '../models/accessory_item.dart';

class ValorantApiService {
  static final Map<String, dynamic> _skinLevelsCache = {};
  static final Map<String, dynamic> _contentTiersCache = {};
  static final Map<String, dynamic> _bundlesCache = {};
  static final Map<String, dynamic> _spraysCache = {};
  static final Map<String, dynamic> _playerCardsCache = {};
  static final Map<String, dynamic> _buddiesCache = {};
  static final Map<String, dynamic> _playerTitlesCache = {};
  static final Map<int, Map<String, String>> _rankTiersCache = {};
  static final Map<String, Map<String, String>> _agentsCache = {};
  static final Map<String, dynamic> _agentsRawCache = {};
  static final Map<String, Map<String, String>> _mapsCache = {};
  static bool _isLoaded = false;

  static Future<void> loadMetadataCache() async {
    if (_isLoaded) return;

    try {
      final responses = await Future.wait([
        http.get(Uri.parse('https://valorant-api.com/v1/weapons/skinlevels')),
        http.get(Uri.parse('https://valorant-api.com/v1/contenttiers')),
        http.get(Uri.parse('https://valorant-api.com/v1/bundles')),
        http.get(Uri.parse('https://valorant-api.com/v1/sprays')),
        http.get(Uri.parse('https://valorant-api.com/v1/playercards')),
        http.get(Uri.parse('https://valorant-api.com/v1/buddies/levels')),
        http.get(Uri.parse('https://valorant-api.com/v1/playertitles')),
        http.get(Uri.parse('https://valorant-api.com/v1/competitivetiers')),
        http.get(Uri.parse('https://valorant-api.com/v1/agents?isPlayableCharacter=true')),
        http.get(Uri.parse('https://valorant-api.com/v1/maps')),
      ]);

      void populate(http.Response res, Map<String, dynamic> targetMap) {
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body)['data'] as List;
          for (var item in data) {
            targetMap[item['uuid']] = item;
          }
        }
      }

      populate(responses[0], _skinLevelsCache);
      populate(responses[1], _contentTiersCache);
      populate(responses[2], _bundlesCache);
      populate(responses[3], _spraysCache);
      populate(responses[4], _playerCardsCache);
      populate(responses[5], _buddiesCache);
      populate(responses[6], _playerTitlesCache);

      // Populate Rank Tiers
      if (responses[7].statusCode == 200) {
        final data = jsonDecode(responses[7].body)['data'] as List;
        if (data.isNotEmpty) {
          final lastTier = data.last['tiers'] as List? ?? [];
          for (var t in lastTier) {
            final tierId = t['tier'] as int? ?? 0;
            _rankTiersCache[tierId] = {
              'tierName': (t['tierName'] ?? 'Unrated').toString(),
              'largeIcon': (t['largeIcon'] ?? t['smallIcon'] ?? '').toString(),
            };
          }
        }
      }

      // Populate Agents
      if (responses[8].statusCode == 200) {
        final data = jsonDecode(responses[8].body)['data'] as List;
        for (var agent in data) {
          final uuid = (agent['uuid'] ?? '').toString().toLowerCase();
          _agentsRawCache[uuid] = agent;
          _agentsCache[uuid] = <String, String>{
            'displayName': (agent['displayName'] ?? 'Agent').toString(),
            'displayIcon': (agent['displayIcon'] ?? agent['killfeedPortrait'] ?? '').toString(),
            'fullPortrait': (agent['fullPortrait'] ?? agent['displayIcon'] ?? '').toString(),
          };
        }
      }

      // Populate Maps
      if (responses[9].statusCode == 200) {
        final data = jsonDecode(responses[9].body)['data'] as List;
        for (var map in data) {
          final urlPath = (map['mapUrl'] ?? map['uuid'] ?? '').toString().toLowerCase();
          final uuid = (map['uuid'] ?? '').toString().toLowerCase();
          final mapInfo = <String, String>{
            'displayName': (map['displayName'] ?? 'Map').toString(),
            'splash': (map['splash'] ?? map['listViewIcon'] ?? '').toString(),
          };
          _mapsCache[uuid] = mapInfo;
          _mapsCache[urlPath] = mapInfo;
        }
      }

      _isLoaded = true;
    } catch (_) {}
  }

  static Map<String, String> resolveRankTier(int tier) {
    if (_rankTiersCache.containsKey(tier)) {
      return _rankTiersCache[tier]!;
    }
    return {
      'tierName': 'Unrated',
      'largeIcon': 'https://media.valorant-api.com/competitivetiers/03621f52-342b-cf4e-4f86-9350a49c6d04/0/largeicon.png',
    };
  }

  static Map<String, String> resolveAgent(String agentUuid) {
    final key = agentUuid.toLowerCase();
    if (_agentsCache.containsKey(key)) {
      return _agentsCache[key]!;
    }
    return {
      'displayName': 'Agent',
      'displayIcon': '',
    };
  }

  static Map<String, String> resolveMap(String mapIdOrPath) {
    final key = mapIdOrPath.toLowerCase();
    if (_mapsCache.containsKey(key)) {
      return _mapsCache[key]!;
    }
    // Match by path tail e.g. /Game/Maps/Ascent/Ascent
    for (var k in _mapsCache.keys) {
      if (key.endsWith(k) || k.endsWith(key)) {
        return _mapsCache[k]!;
      }
    }
    return {
      'displayName': 'Valorant Map',
      'splash': '',
    };
  }

  static SkinItem resolveSkinItem(String itemUuid, int cost) {
    final rawSkin = _skinLevelsCache[itemUuid];

    if (rawSkin == null) {
      return SkinItem(
        uuid: itemUuid,
        displayName: 'Valorant Skin',
        displayIcon: '',
        cost: cost,
      );
    }

    String name = (rawSkin['displayName'] ?? 'Valorant Skin').toString();
    String icon = (rawSkin['displayIcon'] ?? '').toString();
    String video = (rawSkin['streamedVideo'] ?? '').toString();

    String clean = name
        .replaceAll(RegExp(r'\s+Level\s+\d+.*$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+Variant\s+\d+.*$', caseSensitive: false), '')
        .trim();

    return SkinItem(
      uuid: itemUuid,
      displayName: name,
      displayIcon: icon,
      cost: cost,
      tierColor: '#FF4655',
      tierName: 'Exclusive',
      videoUrl: video,
      cleanName: clean,
    );
  }

  static Map<String, String> resolveBundleMeta(String bundleUuid) {
    final raw = _bundlesCache[bundleUuid];
    if (raw == null) {
      return {
        'displayName': 'Featured Bundle',
        'displayIcon': '',
      };
    }
    return {
      'displayName': raw['displayName'] ?? 'Featured Bundle',
      'displayIcon': raw['displayIcon'] ?? raw['verticalPromoImage'] ?? '',
    };
  }

  static AccessoryItem resolveAccessoryItem(String itemId, String itemTypeId, int costKC) {
    final uuid = itemId.toLowerCase();
    String name = 'Phụ Kiện Valorant';
    String icon = '';
    String category = 'Accessory';

    if (_spraysCache.containsKey(uuid)) {
      final item = _spraysCache[uuid];
      name = item['displayName'] ?? 'Spray';
      icon = item['fullTransparentIcon'] ?? item['displayIcon'] ?? '';
      category = 'Spray';
    } else if (_playerCardsCache.containsKey(uuid)) {
      final item = _playerCardsCache[uuid];
      name = item['displayName'] ?? 'Player Card';
      icon = item['largeArt'] ?? item['displayIcon'] ?? '';
      category = 'Card';
    } else if (_buddiesCache.containsKey(uuid)) {
      final item = _buddiesCache[uuid];
      name = item['displayName'] ?? 'Gun Buddy';
      icon = item['displayIcon'] ?? '';
      category = 'Buddy';
    } else if (_playerTitlesCache.containsKey(uuid)) {
      final item = _playerTitlesCache[uuid];
      name = item['titleText'] ?? item['displayName'] ?? 'Title';
      icon = '';
      category = 'Title';
    }

    return AccessoryItem(
      uuid: itemId,
      displayName: name,
      displayIcon: icon,
      categoryName: category,
      costKC: costKC,
    );
  }

  static List<Map<String, dynamic>> getPlayableAgentsList(Set<String> ownedAgentUuids) {
    List<Map<String, dynamic>> agentsList = [];
    _agentsRawCache.forEach((uuid, raw) {
      final isOwned = ownedAgentUuids.contains(uuid);
      agentsList.add({
        'uuid': uuid,
        'displayName': (raw['displayName'] ?? 'Agent').toString(),
        'displayIcon': (raw['displayIcon'] ?? raw['killfeedPortrait'] ?? '').toString(),
        'fullPortrait': (raw['fullPortrait'] ?? raw['displayIcon'] ?? '').toString(),
        'roleName': (raw['role']?['displayName'] ?? 'Initiator').toString(),
        'roleIcon': (raw['role']?['displayIcon'] ?? '').toString(),
        'isOwned': isOwned,
      });
    });
    return agentsList;
  }
}
