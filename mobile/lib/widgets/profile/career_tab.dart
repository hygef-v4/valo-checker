import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/match_summary.dart';
import '../../models/quest_item.dart';
import '../../models/rank_info.dart';
import '../../theme/app_colors.dart';
import '../../utils/format_utils.dart';

class CareerTab extends StatelessWidget {
  final RankInfo? rankInfo;
  final List<QuestItem> quests;
  final List<MatchSummary> matchHistory;
  final ValueChanged<MatchSummary> onMatchTap;

  const CareerTab({
    super.key,
    required this.rankInfo,
    required this.quests,
    required this.matchHistory,
    required this.onMatchTap,
  });

  @override
  Widget build(BuildContext context) {
    final rank = rankInfo;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (rank != null) _RankCard(rank: rank),
        const SizedBox(height: 24),
        const Text(
          'ACTIVE MISSIONS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        if (quests.isEmpty)
          const Text('No active missions.', style: TextStyle(color: Colors.white54))
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: quests.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _QuestRow(quest: quests[index]),
          ),
        const SizedBox(height: 24),
        Text(
          'RECENT ${matchHistory.length} MATCHES',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        if (matchHistory.isEmpty)
          const Text('No recent matches found.', style: TextStyle(color: Colors.white54))
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: matchHistory.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final m = matchHistory[index];
              return _MatchRow(match: m, onTap: () => onMatchTap(m));
            },
          ),
      ],
    );
  }
}

class _RankCard extends StatelessWidget {
  final RankInfo rank;

  const _RankCard({required this.rank});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          if (rank.currentTierIcon.isNotEmpty)
            CachedNetworkImage(imageUrl: rank.currentTierIcon, height: 80)
          else
            const Icon(Icons.military_tech, color: AppColors.primary, size: 70),
          const SizedBox(height: 12),
          Text(
            rank.currentTierName.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 22,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${rank.currentRR} / 100 RR',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (rank.currentRR % 100) / 100.0,
              minHeight: 8,
              backgroundColor: Colors.white10,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Text('PEAK RANK', style: TextStyle(color: Colors.white38, fontSize: 10)),
                  const SizedBox(height: 4),
                  Text(rank.peakTierName, style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              Column(
                children: [
                  const Text('WIN / TOTAL', style: TextStyle(color: Colors.white38, fontSize: 10)),
                  const SizedBox(height: 4),
                  Text(
                    rank.totalGames > 0 ? '${rank.totalWins} / ${rank.totalGames}' : '—',
                    style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuestRow extends StatelessWidget {
  final QuestItem quest;

  const _QuestRow({required this.quest});

  @override
  Widget build(BuildContext context) {
    final hasProgress = quest.targetProgress > 0;
    final progress = hasProgress ? (quest.currentProgress / quest.targetProgress).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  quest.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              if (quest.rewardXP > 0) ...[
                const SizedBox(width: 8),
                Text('+${quest.rewardXP} XP', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ],
          ),
          if (quest.isCompleted) ...[
            const SizedBox(height: 6),
            const Text('Completed', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold)),
          ] else if (hasProgress) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: Colors.white10,
                color: Colors.amber,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${quest.currentProgress} / ${quest.targetProgress}',
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }
}

class _MatchRow extends StatelessWidget {
  final MatchSummary match;
  final VoidCallback onTap;

  const _MatchRow({required this.match, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
              child: match.agentIcon.isNotEmpty
                  ? CachedNetworkImage(imageUrl: match.agentIcon, fit: BoxFit.cover)
                  : const Icon(Icons.person, color: Colors.white38),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Text(
                        match.isVictory ? 'VICTORY (${match.scoreText})' : 'DEFEAT (${match.scoreText})',
                        style: TextStyle(
                          color: match.isVictory ? AppColors.success : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          FormatUtils.cleanGameMode(match.gameMode).toUpperCase(),
                          style: const TextStyle(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('Map: ${match.mapName} • ${match.agentName}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('K / D / A', style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('${match.kills}/${match.deaths}/${match.assists}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: Colors.white38, size: 18),
          ],
        ),
      ),
    );
  }
}
