import 'package:flutter_test/flutter_test.dart';
import 'package:valocheck/services/valorant_api_service.dart';

void main() {
  group('ValorantApiService.resolveMission', () {
    test('returns honest empty values for unknown missions instead of inventing XP', () {
      final meta = ValorantApiService.resolveMission('00000000-0000-0000-0000-000000000000');
      expect(meta['title'], '');
      expect(meta['xpGrant'], 0);
      expect(meta['progressToComplete'], 0);
    });
  });

  group('ValorantApiService.resolveSkinItem', () {
    test('falls back to a neutral placeholder for unknown skins', () {
      final skin = ValorantApiService.resolveSkinItem('not-a-real-uuid', 1775);
      expect(skin.displayName, 'Valorant Item');
      expect(skin.cost, 1775);
      expect(skin.displayIcon, '');
    });
  });

  group('ValorantApiService.resolveRankTier', () {
    test('returns Unrated fallback when metadata is not loaded', () {
      final tier = ValorantApiService.resolveRankTier(99);
      expect(tier['tierName'], 'Unrated');
    });
  });
}
