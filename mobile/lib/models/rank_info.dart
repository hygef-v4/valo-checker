class CompetitiveUpdateItem {
  final String matchId;
  final String mapName;
  final String tierName;
  final String tierIcon;
  final int rrMovement;
  final int rrAfterMatch;
  final int matchStartTime;

  CompetitiveUpdateItem({
    required this.matchId,
    required this.mapName,
    required this.tierName,
    required this.tierIcon,
    required this.rrMovement,
    required this.rrAfterMatch,
    required this.matchStartTime,
  });
}

class RankInfo {
  final String currentTierName;
  final String currentTierIcon;
  final int currentRR;
  final String peakTierName;
  final String peakTierIcon;
  final int totalWins;
  final int totalGames;
  final List<CompetitiveUpdateItem> updates;

  RankInfo({
    required this.currentTierName,
    required this.currentTierIcon,
    required this.currentRR,
    required this.peakTierName,
    required this.peakTierIcon,
    required this.totalWins,
    required this.totalGames,
    required this.updates,
  });
}
