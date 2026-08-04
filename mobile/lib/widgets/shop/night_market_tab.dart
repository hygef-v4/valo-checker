import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/skin_item.dart';
import '../../theme/app_colors.dart';
import '../../utils/format_utils.dart';
import 'shop_shared.dart';

class NightMarketTab extends StatelessWidget {
  /// Each entry: {'skin': SkinItem, 'originalCost': int, 'discountPercent': int}
  final List<Map<String, dynamic>> items;
  final OwnedSkinIndex ownedIndex;
  final int remainingSeconds;
  final Set<String> wishlist;
  final ValueChanged<SkinItem> onSkinTap;

  const NightMarketTab({
    super.key,
    required this.items,
    required this.ownedIndex,
    required this.remainingSeconds,
    this.wishlist = const {},
    required this.onSkinTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(
              child: Text('Night Market is not active.', style: TextStyle(color: Colors.white54)),
            ),
          )
        else ...[
          CountdownRow(label: 'TIME LEFT:', value: FormatUtils.formatLongTimer(remainingSeconds)),
          const SizedBox(height: 16),
          ...items.map((item) {
            final skin = item['skin'] as SkinItem;
            final original = item['originalCost'] as int? ?? 0;
            final discount = item['discountPercent'] as int? ?? 0;
            final isOwned = ownedIndex.contains(skin);
            final isWishlisted = wishlist.contains(skin.uuid);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _NightMarketCard(
                skin: skin,
                originalCost: original,
                discountPercent: discount,
                isOwned: isOwned,
                isWishlisted: isWishlisted,
                onTap: () => onSkinTap(skin),
              ),
            );
          }),
        ],
      ],
    );
  }
}

class _NightMarketCard extends StatelessWidget {
  final SkinItem skin;
  final int originalCost;
  final int discountPercent;
  final bool isOwned;
  final bool isWishlisted;
  final VoidCallback onTap;

  const _NightMarketCard({
    required this.skin,
    required this.originalCost,
    required this.discountPercent,
    required this.isOwned,
    this.isWishlisted = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 170,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        skin.parentName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    if (isWishlisted)
                      const Icon(Icons.favorite, color: AppColors.primary, size: 20),
                  ],
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (isOwned)
                      const OwnedBadge(fontSize: 13)
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (originalCost > 0)
                            Text(
                              '$originalCost VP',
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
                                '${skin.cost} VP',
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
                      Flexible(
                        child: CachedNetworkImage(
                          imageUrl: skin.displayIcon,
                          height: 55,
                          fit: BoxFit.contain,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            if (!isOwned && discountPercent > 0)
              Positioned(
                top: 0,
                right: 0,
                child: Text(
                  '-$discountPercent%',
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
  }
}
