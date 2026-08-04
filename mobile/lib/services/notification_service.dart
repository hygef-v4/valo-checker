import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import '../models/skin_item.dart';
import 'local_cache_service.dart';
import 'riot_auth_service.dart';
import 'valorant_api_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await NotificationService.checkWishlistAndNotify();
      return true;
    } catch (_) {
      return false;
    }
  });
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _taskName = 'valocheck_daily_shop_check';
  static const String _channelId = 'valocheck_wishlist_channel';
  static const String _channelName = 'Wishlist Store Alerts';

  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initSettings);

    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Notifications when your wishlisted skins appear in store',
      importance: Importance.high,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Schedule background periodic task with Workmanager
    try {
      await Workmanager().initialize(callbackDispatcher);
      await Workmanager().registerPeriodicTask(
        '1',
        _taskName,
        frequency: const Duration(hours: 12),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
    } catch (_) {
      // Workmanager init fallback if unsupported in current env
    }
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Notifications when your wishlisted skins appear in store',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(id, title, body, details);
  }

  static Future<void> checkWishlistAndNotify() async {
    final activeAccount = await LocalCacheService.getActiveAccount();
    if (activeAccount == null || activeAccount.accessToken.isEmpty) return;

    if (activeAccount.isTokenExpired) {
      await showNotification(
        id: 999,
        title: '🔒 ValoCheck Login Renewal',
        body: 'Your Riot session expired. Open ValoCheck to refresh your token and stay notified!',
      );
      return;
    }

    final wishlist = await LocalCacheService.getWishlist(activeAccount.puuid);
    if (wishlist.isEmpty) return;

    await ValorantApiService.loadMetadataCache();

    try {
      final data = await RiotAuthService.fetchStorefrontData(
        activeAccount.accessToken,
        activeAccount.idToken,
      );

      final dailySkins = data['dailySkins'] as List<SkinItem>? ?? [];
      final matchingWishlistSkins = <String>[];

      for (var skin in dailySkins) {
        if (wishlist.contains(skin.uuid)) {
          matchingWishlistSkins.add(skin.parentName);
        }
      }

      if (matchingWishlistSkins.isNotEmpty) {
        final names = matchingWishlistSkins.join(', ');
        await showNotification(
          id: 888,
          title: '🎉 Wishlist Item Available!',
          body: '$names ${matchingWishlistSkins.length == 1 ? "is" : "are"} in your Daily Shop today!',
        );
      }
    } catch (_) {
      // Session failure or network drop handled silently during background poll
    }
  }
}
