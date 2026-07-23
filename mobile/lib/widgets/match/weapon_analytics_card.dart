import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/match_summary.dart';
import '../../services/valorant_api_service.dart';

class WeaponAnalyticsCard extends StatelessWidget {
  final List<MatchSummary> matchHistory;
  final String userPuuid;

  const WeaponAnalyticsCard({
    super.key,
    required this.matchHistory,
    required this.userPuuid,
  });

  @override
  Widget build(BuildContext context) {
    final weaponKills = <String, int>{};
    final weaponHeadshots = <String, int>{};
    final weaponTotalHits = <String, int>{};

    for (var match in matchHistory) {
      if (match.rawMatchDetails == null) continue;
      final roundResults = match.rawMatchDetails!['roundResults'] as List? ?? [];

      for (var r in roundResults) {
        final playerStats = r['playerStats'] as List? ?? [];
        for (var ps in playerStats) {
          final sub = (ps['subject'] ?? '').toString();
          if (sub == userPuuid) {
            final kills = ps['kills'] as List? ?? [];
            for (var kEvt in kills) {
              final finDmg = kEvt['finishingDamage'];
              final wUuid = (finDmg?['damageItem'] ?? '').toString();
              if (wUuid.isNotEmpty) {
                weaponKills[wUuid] = (weaponKills[wUuid] ?? 0) + 1;
              }
            }

            final damageList = ps['damage'] as List? ?? [];
            for (var dmg in damageList) {
              final hs = (dmg['headshots'] as int? ?? 0);
              final bs = (dmg['bodyshots'] as int? ?? 0);
              final ls = (dmg['legshots'] as int? ?? 0);
              final hits = hs + bs + ls;

              final wUuid = (dmg['damageItem'] ?? '').toString();
              if (wUuid.isNotEmpty) {
                weaponHeadshots[wUuid] = (weaponHeadshots[wUuid] ?? 0) + hs;
                weaponTotalHits[wUuid] = (weaponTotalHits[wUuid] ?? 0) + hits;
              }
            }
          }
        }
      }
    }

    final sortedWeapons = weaponKills.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topWeapons = sortedWeapons.take(5).toList();

    if (topWeapons.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalTopKills = topWeapons.fold<int>(0, (sum, e) => sum + e.value);

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
                'WEAPON PERFORMANCE MASTERY',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.0),
              ),
              Icon(Icons.sports_esports, color: Colors.amber, size: 18),
            ],
          ),
          const SizedBox(height: 14),
          ...topWeapons.map((entry) {
            final wUuid = entry.key;
            final kills = entry.value;
            final wMeta = ValorantApiService.resolveWeapon(wUuid);
            final name = wMeta['displayName'] ?? 'Weapon';
            final icon = wMeta['displayIcon'] ?? '';

            final hits = weaponTotalHits[wUuid] ?? 0;
            final hs = weaponHeadshots[wUuid] ?? 0;
            final hsPct = hits > 0 ? ((hs / hits) * 100).toStringAsFixed(0) : '0';
            final killShare = totalTopKills > 0 ? kills / totalTopKills : 0.0;

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
                  Container(
                    width: 60,
                    height: 30,
                    alignment: Alignment.center,
                    child: icon.isNotEmpty
                        ? CachedNetworkImage(imageUrl: icon, fit: BoxFit.contain, errorWidget: (c, u, e) => const Icon(Icons.shield, color: Colors.white38, size: 20))
                        : const Icon(Icons.shield, color: Colors.white38, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            Text('$kills Kills ($hsPct% HS)', style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.w900, fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: killShare,
                            minHeight: 4,
                            backgroundColor: Colors.white10,
                            color: const Color(0xFFFF4655),
                          ),
                        ),
                      ],
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
