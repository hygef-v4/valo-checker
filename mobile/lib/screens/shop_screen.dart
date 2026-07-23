import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/user_profile.dart';
import '../models/skin_item.dart';
import '../models/bundle_item.dart';
import '../models/accessory_item.dart';
import '../models/rank_info.dart';
import '../models/match_summary.dart';
import '../models/quest_item.dart';
import '../services/riot_auth_service.dart';
import '../services/valorant_api_service.dart';
import '../services/wishlist_service.dart';
import '../services/local_cache_service.dart';
import '../widgets/common/shimmer_loading_skeleton.dart';
import '../widgets/match/match_details_modal.dart';
import '../widgets/match/weapon_analytics_card.dart';
import '../widgets/profile/agent_stats_summary.dart';
import '../widgets/shop/skin_detail_modal.dart';
import '../utils/match_team_helper.dart';
import 'riot_login_webview.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  int _currentNavIndex = 0; // 0: Shop, 1: Profile, 2: Accounts
  int _shopSubTab = 0; // 0: Daily Shop, 1: Accessory Shop, 2: Night Market, 3: Bundles
  int _profileSubTab = 0; // 0: Collection, 1: Agents, 2: Career/Rank

  bool _isLoading = false;
  String? _error;

  UserProfile? _profile;
  List<SkinItem> _dailySkins = [];
  List<Map<String, dynamic>> _nightMarketSkins = [];
  List<BundleItem> _bundles = [];
  List<AccessoryItem> _accessories = [];
  List<SkinItem> _inventory = [];
  RankInfo? _rankInfo;
  List<MatchSummary> _matchHistory = [];
  List<QuestItem> _quests = [];
  Set<String> _ownedAgents = {};
  Set<String> _wishlistUuids = {};
  int _selectedAgentIndex = 0;

  int _remainingSeconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    final set = await WishlistService.getWishlist();
    if (mounted) {
      setState(() {
        _wishlistUuids = set;
      });
    }
  }

  Future<void> _toggleWishlist(String uuid) async {
    await WishlistService.toggleWishlist(uuid);
    await _loadWishlist();
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        if (mounted) {
          setState(() {
            _remainingSeconds--;
          });
        }
      } else {
        timer.cancel();
      }
    });
  }

  String _formatTimer(int totalSeconds) {
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  Future<void> _handleLogin() async {
    final result = await Navigator.of(context).push<Map<String, String>>(
      MaterialPageRoute(builder: (context) => const RiotLoginWebview()),
    );

    if (result != null && result.containsKey('accessToken')) {
      _loadStoreData(result['accessToken']!, result['idToken'] ?? '');
    }
  }

  Future<void> _loadStoreData(String accessToken, String idToken) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await RiotAuthService.fetchStorefrontData(accessToken, idToken);
      if (!mounted) return;
      setState(() {
        _profile = data['profile'] as UserProfile;
        _dailySkins = data['dailySkins'] as List<SkinItem>;
        _nightMarketSkins = data['nightMarket'] as List<Map<String, dynamic>>;
        _bundles = data['bundles'] as List<BundleItem>;
        _accessories = data['accessories'] as List<AccessoryItem>;
        _inventory = data['inventory'] as List<SkinItem>;
        _rankInfo = data['rankInfo'] as RankInfo?;
        _matchHistory = data['matchHistory'] as List<MatchSummary>;
        _quests = data['quests'] as List<QuestItem>;
        _ownedAgents = data['ownedAgents'] as Set<String>? ?? {};
        _remainingSeconds = data['remainingSeconds'] as int;
      });
      _startCountdown();
      if (_profile != null) {
        LocalCacheService.saveProfile({
          'gameName': _profile!.gameName,
          'tagLine': _profile!.tagLine,
          'puuid': _profile!.puuid,
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSkinDetailModal(SkinItem skin) {
    SkinDetailModal.show(context, skin);
  }



  void _showAgentDetailModal(String agentUuid) {
    final agentData = ValorantApiService.getAgentFullData(agentUuid);
    if (agentData == null) return;

    final name = (agentData['displayName'] ?? 'Agent').toString();
    final description = (agentData['description'] ?? 'Valorant Protocol Agent.').toString();
    final fullPortrait = (agentData['fullPortrait'] ?? agentData['displayIcon'] ?? '').toString();
    final roleName = (agentData['role']?['displayName'] ?? 'Initiator').toString();
    final roleIcon = (agentData['role']?['displayIcon'] ?? '').toString();
    final abilities = (agentData['abilities'] as List? ?? []);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1B1B26),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Agent Header & Role Badge
                Row(
                  children: [
                    if (roleIcon.isNotEmpty)
                      CachedNetworkImage(imageUrl: roleIcon, width: 24, height: 24)
                    else
                      const Icon(Icons.flash_on, color: Color(0xFFFF4655), size: 24),
                    const SizedBox(width: 8),
                    Text(
                      roleName.toUpperCase(),
                      style: const TextStyle(color: Color(0xFFFF4655), fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.2),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  name.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 28, letterSpacing: 1.5),
                ),
                const SizedBox(height: 12),

                // Full Portrait
                if (fullPortrait.isNotEmpty)
                  Center(
                    child: CachedNetworkImage(imageUrl: fullPortrait, height: 220, fit: BoxFit.contain),
                  ),
                const SizedBox(height: 16),

                // Lore Biography
                const Text('BIOGRAPHY', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.0)),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 20),

                // Abilities Header
                const Text('ABILITIES', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2)),
                const SizedBox(height: 12),

                // List of 4 Abilities
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: abilities.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final ab = abilities[index];
                    final abName = (ab['displayName'] ?? 'Ability').toString();
                    final abDesc = (ab['description'] ?? '').toString();
                    final abIcon = (ab['displayIcon'] ?? '').toString();
                    final slot = (ab['slot'] ?? 'Ability').toString();

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: const Color(0xFFFF4655).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                            child: abIcon.isNotEmpty
                                ? CachedNetworkImage(imageUrl: abIcon, fit: BoxFit.contain)
                                : const Icon(Icons.flash_on, color: Color(0xFFFF4655), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(abName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4)),
                                      child: Text(slot, style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(abDesc, style: const TextStyle(color: Colors.white60, fontSize: 12, height: 1.3)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _cleanGameMode(String rawMode) {
    if (rawMode.isEmpty) return 'Competitive';
    final lower = rawMode.toLowerCase();

    if (lower.contains('hurm') || lower.contains('tdm')) return 'Team Deathmatch';
    if (lower.contains('skirmish')) return 'Skirmish';
    if (lower.contains('competitive') || lower.contains('bomb_c') || lower == 'bomb_c') return 'Competitive';
    if (lower.contains('unrated') || lower.contains('bomb_u') || lower == 'bomb_u') return 'Unrated';
    if (lower.contains('swiftplay') || lower.contains('bomb_s') || lower == 'swift') return 'Swiftplay';
    if (lower.contains('spikerush') || lower.contains('spike_rush')) return 'Spike Rush';
    if (lower.contains('deathmatch') || lower.contains('dm')) return 'Deathmatch';
    if (lower.contains('gungame') || lower.contains('escalation')) return 'Escalation';
    if (lower.contains('oneforall') || lower.contains('replication')) return 'Replication';
    if (lower.contains('snowball')) return 'Snowball Fight';
    if (lower.contains('premier')) return 'Premier';
    if (lower.contains('bomb')) return 'Competitive';

    final cleaned = rawMode
        .replaceAll(RegExp(r'.*Gamemode\.', caseSensitive: false), '')
        .replaceAll(RegExp(r'GameMode', caseSensitive: false), '')
        .replaceAll('_C', '')
        .replaceAll('_U', '')
        .trim();

    return cleaned.isNotEmpty ? cleaned : 'Competitive';
  }

  void _showMatchDetailsModal(MatchSummary match) {
    final teams = MatchTeamHelper.generateMatchTeams(
      match: match,
      profile: _profile,
      rankInfo: _rankInfo,
      ownedAgents: _ownedAgents,
    );
    MatchDetailsModal.show(
      context,
      match: match,
      profile: _profile,
      teams: teams,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121218),
      bottomNavigationBar: _profile != null
          ? BottomNavigationBar(
              currentIndex: _currentNavIndex,
              onTap: (index) {
                setState(() {
                  _currentNavIndex = index;
                });
              },
              backgroundColor: const Color(0xFF1B1B26),
              selectedItemColor: const Color(0xFFFF4655),
              unselectedItemColor: Colors.white38,
              type: BottomNavigationBarType.fixed,
              selectedFontSize: 11,
              unselectedFontSize: 11,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.shopping_basket_outlined),
                  activeIcon: Icon(Icons.shopping_basket, color: Color(0xFFFF4655)),
                  label: 'Shop',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person, color: Color(0xFFFF4655)),
                  label: 'Profile',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.group_outlined),
                  activeIcon: Icon(Icons.group, color: Color(0xFFFF4655)),
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
                color: const Color(0xFFFF4655).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(
                color: Color(0xFFFF4655),
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
                color: const Color(0xFFFF4655).withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFF4655).withValues(alpha: 0.4), width: 2),
              ),
              child: const Icon(Icons.shield_outlined, color: Color(0xFFFF4655), size: 44),
            ),
            const SizedBox(height: 24),
            const Text(
              'VALORANT TRACKER',
              style: TextStyle(
                color: Color(0xFFECE8E1),
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Track Daily Store, Night Market, Career Rank & Collection directly on your mobile device!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4655),
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
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader(String titleText) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFF121218),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Avatar + Username Row
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFF4655).withValues(alpha: 0.5), width: 1.5),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: (_profile?.cardIcon.isNotEmpty ?? false)
                            ? CachedNetworkImage(
                                imageUrl: _profile!.cardIcon,
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) => Container(
                                  color: const Color(0xFFFF4655).withValues(alpha: 0.2),
                                  child: const Icon(Icons.person, color: Color(0xFFFF4655), size: 20),
                                ),
                              )
                            : Container(
                                color: const Color(0xFFFF4655).withValues(alpha: 0.2),
                                child: const Icon(Icons.person, color: Color(0xFFFF4655), size: 20),
                              ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _profile?.riotId ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Currency Balances Pill Bar
              Row(
                children: [
                  _buildCurrencyPill('https://media.valorant-api.com/currencies/85ad13f7-3d1b-da12-a0a0-4e907616386c/displayicon.png', '${_profile?.vp ?? 0}'),
                  const SizedBox(width: 6),
                  _buildCurrencyPill('https://media.valorant-api.com/currencies/e59aa87c-4c57-90ab-d663-2a4895203a25/displayicon.png', '${_profile?.rad ?? 0}'),
                  const SizedBox(width: 6),
                  _buildCurrencyPill('https://media.valorant-api.com/currencies/85ca954a-41f2-ce94-9b45-8ca3dd39a00d/displayicon.png', '${_profile?.kc ?? 0}'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            titleText,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 28,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyPill(String iconUrl, String amount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          CachedNetworkImage(
            imageUrl: iconUrl,
            width: 16,
            height: 16,
            fit: BoxFit.contain,
            placeholder: (context, url) => const SizedBox(width: 16, height: 16),
            errorWidget: (context, url, error) => const Icon(Icons.monetization_on, color: Colors.amber, size: 16),
          ),
          const SizedBox(width: 6),
          Text(
            amount,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveMainTab() {
    switch (_currentNavIndex) {
      case 0:
        return _buildShopMainTab();
      case 1:
        return _buildProfileMainTab();
      case 2:
        return _buildAccountsMainTab();
      default:
        return _buildShopMainTab();
    }
  }

  // --- TAB 1: SHOP ---
  Widget _buildShopMainTab() {
    final subTabs = ['DAILY SHOP', 'ACCESSORY SHOP', 'NIGHT MARKET', 'BUNDLES'];

    return Column(
      children: [
        _buildTopHeader('STORE'),
        // Top Sub-tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: List.generate(subTabs.length, (index) {
              final isSelected = _shopSubTab == index;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _shopSubTab = index;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isSelected ? const Color(0xFFFF4655) : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    subTabs[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white38,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const Divider(color: Colors.white10, height: 1),
        Expanded(
          child: _buildShopSubTabContent(),
        ),
      ],
    );
  }

  Widget _buildShopSubTabContent() {
    switch (_shopSubTab) {
      case 0:
        return _buildDailyShopContent();
      case 1:
        return _buildAccessoryShopContent();
      case 2:
        return _buildNightMarketContent();
      case 3:
        return _buildBundlesContent();
      default:
        return _buildDailyShopContent();
    }
  }

  Widget _buildDailyShopContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'TIME LEFT:',
              style: TextStyle(
                color: Colors.white54,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              _formatTimer(_remainingSeconds),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _dailySkins.length,
          itemBuilder: (context, index) {
            return _buildCleanSkinCard(_dailySkins[index]);
          },
        ),
      ],
    );
  }

  Widget _buildAccessoryShopContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'NEXT OFFER:',
              style: TextStyle(
                color: Colors.white54,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
            const Text(
              '05:09:20:03',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_accessories.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(
              child: Text('Accessory Shop is currently unavailable.', style: TextStyle(color: Colors.white54)),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1,
              childAspectRatio: 2.2,
              mainAxisSpacing: 12,
            ),
            itemCount: _accessories.length,
            itemBuilder: (context, index) {
              final acc = _accessories[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1B26),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      acc.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (acc.displayIcon.isNotEmpty)
                          CachedNetworkImage(imageUrl: acc.displayIcon, height: 50, fit: BoxFit.contain)
                        else
                          const Icon(Icons.stars, color: Colors.white24, size: 40),
                        Row(
                          children: [
                            const Icon(Icons.diamond_outlined, color: Colors.white70, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${acc.costKC}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildNightMarketContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'TIME LEFT:',
              style: TextStyle(
                color: Colors.white54,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
            const Text(
              '06:09:19:51',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_nightMarketSkins.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(
              child: Text('Night Market is not active.', style: TextStyle(color: Colors.white54)),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1,
              childAspectRatio: 2.0,
              mainAxisSpacing: 12,
            ),
            itemCount: _nightMarketSkins.length,
            itemBuilder: (context, index) {
              final item = _nightMarketSkins[index];
              final skin = item['skin'] as SkinItem;
              final original = item['originalCost'] as int? ?? 1775;
              final discount = item['discountPercent'] as int? ?? 37;

              return InkWell(
                onTap: () => _showSkinDetailModal(skin),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1B26),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            skin.parentName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            'SPECTRE',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$original',
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 12,
                                      decoration: TextDecoration.lineThrough,
                                      decorationColor: Colors.redAccent,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.monetization_on_outlined, color: Colors.white, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${skin.cost}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (skin.displayIcon.isNotEmpty)
                                CachedNetworkImage(imageUrl: skin.displayIcon, height: 75, fit: BoxFit.contain),
                            ],
                          ),
                        ],
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Text(
                          '-$discount%',
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildBundlesContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_bundles.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(
              child: Text('No Featured Bundles active.', style: TextStyle(color: Colors.white54)),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _bundles.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final b = _bundles[index];
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1B26),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (b.displayIcon.isNotEmpty)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: CachedNetworkImage(imageUrl: b.displayIcon, height: 180, fit: BoxFit.cover),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            b.displayName.toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            '${b.cost} VP',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  // --- TAB 2: PROFILE ---
  Widget _buildProfileMainTab() {
    final subTabs = ['COLLECTION', 'AGENTS', 'CAREER'];

    return Column(
      children: [
        _buildTopHeader('PROFILE'),
        // Top Sub-tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: List.generate(subTabs.length, (index) {
              final isSelected = _profileSubTab == index;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _profileSubTab = index;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isSelected ? const Color(0xFFFF4655) : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    subTabs[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white38,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const Divider(color: Colors.white10, height: 1),
        Expanded(
          child: _buildProfileSubTabContent(),
        ),
      ],
    );
  }

  Widget _buildProfileSubTabContent() {
    switch (_profileSubTab) {
      case 0:
        return _buildCollectionContent();
      case 1:
        return _buildAgentsContent();
      case 2:
        return _buildCareerContent();
      default:
        return _buildCollectionContent();
    }
  }

  Widget _buildCollectionContent() {
    final Map<String, SkinItem> uniqueInventory = {};
    for (var skin in _inventory) {
      final key = skin.parentName;
      if (!uniqueInventory.containsKey(key)) {
        uniqueInventory[key] = skin;
      }
    }
    final displayInventory = uniqueInventory.values.toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (displayInventory.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(
              child: Text('No weapon skins found in collection.', style: TextStyle(color: Colors.white54)),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayInventory.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final skin = displayInventory[index];
              return InkWell(
                onTap: () => _showSkinDetailModal(skin),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1B26),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        skin.parentName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (skin.displayIcon.isNotEmpty)
                        Center(
                          child: CachedNetworkImage(
                            imageUrl: skin.displayIcon,
                            height: 70,
                            fit: BoxFit.contain,
                          ),
                        )
                      else
                        const Center(child: Icon(Icons.shield, color: Colors.white24, size: 50)),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildAgentsContent() {
    final agentsList = ValorantApiService.getPlayableAgentsList(_ownedAgents);

    if (agentsList.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF4655)),
      );
    }

    if (_selectedAgentIndex >= agentsList.length) {
      _selectedAgentIndex = 0;
    }

    final activeAgent = agentsList[_selectedAgentIndex];
    final isOwned = activeAgent['isOwned'] as bool? ?? false;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GestureDetector(
          onTap: () {
            _showAgentDetailModal(activeAgent['uuid']);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1B1B26),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      (activeAgent['displayName'] as String).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 28,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Icon(Icons.info_outline, color: Color(0xFFFF4655), size: 22),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      isOwned ? Icons.check_circle : Icons.lock,
                      color: isOwned ? const Color(0xFF34D399) : Colors.redAccent,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOwned ? 'Owned' : 'Locked',
                      style: TextStyle(
                        color: isOwned ? const Color(0xFF34D399) : Colors.redAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if ((activeAgent['fullPortrait'] as String).isNotEmpty)
                  Center(
                    child: CachedNetworkImage(
                      imageUrl: activeAgent['fullPortrait'],
                      height: 260,
                      fit: BoxFit.contain,
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.flash_on, color: Colors.white70, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            activeAgent['roleName'] as String,
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      'TAP FOR ABILITIES & LORE ➔',
                      style: TextStyle(color: Color(0xFFFF4655), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: agentsList.length,
            itemBuilder: (context, index) {
              final a = agentsList[index];
              final isSelected = index == _selectedAgentIndex;
              final agentOwned = a['isOwned'] as bool? ?? false;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedAgentIndex = index;
                  });
                },
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1B26),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFFF4655) : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: CachedNetworkImage(
                          imageUrl: a['displayIcon'],
                          width: 80,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.black87,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            agentOwned ? Icons.check : Icons.lock,
                            color: agentOwned ? const Color(0xFF34D399) : Colors.white54,
                            size: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCareerContent() {
    final rank = _rankInfo;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (rank != null)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1B1B26),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFF4655).withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                if (rank.currentTierIcon.isNotEmpty)
                  CachedNetworkImage(imageUrl: rank.currentTierIcon, height: 80)
                else
                  const Icon(Icons.military_tech, color: Color(0xFFFF4655), size: 70),
                const SizedBox(height: 12),
                Text(
                  rank.currentTierName.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${rank.currentRR} / 100 RR',
                  style: const TextStyle(
                    color: Color(0xFFFF4655),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: (rank.currentRR % 100) / 100.0,
                    minHeight: 8,
                    backgroundColor: Colors.white10,
                    color: const Color(0xFFFF4655),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('PEAK RANK', style: TextStyle(color: Colors.white38, fontSize: 10)),
                        const SizedBox(height: 4),
                        Text(rank.peakTierName, style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('WIN / TOTAL', style: TextStyle(color: Colors.white38, fontSize: 10)),
                        const SizedBox(height: 4),
                        Text('${rank.totalWins} / ${rank.totalGames}', style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        AgentStatsSummary(matchHistory: _matchHistory),
        const SizedBox(height: 16),
        WeaponAnalyticsCard(matchHistory: _matchHistory, userPuuid: _profile?.puuid ?? ''),
        const SizedBox(height: 24),
        const Text(
          'ACTIVE QUESTS & BATTLEPASS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        if (_quests.isEmpty)
          const Text('No active quests.', style: TextStyle(color: Colors.white54))
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _quests.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final q = _quests[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1B26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(q.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('+${q.rewardXP} XP', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              );
            },
          ),
        const SizedBox(height: 24),
        const Text(
          'RECENT 20 MATCHES',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _matchHistory.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final m = _matchHistory[index];
            return GestureDetector(
              onTap: () {
                _showMatchDetailsModal(m);
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1B26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                      child: m.agentIcon.isNotEmpty ? CachedNetworkImage(imageUrl: m.agentIcon, fit: BoxFit.cover) : const Icon(Icons.person, color: Colors.white38),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                m.isVictory ? 'VICTORY (${m.scoreText})' : 'DEFEAT (${m.scoreText})',
                                style: TextStyle(
                                  color: m.isVictory ? const Color(0xFF34D399) : Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _cleanGameMode(m.gameMode).toUpperCase(),
                                  style: const TextStyle(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.w900),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text('Map: ${m.mapName} • ${m.agentName}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('K / D / A', style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text('${m.kills}/${m.deaths}/${m.assists}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_right, color: Colors.white38, size: 18),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // --- TAB 3: ACCOUNTS ---
  Widget _buildAccountsMainTab() {
    final rankText = _rankInfo != null ? '${_rankInfo!.currentTierName} - ${_rankInfo!.currentRR} RR' : 'UNRANKED';
    final rankIcon = _rankInfo != null ? _rankInfo!.currentTierIcon : '';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'ACCOUNTS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 28,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 20),

        // Account Card matching Screenshot 1
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1B1B26),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Player Card Banner with Level Badge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: (_profile?.cardIcon.isNotEmpty ?? false)
                            ? CachedNetworkImage(
                                imageUrl: _profile!.cardIcon,
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) => Container(
                                  width: 70,
                                  height: 70,
                                  color: const Color(0xFFFF4655).withValues(alpha: 0.2),
                                  child: const Icon(Icons.person, color: Color(0xFFFF4655), size: 36),
                                ),
                              )
                            : Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF4655).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.person, color: Color(0xFFFF4655), size: 36),
                              ),
                      ),
                      Positioned(
                        top: -6,
                        left: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF121218),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white38, width: 1.2),
                          ),
                          child: Text(
                            '${_profile?.accountLevel ?? 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _profile?.riotId ?? 'Riot User',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (rankIcon.isNotEmpty)
                              CachedNetworkImage(imageUrl: rankIcon, width: 20, height: 20)
                            else
                              const Icon(Icons.shield, color: Colors.amber, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              rankText,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF4655),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          setState(() {
                            _currentNavIndex = 0;
                          });
                        },
                        child: const Text(
                          'Select',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.logout, color: Color(0xFFFF4655), size: 20),
                      onPressed: () {
                        setState(() {
                          _profile = null;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4655),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _handleLogin,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Add Account',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCleanSkinCard(SkinItem skin) {
    final isWishlisted = _wishlistUuids.contains(skin.uuid);

    return InkWell(
      onTap: () => _showSkinDetailModal(skin),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1B1B26),
          borderRadius: BorderRadius.circular(16),
          border: isWishlisted ? Border.all(color: const Color(0xFFFF4655), width: 1.5) : null,
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: Text(
                    skin.parentName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.monetization_on_outlined, color: Colors.white70, size: 12),
                    const SizedBox(width: 2),
                    Text(
                      '${skin.cost}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (skin.displayIcon.isNotEmpty)
                  Center(
                    child: CachedNetworkImage(
                      imageUrl: skin.displayIcon,
                      height: 60,
                      fit: BoxFit.contain,
                    ),
                  )
                else
                  const Center(child: Icon(Icons.shield, color: Colors.white24, size: 40)),
              ],
            ),
            Positioned(
              top: -8,
              right: -8,
              child: IconButton(
                icon: Icon(
                  isWishlisted ? Icons.favorite : Icons.favorite_border,
                  color: isWishlisted ? const Color(0xFFFF4655) : Colors.white38,
                  size: 18,
                ),
                onPressed: () => _toggleWishlist(skin.uuid),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
