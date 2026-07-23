class UserProfile {
  final String puuid;
  final String gameName;
  final String tagLine;
  final String region;
  final int vp;
  final int rad;
  final int kc;
  final int accountLevel;
  final String cardIcon;

  UserProfile({
    required this.puuid,
    required this.gameName,
    required this.tagLine,
    required this.region,
    this.vp = 0,
    this.rad = 0,
    this.kc = 0,
    this.accountLevel = 1,
    this.cardIcon = '',
  });

  String get riotId => '$gameName#$tagLine';
}
