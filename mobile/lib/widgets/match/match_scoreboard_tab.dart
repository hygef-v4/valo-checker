import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/match_summary.dart';
import '../../services/valorant_api_service.dart';

class MatchScoreboardTab extends StatelessWidget {
  final MatchSummary match;
  final Map<String, List<Map<String, dynamic>>> teams;

  const MatchScoreboardTab({
    super.key,
    required this.match,
    required this.teams,
  });

  @override
  Widget build(BuildContext context) {
    final isWin = match.isVictory;
    final teamA = teams['teamA'] ?? [];
    final teamB = teams['teamB'] ?? [];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF121218),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTeamHeader(isWin ? 'TEAM A (VICTORY)' : 'TEAM A (DEFEAT)', isWin ? const Color(0xFF34D399) : const Color(0xFFFF4655)),
            const SizedBox(height: 8),
            _buildTableHead(),
            const SizedBox(height: 6),
            ...teamA.map((p) => _buildPlayerRow(p, isWin ? const Color(0xFF34D399) : const Color(0xFFFF4655))),
            const SizedBox(height: 16),

            _buildTeamHeader(!isWin ? 'TEAM B (VICTORY)' : 'TEAM B (DEFEAT)', !isWin ? const Color(0xFF34D399) : const Color(0xFFFF4655)),
            const SizedBox(height: 8),
            _buildTableHead(),
            const SizedBox(height: 6),
            ...teamB.map((p) => _buildPlayerRow(p, !isWin ? const Color(0xFF34D399) : const Color(0xFFFF4655))),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamHeader(String text, Color color) {
    return Text(
      text,
      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.8),
    );
  }

  Widget _buildTableHead() {
    return Row(
      children: const [
        SizedBox(width: 140, child: Text('PLAYER', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold))),
        SizedBox(width: 50, child: Text('RANK', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
        SizedBox(width: 45, child: Text('ACS', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
        SizedBox(width: 30, child: Text('K', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
        SizedBox(width: 30, child: Text('D', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
        SizedBox(width: 30, child: Text('A', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
        SizedBox(width: 40, child: Text('+/-', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
        SizedBox(width: 45, child: Text('K/D', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
        SizedBox(width: 45, child: Text('ADR', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
        SizedBox(width: 40, child: Text('HS%', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
      ],
    );
  }

  Widget _buildPlayerRow(Map<String, dynamic> p, Color teamColor) {
    final isMe = p['isMe'] == true;
    final diff = p['diff'] as int? ?? 0;
    final rankIcon = ValorantApiService.getRankIconByName(p['rankName'].toString());

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: isMe ? teamColor.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: isMe ? Border.all(color: teamColor.withValues(alpha: 0.5)) : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CachedNetworkImage(
                    imageUrl: p['agentIcon'].toString(),
                    width: 24,
                    height: 24,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => const Icon(Icons.person, color: Colors.white38, size: 20),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    p['name'].toString(),
                    style: TextStyle(
                      color: isMe ? teamColor : Colors.white,
                      fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 50,
            child: Center(
              child: rankIcon.isNotEmpty
                  ? CachedNetworkImage(imageUrl: rankIcon, width: 22, height: 22, fit: BoxFit.contain)
                  : Text(p['rankName'].toString(), style: const TextStyle(color: Colors.white54, fontSize: 9)),
            ),
          ),
          SizedBox(width: 45, child: Text('${p['acs']}', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.right)),
          SizedBox(width: 30, child: Text('${p['k']}', style: const TextStyle(color: Colors.white, fontSize: 11), textAlign: TextAlign.right)),
          SizedBox(width: 30, child: Text('${p['d']}', style: const TextStyle(color: Colors.white70, fontSize: 11), textAlign: TextAlign.right)),
          SizedBox(width: 30, child: Text('${p['a']}', style: const TextStyle(color: Colors.white70, fontSize: 11), textAlign: TextAlign.right)),
          SizedBox(
            width: 40,
            child: Text(
              diff > 0 ? '+$diff' : '$diff',
              style: TextStyle(
                color: diff > 0 ? const Color(0xFF34D399) : (diff < 0 ? const Color(0xFFFF4655) : Colors.white54),
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(width: 45, child: Text('${p['kd']}', style: const TextStyle(color: Colors.white70, fontSize: 11), textAlign: TextAlign.right)),
          SizedBox(width: 45, child: Text('${p['adr']}', style: const TextStyle(color: Colors.white70, fontSize: 11), textAlign: TextAlign.right)),
          SizedBox(width: 40, child: Text('${p['hs']}', style: const TextStyle(color: Colors.white70, fontSize: 11), textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}
