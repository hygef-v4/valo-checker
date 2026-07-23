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
    this.accountLevel = 67,
    this.cardIcon = 'https://media.valorant-api.com/playercards/9fb348bc-4141-423b-a63e-cbca722a4d09/displayicon.png',
  });

  String get riotId => '$gameName#$tagLine';
}
