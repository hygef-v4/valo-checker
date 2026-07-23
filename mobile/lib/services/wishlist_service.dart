import 'package:shared_preferences/shared_preferences.dart';

class WishlistService {
  static const String _key = 'wishlist_skin_uuids';

  static Future<Set<String>> getWishlist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_key) ?? [];
      return list.toSet();
    } catch (_) {
      return {};
    }
  }

  static Future<bool> toggleWishlist(String uuid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_key) ?? [];
      final set = list.toSet();

      bool added = false;
      if (set.contains(uuid)) {
        set.remove(uuid);
      } else {
        set.add(uuid);
        added = true;
      }

      await prefs.setStringList(_key, set.toList());
      return added;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isWishlisted(String uuid) async {
    final set = await getWishlist();
    return set.contains(uuid);
  }
}
