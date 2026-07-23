import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/skin_item.dart';
import '../models/accessory_item.dart';

class ValorantApiService {
  static final Map<String, dynamic> _skinsFullCache = {};
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
  static final Map<String, Map<String, String>> _weaponsCache = {};
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
        http.get(Uri.parse('https://valorant-api.com/v1/weapons/skins')),
        http.get(Uri.parse('https://valorant-api.com/v1/weapons')),
      ]);

      void populate(http.Response res, Map<String, dynamic> targetMap) {
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body)['data'] as List;
          for (var item in data) {
            targetMap[item['uuid'].toString().toLowerCase()] = item;
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

      // Populate Full Skins
      if (responses[10].statusCode == 200) {
        final skinsData = jsonDecode(responses[10].body)['data'] as List;
        for (var skin in skinsData) {
          final sUuid = (skin['uuid'] ?? '').toString().toLowerCase();
          _skinsFullCache[sUuid] = skin;

          final chromas = skin['chromas'] as List? ?? [];
          for (var c in chromas) {
            final cUuid = (c['uuid'] ?? '').toString().toLowerCase();
            if (cUuid.isNotEmpty) {
              _skinsFullCache[cUuid] = {
                'displayName': c['displayName'] ?? skin['displayName'],
                'displayIcon': c['displayIcon'] ?? c['fullRender'] ?? skin['displayIcon'],
                'streamedVideo': c['streamedVideo'] ?? skin['levels']?[0]?['streamedVideo'],
                'parentSkin': skin,
              };
            }
          }

          final levels = skin['levels'] as List? ?? [];
          for (var l in levels) {
            final lUuid = (l['uuid'] ?? '').toString().toLowerCase();
            if (lUuid.isNotEmpty) {
              _skinsFullCache[lUuid] = {
                'displayName': l['displayName'] ?? skin['displayName'],
                'displayIcon': l['displayIcon'] ?? skin['displayIcon'],
                'streamedVideo': l['streamedVideo'] ?? skin['levels']?[0]?['streamedVideo'],
                'parentSkin': skin,
              };
            }
          }
        }
      }

      // Populate Weapons
      if (responses[11].statusCode == 200) {
        final weaponsData = jsonDecode(responses[11].body)['data'] as List;
        for (var w in weaponsData) {
          final wUuid = (w['uuid'] ?? '').toString().toLowerCase();
          _weaponsCache[wUuid] = {
            'displayName': (w['displayName'] ?? 'Weapon').toString(),
            'displayIcon': (w['killStreamIcon'] ?? w['displayIcon'] ?? '').toString(),
          };
        }
      }

      _isLoaded = true;
    } catch (_) {}
  }

  static Map<String, String> resolveWeapon(String weaponUuid) {
    final key = weaponUuid.toLowerCase();
    if (_weaponsCache.containsKey(key)) {
      return _weaponsCache[key]!;
    }
    return {
      'displayName': 'Weapon',
      'displayIcon': '',
    };
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

  static String getRankIconByName(String name) {
    final lower = name.toLowerCase().trim();
    int tier = 0;
    if (lower.contains('iron 1')) {
      tier = 3;
    } else if (lower.contains('iron 2')) {
      tier = 4;
    } else if (lower.contains('iron 3') || lower.contains('iron')) {
      tier = 5;
    } else if (lower.contains('bronze 1')) {
      tier = 6;
    } else if (lower.contains('bronze 2')) {
      tier = 7;
    } else if (lower.contains('bronze 3') || lower.contains('bronze')) {
      tier = 8;
    } else if (lower.contains('silver 1')) {
      tier = 9;
    } else if (lower.contains('silver 2')) {
      tier = 10;
    } else if (lower.contains('silver 3') || lower.contains('silver')) {
      tier = 11;
    } else if (lower.contains('gold 1')) {
      tier = 12;
    } else if (lower.contains('gold 2')) {
      tier = 13;
    } else if (lower.contains('gold 3') || lower.contains('gold')) {
      tier = 14;
    } else if (lower.contains('plat') && lower.contains('1')) {
      tier = 15;
    } else if (lower.contains('plat') && lower.contains('2')) {
      tier = 16;
    } else if (lower.contains('plat')) {
      tier = 17;
    } else if (lower.contains('diamond') && lower.contains('1')) {
      tier = 18;
    } else if (lower.contains('diamond') && lower.contains('2')) {
      tier = 19;
    } else if (lower.contains('diamond')) {
      tier = 20;
    } else if (lower.contains('ascendant') && lower.contains('1')) {
      tier = 21;
    } else if (lower.contains('ascendant') && lower.contains('2')) {
      tier = 22;
    } else if (lower.contains('ascendant')) {
      tier = 23;
    } else if (lower.contains('immortal') && lower.contains('1')) {
      tier = 24;
    } else if (lower.contains('immortal') && lower.contains('2')) {
      tier = 25;
    } else if (lower.contains('immortal')) {
      tier = 26;
    } else if (lower.contains('radiant')) {
      tier = 27;
    }

    return resolveRankTier(tier)['largeIcon'] ?? '';
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
    final key = itemUuid.toLowerCase();
    dynamic item = _skinsFullCache[key] ?? _skinLevelsCache[key];

    if (item == null) {
      return SkinItem(
        uuid: itemUuid,
        displayName: 'Valorant Skin',
        displayIcon: '',
        cost: cost,
      );
    }

    String name = (item['displayName'] ?? 'Valorant Skin').toString();
    String icon = (item['displayIcon'] ?? item['fullRender'] ?? '').toString();
    String video = (item['streamedVideo'] ?? '').toString();

    if (icon.isEmpty && item['parentSkin'] != null) {
      icon = (item['parentSkin']['displayIcon'] ?? '').toString();
    }

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

  static Map<String, dynamic>? getSkinFullData(String itemUuid) {
    final key = itemUuid.toLowerCase();
    final item = _skinsFullCache[key];
    if (item != null) {
      if (item['parentSkin'] != null) {
        return item['parentSkin'] as Map<String, dynamic>;
      }
      if (item['chromas'] != null) {
        return item as Map<String, dynamic>;
      }
    }
    return null;
  }

  static Map<String, dynamic>? getAgentFullData(String agentUuid) {
    final key = agentUuid.toLowerCase();
    return _agentsRawCache[key];
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
    final lowerOwned = ownedAgentUuids.map((e) => e.toLowerCase()).toSet();

    _agentsRawCache.forEach((uuid, raw) {
      final isBase = raw['isBaseContent'] == true;
      final isOwned = isBase || lowerOwned.contains(uuid.toLowerCase());

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

  static String resolvePlayerCard(String cardUuid) {
    final key = cardUuid.toLowerCase();
    final item = _playerCardsCache[key];
    if (item != null) {
      final icon = (item['displayIcon'] ?? item['smallArt'] ?? item['largeArt'] ?? '').toString();
      if (icon.isNotEmpty) return icon;
    }
    if (cardUuid.isNotEmpty) {
      return 'https://media.valorant-api.com/playercards/$cardUuid/displayicon.png';
    }
    return '';
  }
}
