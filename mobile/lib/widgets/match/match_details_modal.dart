import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/match_summary.dart';
import '../../models/user_profile.dart';
import '../../utils/json_utils.dart';
import 'match_scoreboard_tab.dart';
import 'match_performance_tab.dart';
import 'match_economy_tab.dart';
import 'match_duels_tab.dart';
import 'match_rounds_tab.dart';

class MatchDetailsModal extends StatefulWidget {
  final MatchSummary match;
  final UserProfile? profile;
  final Map<String, List<Map<String, dynamic>>> teams;

  const MatchDetailsModal({
    super.key,
    required this.match,
    required this.profile,
    required this.teams,
  });

  static void show(
    BuildContext context, {
    required MatchSummary match,
    required UserProfile? profile,
    required Map<String, List<Map<String, dynamic>>> teams,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1B1B26),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => MatchDetailsModal(
        match: match,
        profile: profile,
        teams: teams,
      ),
    );
  }

  @override
  State<MatchDetailsModal> createState() => _MatchDetailsModalState();
}

class _MatchDetailsModalState extends State<MatchDetailsModal> {
  int _activeTab = 0;

  /// Real average combat score (score / rounds played) from raw match data;
  /// null when the data is missing so the UI omits it rather than guessing.
  int? _realAcs() {
    final raw = widget.match.rawMatchDetails;
    if (raw == null) return null;
    final players = raw['players'] as List? ?? [];
    final me = firstWhereOrNull(players, (p) => p['subject'] == widget.profile?.puuid);
    final stats = me?['stats'];
    final score = stats?['score'] as int? ?? 0;
    final rounds = stats?['roundsPlayed'] as int? ?? 0;
    if (rounds <= 0) return null;
    return score ~/ rounds;
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    final userPuuid = widget.profile?.puuid ?? '';
    final modeTitle = match.gameMode.isNotEmpty ? match.gameMode : 'Competitive';

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.90),
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Map Banner Header
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: match.mapIcon.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: match.mapIcon,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          height: 120,
                          width: double.infinity,
                          color: Colors.black45,
                        ),
                ),
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.8),
                        Colors.black.withValues(alpha: 0.4),
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  bottom: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              match.mapName.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 22,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              '${modeTitle.toUpperCase()} • TRACKER ANALYTICS',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: match.isVictory ? const Color(0xFF34D399) : const Color(0xFFFF4655),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          match.isVictory ? 'VICTORY (${match.scoreText})' : 'DEFEAT (${match.scoreText})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // User Personal Combat Performance Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: match.agentIcon.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: match.agentIcon,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => Container(width: 48, height: 48, color: Colors.white10, child: const Icon(Icons.person, color: Colors.white54)),
                          )
                        : Container(width: 48, height: 48, color: Colors.white10, child: const Icon(Icons.person, color: Colors.white54)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.profile?.riotId ?? 'YOUR PERFORMANCE',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'K/D Ratio: ${match.deaths > 0 ? (match.kills / match.deaths).toStringAsFixed(2) : match.kills.toStringAsFixed(2)}${_realAcs() != null ? '  •  ACS: ${_realAcs()}' : ''}',
                          style: const TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('K / D / A', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(
                        '${match.kills} / ${match.deaths} / ${match.assists}',
                        style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tracker.gg Sub-Tab Navigation Chips Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildSubTabChip(0, 'Scoreboard', Icons.table_chart),
                  _buildSubTabChip(1, 'Performance', Icons.analytics),
                  _buildSubTabChip(2, 'Economy', Icons.monetization_on),
                  _buildSubTabChip(3, 'Duels 1v1', Icons.shield),
                  _buildSubTabChip(4, 'Rounds', Icons.view_timeline),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Render Sub-Tab Views
            if (_activeTab == 0) MatchScoreboardTab(match: match, teams: widget.teams),
            if (_activeTab == 1) MatchPerformanceTab(match: match, userPuuid: userPuuid),
            if (_activeTab == 2) MatchEconomyTab(match: match, userPuuid: userPuuid),
            if (_activeTab == 3) MatchDuelsTab(match: match, teams: widget.teams, userPuuid: userPuuid),
            if (_activeTab == 4) MatchRoundsTab(match: match, userPuuid: userPuuid),
          ],
        ),
      ),
    );
  }

  Widget _buildSubTabChip(int index, String label, IconData icon) {
    final isSelected = _activeTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTab = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF4655) : const Color(0xFF121218),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFFFF4655) : Colors.white10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : Colors.white60),
            const SizedBox(width: 6),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                fontSize: 11,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
