import 'package:flutter/material.dart';
import '../../models/match_summary.dart';
import '../../utils/json_utils.dart';
import '../common/data_unavailable.dart';

class MatchEconomyTab extends StatelessWidget {
  final MatchSummary match;
  final String userPuuid;

  const MatchEconomyTab({
    super.key,
    required this.match,
    required this.userPuuid,
  });

  @override
  Widget build(BuildContext context) {
    int totalLoadout = 0;
    int loadoutRounds = 0;
    int ecoTotal = 0;
    int ecoWins = 0;
    int fullBuyTotal = 0;
    int fullBuyWins = 0;

    if (match.rawMatchDetails != null) {
      final roundResults = match.rawMatchDetails!['roundResults'] as List? ?? [];
      final rawPlayers = match.rawMatchDetails!['players'] as List? ?? [];
      final myPlayerObj = firstWhereOrNull(rawPlayers, (p) => p['subject'] == userPuuid);
      final myTeamId = myPlayerObj?['teamId'] ?? 'Blue';

      for (var r in roundResults) {
        final winningTeam = (r['winningTeam'] ?? '').toString();
        final playerStats = r['playerStats'] as List? ?? [];
        for (var ps in playerStats) {
          if (ps['subject'] == userPuuid) {
            final eco = ps['economy'];
            if (eco != null && eco['loadoutValue'] != null) {
              final lv = (eco['loadoutValue'] as int? ?? 0);
              totalLoadout += lv;
              loadoutRounds++;

              if (lv <= 2000) {
                ecoTotal++;
                if (winningTeam == myTeamId) ecoWins++;
              } else if (lv >= 3900) {
                fullBuyTotal++;
                if (winningTeam == myTeamId) fullBuyWins++;
              }
            }
          }
        }
      }
    }

    if (loadoutRounds == 0) {
      return const DataUnavailable(
        message: 'Economy data is unavailable for this match.',
      );
    }

    final avgLoadoutVal = totalLoadout ~/ loadoutRounds;
    final ecoWinPctStr = ecoTotal > 0 ? '${((ecoWins / ecoTotal) * 100).toStringAsFixed(0)}%' : '—';
    final fullBuyWinPctStr = fullBuyTotal > 0 ? '${((fullBuyWins / fullBuyTotal) * 100).toStringAsFixed(0)}%' : '—';
    final efficiencyText = match.kills > 0
        ? 'Spend Efficiency: \$${totalLoadout ~/ match.kills} per kill. Calculated across all played rounds.'
        : 'Spend Efficiency: no kills recorded this match.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF121218),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ECONOMY & SPENDING RATINGS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.0)),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildEcoStatItem('AVG LOADOUT', '\$$avgLoadoutVal', 'Average Round Buy'),
                  _buildEcoStatItem('ECO WIN %', ecoWinPctStr, 'Save Rounds ($ecoWins/$ecoTotal)'),
                  _buildEcoStatItem('FULL BUY WIN %', fullBuyWinPctStr, 'Full Weapon ($fullBuyWins/$fullBuyTotal)'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF121218),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              const Icon(Icons.monetization_on, color: Colors.amber, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  efficiencyText,
                  style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEcoStatItem(String title, String val, String sub) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.w900, fontSize: 16)),
        const SizedBox(height: 2),
        Text(sub, style: const TextStyle(color: Colors.white54, fontSize: 9)),
      ],
    );
  }
}
