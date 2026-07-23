import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_profile.dart';
import '../models/skin_item.dart';
import '../models/bundle_item.dart';
import '../models/accessory_item.dart';
import '../models/rank_info.dart';
import '../models/match_summary.dart';
import '../models/quest_item.dart';
import 'valorant_api_service.dart';

class RiotAuthService {
  static const String vpUuid = '85ad13f7-3d1b-da12-a0a0-4e907616386c';
  static const String kcUuid = '85ca954a-41f2-ce94-9b45-8ca3dd39a00d';
  static const String radUuid = 'e59aa87c-4c57-90ab-d663-2a4895203a25';
  static const String clientPlatform =
      'ew0KCSJwbGF0Zm9ybVR5cGUiOiAiUEMiLA0KCSJwbGF0Zm9ybU9TIjogIldpbmRvd3MiLA0KCSJwbGF0Zm9ybU9TVmVyc2lvbiI6ICIxMC4wLjE5MDQyLjEuMjU2LjY4Yml0IiwNCgkicGxhdGZvcm1CYXNlT1MiOiAiV2luZG93cyINCn0=';

  static Future<String> getEntitlements(String accessToken) async {
    final res = await http.post(
      Uri.parse('https://entitlements.auth.riotgames.com/api/token/v1'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({}),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to get entitlements token (Status: ${res.statusCode})');
    }

    final data = jsonDecode(res.body);
    return data['entitlements_token'] ?? '';
  }

  static Future<Map<String, dynamic>> getUserInfo(String accessToken) async {
    final res = await http.get(
      Uri.parse('https://auth.riotgames.com/userinfo'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to get userinfo (Status: ${res.statusCode})');
    }

    return jsonDecode(res.body);
  }

  static Future<String> getClientVersion() async {
    try {
      final res = await http.get(Uri.parse('https://valorant-api.com/v1/version'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['data']['riotClientVersion'] ?? '96.0.2.2359.4393';
      }
    } catch (_) {}
    return '96.0.2.2359.4393';
  }

  static Future<String> getRiotGeo(String accessToken, String idToken, String entitlementToken) async {
    try {
      final res = await http.put(
        Uri.parse('https://riot-geo.pas.si.riotgames.com/pas/v1/product/valorant'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'X-Riot-Entitlements-JWT': entitlementToken,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'id_token': idToken,
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final liveAffinity = data['affinities']?['live'] ?? 'ap';
        return liveAffinity.toString().toLowerCase().split('-')[0];
      }
    } catch (_) {}
    return 'ap';
  }

  static Future<Map<String, int>> getWallet(String accessToken, String entitlementToken, String puuid, String shard) async {
    final clientVersion = await getClientVersion();
    int vp = 0;
    int rad = 0;
    int kc = 0;

    try {
      final res = await http.get(
        Uri.parse('https://pd.$shard.a.pvp.net/store/v1/wallet/$puuid'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'X-Riot-Entitlements-JWT': entitlementToken,
          'X-Riot-ClientVersion': clientVersion,
          'X-Riot-ClientPlatform': clientPlatform,
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final balances = data['Balances'] as Map<String, dynamic>?;
        if (balances != null) {
          vp = balances[vpUuid] ?? balances['85ad13f7-3d1b-5128-9eb2-7cd8ee0b5741'] ?? 0;
          rad = balances[radUuid] ?? 0;
          kc = balances[kcUuid] ?? balances['85ca954a-41f2-ce94-9b45-8ca3dd39a00d'] ?? 0;
        }
      }
    } catch (_) {}

    return {'vp': vp, 'rad': rad, 'kc': kc};
  }

  static Future<Set<String>> fetchOwnedAgents(String accessToken, String entitlementToken, String puuid, String shard) async {
    final clientVersion = await getClientVersion();
    Set<String> ownedAgentUuids = {};

    // 1. Fetch entitlements
    try {
      final res = await http.get(
        Uri.parse('https://pd.$shard.a.pvp.net/store/v1/entitlements/$puuid/01bb38e1-da47-4e6a-9b3d-945fe4655707'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'X-Riot-Entitlements-JWT': entitlementToken,
          'X-Riot-ClientVersion': clientVersion,
          'X-Riot-ClientPlatform': clientPlatform,
        },
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
    } catch (_) {}

    // 2. Fetch contracts / unlocked characters
    try {
      final contractRes = await http.get(
        Uri.parse('https://pd.$shard.a.pvp.net/contracts/v1/contracts/$puuid'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'X-Riot-Entitlements-JWT': entitlementToken,
          'X-Riot-ClientVersion': clientVersion,
          'X-Riot-ClientPlatform': clientPlatform,
        },
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
    } catch (_) {}

    return ownedAgentUuids;
  }

  static Future<String> fetchPlayerCard(String accessToken, String entitlementToken, String puuid, String shard) async {
    final clientVersion = await getClientVersion();
    try {
      final res = await http.get(
        Uri.parse('https://pd.$shard.a.pvp.net/personalization/v2/players/$puuid/playerloadout'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'X-Riot-Entitlements-JWT': entitlementToken,
          'X-Riot-ClientVersion': clientVersion,
          'X-Riot-ClientPlatform': clientPlatform,
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final cardUuid = (data['Identity']?['PlayerCardID'] ?? '').toString();
        if (cardUuid.isNotEmpty) {
          return ValorantApiService.resolvePlayerCard(cardUuid);
        }
      }
    } catch (_) {}

    return '';
  }

  static Future<int> fetchAccountLevel(String accessToken, String entitlementToken, String puuid, String shard) async {
    final clientVersion = await getClientVersion();
    try {
      final res = await http.get(
        Uri.parse('https://pd.$shard.a.pvp.net/account-xp/v1/players/$puuid'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'X-Riot-Entitlements-JWT': entitlementToken,
          'X-Riot-ClientVersion': clientVersion,
          'X-Riot-ClientPlatform': clientPlatform,
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final level = data['Progress']?['Level'] as int? ?? 1;
        return level;
      }
    } catch (_) {}
    return 1;
  }

  static Future<List<SkinItem>> fetchOwnedInventory(String accessToken, String entitlementToken, String puuid, String shard) async {
    final clientVersion = await getClientVersion();
    List<SkinItem> ownedSkins = [];

    try {
      final res = await http.get(
        Uri.parse('https://pd.$shard.a.pvp.net/store/v1/entitlements/$puuid/e7c63390-eda7-46e0-bb7a-a6abdacd2433'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'X-Riot-Entitlements-JWT': entitlementToken,
          'X-Riot-ClientVersion': clientVersion,
          'X-Riot-ClientPlatform': clientPlatform,
        },
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
    } catch (_) {}

    return ownedSkins;
  }

  static Future<RankInfo?> fetchRankInfo(String accessToken, String entitlementToken, String puuid, String shard) async {
    final clientVersion = await getClientVersion();
    try {
      final mmrRes = await http.get(
        Uri.parse('https://pd.$shard.a.pvp.net/mmr/v1/players/$puuid'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'X-Riot-Entitlements-JWT': entitlementToken,
          'X-Riot-ClientVersion': clientVersion,
          'X-Riot-ClientPlatform': clientPlatform,
        },
      );

      final updatesRes = await http.get(
        Uri.parse('https://pd.$shard.a.pvp.net/mmr/v1/players/$puuid/competitiveupdates?startIndex=0&endIndex=20'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'X-Riot-Entitlements-JWT': entitlementToken,
          'X-Riot-ClientVersion': clientVersion,
          'X-Riot-ClientPlatform': clientPlatform,
        },
      );

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
              final wins = season['NumberOfWins'] as int? ?? 0;
              final games = season['NumberOfGames'] as int? ?? 0;

              totalWins += wins;
              totalGames += games;

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
          final rrMovement = m['RankedRatingEarned'] as int? ?? (m['RankedRatingAfterUpdate'] - m['RankedRatingBeforeUpdate']);
          final rrAfter = m['RankedRatingAfterUpdate'] as int? ?? 0;
          final mapId = m['MapID'] ?? '';
          final matchTime = m['MatchStartTime'] as int? ?? 0;

          // Find the most recent COMPETITIVE match where tierAfter > 0 (skipping unrated matches)
          if (tierAfter > 0 && lastCompetitiveTier == 0) {
            lastCompetitiveTier = tierAfter;
            lastCompetitiveRR = rrAfter;
          }

          if (tierAfter > peakTier) {
            peakTier = tierAfter;
          }

          if (rrMovement > 0) totalWins++;
          totalGames++;

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

      // Priority 1: Most recent competitive match tier from updates (skipping unrated 0-tier matches)
      if (lastCompetitiveTier > 0) {
        currentTier = lastCompetitiveTier;
        currentRR = lastCompetitiveRR;
      } else if (latestRankedTier > 0) {
        // Priority 2: Latest non-zero seasonal tier
        currentTier = latestRankedTier;
        currentRR = latestRankedRR;
      } else if (peakTier > 0) {
        // Priority 3: Fallback to Peak Tier if all recent games are unrated
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
        totalWins: totalWins > 0 ? totalWins : 5,
        totalGames: totalGames > 0 ? totalGames : 8,
        updates: updates,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<List<MatchSummary>> fetchMatchHistory(String accessToken, String entitlementToken, String puuid, String shard) async {
    final clientVersion = await getClientVersion();
    List<MatchSummary> matches = [];

    try {
      final historyRes = await http.get(
        Uri.parse('https://pd.$shard.a.pvp.net/match-history/v1/history/$puuid?startIndex=0&endIndex=20'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'X-Riot-Entitlements-JWT': entitlementToken,
          'X-Riot-ClientVersion': clientVersion,
          'X-Riot-ClientPlatform': clientPlatform,
        },
      );

      if (historyRes.statusCode == 200) {
        final historyData = jsonDecode(historyRes.body);
        final historyList = historyData['History'] as List? ?? [];
        final recentMatches = historyList.take(20).toList();

        final detailFutures = recentMatches.map((h) {
          final matchId = h['MatchID'] ?? '';
          if (matchId.toString().isEmpty) return Future<http.Response?>.value(null);
          return http.get(
            Uri.parse('https://pd.$shard.a.pvp.net/match-details/v1/matches/$matchId'),
            headers: {
              'Authorization': 'Bearer $accessToken',
              'X-Riot-Entitlements-JWT': entitlementToken,
              'X-Riot-ClientVersion': clientVersion,
              'X-Riot-ClientPlatform': clientPlatform,
            },
          ).then<http.Response?>((res) => res).catchError((_) => null);
        }).toList();

        final responses = await Future.wait(detailFutures);

        // Batch resolve player PUUIDs via Riot Name Service
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
            } catch (_) {}
          }
        }

        final Map<String, Map<String, String>> resolvedNames = {};
        if (puuidSet.isNotEmpty) {
          try {
            final url = Uri.parse('https://pd.$shard.a.pvp.net/name-service/v2/players');
            var nameRes = await http.put(
              url,
              headers: {
                'Authorization': 'Bearer $accessToken',
                'X-Riot-Entitlements-JWT': entitlementToken,
                'X-Riot-ClientVersion': clientVersion,
                'X-Riot-ClientPlatform': clientPlatform,
                'Content-Type': 'application/json',
              },
              body: jsonEncode(puuidSet.toList()),
            );

            if (nameRes.statusCode != 200) {
              nameRes = await http.post(
                url,
                headers: {
                  'Authorization': 'Bearer $accessToken',
                  'X-Riot-Entitlements-JWT': entitlementToken,
                  'X-Riot-ClientVersion': clientVersion,
                  'X-Riot-ClientPlatform': clientPlatform,
                  'Content-Type': 'application/json',
                },
                body: jsonEncode(puuidSet.toList()),
              );
            }

            if (nameRes.statusCode == 200) {
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
                  resolvedNames[sub] = {
                    'gameName': gName,
                    'tagLine': tLine,
                  };
                }
              }
            }
          } catch (_) {}
        }

        for (var matchRes in responses) {
          if (matchRes != null && matchRes.statusCode == 200) {
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

            final playerObj = players.firstWhere(
              (p) => p['subject'] == puuid,
              orElse: () => null,
            );

            if (playerObj != null) {
              final playerTeam = playerObj['teamId'];
              final characterId = playerObj['characterId'] ?? '';
              final stats = playerObj['stats'];

              final kills = stats?['kills'] ?? 0;
              final deaths = stats?['deaths'] ?? 0;
              final assists = stats?['assists'] ?? 0;

              final teamObj = teams.firstWhere(
                (t) => t['teamId'] == playerTeam,
                orElse: () => null,
              );

              final isWon = teamObj?['won'] ?? false;
              final roundsWon = teamObj?['roundsWon'] ?? 0;

              final enemyTeam = teams.firstWhere(
                (t) => t['teamId'] != playerTeam,
                orElse: () => null,
              );
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
          }
        }
      }
    } catch (_) {}

    return matches;
  }

  static Future<List<QuestItem>> fetchQuestsAndBattlePass(String accessToken, String entitlementToken, String puuid, String shard) async {
    final clientVersion = await getClientVersion();
    List<QuestItem> quests = [];

    try {
      final res = await http.get(
        Uri.parse('https://pd.$shard.a.pvp.net/contracts/v1/contracts/$puuid'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'X-Riot-Entitlements-JWT': entitlementToken,
          'X-Riot-ClientVersion': clientVersion,
          'X-Riot-ClientPlatform': clientPlatform,
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final activeQuests = data['Missions'] as List? ?? [];

        for (var q in activeQuests) {
          final isComplete = q['Complete'] ?? false;
          final objectives = q['Objectives'] as Map<String, dynamic>?;
          int currentProg = 0;
          int targetProg = 1;
          if (objectives != null && objectives.isNotEmpty) {
            currentProg = objectives.values.first as int? ?? 0;
            targetProg = 100;
          }

          quests.add(QuestItem(
            title: 'Daily / Weekly Mission',
            description: isComplete ? 'Completed' : 'In Progress',
            currentProgress: currentProg,
            targetProgress: targetProg,
            rewardXP: 2000,
            isCompleted: isComplete,
          ));
        }
      }
    } catch (_) {}

    return quests;
  }

  static Future<Map<String, dynamic>> fetchStorefrontData(String accessToken, String idToken) async {
    final entitlementTokenFuture = getEntitlements(accessToken);
    final userInfoFuture = getUserInfo(accessToken);
    final metadataFuture = ValorantApiService.loadMetadataCache();

    final entitlementToken = await entitlementTokenFuture;
    final userInfo = await userInfoFuture;
    await metadataFuture;

    final puuid = userInfo['sub'] ?? '';
    final acct = userInfo['acct'] as Map<String, dynamic>?;
    final gameName = acct?['game_name'] ?? 'Agent';
    final tagLine = acct?['tag_line'] ?? 'VALO';

    final clientVersion = await getClientVersion();
    String detectedShard = await getRiotGeo(accessToken, idToken, entitlementToken);

    http.Response? storeRes;
    final shardsToTry = {detectedShard, 'ap', 'eu', 'na', 'kr'}.toList();
    String activeShard = detectedShard;
    int lastStatus = 0;
    String lastError = '';

    for (var s in shardsToTry) {
      try {
        final res = await http.post(
          Uri.parse('https://pd.$s.a.pvp.net/store/v3/storefront/$puuid'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'X-Riot-Entitlements-JWT': entitlementToken,
            'X-Riot-ClientVersion': clientVersion,
            'X-Riot-ClientPlatform': clientPlatform,
            'Content-Type': 'application/json',
          },
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

    if (storeRes == null || storeRes.statusCode != 200) {
      final statusInfo = storeRes != null ? 'Status: ${storeRes.statusCode}' : (lastStatus > 0 ? 'Status: $lastStatus' : lastError);
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

    // 1. Parse Single Item Offers (Daily Shop 4 skins)
    final singleItemOffers = storeData['SkinsPanelLayout']?['SingleItemStoreOffers'] as List? ?? [];
    final singleItemRemainingSeconds = storeData['SkinsPanelLayout']?['SingleItemOffersRemainingDurationInSeconds'] ?? 86400;

    List<SkinItem> dailySkins = [];
    for (var offer in singleItemOffers) {
      final rewards = offer['Rewards'] as List?;
      final rewardItemId = rewards != null && rewards.isNotEmpty ? rewards[0]['ItemID'] : null;
      final offerId = rewardItemId ?? offer['OfferID'] ?? '';

      final costMap = offer['Cost'] as Map<String, dynamic>?;
      final cost = costMap?[vpUuid] ??
          costMap?['85ad13f7-3d1b-da12-a0a0-4e907616386c'] ??
          costMap?['85ad13f7-3d1b-5128-9eb2-7cd8ee0b5741'] ??
          0;

      dailySkins.add(ValorantApiService.resolveSkinItem(offerId.toString(), cost is int ? cost : (int.tryParse(cost.toString()) ?? 0)));
    }

    // 2. Parse Night Market (Bonus Store)
    List<Map<String, dynamic>> nightMarketSkins = [];
    final bonusStore = storeData['BonusStore'];
    if (bonusStore != null && bonusStore['BonusStoreOffers'] != null) {
      final offers = bonusStore['BonusStoreOffers'] as List;
      for (var offer in offers) {
        final offerItem = offer['Offer'];
        final rewards = offerItem?['Rewards'] as List?;
        final rewardItemId = rewards != null && rewards.isNotEmpty ? rewards[0]['ItemID'] : null;
        final offerId = rewardItemId ?? offerItem?['OfferID'] ?? '';

        final discountPercent = offer['DiscountPercent'] ?? 0;
        final discountCosts = offer['DiscountCosts'] as Map<String, dynamic>?;
        final originalCosts = offerItem?['Cost'] as Map<String, dynamic>?;

        int getCost(Map<String, dynamic>? costMap) {
          if (costMap == null || costMap.isEmpty) return 0;
          final val = costMap[vpUuid] ??
              costMap['85ad13f7-3d1b-da12-a0a0-4e907616386c'] ??
              costMap['85ad13f7-3d1b-5128-9eb2-7cd8ee0b5741'] ??
              costMap.values.first;
          return val is int ? val : (int.tryParse(val.toString()) ?? 0);
        }

        final discountedCost = getCost(discountCosts);
        final originalCost = getCost(originalCosts);

        final skin = ValorantApiService.resolveSkinItem(offerId.toString(), discountedCost);
        nightMarketSkins.add({
          'skin': skin,
          'originalCost': originalCost,
          'discountPercent': discountPercent,
        });
      }
    }

    // 3. Parse Featured Bundles
    List<BundleItem> bundles = [];
    final featuredBundle = storeData['FeaturedBundle'];
    if (featuredBundle != null) {
      final bundleList = featuredBundle['Bundles'] as List? ?? [featuredBundle];
      for (var b in bundleList) {
        final bundleUuid = b['DataAssetID'] ?? b['BundleID'] ?? '';
        final remainingSecs = b['DurationRemainingInSeconds'] ?? 604800;
        final itemsList = b['Items'] as List? ?? [];

        int totalCost = 0;
        List<SkinItem> bundleSkins = [];
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
          cost: totalCost > 0 ? totalCost : 7100,
          remainingSeconds: remainingSecs is int ? remainingSecs : 604800,
          items: bundleSkins,
        ));
      }
    }

    // 4. Parse Accessory Store (Kingdom Credits)
    List<AccessoryItem> accessoryItems = [];
    final accessoryStore = storeData['AccessoryStore'];
    if (accessoryStore != null && accessoryStore['AccessoryStoreOffers'] != null) {
      final accOffers = accessoryStore['AccessoryStoreOffers'] as List;
      for (var offer in accOffers) {
        final offerItem = offer['Offer'];
        final rewards = offerItem?['Rewards'] as List?;
        final itemId = rewards != null && rewards.isNotEmpty ? rewards[0]['ItemID'] : offerItem?['OfferID'] ?? '';
        final itemTypeId = rewards != null && rewards.isNotEmpty ? rewards[0]['ItemTypeID'] : '';

        final costMap = offerItem?['Cost'] as Map<String, dynamic>?;
        final costKC = costMap?[kcUuid] ?? costMap?['85ca954a-41f2-ce94-9b45-8ca3dd39a00d'] ?? 4000;

        accessoryItems.add(ValorantApiService.resolveAccessoryItem(
          itemId.toString(),
          itemTypeId.toString(),
          costKC is int ? costKC : 4000,
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

  static Future<Map<String, dynamic>?> fetchMatchDetails(
      String accessToken, String entitlementToken, String puuid, String shard, String matchId) async {
    final clientVersion = await getClientVersion();
    try {
      final res = await http.get(
        Uri.parse('https://pd.$shard.a.pvp.net/match-details/v1/matches/$matchId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'X-Riot-Entitlements-JWT': entitlementToken,
          'X-Riot-ClientVersion': clientVersion,
          'X-Riot-ClientPlatform': clientPlatform,
        },
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, String>> fetchPlayerNames(
      String accessToken, String entitlementToken, String shard, List<String> puuids) async {
    final clientVersion = await getClientVersion();
    try {
      final res = await http.put(
        Uri.parse('https://pd.$shard.a.pvp.net/name-service/v2/players'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'X-Riot-Entitlements-JWT': entitlementToken,
          'X-Riot-ClientVersion': clientVersion,
          'X-Riot-ClientPlatform': clientPlatform,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(puuids),
      );

      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        final Map<String, String> namesMap = {};
        for (var item in list) {
          final subject = item['Subject'] as String?;
          final gameName = item['GameName'] as String?;
          final tagLine = item['TagLine'] as String?;
          if (subject != null && gameName != null && gameName.isNotEmpty) {
            namesMap[subject] = tagLine != null && tagLine.isNotEmpty ? '$gameName#$tagLine' : gameName;
          }
        }
        return namesMap;
      }
    } catch (_) {}
    return {};
  }
}
