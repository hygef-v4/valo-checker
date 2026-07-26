import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/accessory_item.dart';
import '../models/bundle_item.dart';
import '../models/match_summary.dart';
import '../models/quest_item.dart';
import '../models/rank_info.dart';
import '../models/skin_item.dart';
import '../models/user_profile.dart';
import '../utils/json_utils.dart';
import 'riot_api_client.dart';
import 'valorant_api_service.dart';

class RiotAuthService {
  // Currency UUIDs as they appear in wallet/storefront responses. The "alt"
  // variants show up in some legacy storefront Cost maps.
  static const String vpUuid = '85ad13f7-3d1b-5128-9eb2-7cd8ee0b5741';
  static const String vpUuidAlt = '85ad13f7-3d1b-da12-a0a0-4e907616386c';
  static const String kcUuid = '85ca954a-41f2-ce94-9b45-8ca3dd39a00d';
  static const String radUuid = 'e59aa87c-4cbf-517a-5983-6e81511be9b7';
  static const String radUuidAlt = 'e59aa87c-4c57-90ab-d663-2a4895203a25';

  static const int matchHistoryCount = 20;

  static Future<String> getEntitlements(String accessToken) async {
    final res = await RiotApiClient.post(
      Uri.parse('https://entitlements.auth.riotgames.com/api/token/v1'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({}),
    );

    if (res.statusCode == 400 || RiotApiClient.isAuthFailure(res)) {
      throw SessionExpiredException();
    }
    if (res.statusCode != 200) {
      throw Exception('Failed to get entitlements token (Status: ${res.statusCode})');
    }

    final data = jsonDecode(res.body);
    return data['entitlements_token'] ?? '';
  }

  static Future<Map<String, dynamic>> getUserInfo(String accessToken) async {
    final res = await RiotApiClient.get(
      Uri.parse('https://auth.riotgames.com/userinfo'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (RiotApiClient.isAuthFailure(res)) {
      throw SessionExpiredException();
    }
    if (res.statusCode != 200) {
      throw Exception('Failed to get userinfo (Status: ${res.statusCode})');
    }

    return jsonDecode(res.body);
  }

  static Future<String> getRiotGeo(String accessToken, String idToken, String entitlementToken) async {
    try {
      final res = await RiotApiClient.put(
        Uri.parse('https://riot-geo.pas.si.riotgames.com/pas/v1/product/valorant'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'X-Riot-Entitlements-JWT': entitlementToken,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'id_token': idToken}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final liveAffinity = data['affinities']?['live'] ?? 'ap';
        return liveAffinity.toString().toLowerCase().split('-')[0];
      }
    } catch (e) {
      RiotApiClient.logError('getRiotGeo', e);
    }
    return 'ap';
  }

  static Future<Map<String, int>> getWallet(String accessToken, String entitlementToken, String puuid, String shard) async {
    int vp = 0;
    int rad = 0;
    int kc = 0;

    try {
      final res = await RiotApiClient.get(
        Uri.parse('https://pd.$shard.a.pvp.net/store/v1/wallet/$puuid'),
        headers: await RiotApiClient.playerHeaders(accessToken, entitlementToken),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final balances = data['Balances'] as Map<String, dynamic>?;
        if (balances != null) {
          vp = (balances[vpUuid] ?? balances[vpUuidAlt] ?? 0) as int;
          rad = (balances[radUuid] ?? balances[radUuidAlt] ?? 0) as int;
          kc = (balances[kcUuid] ?? 0) as int;
        }
      }
    } catch (e) {
      RiotApiClient.logError('getWallet', e);
    }

    return {'vp': vp, 'rad': rad, 'kc': kc};
  }

  static Future<Set<String>> fetchOwnedAgents(String accessToken, String entitlementToken, String puuid, String shard) async {
    final headers = await RiotApiClient.playerHeaders(accessToken, entitlementToken);
    final Set<String> ownedAgentUuids = {};

    // 1. Agent entitlements
    try {
      final res = await RiotApiClient.get(
        Uri.parse('https://pd.$shard.a.pvp.net/store/v1/entitlements/$puuid/01bb38e1-da47-4e6a-9b3d-945fe4655707'),
        headers: headers,
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final entitlements = data['Entitlements'] as List? ?? [];
        for (var item in entitlements) {
          final itemId = (item['ItemID'] ?? '').toString().toLowerCase();
          if (itemId.isNotEmpty) {
            ownedAgentUuids.add(itemId);
          }
        }
      }
    } catch (e) {
      RiotApiClient.logError('fetchOwnedAgents/entitlements', e);
    }

    // 2. Characters unlocked through contracts
    try {
      final contractRes = await RiotApiClient.get(
        Uri.parse('https://pd.$shard.a.pvp.net/contracts/v1/contracts/$puuid'),
        headers: headers,
      );

      if (contractRes.statusCode == 200) {
        final data = jsonDecode(contractRes.body);
        final unlocked = data['UnlockedCharacters'] as List? ?? [];
        for (var charId in unlocked) {
          final idStr = charId.toString().toLowerCase();
          if (idStr.isNotEmpty) {
            ownedAgentUuids.add(idStr);
          }
        }
      }
    } catch (e) {
      RiotApiClient.logError('fetchOwnedAgents/contracts', e);
    }

    return ownedAgentUuids;
  }

  static Future<String> fetchPlayerCard(String accessToken, String entitlementToken, String puuid, String shard) async {
    try {
      final res = await RiotApiClient.get(
        Uri.parse('https://pd.$shard.a.pvp.net/personalization/v2/players/$puuid/playerloadout'),
        headers: await RiotApiClient.playerHeaders(accessToken, entitlementToken),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final cardUuid = (data['Identity']?['PlayerCardID'] ?? '').toString();
        if (cardUuid.isNotEmpty) {
          return ValorantApiService.resolvePlayerCard(cardUuid);
        }
      }
    } catch (e) {
      RiotApiClient.logError('fetchPlayerCard', e);
    }

    return '';
  }

  static Future<int> fetchAccountLevel(String accessToken, String entitlementToken, String puuid, String shard) async {
    try {
      final res = await RiotApiClient.get(
        Uri.parse('https://pd.$shard.a.pvp.net/account-xp/v1/players/$puuid'),
        headers: await RiotApiClient.playerHeaders(accessToken, entitlementToken),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['Progress']?['Level'] as int? ?? 0;
      }
    } catch (e) {
      RiotApiClient.logError('fetchAccountLevel', e);
    }
    return 0;
  }

  static Future<List<SkinItem>> fetchOwnedInventory(String accessToken, String entitlementToken, String puuid, String shard) async {
    final List<SkinItem> ownedSkins = [];

    try {
      final res = await RiotApiClient.get(
        Uri.parse('https://pd.$shard.a.pvp.net/store/v1/entitlements/$puuid/e7c63390-eda7-46e0-bb7a-a6abdacd2433'),
        headers: await RiotApiClient.playerHeaders(accessToken, entitlementToken),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final entitlements = data['Entitlements'] as List? ?? [];
        for (var item in entitlements) {
          final itemId = item['ItemID'] ?? '';
          if (itemId.isNotEmpty) {
            ownedSkins.add(ValorantApiService.resolveSkinItem(itemId.toString(), 0));
          }
        }
      }
    } catch (e) {
      RiotApiClient.logError('fetchOwnedInventory', e);
    }

    return ownedSkins;
  }

  static Future<RankInfo?> fetchRankInfo(String accessToken, String entitlementToken, String puuid, String shard) async {
    try {
      final headers = await RiotApiClient.playerHeaders(accessToken, entitlementToken);
      final responses = await Future.wait([
        RiotApiClient.get(
          Uri.parse('https://pd.$shard.a.pvp.net/mmr/v1/players/$puuid'),
          headers: headers,
        ),
        RiotApiClient.get(
          Uri.parse('https://pd.$shard.a.pvp.net/mmr/v1/players/$puuid/competitiveupdates?startIndex=0&endIndex=$matchHistoryCount'),
          headers: headers,
        ),
      ]);
      final mmrRes = responses[0];
      final updatesRes = responses[1];

      int currentTier = 0;
      int currentRR = 0;
      int peakTier = 0;
      int totalWins = 0;
      int totalGames = 0;

      int latestRankedTier = 0;
      int latestRankedRR = 0;

      if (mmrRes.statusCode == 200) {
        final mmrData = jsonDecode(mmrRes.body);
        final queueSkills = mmrData['QueueSkills']?['competitive'];
        if (queueSkills != null) {
          final seasonalInfo = queueSkills['SeasonalInfoBySeason'];
          if (seasonalInfo != null && seasonalInfo is Map) {
            for (var season in seasonalInfo.values) {
              final tier = season['CompetitiveTier'] as int? ?? 0;
              final rr = season['RankedRating'] as int? ?? 0;

              totalWins += season['NumberOfWins'] as int? ?? 0;
              totalGames += season['NumberOfGames'] as int? ?? 0;

              if (tier > 0) {
                latestRankedTier = tier;
                latestRankedRR = rr;
              }

              if (tier > peakTier) {
                peakTier = tier;
              }
            }
          }
        }
      }

      List<CompetitiveUpdateItem> updates = [];
      int lastCompetitiveTier = 0;
      int lastCompetitiveRR = 0;

      if (updatesRes.statusCode == 200) {
        final updatesData = jsonDecode(updatesRes.body);
        final matches = updatesData['Matches'] as List? ?? [];

        for (var m in matches) {
          final tierAfter = m['TierAfterUpdate'] as int? ?? 0;
          final rrAfter = m['RankedRatingAfterUpdate'] as int? ?? 0;
          final rrBefore = m['RankedRatingBeforeUpdate'] as int? ?? rrAfter;
          final rrMovement = m['RankedRatingEarned'] as int? ?? (rrAfter - rrBefore);
          final mapId = m['MapID'] ?? '';
          final matchTime = m['MatchStartTime'] as int? ?? 0;

          // Most recent competitive match with a real tier (skips unrated entries).
          if (tierAfter > 0 && lastCompetitiveTier == 0) {
            lastCompetitiveTier = tierAfter;
            lastCompetitiveRR = rrAfter;
          }

          if (tierAfter > peakTier) {
            peakTier = tierAfter;
          }

          final tierMeta = ValorantApiService.resolveRankTier(tierAfter);
          final mapMeta = ValorantApiService.resolveMap(mapId.toString());

          updates.add(CompetitiveUpdateItem(
            matchId: m['MatchID'] ?? '',
            mapName: mapMeta['displayName']!,
            tierName: tierMeta['tierName']!,
            tierIcon: tierMeta['largeIcon']!,
            rrMovement: rrMovement,
            rrAfterMatch: rrAfter,
            matchStartTime: matchTime,
          ));
        }
      }

      // Priority 1: most recent competitive match tier. Priority 2: latest
      // non-zero seasonal tier. Priority 3: peak tier.
      if (lastCompetitiveTier > 0) {
        currentTier = lastCompetitiveTier;
        currentRR = lastCompetitiveRR;
      } else if (latestRankedTier > 0) {
        currentTier = latestRankedTier;
        currentRR = latestRankedRR;
      } else if (peakTier > 0) {
        currentTier = peakTier;
      }

      if (currentTier > peakTier) {
        peakTier = currentTier;
      }

      final currentMeta = ValorantApiService.resolveRankTier(currentTier);
      final peakMeta = ValorantApiService.resolveRankTier(peakTier);

      return RankInfo(
        currentTierName: currentMeta['tierName']!,
        currentTierIcon: currentMeta['largeIcon']!,
        currentRR: currentRR,
        peakTierName: peakMeta['tierName']!,
        peakTierIcon: peakMeta['largeIcon']!,
        totalWins: totalWins,
        totalGames: totalGames,
        updates: updates,
      );
    } catch (e) {
      RiotApiClient.logError('fetchRankInfo', e);
      return null;
    }
  }

  static Future<List<MatchSummary>> fetchMatchHistory(String accessToken, String entitlementToken, String puuid, String shard) async {
    final List<MatchSummary> matches = [];

    try {
      final headers = await RiotApiClient.playerHeaders(accessToken, entitlementToken);
      final historyRes = await RiotApiClient.get(
        Uri.parse('https://pd.$shard.a.pvp.net/match-history/v1/history/$puuid?startIndex=0&endIndex=$matchHistoryCount'),
        headers: headers,
      );

      if (historyRes.statusCode != 200) {
        return matches;
      }

      final historyData = jsonDecode(historyRes.body);
      final historyList = historyData['History'] as List? ?? [];
      final recentMatches = historyList.take(matchHistoryCount).toList();

      final detailFutures = recentMatches.map((h) {
        final matchId = h['MatchID'] ?? '';
        if (matchId.toString().isEmpty) return Future<http.Response?>.value(null);
        return RiotApiClient.get(
          Uri.parse('https://pd.$shard.a.pvp.net/match-details/v1/matches/$matchId'),
          headers: headers,
        ).then<http.Response?>((res) => res).catchError((_) => null);
      }).toList();

      final responses = await Future.wait(detailFutures);

      // Resolve display names for every player we saw, in batches of 30.
      final Set<String> puuidSet = {};
      for (var matchRes in responses) {
        if (matchRes != null && matchRes.statusCode == 200) {
          try {
            final detailData = jsonDecode(matchRes.body);
            final players = detailData['players'] as List? ?? [];
            for (var p in players) {
              final s = (p['subject'] ?? '').toString();
              if (s.isNotEmpty) puuidSet.add(s);
            }
          } catch (e) {
            RiotApiClient.logError('fetchMatchHistory/parsePlayers', e);
          }
        }
      }

      final resolvedNames = await _resolvePlayerNames(headers, shard, puuidSet);

      for (var matchRes in responses) {
        if (matchRes == null || matchRes.statusCode != 200) continue;

        final detailData = jsonDecode(matchRes.body);
        final matchInfo = detailData['matchInfo'];
        final players = detailData['players'] as List? ?? [];
        final teams = detailData['teams'] as List? ?? [];

        for (var p in players) {
          final sub = (p['subject'] ?? '').toString();
          if (resolvedNames.containsKey(sub)) {
            p['gameName'] = resolvedNames[sub]!['gameName'];
            p['tagLine'] = resolvedNames[sub]!['tagLine'];
          }
        }

        final mapId = matchInfo?['mapId'] ?? '';
        final queueId = (matchInfo?['queueID'] ?? '').toString();
        final rawMode = (matchInfo?['gameMode'] ?? 'Competitive').toString();
        final modeStr = queueId.isNotEmpty ? queueId : rawMode.split('/').last;
        final gameStartTime = matchInfo?['gameStartMillis'] ?? 0;

        final playerObj = firstWhereOrNull(players, (p) => p['subject'] == puuid);
        if (playerObj == null) continue;

        final playerTeam = playerObj['teamId'];
        final characterId = playerObj['characterId'] ?? '';
        final stats = playerObj['stats'];

        final kills = stats?['kills'] ?? 0;
        final deaths = stats?['deaths'] ?? 0;
        final assists = stats?['assists'] ?? 0;

        final teamObj = firstWhereOrNull(teams, (t) => t['teamId'] == playerTeam);

        final isWon = teamObj?['won'] ?? false;
        final roundsWon = teamObj?['roundsWon'] ?? 0;

        final enemyTeam = firstWhereOrNull(teams, (t) => t['teamId'] != playerTeam);
        final roundsLost = enemyTeam?['roundsWon'] ?? 0;

        int topScore = 0;
        for (var p in players) {
          final s = p['stats']?['score'] ?? 0;
          if (s > topScore) topScore = s;
        }
        final isMvp = (stats?['score'] ?? 0) >= topScore && topScore > 0;

        final agentMeta = ValorantApiService.resolveAgent(characterId.toString());
        final mapMeta = ValorantApiService.resolveMap(mapId.toString());

        matches.add(MatchSummary(
          matchId: (matchInfo?['matchId'] ?? '').toString(),
          mapName: mapMeta['displayName']!,
          mapIcon: mapMeta['splash']!,
          agentName: agentMeta['displayName']!,
          agentIcon: agentMeta['displayIcon']!,
          gameMode: modeStr,
          isVictory: isWon,
          scoreText: '$roundsWon - $roundsLost',
          kills: kills,
          deaths: deaths,
          assists: assists,
          isMvp: isMvp,
          matchStartTime: gameStartTime,
          rawMatchDetails: detailData as Map<String, dynamic>?,
        ));
      }
    } catch (e) {
      RiotApiClient.logError('fetchMatchHistory', e);
    }

    return matches;
  }

  static Future<Map<String, Map<String, String>>> _resolvePlayerNames(
      Map<String, String> headers, String shard, Set<String> puuidSet) async {
    final Map<String, Map<String, String>> resolvedNames = {};
    if (puuidSet.isEmpty) return resolvedNames;

    final url = Uri.parse('https://pd.$shard.a.pvp.net/name-service/v2/players');
    final jsonHeaders = {...headers, 'Content-Type': 'application/json'};
    final List<String> allPuuids = puuidSet.toList();

    for (int i = 0; i < allPuuids.length; i += 30) {
      final chunk = allPuuids.sublist(i, (i + 30 > allPuuids.length) ? allPuuids.length : i + 30);
      try {
        var nameRes = await RiotApiClient.put(url, headers: jsonHeaders, body: jsonEncode(chunk));
        if (nameRes.statusCode != 200) {
          nameRes = await RiotApiClient.post(url, headers: jsonHeaders, body: jsonEncode(chunk));
        }
        if (nameRes.statusCode != 200) continue;

        final List nameList = jsonDecode(nameRes.body);
        for (var item in nameList) {
          final sub = (item['Subject'] ?? item['subject'] ?? item['puuid'] ?? '').toString();
          String gName = (item['GameName'] ?? item['gameName'] ?? '').toString();
          String tLine = (item['TagLine'] ?? item['tagLine'] ?? '').toString();

          if (gName.isEmpty && item['DisplayName'] != null) {
            final dn = item['DisplayName'].toString();
            if (dn.contains('#')) {
              final parts = dn.split('#');
              gName = parts[0];
              tLine = parts.sublist(1).join('#');
            } else {
              gName = dn;
            }
          }

          if (sub.isNotEmpty && gName.isNotEmpty) {
            resolvedNames[sub] = {'gameName': gName, 'tagLine': tLine};
          }
        }
      } catch (e) {
        RiotApiClient.logError('resolvePlayerNames', e);
      }
    }

    return resolvedNames;
  }

  static Future<List<QuestItem>> fetchQuestsAndBattlePass(String accessToken, String entitlementToken, String puuid, String shard) async {
    final List<QuestItem> quests = [];

    try {
      final res = await RiotApiClient.get(
        Uri.parse('https://pd.$shard.a.pvp.net/contracts/v1/contracts/$puuid'),
        headers: await RiotApiClient.playerHeaders(accessToken, entitlementToken),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final activeMissions = data['Missions'] as List? ?? [];

        for (var m in activeMissions) {
          final missionId = (m['ID'] ?? '').toString();
          final isComplete = m['Complete'] ?? false;
          final objectives = m['Objectives'] as Map<String, dynamic>?;
          int currentProg = 0;
          if (objectives != null && objectives.isNotEmpty) {
            currentProg = objectives.values.first as int? ?? 0;
          }

          // Real title / XP / target from valorant-api mission metadata;
          // unknown missions fall back to a generic label with no XP claim.
          final meta = ValorantApiService.resolveMission(missionId);
          final targetProg = meta['progressToComplete'] as int? ?? 0;

          quests.add(QuestItem(
            title: (meta['title'] as String?)?.isNotEmpty == true ? meta['title'] as String : 'Daily / Weekly Mission',
            description: isComplete ? 'Completed' : 'In Progress',
            currentProgress: currentProg,
            targetProgress: targetProg > 0 ? targetProg : (isComplete ? currentProg : 0),
            rewardXP: meta['xpGrant'] as int? ?? 0,
            isCompleted: isComplete,
          ));
        }
      }
    } catch (e) {
      RiotApiClient.logError('fetchQuests', e);
    }

    return quests;
  }

  static Future<Map<String, dynamic>> fetchStorefrontData(String accessToken, String idToken) async {
    final entitlementTokenFuture = getEntitlements(accessToken);
    final userInfoFuture = getUserInfo(accessToken);
    final metadataFuture = ValorantApiService.loadMetadataCache();

    // These two throw SessionExpiredException when the token is stale.
    final entitlementToken = await entitlementTokenFuture;
    final userInfo = await userInfoFuture;
    await metadataFuture;

    final puuid = userInfo['sub'] ?? '';
    final acct = userInfo['acct'] as Map<String, dynamic>?;
    final gameName = acct?['game_name'] ?? 'Agent';
    final tagLine = acct?['tag_line'] ?? '';

    final headers = await RiotApiClient.playerHeaders(accessToken, entitlementToken, json: true);
    final detectedShard = await getRiotGeo(accessToken, idToken, entitlementToken);

    http.Response? storeRes;
    final shardsToTry = {detectedShard, 'ap', 'eu', 'na', 'kr'}.toList();
    String activeShard = detectedShard;
    int lastStatus = 0;
    String lastError = '';

    for (var s in shardsToTry) {
      try {
        final res = await RiotApiClient.post(
          Uri.parse('https://pd.$s.a.pvp.net/store/v3/storefront/$puuid'),
          headers: headers,
          body: jsonEncode({}),
        );

        if (res.statusCode == 200) {
          storeRes = res;
          activeShard = s;
          break;
        } else {
          lastStatus = res.statusCode;
        }
      } catch (e) {
        lastError = e.toString();
      }
    }

    if (storeRes == null) {
      final statusInfo = lastStatus > 0 ? 'Status: $lastStatus' : lastError;
      throw Exception('Failed to connect to Valorant servers ($statusInfo). Please try again.');
    }

    final results = await Future.wait([
      getWallet(accessToken, entitlementToken, puuid, activeShard),
      fetchOwnedInventory(accessToken, entitlementToken, puuid, activeShard),
      fetchRankInfo(accessToken, entitlementToken, puuid, activeShard),
      fetchMatchHistory(accessToken, entitlementToken, puuid, activeShard),
      fetchQuestsAndBattlePass(accessToken, entitlementToken, puuid, activeShard),
      fetchOwnedAgents(accessToken, entitlementToken, puuid, activeShard),
      fetchPlayerCard(accessToken, entitlementToken, puuid, activeShard),
      fetchAccountLevel(accessToken, entitlementToken, puuid, activeShard),
    ]);

    final wallet = results[0] as Map<String, int>;
    final ownedInventory = results[1] as List<SkinItem>;
    final rankInfo = results[2] as RankInfo?;
    final matchHistory = results[3] as List<MatchSummary>;
    final quests = results[4] as List<QuestItem>;
    final ownedAgents = results[5] as Set<String>;
    final cardIcon = results[6] as String;
    final accountLevel = results[7] as int;

    final storeData = jsonDecode(storeRes.body);

    int parseSeconds(dynamic val) {
      if (val is num) return val.toInt();
      if (val != null) return int.tryParse(val.toString()) ?? 0;
      return 0;
    }

    int parseCost(Map<String, dynamic>? costMap) {
      if (costMap == null || costMap.isEmpty) return 0;
      final val = costMap[vpUuid] ?? costMap[vpUuidAlt] ?? costMap.values.first;
      return val is int ? val : (int.tryParse(val.toString()) ?? 0);
    }

    // 1. Daily shop (4 single-item offers)
    final singleItemOffers = storeData['SkinsPanelLayout']?['SingleItemStoreOffers'] as List? ?? [];
    final singleItemRemainingSeconds = parseSeconds(storeData['SkinsPanelLayout']?['SingleItemOffersRemainingDurationInSeconds']);

    final List<SkinItem> dailySkins = [];
    for (var offer in singleItemOffers) {
      final rewards = offer['Rewards'] as List?;
      final rewardItemId = rewards != null && rewards.isNotEmpty ? rewards[0]['ItemID'] : null;
      final offerId = rewardItemId ?? offer['OfferID'] ?? '';
      final cost = parseCost(offer['Cost'] as Map<String, dynamic>?);
      dailySkins.add(ValorantApiService.resolveSkinItem(offerId.toString(), cost));
    }

    // 2. Night Market (bonus store)
    final List<Map<String, dynamic>> nightMarketSkins = [];
    final bonusStore = storeData['BonusStore'];
    final bonusStoreRemainingSeconds = parseSeconds(bonusStore?['BonusStoreOffersRemainingDurationInSeconds']);
    if (bonusStore != null && bonusStore['BonusStoreOffers'] != null) {
      final offers = bonusStore['BonusStoreOffers'] as List;
      for (var offer in offers) {
        final offerItem = offer['Offer'];
        final rewards = offerItem?['Rewards'] as List?;
        final rewardItemId = rewards != null && rewards.isNotEmpty ? rewards[0]['ItemID'] : null;
        final offerId = rewardItemId ?? offerItem?['OfferID'] ?? '';

        final skin = ValorantApiService.resolveSkinItem(
          offerId.toString(),
          parseCost(offer['DiscountCosts'] as Map<String, dynamic>?),
        );
        nightMarketSkins.add({
          'skin': skin,
          'originalCost': parseCost(offerItem?['Cost'] as Map<String, dynamic>?),
          'discountPercent': offer['DiscountPercent'] ?? 0,
        });
      }
    }

    // 3. Featured bundles
    final List<BundleItem> bundles = [];
    final featuredBundle = storeData['FeaturedBundle'];
    if (featuredBundle != null) {
      final bundleList = featuredBundle['Bundles'] as List? ?? [featuredBundle];
      for (var b in bundleList) {
        final bundleUuid = b['DataAssetID'] ?? b['BundleID'] ?? '';
        final remainingSecs = parseSeconds(b['DurationRemainingInSeconds']);
        final itemsList = b['Items'] as List? ?? [];

        int totalCost = 0;
        final List<SkinItem> bundleSkins = [];
        for (var item in itemsList) {
          final itemId = item['Item']?['ItemID'] ?? item['ItemID'] ?? '';
          final cost = item['DiscountedPrice'] ?? item['BasePrice'] ?? 0;
          totalCost += (cost as int? ?? 0);
          if (itemId.toString().isNotEmpty) {
            bundleSkins.add(ValorantApiService.resolveSkinItem(itemId.toString(), cost is int ? cost : 0));
          }
        }

        final bundleMeta = ValorantApiService.resolveBundleMeta(bundleUuid.toString());
        bundles.add(BundleItem(
          uuid: bundleUuid.toString(),
          displayName: bundleMeta['displayName']!,
          displayIcon: bundleMeta['displayIcon']!,
          cost: totalCost,
          remainingSeconds: remainingSecs,
          items: bundleSkins,
        ));
      }
    }

    // 4. Accessory store (Kingdom Credits)
    final List<AccessoryItem> accessoryItems = [];
    final accessoryStore = storeData['AccessoryStore'];
    final accessoryStoreRemainingSeconds = parseSeconds(accessoryStore?['AccessoryStoreRemainingDurationInSeconds']);
    if (accessoryStore != null && accessoryStore['AccessoryStoreOffers'] != null) {
      final accOffers = accessoryStore['AccessoryStoreOffers'] as List;
      for (var offer in accOffers) {
        final offerItem = offer['Offer'];
        final rewards = offerItem?['Rewards'] as List?;
        final itemId = rewards != null && rewards.isNotEmpty ? rewards[0]['ItemID'] : offerItem?['OfferID'] ?? '';
        final itemTypeId = rewards != null && rewards.isNotEmpty ? rewards[0]['ItemTypeID'] : '';

        final costMap = offerItem?['Cost'] as Map<String, dynamic>?;
        final costKC = costMap?[kcUuid] ?? 0;

        accessoryItems.add(ValorantApiService.resolveAccessoryItem(
          itemId.toString(),
          itemTypeId.toString(),
          costKC is int ? costKC : 0,
        ));
      }
    }

    final profile = UserProfile(
      puuid: puuid,
      gameName: gameName,
      tagLine: tagLine,
      region: activeShard.toUpperCase(),
      vp: wallet['vp'] ?? 0,
      rad: wallet['rad'] ?? 0,
      kc: wallet['kc'] ?? 0,
      accountLevel: accountLevel,
      cardIcon: cardIcon,
    );

    return {
      'profile': profile,
      'dailySkins': dailySkins,
      'remainingSeconds': singleItemRemainingSeconds,
      'nightMarketRemainingSeconds': bonusStoreRemainingSeconds,
      'accessoryRemainingSeconds': accessoryStoreRemainingSeconds,
      'nightMarket': nightMarketSkins,
      'bundles': bundles,
      'accessories': accessoryItems,
      'inventory': ownedInventory,
      'rankInfo': rankInfo,
      'matchHistory': matchHistory,
      'quests': quests,
      'ownedAgents': ownedAgents,
    };
  }
}
