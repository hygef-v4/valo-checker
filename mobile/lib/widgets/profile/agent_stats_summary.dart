import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/match_summary.dart';

class AgentStatsSummary extends StatelessWidget {
  final List<MatchSummary> matchHistory;

  const AgentStatsSummary({
    super.key,
    required this.matchHistory,
  });

  @override
  Widget build(BuildContext context) {
    final agentStats = <String, Map<String, dynamic>>{};

    for (var match in matchHistory) {
      final name = match.agentName.isNotEmpty ? match.agentName : 'Agent';
      final icon = match.agentIcon;

      agentStats.putIfAbsent(name, () => {
        'name': name,
        'icon': icon,
        'matches': 0,
        'wins': 0,
        'kills': 0,
        'deaths': 0,
        'assists': 0,
      });

      final stat = agentStats[name]!;
      stat['matches'] = (stat['matches'] as int) + 1;
      if (match.isVictory) stat['wins'] = (stat['wins'] as int) + 1;
      stat['kills'] = (stat['kills'] as int) + match.kills;
      stat['deaths'] = (stat['deaths'] as int) + match.deaths;
      stat['assists'] = (stat['assists'] as int) + match.assists;
    }

    final sortedAgents = agentStats.values.toList()
      ..sort((a, b) => (b['matches'] as int).compareTo(a['matches'] as int));

    if (sortedAgents.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121218),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'AGENT PERFORMANCE & WIN RATES',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.0),
              ),
              Icon(Icons.stars, color: Color(0xFF34D399), size: 18),
            ],
          ),
          const SizedBox(height: 14),
          ...sortedAgents.take(4).map((stat) {
            final name = stat['name'].toString();
            final icon = stat['icon'].toString();
            final matches = stat['matches'] as int;
            final wins = stat['wins'] as int;
            final kills = stat['kills'] as int;
            final deaths = stat['deaths'] as int;

            final winRate = matches > 0 ? ((wins / matches) * 100).toStringAsFixed(0) : '0';
            final kd = deaths > 0 ? (kills / deaths).toStringAsFixed(2) : '$kills.0';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: icon.isNotEmpty
                        ? CachedNetworkImage(imageUrl: icon, width: 36, height: 36, fit: BoxFit.cover, errorWidget: (c, u, e) => const Icon(Icons.person, color: Colors.white38))
                        : const Icon(Icons.person, color: Colors.white38),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text('$matches Matches • K/D $kd', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (wins / matches >= 0.5) ? const Color(0xFF34D399).withValues(alpha: 0.2) : const Color(0xFFFF4655).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$winRate% WR',
                      style: TextStyle(
                        color: (wins / matches >= 0.5) ? const Color(0xFF34D399) : const Color(0xFFFF4655),
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
