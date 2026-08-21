import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/skin_item.dart';
import '../../theme/app_colors.dart';
import '../../utils/format_utils.dart';
import 'shop_shared.dart';

class DailyShopTab extends StatelessWidget {
  final List<SkinItem> skins;
  final OwnedSkinIndex ownedIndex;
  final int remainingSeconds;
  final Set<String> wishlist;
  final ValueChanged<SkinItem> onSkinTap;

  const DailyShopTab({
    super.key,
    required this.skins,
    required this.ownedIndex,
    required this.remainingSeconds,
    this.wishlist = const {},
    required this.onSkinTap,
  });

  @override
  Widget build(BuildContext context) {
    final wishlistedInShop = skins.where((s) => wishlist.contains(s.uuid)).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (skins.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(
              child: Text(
                'Daily shop data is unavailable. Pull down to refresh.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54),
              ),
            ),
          )
        else ...[
          if (wishlistedInShop.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.25),
                    Colors.purple.withValues(alpha: 0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'WISHLIST ALERT!',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          wishlistedInShop.length == 1
                              ? '${wishlistedInShop.first.displayName} is in your daily shop!'
                              : '${wishlistedInShop.length} wishlisted items are available today!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.favorite, color: AppColors.primary, size: 18),
                ],
              ),
            ),
          ],
          CountdownRow(label: 'TIME LEFT:', value: FormatUtils.formatTimer(remainingSeconds)),
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
            itemCount: skins.length,
            itemBuilder: (context, index) => _SkinCard(
              skin: skins[index],
              isOwned: ownedIndex.contains(skins[index]),
              isWishlisted: wishlist.contains(skins[index].uuid),
              onTap: () => onSkinTap(skins[index]),
            ),
          ),
        ],
      ],
    );
  }
}

class _SkinCard extends StatelessWidget {
  final SkinItem skin;
  final bool isOwned;
  final bool isWishlisted;
  final VoidCallback onTap;

  const _SkinCard({
    required this.skin,
    required this.isOwned,
    this.isWishlisted = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isWishlisted ? AppColors.primary.withValues(alpha: 0.6) : Colors.transparent,
            width: isWishlisted ? 1.5 : 0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
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
                if (isWishlisted)
                  const Icon(Icons.favorite, color: AppColors.primary, size: 16),
              ],
            ),
            const SizedBox(height: 4),
            if (isOwned)
              const OwnedBadge()
            else
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
      ),
    );
  }
}
