import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/skin_item.dart';
import '../models/accessory_item.dart';
import 'riot_api_client.dart';

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
  static final Map<String, dynamic> _missionsCache = {};
  static bool _isLoaded = false;

  static Future<void> loadMetadataCache() async {
    if (_isLoaded) return;

    try {
      final responses = await Future.wait([
        RiotApiClient.get(Uri.parse('https://valorant-api.com/v1/weapons/skinlevels')),
        RiotApiClient.get(Uri.parse('https://valorant-api.com/v1/contenttiers')),
        RiotApiClient.get(Uri.parse('https://valorant-api.com/v1/bundles')),
        RiotApiClient.get(Uri.parse('https://valorant-api.com/v1/sprays')),
        RiotApiClient.get(Uri.parse('https://valorant-api.com/v1/playercards')),
        RiotApiClient.get(Uri.parse('https://valorant-api.com/v1/buddies/levels')),
        RiotApiClient.get(Uri.parse('https://valorant-api.com/v1/playertitles')),
        RiotApiClient.get(Uri.parse('https://valorant-api.com/v1/competitivetiers')),
        RiotApiClient.get(Uri.parse('https://valorant-api.com/v1/agents?isPlayableCharacter=true')),
        RiotApiClient.get(Uri.parse('https://valorant-api.com/v1/maps')),
        RiotApiClient.get(Uri.parse('https://valorant-api.com/v1/weapons/skins')),
        RiotApiClient.get(Uri.parse('https://valorant-api.com/v1/weapons')),
        RiotApiClient.get(Uri.parse('https://valorant-api.com/v1/missions')),
        RiotApiClient.get(Uri.parse('https://valorant-api.com/v1/buddies')),
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

      // Populate Buddies (both buddy UUID and buddy level UUIDs)
      if (responses[13].statusCode == 200) {
        final data = jsonDecode(responses[13].body)['data'] as List;
        for (var buddy in data) {
          final bUuid = (buddy['uuid'] ?? '').toString().toLowerCase();
          if (bUuid.isNotEmpty) {
            _buddiesCache[bUuid] = buddy;
          }
          final levels = buddy['levels'] as List? ?? [];
          for (var l in levels) {
            final lUuid = (l['uuid'] ?? '').toString().toLowerCase();
            if (lUuid.isNotEmpty) {
              _buddiesCache[lUuid] = {
                'displayName': l['displayName'] ?? buddy['displayName'],
                'displayIcon': l['displayIcon'] ?? buddy['displayIcon'],
              };
            }
          }
        }
      }

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

      populate(responses[12], _missionsCache);

      _isLoaded = true;
    } catch (e) {
      RiotApiClient.logError('loadMetadataCache', e);
    }
  }

  static final List<Map<String, String>> officialValorantWeapons = [
    {'name': 'Melee', 'category': 'MELEE', 'icon': 'https://media.valorant-api.com/weaponskins/00c0b968-45db-953e-561b-9694119d84c1/displayicon.png'},
    {'name': 'Classic', 'category': 'SIDEARMS', 'icon': 'https://media.valorant-api.com/weaponskins/e3760023-484e-2660-9a7d-f1a407736777/displayicon.png'},
    {'name': 'Shorty', 'category': 'SIDEARMS', 'icon': 'https://media.valorant-api.com/weaponskins/4be08d51-4f9e-4e4b-482f-2d9370da0e30/displayicon.png'},
    {'name': 'Frenzy', 'category': 'SIDEARMS', 'icon': 'https://media.valorant-api.com/weaponskins/5e533e4f-4d37-e544-7067-178b665df070/displayicon.png'},
    {'name': 'Ghost', 'category': 'SIDEARMS', 'icon': 'https://media.valorant-api.com/weaponskins/0545f061-4682-6f9a-0e99-4d924d55050f/displayicon.png'},
    {'name': 'Sheriff', 'category': 'SIDEARMS', 'icon': 'https://media.valorant-api.com/weaponskins/5df3297a-4c28-97e3-0d35-3b99912759e6/displayicon.png'},
    {'name': 'Stinger', 'category': 'SMGS', 'icon': 'https://media.valorant-api.com/weaponskins/14b3d325-4122-8d7d-5a82-f5b24479e0a0/displayicon.png'},
    {'name': 'Spectre', 'category': 'SMGS', 'icon': 'https://media.valorant-api.com/weaponskins/bb6e7465-4f7f-6819-bf93-9c86a60e0a58/displayicon.png'},
    {'name': 'Bucky', 'category': 'SHOTGUNS', 'icon': 'https://media.valorant-api.com/weaponskins/67eb9548-466d-eb10-f1c5-cb810c978008/displayicon.png'},
    {'name': 'Judge', 'category': 'SHOTGUNS', 'icon': 'https://media.valorant-api.com/weaponskins/75ce7cfa-468e-28cb-b0f3-ea9f0fb576ef/displayicon.png'},
    {'name': 'Bulldog', 'category': 'RIFLES', 'icon': 'https://media.valorant-api.com/weaponskins/ffb233a7-47d0-1e5b-b9f3-b78809c7eb4e/displayicon.png'},
    {'name': 'Guardian', 'category': 'RIFLES', 'icon': 'https://media.valorant-api.com/weaponskins/140236a9-4674-325b-be13-909d9a0d89e5/displayicon.png'},
    {'name': 'Phantom', 'category': 'RIFLES', 'icon': 'https://media.valorant-api.com/weaponskins/83141f3e-4b47-1960-d667-bb8909180738/displayicon.png'},
    {'name': 'Vandal', 'category': 'RIFLES', 'icon': 'https://media.valorant-api.com/weaponskins/9c83332a-4503-99c3-8177-dce0c0445e72/displayicon.png'},
    {'name': 'Marshal', 'category': 'SNIPERS', 'icon': 'https://media.valorant-api.com/weaponskins/8ab7d75b-432d-2051-512c-9a888c3a10ee/displayicon.png'},
    {'name': 'Outlaw', 'category': 'SNIPERS', 'icon': 'https://media.valorant-api.com/weaponskins/50627063-4696-8408-7715-d2a333363f4f/displayicon.png'},
    {'name': 'Operator', 'category': 'SNIPERS', 'icon': 'https://media.valorant-api.com/weaponskins/a03b24d3-4319-996d-0f8c-94bbfba1dfc7/displayicon.png'},
    {'name': 'Ares', 'category': 'HEAVY', 'icon': 'https://media.valorant-api.com/weaponskins/9d18c94e-4f24-6447-1845-a99f36f98f6d/displayicon.png'},
    {'name': 'Odin', 'category': 'HEAVY', 'icon': 'https://media.valorant-api.com/weaponskins/e0dfb720-410a-20fa-fa9d-1ba672bf6246/displayicon.png'},
  ];

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

  static SkinItem resolveSkinItem(String itemUuid, int cost, {String? itemTypeId}) {
    final key = itemUuid.toLowerCase();
    final typeKey = (itemTypeId ?? '').toLowerCase();

    // 1. Player Card
    if (typeKey == '3f296326-62c0-4f96-94e9-77c08096fc88' || _playerCardsCache.containsKey(key)) {
      final card = _playerCardsCache[key];
      final name = (card?['displayName'] ?? 'Player Card').toString();
      final icon = (card?['displayIcon'] ??
              card?['smallArt'] ??
              card?['largeArt'] ??
              'https://media.valorant-api.com/playercards/$itemUuid/displayicon.png')
          .toString();
      return SkinItem(
        uuid: itemUuid,
        displayName: name,
        displayIcon: icon,
        cost: cost,
      );
    }

    // 2. Gun Buddy / Buddy Level
    if (typeKey == 'dd3b2834-433a-4ba3-727b-d8912a428447' || _buddiesCache.containsKey(key)) {
      final buddy = _buddiesCache[key];
      final name = (buddy?['displayName'] ?? 'Gun Buddy').toString();
      final icon = (buddy?['displayIcon'] ??
              'https://media.valorant-api.com/buddies/$itemUuid/displayicon.png')
          .toString();
      return SkinItem(
        uuid: itemUuid,
        displayName: name,
        displayIcon: icon,
        cost: cost,
      );
    }

    // 3. Spray
    if (typeKey == 'd5f12124-92a5-43ac-9238-631143a0425b' || _spraysCache.containsKey(key)) {
      final spray = _spraysCache[key];
      final name = (spray?['displayName'] ?? 'Spray').toString();
      final icon = (spray?['fullTransparentIcon'] ??
              spray?['displayIcon'] ??
              'https://media.valorant-api.com/sprays/$itemUuid/fulltransparenticon.png')
          .toString();
      return SkinItem(
        uuid: itemUuid,
        displayName: name,
        displayIcon: icon,
        cost: cost,
      );
    }

    // 4. Title
    if (typeKey == 'de7ea82c-446a-44b0-9900-47bf2b51206d' || _playerTitlesCache.containsKey(key)) {
      final title = _playerTitlesCache[key];
      final name = (title?['titleText'] ?? title?['displayName'] ?? 'Title').toString();
      return SkinItem(
        uuid: itemUuid,
        displayName: name,
        displayIcon: '',
        cost: cost,
      );
    }

    // 5. Weapon Skin or Level
    dynamic item = _skinsFullCache[key] ?? _skinLevelsCache[key];

    if (item != null) {
      String name = (item['displayName'] ?? 'Valorant Item').toString();
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
        videoUrl: video,
        cleanName: clean,
      );
    }

    return SkinItem(
      uuid: itemUuid,
      displayName: 'Valorant Item',
      displayIcon: '',
      cost: cost,
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

  /// Real mission title, XP grant, and completion target from valorant-api
  /// metadata. Returns empty values for unknown mission IDs so callers can
  /// fall back honestly instead of inventing numbers.
  static Map<String, dynamic> resolveMission(String missionUuid) {
    final raw = _missionsCache[missionUuid.toLowerCase()];
    if (raw == null) {
      return {'title': '', 'xpGrant': 0, 'progressToComplete': 0};
    }
    return {
      'title': (raw['title'] ?? raw['displayName'] ?? '').toString(),
      'xpGrant': raw['xpGrant'] as int? ?? 0,
      'progressToComplete': raw['progressToComplete'] as int? ?? 0,
    };
  }

  static AccessoryItem resolveAccessoryItem(String itemId, String itemTypeId, int costKC) {
    final uuid = itemId.toLowerCase();
    String name = 'Valorant Accessory';
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
