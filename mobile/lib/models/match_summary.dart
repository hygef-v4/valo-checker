class MatchSummary {
  final String matchId;
  final String mapName;
  final String mapIcon;
  final String agentName;
  final String agentIcon;
  final String gameMode;
  final bool isVictory;
  final String scoreText;
  final int kills;
  final int deaths;
  final int assists;
  final bool isMvp;
  final int matchStartTime;

  MatchSummary({
    required this.matchId,
    required this.mapName,
    required this.mapIcon,
    required this.agentName,
    required this.agentIcon,
    required this.gameMode,
    required this.isVictory,
    required this.scoreText,
    required this.kills,
    required this.deaths,
    required this.assists,
    required this.isMvp,
    required this.matchStartTime,
  });
}
