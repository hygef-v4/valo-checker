import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../services/valorant_api_service.dart';
import '../../theme/app_colors.dart';
import '../shop/shop_shared.dart';
import '../shop/skin_detail_modal.dart';

enum ExplorerViewMode { detailed, compact, list }

class WeaponsTab extends StatefulWidget {
  final Set<String> wishlist;
  final OwnedSkinIndex? ownedIndex;
  final Function(String skinUuid)? onToggleWishlist;

  const WeaponsTab({
    super.key,
    this.wishlist = const {},
    this.ownedIndex,
    this.onToggleWishlist,
  });

  @override
  State<WeaponsTab> createState() => _WeaponsTabState();
}

class _WeaponsTabState extends State<WeaponsTab> {
  final ScrollController _scrollController = ScrollController();

  String _searchQuery = '';
  String _selectedCategory = 'ALL'; 
  String _selectedWeapon = 'ALL';   
  String _selectedTier = 'ALL';     
  ExplorerViewMode _viewMode = ExplorerViewMode.detailed;

  List<Map<String, dynamic>> _allCatalog = [];
  List<Map<String, dynamic>> _filteredList = [];

  static const int _pageSize = 36;
  int _visibleCount = _pageSize;

  static const List<String> _categories = [
    'ALL',
    '❤️ WISHLIST',
    'Rifles',
    'Sidearms',
    'Melee',
    'Snipers',
    'SMGs',
    'Shotguns',
    'Heavies',
  ];

  static const Map<String, List<String>> _categoryWeaponsMap = {
    'Rifles': ['ALL', 'Vandal', 'Phantom', 'Guardian', 'Bulldog'],
    'Sidearms': ['ALL', 'Sheriff', 'Ghost', 'Classic', 'Shorty', 'Frenzy'],
    'Melee': ['ALL', 'Karambit', 'Butterfly', 'Dagger', 'Sword', 'Axe', 'Scythe', 'Baton'],
    'Snipers': ['ALL', 'Operator', 'Outlaw', 'Marshal'],
    'SMGs': ['ALL', 'Spectre', 'Stinger'],
    'Shotguns': ['ALL', 'Bucky', 'Judge'],
    'Heavies': ['ALL', 'Odin', 'Ares'],
  };

  static const List<String> _tiers = [
    'ALL',
    'Exclusive',
    'Ultra',
    'Premium',
    'Deluxe',
    'Select',
  ];

  @override
  void initState() {
    super.initState();
    _allCatalog = ValorantApiService.getAllSkinsCatalog();
    _applyFilters();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant WeaponsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.wishlist != widget.wishlist || oldWidget.ownedIndex != widget.ownedIndex) {
      setState(() {
        _applyFilters();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 400) {
      if (_visibleCount < _filteredList.length) {
        setState(() {
          _visibleCount = (_visibleCount + _pageSize).clamp(0, _filteredList.length);
        });
      }
    }
  }

  void _applyFilters() {
    final query = _searchQuery.toLowerCase();
    final cat = _selectedCategory;
    final weapon = _selectedWeapon;
    final tier = _selectedTier.toLowerCase();

    _filteredList = _allCatalog.where((skin) {
      final uuid = (skin['uuid'] ?? '').toString();
      final skinCategory = (skin['category'] ?? '').toString();
      final skinWeapon = (skin['weaponName'] ?? skinCategory).toString();
      final displayName = (skin['displayName'] as String? ?? '');
      final lowerName = displayName.toLowerCase();

      if (cat == '❤️ WISHLIST') {
        if (!widget.wishlist.contains(uuid)) {
          return false;
        }
      } else if (cat != 'ALL' && skinCategory != cat) {
        return false;
      }

      if (cat == 'Melee' && weapon != 'ALL') {
        bool matchMeleeArchetype = false;
        switch (weapon) {
          case 'Karambit':
            matchMeleeArchetype = lowerName.contains('karambit') || lowerName.contains('claw');
            break;
          case 'Butterfly':
            matchMeleeArchetype = lowerName.contains('butterfly') || lowerName.contains('comb') || lowerName.contains('balisong');
            break;
          case 'Dagger':
            matchMeleeArchetype = lowerName.contains('dagger') || lowerName.contains('knife') || lowerName.contains('blade') || lowerName.contains('kunai');
            break;
          case 'Sword':
            matchMeleeArchetype = lowerName.contains('sword') || lowerName.contains('katana') || lowerName.contains('relic') || lowerName.contains('onimaru') || lowerName.contains('blade');
            break;
          case 'Axe':
            matchMeleeArchetype = lowerName.contains('axe') || lowerName.contains('hatchet');
            break;
          case 'Scythe':
            matchMeleeArchetype = lowerName.contains('scythe') || lowerName.contains('anchor');
            break;
          case 'Baton':
            matchMeleeArchetype = lowerName.contains('baton') || lowerName.contains('hammer') || lowerName.contains('mace') || lowerName.contains('cudgel') || lowerName.contains('staff');
            break;
          default:
            matchMeleeArchetype = lowerName.contains(weapon.toLowerCase());
        }
        if (!matchMeleeArchetype) return false;
      } else if (weapon != 'ALL' && skinWeapon != weapon) {
        return false;
      }

      if (tier != 'all') {
        final tierName = (skin['tierName'] as String).toLowerCase();
        if (!tierName.contains(tier)) {
          return false;
        }
      }
      if (query.isNotEmpty) {
        if (!lowerName.contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();

    _visibleCount = _pageSize.clamp(0, _filteredList.isEmpty ? 1 : _filteredList.length);
  }

  void _showTierFilterSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1B1B26),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'FILTER BY EDITION TIER',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 1.0,
                        ),
                      ),
                      if (_selectedTier != 'ALL')
                        TextButton(
                          onPressed: () {
                            setSheetState(() => _selectedTier = 'ALL');
                            setState(() => _applyFilters());
                          },
                          child: const Text('Reset', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _tiers.map((tier) {
                      final isSelected = _selectedTier == tier;
                      return ChoiceChip(
                        label: Text(tier),
                        selected: isSelected,
                        onSelected: (sel) {
                          if (sel) {
                            HapticFeedback.selectionClick();
                            setSheetState(() => _selectedTier = tier);
                            setState(() => _applyFilters());
                            Navigator.pop(context);
                          }
                        },
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surface,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? activeColor,
  }) {
    final themeColor = activeColor ?? AppColors.primary;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? themeColor.withValues(alpha: 0.2) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? themeColor.withValues(alpha: 0.8) : Colors.white12,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  void _cycleViewMode() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_viewMode == ExplorerViewMode.detailed) {
        _viewMode = ExplorerViewMode.compact;
      } else if (_viewMode == ExplorerViewMode.compact) {
        _viewMode = ExplorerViewMode.list;
      } else {
        _viewMode = ExplorerViewMode.detailed;
      }
    });
  }

  IconData _getViewModeIcon() {
    switch (_viewMode) {
      case ExplorerViewMode.detailed:
        return Icons.grid_view_rounded;
      case ExplorerViewMode.compact:
        return Icons.view_comfy_rounded;
      case ExplorerViewMode.list:
        return Icons.view_list_rounded;
    }
  }

  String _getViewModeTooltip() {
    switch (_viewMode) {
      case ExplorerViewMode.detailed:
        return 'Detailed Cards';
      case ExplorerViewMode.compact:
        return 'Compact Grid';
      case ExplorerViewMode.list:
        return 'List View';
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayItems = _filteredList.take(_visibleCount).toList();
    final subWeaponsList = _categoryWeaponsMap[_selectedCategory] ?? [];

    return Column(
      children: [
        Container(
          color: AppColors.background,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        onChanged: (val) {
                          _searchQuery = val;
                          setState(() {
                            _applyFilters();
                          });
                        },
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Search skin name...',
                          hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                          prefixIcon: Icon(Icons.search, color: Colors.white38, size: 20),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 11),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  InkWell(
                    onTap: _showTierFilterSheet,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: _selectedTier != 'ALL' ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedTier != 'ALL' ? AppColors.primary : Colors.white12,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            color: _selectedTier != 'ALL' ? AppColors.primary : Colors.white70,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _selectedTier == 'ALL' ? 'Tier' : _selectedTier,
                            style: TextStyle(
                              color: _selectedTier != 'ALL' ? Colors.white : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  InkWell(
                    onTap: _cycleViewMode,
                    borderRadius: BorderRadius.circular(12),
                    child: Tooltip(
                      message: _getViewModeTooltip(),
                      child: Container(
                        height: 42,
                        width: 42,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Icon(
                          _getViewModeIcon(),
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((cat) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: _buildFilterPill(
                        label: cat,
                        isSelected: _selectedCategory == cat,
                        onTap: () {
                          setState(() {
                            _selectedCategory = cat;
                            _selectedWeapon = 'ALL';
                            _applyFilters();
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              if (subWeaponsList.isNotEmpty) ...[
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: subWeaponsList.map((w) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: _buildFilterPill(
                          label: w,
                          isSelected: _selectedWeapon == w,
                          activeColor: const Color(0xFFFFB74D),
                          onTap: () {
                            setState(() {
                              _selectedWeapon = w;
                              _applyFilters();
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SKINS (${_filteredList.length})',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  if (widget.wishlist.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedCategory = _selectedCategory == '❤️ WISHLIST' ? 'ALL' : '❤️ WISHLIST';
                          _selectedWeapon = 'ALL';
                          _applyFilters();
                        });
                      },
                      child: Text(
                        '❤️ ${widget.wishlist.length} Wishlisted',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        const Divider(color: Colors.white10, height: 1),

        Expanded(
          child: _filteredList.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(
                    child: Text(
                      _selectedCategory == '❤️ WISHLIST'
                          ? 'No wishlisted skins yet.\nTap the heart icon on any skin to add it to your wishlist!'
                          : 'No skins match your filters.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white54, height: 1.4),
                    ),
                  ),
                )
              : _buildSkinsView(displayItems),
        ),
      ],
    );
  }

  Widget _buildSkinsView(List<Map<String, dynamic>> displayItems) {
    switch (_viewMode) {
      case ExplorerViewMode.compact:
        return _buildCompactGrid(displayItems);
      case ExplorerViewMode.list:
        return _buildListView(displayItems);
      case ExplorerViewMode.detailed:
        return _buildDetailedGrid(displayItems);
    }
  }

  Widget _buildDetailedGrid(List<Map<String, dynamic>> displayItems) {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.25,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: displayItems.length + (_visibleCount < _filteredList.length ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == displayItems.length) {
          return const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
          );
        }

        final skinData = displayItems[index];
        final uuid = skinData['uuid'] as String;
        final name = skinData['displayName'] as String;
        final icon = skinData['displayIcon'] as String;
        final tierName = skinData['tierName'] as String;
        final isLiked = widget.wishlist.contains(uuid);
        final isOwned = widget.ownedIndex?.containsUuid(uuid) == true ||
            widget.ownedIndex?.containsName(name) == true;

        final shortTier = tierName
            .replaceAll(RegExp(r'\s+edition', caseSensitive: false), '')
            .trim()
            .toUpperCase();

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            final skinItem = ValorantApiService.resolveSkinItem(uuid, 0);
            SkinDetailModal.show(
              context,
              skinItem,
              isWishlisted: isLiked,
              isOwned: isOwned,
              onToggleWishlist: () {
                HapticFeedback.lightImpact();
                widget.onToggleWishlist?.call(uuid);
              },
            );
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isLiked
                    ? AppColors.primary.withValues(alpha: 0.6)
                    : (isOwned ? AppColors.success.withValues(alpha: 0.3) : Colors.white10),
                width: isLiked || isOwned ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                shortTier,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          if (isOwned) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check, color: AppColors.success, size: 9),
                                  SizedBox(width: 2),
                                  Text(
                                    'OWNED',
                                    style: TextStyle(
                                      color: AppColors.success,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        widget.onToggleWishlist?.call(uuid);
                      },
                      child: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? AppColors.primary : Colors.white38,
                        size: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Center(
                    child: icon.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: icon,
                            fit: BoxFit.contain,
                            memCacheWidth: 240,
                            errorWidget: (context, url, error) => const Icon(Icons.shield, color: Colors.white24, size: 36),
                          )
                        : const Icon(Icons.shield, color: Colors.white24, size: 36),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactGrid(List<Map<String, dynamic>> displayItems) {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.88,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: displayItems.length + (_visibleCount < _filteredList.length ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == displayItems.length) {
          return const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
          );
        }

        final skinData = displayItems[index];
        final uuid = skinData['uuid'] as String;
        final name = skinData['displayName'] as String;
        final icon = skinData['displayIcon'] as String;
        final isLiked = widget.wishlist.contains(uuid);
        final isOwned = widget.ownedIndex?.containsUuid(uuid) == true ||
            widget.ownedIndex?.containsName(name) == true;

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            final skinItem = ValorantApiService.resolveSkinItem(uuid, 0);
            SkinDetailModal.show(
              context,
              skinItem,
              isWishlisted: isLiked,
              isOwned: isOwned,
              onToggleWishlist: () {
                HapticFeedback.lightImpact();
                widget.onToggleWishlist?.call(uuid);
              },
            );
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isLiked
                    ? AppColors.primary.withValues(alpha: 0.7)
                    : (isOwned ? AppColors.success.withValues(alpha: 0.35) : Colors.white10),
                width: isLiked || isOwned ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (isOwned)
                      const Icon(Icons.check_circle, color: AppColors.success, size: 12)
                    else
                      const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        widget.onToggleWishlist?.call(uuid);
                      },
                      child: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? AppColors.primary : Colors.white24,
                        size: 14,
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Center(
                    child: icon.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: icon,
                            fit: BoxFit.contain,
                            memCacheWidth: 160,
                            errorWidget: (context, url, error) => const Icon(Icons.shield, color: Colors.white24, size: 24),
                          )
                        : const Icon(Icons.shield, color: Colors.white24, size: 24),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildListView(List<Map<String, dynamic>> displayItems) {
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: displayItems.length + (_visibleCount < _filteredList.length ? 1 : 0),
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == displayItems.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(12.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
            ),
          );
        }

        final skinData = displayItems[index];
        final uuid = skinData['uuid'] as String;
        final name = skinData['displayName'] as String;
        final icon = skinData['displayIcon'] as String;
        final tierName = skinData['tierName'] as String;
        final isLiked = widget.wishlist.contains(uuid);
        final isOwned = widget.ownedIndex?.containsUuid(uuid) == true ||
            widget.ownedIndex?.containsName(name) == true;

        final shortTier = tierName
            .replaceAll(RegExp(r'\s+edition', caseSensitive: false), '')
            .trim()
            .toUpperCase();

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            final skinItem = ValorantApiService.resolveSkinItem(uuid, 0);
            SkinDetailModal.show(
              context,
              skinItem,
              isWishlisted: isLiked,
              isOwned: isOwned,
              onToggleWishlist: () {
                HapticFeedback.lightImpact();
                widget.onToggleWishlist?.call(uuid);
              },
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isLiked
                    ? AppColors.primary.withValues(alpha: 0.6)
                    : (isOwned ? AppColors.success.withValues(alpha: 0.3) : Colors.white10),
                width: isLiked || isOwned ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 44,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: icon.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: icon,
                          fit: BoxFit.contain,
                          memCacheWidth: 120,
                          errorWidget: (context, url, error) => const Icon(Icons.shield, color: Colors.white24, size: 24),
                        )
                      : const Icon(Icons.shield, color: Colors.white24, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              shortTier,
                              style: const TextStyle(color: Colors.white60, fontSize: 8.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (isOwned) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'OWNED',
                                style: TextStyle(color: AppColors.success, fontSize: 8.5, fontWeight: FontWeight.w900),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.onToggleWishlist?.call(uuid);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? AppColors.primary : Colors.white38,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
