import '../models/match_summary.dart';
import '../models/rank_info.dart';
import '../models/user_profile.dart';
import '../services/valorant_api_service.dart';
import 'json_utils.dart';

/// Builds the two scoreboard team lists from raw match details.
///
/// Returns empty lists when the raw payload is missing — the UI shows an
/// honest "unavailable" state instead of fabricated players.
class MatchTeamHelper {
  static Map<String, List<Map<String, dynamic>>> generateMatchTeams({
    required MatchSummary match,
    required UserProfile? profile,
    required RankInfo? rankInfo,
  }) {
    final raw = match.rawMatchDetails;
    if (raw == null) {
      return {'teamA': const [], 'teamB': const []};
    }

    final rawPlayers = raw['players'] as List? ?? [];
    final roundResults = raw['roundResults'] as List? ?? [];
    final myPlayerObj = firstWhereOrNull(rawPlayers, (p) => p['subject'] == profile?.puuid);
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

      final tier = (p['competitiveTier'] ?? 0) as int;
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
      final adrStr = roundsPlayed > 0 ? (totalDmg / roundsPlayed).toStringAsFixed(1) : '0.0';

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
        'fk': fkMap[sub] ?? 0,
        'fd': fdMap[sub] ?? 0,
        'mk': mkMap[sub] ?? 0,
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

    return {'teamA': teamA, 'teamB': teamB};
  }
}
