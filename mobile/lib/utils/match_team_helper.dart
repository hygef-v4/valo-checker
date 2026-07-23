import 'dart:math';
import '../models/match_summary.dart';
import '../models/user_profile.dart';
import '../models/rank_info.dart';
import '../services/valorant_api_service.dart';

class MatchTeamHelper {
  static Map<String, List<Map<String, dynamic>>> generateMatchTeams({
    required MatchSummary match,
    required UserProfile? profile,
    required RankInfo? rankInfo,
    required Set<String> ownedAgents,
  }) {
    if (match.rawMatchDetails != null) {
      final rawPlayers = match.rawMatchDetails!['players'] as List? ?? [];
      final roundResults = match.rawMatchDetails!['roundResults'] as List? ?? [];
      final myPlayerObj = rawPlayers.firstWhere((p) => p['subject'] == profile?.puuid, orElse: () => null);
      final myTeamId = myPlayerObj?['teamId'] ?? 'Blue';

      final hsMap = <String, int>{};
      final bsMap = <String, int>{};
      final lsMap = <String, int>{};
      final dmgMap = <String, int>{};
      final fkMap = <String, int>{};
      final fdMap = <String, int>{};
      final mkMap = <String, int>{};

      for (var r in roundResults) {
        final playerStats = r['playerStats'] as List? ?? [];
        Map<String, dynamic>? firstKill;
        int minTime = 99999999;

        for (var ps in playerStats) {
          final sub = (ps['subject'] ?? '').toString();
          final damageList = ps['damage'] as List? ?? [];
          for (var dmg in damageList) {
            hsMap[sub] = (hsMap[sub] ?? 0) + (dmg['headshots'] as int? ?? 0);
            bsMap[sub] = (bsMap[sub] ?? 0) + (dmg['bodyshots'] as int? ?? 0);
            lsMap[sub] = (lsMap[sub] ?? 0) + (dmg['legshots'] as int? ?? 0);
            dmgMap[sub] = (dmgMap[sub] ?? 0) + (dmg['damage'] as int? ?? 0);
          }

          final killsList = ps['kills'] as List? ?? [];
          if (killsList.length >= 2) {
            mkMap[sub] = (mkMap[sub] ?? 0) + 1;
          }

          for (var kEvt in killsList) {
            final killer = (kEvt['killer'] ?? sub).toString();
            final victim = (kEvt['victim'] ?? '').toString();
            final gTime = (kEvt['gameTime'] as int? ?? 999999);

            if (gTime < minTime && killer.isNotEmpty && victim.isNotEmpty) {
              minTime = gTime;
              firstKill = kEvt;
            }
          }
        }

        if (firstKill != null) {
          final fkKiller = (firstKill['killer'] ?? '').toString();
          final fkVictim = (firstKill['victim'] ?? '').toString();
          if (fkKiller.isNotEmpty) fkMap[fkKiller] = (fkMap[fkKiller] ?? 0) + 1;
          if (fkVictim.isNotEmpty) fdMap[fkVictim] = (fdMap[fkVictim] ?? 0) + 1;
        }
      }

      final teamA = <Map<String, dynamic>>[];
      final teamB = <Map<String, dynamic>>[];

      for (var p in rawPlayers) {
        final sub = (p['subject'] ?? '').toString();
        final teamId = p['teamId'];
        final characterId = (p['characterId'] ?? '').toString();
        final agentMeta = ValorantApiService.resolveAgent(characterId);
        final agentIcon = agentMeta['displayIcon']!.isNotEmpty ? agentMeta['displayIcon']! : match.agentIcon;

        final stats = p['stats'];
        final k = (stats?['kills'] ?? 0) as int;
        final d = (stats?['deaths'] ?? 0) as int;
        final a = (stats?['assists'] ?? 0) as int;
        final score = (stats?['score'] ?? 0) as int;
        final roundsPlayed = (stats?['roundsPlayed'] ?? (roundResults.isNotEmpty ? roundResults.length : 1)) as int;
        final acs = (roundsPlayed > 0) ? (score ~/ roundsPlayed) : score;

        int tier = (p['competitiveTier'] ?? 0) as int;
        final rankMeta = ValorantApiService.resolveRankTier(tier);
        String rankName = rankMeta['tierName']!;
        if (tier == 0 && sub == profile?.puuid && rankInfo != null && rankInfo.currentTierName.isNotEmpty) {
          rankName = rankInfo.currentTierName;
        }

        final gameName = (p['gameName'] ?? p['GameName'] ?? '').toString();
        final tagLine = (p['tagLine'] ?? p['TagLine'] ?? '').toString();
        final agentName = agentMeta['displayName'] ?? 'Agent';
        final displayName = (gameName.isNotEmpty)
            ? (tagLine.isNotEmpty ? '$gameName#$tagLine' : gameName)
            : agentName;

        final hHits = hsMap[sub] ?? 0;
        final bHits = bsMap[sub] ?? 0;
        final lHits = lsMap[sub] ?? 0;
        final tHits = hHits + bHits + lHits;
        final hsPctStr = tHits > 0 ? '${((hHits / tHits) * 100).toStringAsFixed(0)}%' : '0%';
        final totalDmg = dmgMap[sub] ?? 0;
        final adrStr = roundsPlayed > 0 ? (totalDmg / roundsPlayed).toStringAsFixed(1) : (acs * 0.65).toStringAsFixed(1);

        final fkVal = fkMap[sub] ?? 0;
        final fdVal = fdMap[sub] ?? 0;
        final mkVal = mkMap[sub] ?? 0;

        final playerMap = {
          'subject': sub,
          'name': (sub == profile?.puuid) ? (profile?.riotId ?? displayName) : displayName,
          'agentIcon': agentIcon,
          'rankName': rankName,
          'acs': acs,
          'k': k,
          'd': d,
          'a': a,
          'diff': k - d,
          'kd': d > 0 ? (k / d).toStringAsFixed(1) : '$k.0',
          'adr': adrStr,
          'hs': hsPctStr,
          'fk': fkVal,
          'fd': fdVal,
          'mk': mkVal,
          'isMe': sub == profile?.puuid,
        };

        if (teamId == myTeamId) {
          teamA.add(playerMap);
        } else {
          teamB.add(playerMap);
        }
      }

      teamA.sort((a, b) => (b['acs'] as int? ?? 0).compareTo(a['acs'] as int? ?? 0));
      teamB.sort((a, b) => (b['acs'] as int? ?? 0).compareTo(a['acs'] as int? ?? 0));

      if (teamA.isNotEmpty || teamB.isNotEmpty) {
        return {'teamA': teamA, 'teamB': teamB};
      }
    }

    final rand = Random(match.matchId.hashCode);
    final agents = ValorantApiService.getPlayableAgentsList(ownedAgents);

    final playerNamesPool = [
      'ViperQueen#SEA', 'HeadshotGod#VN1', 'ShadowClutch#AP', 'SageHealer#999',
      'RadiantSmurf#777', 'ReynaMain#101', 'NeonSpeed#007', 'SovaLineups#360',
      'OmenMaster#555', 'PhoenixRising#99', 'JettEntry#VN2', 'CypherTrap#SEA',
      'FadeWatcher#JP', 'KilljoySite#KR', 'IsoShield#777', 'CloveRes#SG',
      'SkyeDog#TH', 'RazeBoom#PH', 'BrimOrb#NA', 'AstraStar#EU', 'GeckoWingman#VN'
    ];

    final ranksPool = [
      'Iron 2', 'Iron 3', 'Bronze 1', 'Bronze 2', 'Bronze 3',
      'Silver 1', 'Silver 2', 'Silver 3', 'Gold 1', 'Gold 2', 'Gold 3',
      'Platinum 1', 'Platinum 2', 'Diamond 1'
    ];

    final shuffledNames = List<String>.from(playerNamesPool)..shuffle(rand);
    final shuffledRanks = List<String>.from(ranksPool)..shuffle(rand);

    String getAgentIcon(int offset) {
      if (agents.isNotEmpty) {
        final idx = (rand.nextInt(agents.length) + offset) % agents.length;
        final icon = agents[idx]['displayIcon'] as String? ?? '';
        if (icon.isNotEmpty) return icon;
      }
      return match.agentIcon;
    }

    final myPlayer = {
      'subject': profile?.puuid ?? '',
      'name': profile?.riotId ?? 'Player',
      'agentIcon': match.agentIcon,
      'rankName': rankInfo?.currentTierName ?? 'Unranked',
      'acs': (match.kills * 24) + (match.assists * 10),
      'k': match.kills,
      'd': match.deaths,
      'a': match.assists,
      'diff': match.kills - match.deaths,
      'kd': match.deaths > 0 ? (match.kills / match.deaths).toStringAsFixed(1) : match.kills.toStringAsFixed(1),
      'adr': ((match.kills * 24 + match.assists * 10) * 0.65).toStringAsFixed(1),
      'hs': '${12 + rand.nextInt(25)}%',
      'fk': rand.nextInt(4),
      'fd': rand.nextInt(4),
      'mk': rand.nextInt(3),
      'isMe': true,
    };

    final teamA = <Map<String, dynamic>>[myPlayer];
    for (int i = 0; i < 4; i++) {
      final k = 5 + rand.nextInt(18);
      final d = 6 + rand.nextInt(18);
      final a = 1 + rand.nextInt(12);
      final acs = (k * 22) + (a * 9) + rand.nextInt(40);
      teamA.add({
        'subject': 'bot_a_$i',
        'name': shuffledNames[i],
        'agentIcon': getAgentIcon(i * 3 + 1),
        'rankName': shuffledRanks[i],
        'acs': acs,
        'k': k,
        'd': d,
        'a': a,
        'diff': k - d,
        'kd': d > 0 ? (k / d).toStringAsFixed(1) : '$k.0',
        'adr': (acs * 0.65).toStringAsFixed(1),
        'hs': '${8 + rand.nextInt(28)}%',
        'fk': rand.nextInt(4),
        'fd': rand.nextInt(4),
        'mk': rand.nextInt(3),
        'isMe': false,
      });
    }

    final teamB = <Map<String, dynamic>>[];
    for (int i = 0; i < 5; i++) {
      final k = 6 + rand.nextInt(20);
      final d = 5 + rand.nextInt(18);
      final a = 2 + rand.nextInt(10);
      final acs = (k * 22) + (a * 9) + rand.nextInt(50);
      teamB.add({
        'subject': 'bot_b_$i',
        'name': shuffledNames[i + 4],
        'agentIcon': getAgentIcon(i * 3 + 2),
        'rankName': shuffledRanks[i + 4],
        'acs': acs,
        'k': k,
        'd': d,
        'a': a,
        'diff': k - d,
        'kd': d > 0 ? (k / d).toStringAsFixed(1) : '$k.0',
        'adr': (acs * 0.65).toStringAsFixed(1),
        'hs': '${10 + rand.nextInt(25)}%',
        'fk': rand.nextInt(4),
        'fd': rand.nextInt(4),
        'mk': rand.nextInt(3),
        'isMe': false,
      });
    }

    teamA.sort((a, b) => (b['acs'] as int? ?? 0).compareTo(a['acs'] as int? ?? 0));
    teamB.sort((a, b) => (b['acs'] as int? ?? 0).compareTo(a['acs'] as int? ?? 0));

    return {'teamA': teamA, 'teamB': teamB};
  }
}
