import 'package:flutter_test/flutter_test.dart';
import 'package:valocheck/models/saved_account.dart';

void main() {
  group('SavedAccount model tests', () {
    test('toJson and fromJson serializes accurately', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final account = SavedAccount(
        puuid: 'test-puuid-123',
        gameName: 'RiotPlayer',
        tagLine: 'NA1',
        region: 'ap',
        accountLevel: 120,
        cardIcon: 'https://example.com/card.png',
        accessToken: 'access_123',
        idToken: 'id_123',
        timestamp: now,
        rankTierName: 'Gold 2',
        rankTierIcon: 'https://example.com/gold.png',
        rankRR: 45,
      );

      expect(account.riotId, 'RiotPlayer#NA1');
      expect(account.isTokenExpired, false);

      final json = account.toJson();
      final deserialized = SavedAccount.fromJson(json);

      expect(deserialized.puuid, 'test-puuid-123');
      expect(deserialized.gameName, 'RiotPlayer');
      expect(deserialized.tagLine, 'NA1');
      expect(deserialized.region, 'ap');
      expect(deserialized.accountLevel, 120);
      expect(deserialized.cardIcon, 'https://example.com/card.png');
      expect(deserialized.accessToken, 'access_123');
      expect(deserialized.idToken, 'id_123');
      expect(deserialized.timestamp, now);
      expect(deserialized.rankTierName, 'Gold 2');
      expect(deserialized.rankTierIcon, 'https://example.com/gold.png');
      expect(deserialized.rankRR, 45);
    });

    test('isTokenExpired returns true for tokens older than 55 mins', () {
      final oldTimestamp = DateTime.now().millisecondsSinceEpoch - (56 * 60 * 1000);
      final account = SavedAccount(
        puuid: 'test-puuid-expired',
        gameName: 'OldPlayer',
        tagLine: 'EUW',
        region: 'eu',
        accessToken: 'old_access',
        idToken: 'old_id',
        timestamp: oldTimestamp,
      );

      expect(account.isTokenExpired, true);
    });
  });
}
