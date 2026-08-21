import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/skin_item.dart';
import '../../theme/app_colors.dart';

enum CollectionViewMode { detailed, compact, list }

class CollectionTab extends StatefulWidget {
  final List<SkinItem> inventory;
  final ValueChanged<SkinItem> onSkinTap;

  const CollectionTab({
    super.key,
    required this.inventory,
    required this.onSkinTap,
  });

  @override
  State<CollectionTab> createState() => _CollectionTabState();
}

class _CollectionTabState extends State<CollectionTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'ALL';
  CollectionViewMode _viewMode = CollectionViewMode.detailed;

  static const List<String> _categories = [
    'ALL',
    'Rifles',
    'Sidearms',
    'Melee',
    'Snipers',
    'SMGs',
    'Shotguns',
    'Heavies',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static String _resolveCategory(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('vandal') || lower.contains('phantom') || lower.contains('guardian') || lower.contains('bulldog')) {
      return 'Rifles';
    }
    if (lower.contains('sheriff') || lower.contains('ghost') || lower.contains('classic') || lower.contains('shorty') || lower.contains('frenzy')) {
      return 'Sidearms';
    }
    if (lower.contains('operator') || lower.contains('outlaw') || lower.contains('marshal')) {
      return 'Snipers';
    }
    if (lower.contains('spectre') || lower.contains('stinger')) {
      return 'SMGs';
    }
    if (lower.contains('bucky') || lower.contains('judge')) {
      return 'Shotguns';
    }
    if (lower.contains('odin') || lower.contains('ares')) {
      return 'Heavies';
    }
    return 'Melee';
  }

  List<SkinItem> _getUniqueSkins() {
    final Map<String, SkinItem> uniqueMap = {};
    for (var skin in widget.inventory) {
      uniqueMap.putIfAbsent(skin.parentName, () => skin);
    }
    return uniqueMap.values.toList();
  }

  List<SkinItem> _getFilteredSkins(List<SkinItem> allUnique) {
    final query = _searchQuery.trim().toLowerCase();
    return allUnique.where((skin) {
      final name = skin.parentName.toLowerCase();
      final category = _resolveCategory(skin.parentName);

      if (_selectedCategory != 'ALL' && category != _selectedCategory) {
        return false;
      }

      if (query.isNotEmpty && !name.contains(query)) {
        return false;
      }

      return true;
    }).toList();
  }

  Map<String, int> _getCategoryCounts(List<SkinItem> allUnique) {
    final Map<String, int> counts = {'ALL': allUnique.length};
    for (var skin in allUnique) {
      final cat = _resolveCategory(skin.parentName);
      counts[cat] = (counts[cat] ?? 0) + 1;
    }
    return counts;
  }

  void _cycleViewMode() {
    HapticFeedback.selectionClick();
    setState(() {
      switch (_viewMode) {
        case CollectionViewMode.detailed:
          _viewMode = CollectionViewMode.compact;
          break;
        case CollectionViewMode.compact:
          _viewMode = CollectionViewMode.list;
          break;
        case CollectionViewMode.list:
          _viewMode = CollectionViewMode.detailed;
          break;
      }
    });
  }

  IconData _getViewModeIcon() {
    switch (_viewMode) {
      case CollectionViewMode.detailed:
        return Icons.grid_view_rounded;
      case CollectionViewMode.compact:
        return Icons.apps_rounded;
      case CollectionViewMode.list:
        return Icons.view_agenda_outlined;
    }
  }

  String _getViewModeLabel() {
    switch (_viewMode) {
      case CollectionViewMode.detailed:
        return 'Card';
      case CollectionViewMode.compact:
        return 'Grid';
      case CollectionViewMode.list:
        return 'List';
    }
  }

  @override
  Widget build(BuildContext context) {
    final allUnique = _getUniqueSkins();
    final filtered = _getFilteredSkins(allUnique);
    final categoryCounts = _getCategoryCounts(allUnique);

    if (allUnique.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inventory_2_outlined, color: Colors.white24, size: 48),
              SizedBox(height: 16),
              Text(
                'No owned skins found in collection.',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Search & View Mode Switcher Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search collection...',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 18),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.white38, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _cycleViewMode,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(_getViewModeIcon(), color: AppColors.primary, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        _getViewModeLabel(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Category Filter Pills
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final isSelected = _selectedCategory == cat;
              final count = categoryCounts[cat] ?? 0;

              return Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedCategory = cat);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surface,
                      borderRadius: BorderRadius.circular(19),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.white12,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          cat,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white60,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                            fontSize: 11,
                          ),
                        ),
                        if (count > 0) ...[
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : Colors.white10,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$count',
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white60,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Count Summary Badge
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'OWNED SKINS (${filtered.length})',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              if (_selectedCategory != 'ALL' || _searchQuery.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedCategory = 'ALL';
                      _searchQuery = '';
                      _searchController.clear();
                    });
                  },
                  child: const Text(
                    'Reset Filters',
                    style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),

        // Skins Content List / Grid
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.search_off_rounded, color: Colors.white24, size: 40),
                      const SizedBox(height: 12),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'No skins matching "$_searchQuery"'
                            : 'No $_selectedCategory skins found in collection.',
                        style: const TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : _buildContentView(filtered),
        ),
      ],
    );
  }

  Widget _buildContentView(List<SkinItem> skins) {
    switch (_viewMode) {
      case CollectionViewMode.detailed:
        return _buildDetailedGrid(skins);
      case CollectionViewMode.compact:
        return _buildCompactGrid(skins);
      case CollectionViewMode.list:
        return _buildListView(skins);
    }
  }

  // 1. Detailed 2-Column Grid
  Widget _buildDetailedGrid(List<SkinItem> skins) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.95,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: skins.length,
      itemBuilder: (context, index) {
        final skin = skins[index];
        final category = _resolveCategory(skin.parentName);

        return GestureDetector(
          onTap: () => widget.onSkinTap(skin),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        category.toUpperCase(),
                        style: const TextStyle(color: Colors.white54, fontSize: 8.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 14),
                  ],
                ),
                Expanded(
                  child: Center(
                    child: skin.displayIcon.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: skin.displayIcon,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => const SizedBox(),
                            errorWidget: (context, url, error) => const Icon(Icons.shield, color: Colors.white24, size: 30),
                          )
                        : const Icon(Icons.shield, color: Colors.white24, size: 30),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  skin.parentName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 2. Compact 3-Column Grid
  Widget _buildCompactGrid(List<SkinItem> skins) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.82,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: skins.length,
      itemBuilder: (context, index) {
        final skin = skins[index];

        return GestureDetector(
          onTap: () => widget.onSkinTap(skin),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: skin.displayIcon.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: skin.displayIcon,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => const SizedBox(),
                            errorWidget: (context, url, error) => const Icon(Icons.shield, color: Colors.white24, size: 24),
                          )
                        : const Icon(Icons.shield, color: Colors.white24, size: 24),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  skin.parentName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
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

  // 3. List View
  Widget _buildListView(List<SkinItem> skins) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: skins.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final skin = skins[index];
        final category = _resolveCategory(skin.parentName);

        return GestureDetector(
          onTap: () => widget.onSkinTap(skin),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 38,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: skin.displayIcon.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: skin.displayIcon,
                          fit: BoxFit.contain,
                          errorWidget: (context, url, error) => const Icon(Icons.shield, color: Colors.white24, size: 20),
                        )
                      : const Icon(Icons.shield, color: Colors.white24, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        skin.parentName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        category,
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
