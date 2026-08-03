class SavedAccount {
  final String puuid;
  final String gameName;
  final String tagLine;
  final String region;
  final int accountLevel;
  final String cardIcon;
  final String accessToken;
  final String idToken;
  final int timestamp;
  final String? rankTierName;
  final String? rankTierIcon;
  final int? rankRR;

  const SavedAccount({
    required this.puuid,
    required this.gameName,
    required this.tagLine,
    required this.region,
    this.accountLevel = 1,
    this.cardIcon = '',
    required this.accessToken,
    required this.idToken,
    required this.timestamp,
    this.rankTierName,
    this.rankTierIcon,
    this.rankRR,
  });

  String get riotId => '$gameName#$tagLine';

  /// Riot access token TTL is ~60 minutes. Treat >=55 minutes as expired.
  bool get isTokenExpired {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (now - timestamp) > 3300000;
  }

  SavedAccount copyWith({
    String? puuid,
    String? gameName,
    String? tagLine,
    String? region,
    int? accountLevel,
    String? cardIcon,
    String? accessToken,
    String? idToken,
    int? timestamp,
    String? rankTierName,
    String? rankTierIcon,
    int? rankRR,
  }) {
    return SavedAccount(
      puuid: puuid ?? this.puuid,
      gameName: gameName ?? this.gameName,
      tagLine: tagLine ?? this.tagLine,
      region: region ?? this.region,
      accountLevel: accountLevel ?? this.accountLevel,
      cardIcon: cardIcon ?? this.cardIcon,
      accessToken: accessToken ?? this.accessToken,
      idToken: idToken ?? this.idToken,
      timestamp: timestamp ?? this.timestamp,
      rankTierName: rankTierName ?? this.rankTierName,
      rankTierIcon: rankTierIcon ?? this.rankTierIcon,
      rankRR: rankRR ?? this.rankRR,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'puuid': puuid,
      'gameName': gameName,
      'tagLine': tagLine,
      'region': region,
      'accountLevel': accountLevel,
      'cardIcon': cardIcon,
      'accessToken': accessToken,
      'idToken': idToken,
      'timestamp': timestamp,
      'rankTierName': rankTierName,
      'rankTierIcon': rankTierIcon,
      'rankRR': rankRR,
    };
  }

  factory SavedAccount.fromJson(Map<String, dynamic> json) {
    return SavedAccount(
      puuid: (json['puuid'] ?? '').toString(),
      gameName: (json['gameName'] ?? '').toString(),
      tagLine: (json['tagLine'] ?? '').toString(),
      region: (json['region'] ?? 'ap').toString(),
      accountLevel: json['accountLevel'] as int? ?? 1,
      cardIcon: (json['cardIcon'] ?? '').toString(),
      accessToken: (json['accessToken'] ?? '').toString(),
      idToken: (json['idToken'] ?? '').toString(),
      timestamp: json['timestamp'] as int? ?? 0,
      rankTierName: json['rankTierName']?.toString(),
      rankTierIcon: json['rankTierIcon']?.toString(),
      rankRR: json['rankRR'] as int?,
    );
  }
}
