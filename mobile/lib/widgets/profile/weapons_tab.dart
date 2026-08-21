import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../services/valorant_api_service.dart';
import '../../theme/app_colors.dart';
import '../shop/shop_shared.dart';
import '../shop/skin_detail_modal.dart';

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
  String _selectedCategory = 'ALL'; // 'ALL', '❤️ WISHLIST', 'OWNED', 'Rifles', 'Sidearms', 'Melee', 'Snipers', 'SMGs', 'Shotguns', 'Heavies'
  String _selectedWeapon = 'ALL';   // Sub-weapon filter (e.g. 'Vandal', 'Phantom')
  String _selectedTier = 'ALL';     // Tier filter ('Exclusive', 'Ultra', etc.)

  List<Map<String, dynamic>> _allCatalog = [];
  List<Map<String, dynamic>> _filteredList = [];

  static const int _pageSize = 30;
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
    'Melee': ['ALL', 'Melee'],
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

      if (cat == '❤️ WISHLIST') {
        if (!widget.wishlist.contains(uuid)) {
          return false;
        }
      } else if (cat != 'ALL' && skinCategory != cat) {
        return false;
      }

      if (weapon != 'ALL' && skinWeapon != weapon) {
        return false;
      }
      if (tier != 'all') {
        final tierName = (skin['tierName'] as String).toLowerCase();
        if (!tierName.contains(tier)) {
          return false;
        }
      }
      if (query.isNotEmpty) {
        final name = (skin['displayName'] as String).toLowerCase();
        if (!name.contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();

    _visibleCount = _pageSize.clamp(0, _filteredList.isEmpty ? 1 : _filteredList.length);
  }

  void _showTierFilterSheet() {
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
      onTap: onTap,
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

  @override
  Widget build(BuildContext context) {
    final displayItems = _filteredList.take(_visibleCount).toList();
    final subWeaponsList = _categoryWeaponsMap[_selectedCategory] ?? [];

    return Column(
      children: [
        // Fixed Sticky Header (Sleek Modern Design)
        Container(
          color: AppColors.background,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Input + Edition Tier Button Row
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
                  const SizedBox(width: 10),

                  // Tier Filter Button with Active Badge
                  InkWell(
                    onTap: _showTierFilterSheet,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
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
                          const SizedBox(width: 6),
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
                ],
              ),

              const SizedBox(height: 12),

              // Level 1: Primary Category Chips
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

              // Level 2: Sub-Weapon Chips (Only shown when a category is selected)
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
                          activeColor: const Color(0xFFFFB74D), // Soft amber for sub-weapons
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

              // Skins Count Header
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

        // Scrollable Skins Grid
        Expanded(
          child: _filteredList.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(
                    child: Text(
                      _selectedCategory == '❤️ WISHLIST'
                          ? 'No wishlisted skins yet.\nTap the heart icon on any skin to add it to your wishlist!'
                          : (_selectedCategory == 'OWNED'
                              ? 'No owned skins found matching this filter.'
                              : 'No skins match your filters.'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white54, height: 1.4),
                    ),
                  ),
                )
              : GridView.builder(
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
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
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
                        final skinItem = ValorantApiService.resolveSkinItem(uuid, 0);
                        SkinDetailModal.show(
                          context,
                          skinItem,
                          isWishlisted: isLiked,
                          isOwned: isOwned,
                          onToggleWishlist: () => widget.onToggleWishlist?.call(uuid),
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
                                : (isOwned
                                    ? AppColors.success.withValues(alpha: 0.3)
                                    : Colors.white10),
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
                                  onTap: () => widget.onToggleWishlist?.call(uuid),
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
                ),
        ),
      ],
    );
  }
}
