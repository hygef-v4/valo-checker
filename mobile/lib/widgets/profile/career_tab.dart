import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/match_summary.dart';
import '../../models/quest_item.dart';
import '../../models/rank_info.dart';
import '../../theme/app_colors.dart';
import '../../utils/format_utils.dart';

class CareerTab extends StatefulWidget {
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
  State<CareerTab> createState() => _CareerTabState();
}

class _CareerTabState extends State<CareerTab> {
  String _selectedMode = 'ALL';
  String? _selectedSeason;
  int _visibleDaysCount = 5;

  static const List<Map<String, dynamic>> _modeTabs = [
    {'key': 'ALL', 'label': 'ALL', 'icon': Icons.apps_rounded},
    {'key': 'COMPETITIVE', 'label': 'COMPETITIVE', 'icon': Icons.military_tech_rounded},
    {'key': 'UNRATED', 'label': 'UNRATED', 'icon': Icons.sports_esports_rounded},
    {'key': 'DEATHMATCH', 'label': 'DEATHMATCH', 'icon': Icons.gps_fixed_rounded},
    {'key': 'SWIFTPLAY', 'label': 'SWIFTPLAY', 'icon': Icons.bolt_rounded},
    {'key': 'SKIRMISH', 'label': 'SKIRMISH', 'icon': Icons.shield_outlined},
    {'key': 'SPIKE RUSH', 'label': 'SPIKE RUSH', 'icon': Icons.timer_rounded},
    {'key': 'TEAM DEATHMATCH', 'label': 'TDM', 'icon': Icons.groups_rounded},
    {'key': 'PREMIER', 'label': 'PREMIER', 'icon': Icons.emoji_events_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _initDefaultSeason();
  }

  @override
  void didUpdateWidget(covariant CareerTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.matchHistory != widget.matchHistory) {
      if (_selectedSeason == null) {
        _initDefaultSeason();
      }
    }
  }

  void _initDefaultSeason() {
    final compMatches = widget.matchHistory.where((m) {
      final cleanMode = FormatUtils.cleanGameMode(m.gameMode).toUpperCase();
      return cleanMode == 'COMPETITIVE' || m.gameMode.toUpperCase().contains('COMPETITIVE');
    }).toList();
    final seasons = _getAvailableSeasons(compMatches);
    if (seasons.isNotEmpty) {
      _selectedSeason = seasons.first;
    } else {
      _selectedSeason = 'ALL SEASONS';
    }
  }

  List<String> _getAvailableSeasons(List<MatchSummary> competitiveMatches) {
    final seasons = <String>{};
    for (final m in competitiveMatches) {
      if (m.seasonName.isNotEmpty) {
        seasons.add(m.seasonName.toUpperCase());
      }
    }
    return seasons.toList();
  }

  String _formatDateHeader(DateTime date) {
    if (date.year <= 2000) {
      return 'RECENT MATCHES';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final dayStr = date.day.toString().padLeft(2, '0');
    final monthStr = date.month.toString().padLeft(2, '0');
    final yearStr = date.year.toString();

    if (date == today) {
      return 'TODAY • $dayStr/$monthStr/$yearStr';
    } else if (date == yesterday) {
      return 'YESTERDAY • $dayStr/$monthStr/$yearStr';
    } else {
      const weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
      final wd = weekdays[date.weekday - 1];
      return '$wd • $dayStr/$monthStr/$yearStr';
    }
  }

  List<MatchSummary> _getFilteredMatches(String activeSeason) {
    return widget.matchHistory.where((m) {
      final cleanMode = FormatUtils.cleanGameMode(m.gameMode).toUpperCase();
      final rawMode = m.gameMode.toUpperCase();
      final queueId = m.queueId.toUpperCase();

      if (_selectedMode != 'ALL') {
        final matchesMode = cleanMode == _selectedMode ||
            cleanMode.contains(_selectedMode) ||
            rawMode.contains(_selectedMode) ||
            queueId == _selectedMode;
        if (!matchesMode) return false;
      }

      if (_selectedMode == 'COMPETITIVE' && activeSeason != 'ALL SEASONS') {
        final matchSeason = m.seasonName.toUpperCase();
        if (matchSeason.isNotEmpty && matchSeason != activeSeason) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final rank = widget.rankInfo;
    final allMatches = widget.matchHistory;

    // Filter competitive matches to extract season list
    final competitiveMatches = allMatches.where((m) {
      final cleanMode = FormatUtils.cleanGameMode(m.gameMode).toUpperCase();
      return cleanMode == 'COMPETITIVE' || m.gameMode.toUpperCase().contains('COMPETITIVE');
    }).toList();
    final availableSeasons = _getAvailableSeasons(competitiveMatches);
    final activeSeason = _selectedSeason ?? (availableSeasons.isNotEmpty ? availableSeasons.first : 'ALL SEASONS');

    final filteredMatches = _getFilteredMatches(activeSeason);

    // Group filtered matches by date
    final Map<DateTime, List<MatchSummary>> groupedByDay = {};
    for (final m in filteredMatches) {
      final dt = m.matchStartTime > 0
          ? DateTime.fromMillisecondsSinceEpoch(m.matchStartTime)
          : DateTime(2000, 1, 1);
      final dayKey = DateTime(dt.year, dt.month, dt.day);
      groupedByDay.putIfAbsent(dayKey, () => []).add(m);
    }
    final allDays = groupedByDay.keys.toList()..sort((a, b) => b.compareTo(a));
    final visibleDays = allDays.take(_visibleDaysCount).toList();
    final totalVisibleMatches = visibleDays.fold<int>(0, (sum, d) => sum + (groupedByDay[d]?.length ?? 0));
    final hasMoreDays = _visibleDaysCount < allDays.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (rank != null) _RankCard(rank: rank),
        const SizedBox(height: 24),

        // Active Missions Section
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
        if (widget.quests.isEmpty)
          const Text('No active missions.', style: TextStyle(color: Colors.white54))
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.quests.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _QuestRow(quest: widget.quests[index]),
          ),
        const SizedBox(height: 24),

        // Match History Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'MATCH HISTORY',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 1.2,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$totalVisibleMatches Matches • ${visibleDays.length}/${allDays.length} Days',
                style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Level 1: Game Mode Tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _modeTabs.map((tab) {
              final key = tab['key'] as String;
              final label = tab['label'] as String;
              final icon = tab['icon'] as IconData;
              final isSelected = _selectedMode == key;

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedMode = key;
                      _visibleDaysCount = 5;
                      if (key == 'COMPETITIVE') {
                        _initDefaultSeason();
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.white12,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 14,
                          color: isSelected ? AppColors.primary : Colors.white60,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white60,
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Level 2: Season / Act Filter (Only for Competitive Mode)
        if (_selectedMode == 'COMPETITIVE' && availableSeasons.isNotEmpty) ...[
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSeasonPill(
                  label: 'ALL SEASONS',
                  isSelected: activeSeason == 'ALL SEASONS',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedSeason = 'ALL SEASONS';
                      _visibleDaysCount = 5;
                    });
                  },
                ),
                ...availableSeasons.map((season) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 6.0),
                    child: _buildSeasonPill(
                      label: season,
                      isSelected: activeSeason == season,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedSeason = season;
                          _visibleDaysCount = 5;
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ],

        // Performance Analytics for Selected Mode/Season
        if (filteredMatches.isNotEmpty) ...[
          const SizedBox(height: 16),
          _PerformanceAnalyticsCard(
            matchHistory: filteredMatches,
            modeTitle: _selectedMode == 'ALL' ? 'ALL MODES' : _selectedMode,
            seasonTitle: _selectedMode == 'COMPETITIVE' && activeSeason != 'ALL SEASONS'
                ? activeSeason
                : null,
          ),
        ],

        const SizedBox(height: 16),

        // Match Rows Grouped by Day
        if (visibleDays.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              children: [
                const Icon(Icons.history_toggle_off, color: Colors.white24, size: 40),
                const SizedBox(height: 12),
                Text(
                  _selectedMode == 'ALL'
                      ? 'No recent matches found.'
                      : 'No matches found for $_selectedMode${activeSeason != 'ALL SEASONS' ? ' ($activeSeason)' : ''}.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          )
        else ...[
          for (int dayIdx = 0; dayIdx < visibleDays.length; dayIdx++) ...[
            Builder(
              builder: (context) {
                final day = visibleDays[dayIdx];
                final dayMatches = groupedByDay[day] ?? [];
                final dayWins = dayMatches.where((m) => m.isVictory).length;
                final dayLosses = dayMatches.length - dayWins;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (dayIdx > 0) const SizedBox(height: 18),

                    // Day Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, color: Colors.white38, size: 12),
                              const SizedBox(width: 6),
                              Text(
                                _formatDateHeader(day),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: dayWins >= dayLosses
                                  ? AppColors.success.withValues(alpha: 0.15)
                                  : Colors.redAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${dayWins}W - ${dayLosses}L',
                              style: TextStyle(
                                color: dayWins >= dayLosses ? AppColors.success : Colors.redAccent,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Matches for this day
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: dayMatches.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final m = dayMatches[index];
                        return _MatchRow(match: m, onTap: () => widget.onMatchTap(m));
                      },
                    ),
                  ],
                );
              },
            ),
          ],

          // Load More Button
          if (hasMoreDays) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _visibleDaysCount += 5;
                  });
                },
                icon: const Icon(Icons.expand_more_rounded, color: AppColors.primary, size: 18),
                label: Text(
                  'LOAD MORE (${allDays.length - _visibleDaysCount} older days remaining)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildSeasonPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFB74D).withValues(alpha: 0.2) : Colors.black26,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFB74D) : Colors.white12,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 11,
              color: isSelected ? const Color(0xFFFFB74D) : Colors.white38,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PerformanceAnalyticsCard extends StatelessWidget {
  final List<MatchSummary> matchHistory;
  final String? modeTitle;
  final String? seasonTitle;

  const _PerformanceAnalyticsCard({
    required this.matchHistory,
    this.modeTitle,
    this.seasonTitle,
  });

  @override
  Widget build(BuildContext context) {
    if (matchHistory.isEmpty) return const SizedBox.shrink();

    final total = matchHistory.length;
    final wins = matchHistory.where((m) => m.isVictory).length;
    final winrate = (wins / total * 100).round();
    final totalKills = matchHistory.fold(0, (sum, m) => sum + m.kills);
    final totalDeaths = matchHistory.fold(0, (sum, m) => sum + m.deaths);
    final totalAssists = matchHistory.fold(0, (sum, m) => sum + m.assists);
    final kdRatio = totalDeaths > 0 ? (totalKills / totalDeaths).toStringAsFixed(2) : totalKills.toString();
    final mvpCount = matchHistory.where((m) => m.isMvp).length;

    final Map<String, List<MatchSummary>> mapGroups = {};
    for (final m in matchHistory) {
      if (m.mapName.isNotEmpty) {
        mapGroups.putIfAbsent(m.mapName, () => []).add(m);
      }
    }
    final sortedMaps = mapGroups.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    final headerSubtitle = [
      if (modeTitle != null && modeTitle!.isNotEmpty) modeTitle,
      if (seasonTitle != null && seasonTitle!.isNotEmpty) seasonTitle,
    ].join(' • ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.analytics_outlined, color: AppColors.primary, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'PERFORMANCE STATS',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                    if (headerSubtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        headerSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Last $total matches',
                  style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('WIN RATE', style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        '$winrate%',
                        style: TextStyle(
                          color: winrate >= 50 ? AppColors.success : Colors.redAccent,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text('$wins W - ${total - wins} L', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('K / D RATIO', style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        kdRatio,
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text('$totalKills K • $totalDeaths D', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('MATCH MVPS', style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        '$mvpCount',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text('$totalAssists Assists', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (sortedMaps.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'MAP WIN RATES',
              style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: sortedMaps.map((entry) {
                  final mapName = entry.key;
                  final mapMatches = entry.value;
                  final mapWins = mapMatches.where((m) => m.isVictory).length;
                  final mapWinrate = (mapWins / mapMatches.length * 100).round();

                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          mapName,
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: mapWinrate >= 50
                                ? AppColors.success.withValues(alpha: 0.2)
                                : Colors.redAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$mapWinrate% ($mapWins/${mapMatches.length})',
                            style: TextStyle(
                              color: mapWinrate >= 50 ? AppColors.success : Colors.redAccent,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
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
