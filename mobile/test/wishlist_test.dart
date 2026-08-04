import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valocheck/services/local_cache_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Wishlist LocalCacheService tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('getWishlist returns empty set when no items stored', () async {
      final wishlist = await LocalCacheService.getWishlist('puuid-1');
      expect(wishlist, isEmpty);
    });

    test('toggleWishlist adds and removes skinUuid correctly', () async {
      const puuid = 'puuid-test-123';
      const skinUuid = 'skin-vandal-prime';

      expect(await LocalCacheService.isWishlisted(puuid, skinUuid), false);

      final isAdded = await LocalCacheService.toggleWishlist(puuid, skinUuid);
      expect(isAdded, true);
      expect(await LocalCacheService.isWishlisted(puuid, skinUuid), true);

      final list = await LocalCacheService.getWishlist(puuid);
      expect(list, contains(skinUuid));

      final isRemoved = await LocalCacheService.toggleWishlist(puuid, skinUuid);
      expect(isRemoved, false);
      expect(await LocalCacheService.isWishlisted(puuid, skinUuid), false);
    });
  });
}
