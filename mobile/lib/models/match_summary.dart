class MatchSummary {
  final String matchId;
  final String mapName;
  final String mapIcon;
  final String agentName;
  final String agentIcon;
  final String gameMode;
  final String queueId;
  final String seasonId;
  final String seasonName;
  final bool isVictory;
  final String scoreText;
  final int kills;
  final int deaths;
  final int assists;
  final bool isMvp;
  final int matchStartTime;
  final Map<String, dynamic>? rawMatchDetails;

  MatchSummary({
    required this.matchId,
    required this.mapName,
    required this.mapIcon,
    required this.agentName,
    required this.agentIcon,
    required this.gameMode,
    this.queueId = '',
    this.seasonId = '',
    this.seasonName = '',
    required this.isVictory,
    required this.scoreText,
    required this.kills,
    required this.deaths,
    required this.assists,
    required this.isMvp,
    required this.matchStartTime,
    this.rawMatchDetails,
  });

  Map<String, dynamic> toJson() {
    return {
      'matchId': matchId,
      'mapName': mapName,
      'mapIcon': mapIcon,
      'agentName': agentName,
      'agentIcon': agentIcon,
      'gameMode': gameMode,
      'queueId': queueId,
      'seasonId': seasonId,
      'seasonName': seasonName,
      'isVictory': isVictory,
      'scoreText': scoreText,
      'kills': kills,
      'deaths': deaths,
      'assists': assists,
      'isMvp': isMvp,
      'matchStartTime': matchStartTime,
      'rawMatchDetails': rawMatchDetails,
    };
  }

  factory MatchSummary.fromJson(Map<String, dynamic> json) {
    return MatchSummary(
      matchId: (json['matchId'] ?? '').toString(),
      mapName: (json['mapName'] ?? '').toString(),
      mapIcon: (json['mapIcon'] ?? '').toString(),
      agentName: (json['agentName'] ?? '').toString(),
      agentIcon: (json['agentIcon'] ?? '').toString(),
      gameMode: (json['gameMode'] ?? 'Competitive').toString(),
      queueId: (json['queueId'] ?? '').toString(),
      seasonId: (json['seasonId'] ?? '').toString(),
      seasonName: (json['seasonName'] ?? '').toString(),
      isVictory: json['isVictory'] as bool? ?? false,
      scoreText: (json['scoreText'] ?? '0 - 0').toString(),
      kills: json['kills'] as int? ?? 0,
      deaths: json['deaths'] as int? ?? 0,
      assists: json['assists'] as int? ?? 0,
      isMvp: json['isMvp'] as bool? ?? false,
      matchStartTime: json['matchStartTime'] as int? ?? 0,
      rawMatchDetails: json['rawMatchDetails'] as Map<String, dynamic>?,
    );
  }
}
