import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/accessory_item.dart';
import '../models/bundle_item.dart';
import '../models/match_summary.dart';
import '../models/quest_item.dart';
import '../models/rank_info.dart';
import '../models/saved_account.dart';
import '../models/skin_item.dart';
import '../models/user_profile.dart';
import '../services/local_cache_service.dart';
import '../services/notification_service.dart';
import '../services/riot_api_client.dart';
import '../services/riot_auth_service.dart';
import '../theme/app_colors.dart';
import '../utils/match_team_helper.dart';
import '../widgets/accounts/accounts_tab.dart';
import '../widgets/common/shimmer_loading_skeleton.dart';
import '../widgets/common/sub_tab_bar.dart';
import '../widgets/common/top_header.dart';
import '../widgets/match/match_details_modal.dart';
import '../widgets/profile/agents_tab.dart';
import '../widgets/profile/career_tab.dart';
import '../widgets/profile/collection_tab.dart';
import '../widgets/profile/weapons_tab.dart';
import '../widgets/shop/accessory_shop_tab.dart';
import '../widgets/shop/bundles_tab.dart';
import '../widgets/shop/daily_shop_tab.dart';
import '../widgets/shop/night_market_tab.dart';
import '../widgets/shop/shop_shared.dart';
import '../widgets/shop/skin_detail_modal.dart';
import 'riot_login_webview.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  static const _shopSubTabs = ['DAILY SHOP', 'ACCESSORY SHOP', 'NIGHT MARKET', 'BUNDLES'];
  static const _explorerSubTabs = ['WEAPONS', 'AGENTS'];
  static const _profileSubTabs = ['COLLECTION', 'CAREER'];

  int _currentNavIndex = 0; // 0: Shop, 1: Explorer, 2: Profile, 3: Accounts
  int _shopSubTab = 0;
  int _explorerSubTab = 0;
  int _profileSubTab = 0;

  List<SavedAccount> _savedAccounts = [];
  String? _activePuuid;

  bool _isLoading = false;
  String? _error;
  String? _accessToken;
  String? _idToken;

  UserProfile? _profile;
  List<SkinItem> _dailySkins = [];
  List<Map<String, dynamic>> _nightMarketSkins = [];
  List<BundleItem> _bundles = [];
  List<AccessoryItem> _accessories = [];
  List<SkinItem> _inventory = [];
  OwnedSkinIndex _ownedIndex = OwnedSkinIndex.fromInventory(const []);
  RankInfo? _rankInfo;
  List<MatchSummary> _matchHistory = [];
  List<QuestItem> _quests = [];
  Set<String> _ownedAgents = {};
  Set<String> _wishlist = {};
  int _selectedAgentIndex = 0;

  int _remainingSeconds = 0;
  int _nightMarketRemainingSeconds = 0;
  int _accessoryRemainingSeconds = 0;
  Timer? _timer;

  Future<void> _handleToggleWishlist(String skinUuid) async {
    final puuid = _profile?.puuid ?? _activePuuid ?? '';
    if (puuid.isEmpty) return;
    await LocalCacheService.toggleWishlist(puuid, skinUuid);
    final updated = await LocalCacheService.getWishlist(puuid);
    if (!mounted) return;
    setState(() {
      _wishlist = updated;
    });

    if (updated.contains(skinUuid)) {
      final matchingDaily = _dailySkins.where((s) => s.uuid == skinUuid).firstOrNull;
      if (matchingDaily != null) {
        NotificationService.showNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: '🎉 Wishlist Item Available!',
          body: '${matchingDaily.parentName} is in your Daily Shop today!',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 ${matchingDaily.parentName} is available in your Daily Shop today!'),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _checkSavedTokenAndAutoLogin();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkSavedTokenAndAutoLogin() async {
    _savedAccounts = await LocalCacheService.getSavedAccounts();
    _activePuuid = await LocalCacheService.getActivePuuid();

    final activeAccount = await LocalCacheService.getActiveAccount();
    if (activeAccount != null && activeAccount.accessToken.isNotEmpty) {
      if (!activeAccount.isTokenExpired) {
        _loadStoreData(activeAccount.accessToken, activeAccount.idToken);
      } else {
        final tokens = await LocalCacheService.getValidTokens();
        if (tokens != null && tokens['accessToken']!.isNotEmpty) {
          _loadStoreData(tokens['accessToken']!, tokens['idToken'] ?? '');
        } else if (mounted) {
          setState(() {});
        }
      }
    } else {
      final tokens = await LocalCacheService.getValidTokens();
      if (tokens != null && tokens['accessToken']!.isNotEmpty) {
        _loadStoreData(tokens['accessToken']!, tokens['idToken'] ?? '');
      } else if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _onRefresh() async {
    if (_accessToken != null && _idToken != null) {
      await _loadStoreData(_accessToken!, _idToken!);
    } else {
      await _checkSavedTokenAndAutoLogin();
    }
  }

  Future<void> _handleLogin() async {
    final result = await Navigator.of(context).push<Map<String, String>>(
      MaterialPageRoute(builder: (context) => const RiotLoginWebview()),
    );

    if (result != null && result.containsKey('accessToken')) {
      _loadStoreData(result['accessToken']!, result['idToken'] ?? '');
    }
  }

  Future<void> _handleSelectSavedAccount(SavedAccount account) async {
    if (account.isTokenExpired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token expired. Opening Riot login to re-authenticate...'),
          duration: Duration(seconds: 2),
        ),
      );
      await _handleAddAccount();
      return;
    }

    await LocalCacheService.setActivePuuid(account.puuid);
    setState(() {
      _activePuuid = account.puuid;
      _clearAllData();
    });
    await _loadStoreData(account.accessToken, account.idToken);
  }

  Future<void> _handleAddAccount() async {
    final result = await Navigator.of(context).push<Map<String, String>>(
      MaterialPageRoute(builder: (context) => const RiotLoginWebview(clearSession: true)),
    );

    if (result != null && result.containsKey('accessToken')) {
      _loadStoreData(result['accessToken']!, result['idToken'] ?? '');
    }
  }

  Future<void> _handleDeleteAccount(SavedAccount account) async {
    await LocalCacheService.removeAccount(account.puuid);
    final updatedAccounts = await LocalCacheService.getSavedAccounts();
    final updatedActivePuuid = await LocalCacheService.getActivePuuid();

    if (!mounted) return;
    setState(() {
      _savedAccounts = updatedAccounts;
      _activePuuid = updatedActivePuuid;
    });

    if (account.puuid == _profile?.puuid) {
      if (updatedAccounts.isNotEmpty) {
        final nextActive = updatedAccounts.first;
        await _handleSelectSavedAccount(nextActive);
      } else {
        await _handleLogout();
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed ${account.riotId}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleLogout() async {
    try {
      final cookieManager = WebViewCookieManager();
      await cookieManager.clearCookies();
    } catch (_) {}
    await LocalCacheService.clearAllAccounts();

    if (!mounted) return;
    setState(() {
      _clearAllData();
      _savedAccounts = [];
      _activePuuid = null;
      _currentNavIndex = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logged out successfully.'),
        duration: Duration(seconds: 2),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _clearAllData() {
    _profile = null;
    _accessToken = null;
    _idToken = null;
    _dailySkins = [];
    _nightMarketSkins = [];
    _bundles = [];
    _accessories = [];
    _inventory = [];
    _ownedIndex = OwnedSkinIndex.fromInventory(const []);
    _matchHistory = [];
    _quests = [];
    _ownedAgents = {};
    _wishlist = {};
    _rankInfo = null;
  }

  Future<void> _loadStoreData(String accessToken, String idToken) async {
    _accessToken = accessToken;
    _idToken = idToken;
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await RiotAuthService.fetchStorefrontData(accessToken, idToken);
      if (!mounted) return;
      final inventory = data['inventory'] as List<SkinItem>;
      final profile = data['profile'] as UserProfile;
      final wishlist = await LocalCacheService.getWishlist(profile.puuid);
      setState(() {
        _profile = profile;
        _wishlist = wishlist;
        _dailySkins = data['dailySkins'] as List<SkinItem>;
        _nightMarketSkins = data['nightMarket'] as List<Map<String, dynamic>>;
        _bundles = data['bundles'] as List<BundleItem>;
        _accessories = data['accessories'] as List<AccessoryItem>;
        _inventory = inventory;
        _ownedIndex = OwnedSkinIndex.fromInventory(inventory);
        _rankInfo = (data['rankInfo'] as RankInfo?) ?? _rankInfo;
        final newMatches = data['matchHistory'] as List<MatchSummary>? ?? [];
        if (newMatches.isNotEmpty || _matchHistory.isEmpty) {
          _matchHistory = newMatches;
        }
        final newQuests = data['quests'] as List<QuestItem>? ?? [];
        if (newQuests.isNotEmpty || _quests.isEmpty) {
          _quests = newQuests;
        }
        _ownedAgents = data['ownedAgents'] as Set<String>? ?? _ownedAgents;
        _remainingSeconds = data['remainingSeconds'] as int? ?? 0;
        _nightMarketRemainingSeconds = data['nightMarketRemainingSeconds'] as int? ?? 0;
        _accessoryRemainingSeconds = data['accessoryRemainingSeconds'] as int? ?? 0;
      });
      _startCountdown();
      final matchingWishlist = _dailySkins.where((s) => _wishlist.contains(s.uuid)).toList();
      if (matchingWishlist.isNotEmpty) {
        final names = matchingWishlist.map((s) => s.parentName).join(', ');
        NotificationService.showNotification(
          id: 888,
          title: '🎉 Wishlist Item Available!',
          body: '$names is in your Daily Shop today!',
        );
      }
      await LocalCacheService.saveTokens(accessToken, idToken);
      if (_profile != null) {
        final saved = SavedAccount(
          puuid: _profile!.puuid,
          gameName: _profile!.gameName,
          tagLine: _profile!.tagLine,
          region: _profile!.region,
          accountLevel: _profile!.accountLevel,
          cardIcon: _profile!.cardIcon,
          accessToken: accessToken,
          idToken: idToken,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          rankTierName: _rankInfo?.currentTierName,
          rankTierIcon: _rankInfo?.currentTierIcon,
          rankRR: _rankInfo?.currentRR,
        );
        await LocalCacheService.saveAccount(saved);
        final accounts = await LocalCacheService.getSavedAccounts();
        if (mounted) {
          setState(() {
            _savedAccounts = accounts;
            _activePuuid = _profile!.puuid;
          });
        }
      }
    } on SessionExpiredException catch (e) {
      // The token is genuinely dead: sign out locally and ask to log in again.
      await LocalCacheService.clearTokens();
      if (!mounted) return;
      setState(() {
        _clearAllData();
        _error = e.message;
      });
    } catch (e) {
      // Transient failure (offline, Riot maintenance...): keep the session
      // and any already-loaded data instead of forcing a re-login.
      if (!mounted) return;
      final message = 'Could not load data. Check your connection and try again.\n(${e.toString().replaceAll('Exception: ', '')})';
      if (_profile != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.primary),
        );
      } else {
        setState(() {
          _error = message;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_remainingSeconds > 0) _remainingSeconds--;
        if (_nightMarketRemainingSeconds > 0) _nightMarketRemainingSeconds--;
        if (_accessoryRemainingSeconds > 0) _accessoryRemainingSeconds--;
        for (var b in _bundles) {
          if (b.remainingSeconds > 0) {
            b.remainingSeconds--;
          }
        }
      });
    });
  }

  void _showSkinDetailModal(SkinItem skin) {
    final isLiked = _wishlist.contains(skin.uuid);
    final isOwned = _ownedIndex.contains(skin);
    SkinDetailModal.show(
      context,
      skin,
      isWishlisted: isLiked,
      isOwned: isOwned,
      onToggleWishlist: () => _handleToggleWishlist(skin.uuid),
    );
  }

  void _showMatchDetailsModal(MatchSummary match) {
    final teams = MatchTeamHelper.generateMatchTeams(
      match: match,
      profile: _profile,
      rankInfo: _rankInfo,
    );
    MatchDetailsModal.show(
      context,
      match: match,
      profile: _profile,
      teams: teams,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: _profile != null
          ? BottomNavigationBar(
              currentIndex: _currentNavIndex,
              onTap: (index) {
                setState(() {
                  _currentNavIndex = index;
                });
              },
              backgroundColor: AppColors.surface,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: Colors.white38,
              type: BottomNavigationBarType.fixed,
              selectedFontSize: 11,
              unselectedFontSize: 11,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.shopping_basket_outlined),
                  activeIcon: Icon(Icons.shopping_basket, color: AppColors.primary),
                  label: 'Shop',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.explore_outlined),
                  activeIcon: Icon(Icons.explore, color: AppColors.primary),
                  label: 'Explorer',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person, color: AppColors.primary),
                  label: 'Profile',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.group_outlined),
                  activeIcon: Icon(Icons.group, color: AppColors.primary),
                  label: 'Accounts',
                ),
              ],
            )
          : null,
      body: SafeArea(
        child: _profile == null ? _buildLoginState() : _buildActiveMainTab(),
      ),
    );
  }

  Widget _buildLoginState() {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'AUTHENTICATING WITH RIOT GAMES',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 15,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Fetching Daily Store, Career Rank & Match Details...',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
            const SizedBox(height: 32),
            const ShimmerLoadingSkeleton(height: 50, borderRadius: 12),
            const SizedBox(height: 12),
            const ShimmerLoadingSkeleton(height: 100, borderRadius: 16),
            const SizedBox(height: 12),
            const ShimmerLoadingSkeleton(height: 100, borderRadius: 16),
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 2),
              ),
              child: const Icon(Icons.shield_outlined, color: AppColors.primary, size: 44),
            ),
            const SizedBox(height: 24),
            const Text(
              'VALOCHECK',
              style: TextStyle(
                color: AppColors.offWhite,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Track your Daily Store, Night Market, Career Rank & Collection on mobile.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 6,
                ),
                onPressed: _handleLogin,
                icon: const Icon(Icons.lock_open, color: Colors.white),
                label: const Text(
                  'LOG IN WITH RIOT GAMES',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Text(
              'ValoCheck is an unofficial companion app and is not endorsed by Riot Games.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white30, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveMainTab() {
    switch (_currentNavIndex) {
      case 1:
        return _buildExplorerMainTab();
      case 2:
        return _buildProfileMainTab();
      case 3:
        return AccountsTab(
          accounts: _savedAccounts,
          activePuuid: _activePuuid ?? _profile?.puuid,
          activeProfile: _profile,
          activeRankInfo: _rankInfo,
          onSelectAccount: _handleSelectSavedAccount,
          onDeleteAccount: _handleDeleteAccount,
          onAddAccount: _handleAddAccount,
        );
      case 0:
      default:
        return _buildShopMainTab();
    }
  }

  Widget _buildShopMainTab() {
    Widget content;
    switch (_shopSubTab) {
      case 1:
        content = AccessoryShopTab(
          accessories: _accessories,
          remainingSeconds: _accessoryRemainingSeconds,
        );
        break;
      case 2:
        content = NightMarketTab(
          items: _nightMarketSkins,
          ownedIndex: _ownedIndex,
          remainingSeconds: _nightMarketRemainingSeconds,
          wishlist: _wishlist,
          onSkinTap: _showSkinDetailModal,
        );
        break;
      case 3:
        content = BundlesTab(
          bundles: _bundles,
          ownedIndex: _ownedIndex,
          onSkinTap: _showSkinDetailModal,
        );
        break;
      case 0:
      default:
        content = DailyShopTab(
          skins: _dailySkins,
          ownedIndex: _ownedIndex,
          remainingSeconds: _remainingSeconds,
          wishlist: _wishlist,
          onSkinTap: _showSkinDetailModal,
        );
    }

    return Column(
      children: [
        TopHeader(profile: _profile, title: 'STORE'),
        SubTabBar(
          tabs: _shopSubTabs,
          selectedIndex: _shopSubTab,
          onTabSelected: (index) => setState(() => _shopSubTab = index),
        ),
        const Divider(color: Colors.white10, height: 1),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            child: content,
          ),
        ),
      ],
    );
  }

  Widget _buildExplorerMainTab() {
    Widget content;
    switch (_explorerSubTab) {
      case 1:
        content = AgentsTab(
          ownedAgents: _ownedAgents,
          selectedIndex: _selectedAgentIndex,
          onAgentSelected: (index) => setState(() => _selectedAgentIndex = index),
        );
        break;
      case 0:
      default:
        content = WeaponsTab(
          wishlist: _wishlist,
          ownedIndex: _ownedIndex,
          onToggleWishlist: _handleToggleWishlist,
        );
    }

    return Column(
      children: [
        TopHeader(profile: _profile, title: 'EXPLORER'),
        SubTabBar(
          tabs: _explorerSubTabs,
          selectedIndex: _explorerSubTab,
          onTabSelected: (index) => setState(() => _explorerSubTab = index),
        ),
        const Divider(color: Colors.white10, height: 1),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            child: content,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileMainTab() {
    Widget content;
    switch (_profileSubTab) {
      case 1:
        content = CareerTab(
          rankInfo: _rankInfo,
          quests: _quests,
          matchHistory: _matchHistory,
          onMatchTap: _showMatchDetailsModal,
        );
        break;
      case 0:
      default:
        content = CollectionTab(
          inventory: _inventory,
          onSkinTap: _showSkinDetailModal,
        );
    }

    return Column(
      children: [
        TopHeader(profile: _profile, title: 'PROFILE'),
        SubTabBar(
          tabs: _profileSubTabs,
          selectedIndex: _profileSubTab,
          onTabSelected: (index) => setState(() => _profileSubTab = index),
        ),
        const Divider(color: Colors.white10, height: 1),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            child: content,
          ),
        ),
      ],
    );
  }
}
