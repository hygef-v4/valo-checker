import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/match_summary.dart';
import '../common/data_unavailable.dart';

class MatchDuelsTab extends StatelessWidget {
  final MatchSummary match;
  final Map<String, List<Map<String, dynamic>>> teams;
  final String userPuuid;

  const MatchDuelsTab({
    super.key,
    required this.match,
    required this.teams,
    required this.userPuuid,
  });

  @override
  Widget build(BuildContext context) {
    final enemyTeam = teams['teamB'] ?? [];
    final duelsMap = <String, Map<String, int>>{};

    if (match.rawMatchDetails != null) {
      final roundResults = match.rawMatchDetails!['roundResults'] as List? ?? [];

      for (var r in roundResults) {
        final playerStats = r['playerStats'] as List? ?? [];
        for (var ps in playerStats) {
          final killsList = ps['kills'] as List? ?? [];
          for (var kEvt in killsList) {
            final killer = (kEvt['killer'] ?? ps['subject'] ?? '').toString();
            final victim = (kEvt['victim'] ?? '').toString();

            if (killer == userPuuid && victim.isNotEmpty) {
              duelsMap.putIfAbsent(victim, () => {'kills': 0, 'deaths': 0})['kills'] =
                  (duelsMap[victim]!['kills']! + 1);
            } else if (victim == userPuuid && killer.isNotEmpty) {
              duelsMap.putIfAbsent(killer, () => {'kills': 0, 'deaths': 0})['deaths'] =
                  (duelsMap[killer]!['deaths']! + 1);
            }
          }
        }
      }
    }

    if (match.rawMatchDetails == null || enemyTeam.isEmpty) {
      return const DataUnavailable(
        message: 'Duel data is unavailable for this match.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('1v1 HEAD-TO-HEAD DUELS MATRIX', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.0)),
        const SizedBox(height: 10),
        ...enemyTeam.map((e) {
          final enemySub = (e['subject'] ?? '').toString();
          final kills = duelsMap[enemySub]?['kills'] ?? 0;
          final deaths = duelsMap[enemySub]?['deaths'] ?? 0;

          final isWin = kills >= deaths;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF121218),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: match.agentIcon.isNotEmpty
                      ? CachedNetworkImage(imageUrl: match.agentIcon, width: 28, height: 28, fit: BoxFit.cover)
                      : const Icon(Icons.person, color: Colors.white54),
                ),
                const SizedBox(width: 8),
                const Text('VS', style: TextStyle(color: Colors.white38, fontWeight: FontWeight.w900, fontSize: 11)),
                const SizedBox(width: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: CachedNetworkImage(imageUrl: e['agentIcon'].toString(), width: 28, height: 28, fit: BoxFit.cover),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e['name'].toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      Text(e['rankName'].toString(), style: const TextStyle(color: Colors.white54, fontSize: 10)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isWin ? const Color(0xFF34D399).withValues(alpha: 0.2) : const Color(0xFFFF4655).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$kills - $deaths',
                    style: TextStyle(
                      color: isWin ? const Color(0xFF34D399) : const Color(0xFFFF4655),
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
