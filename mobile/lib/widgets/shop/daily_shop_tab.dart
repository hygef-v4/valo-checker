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
  final ValueChanged<SkinItem> onSkinTap;

  const DailyShopTab({
    super.key,
    required this.skins,
    required this.ownedIndex,
    required this.remainingSeconds,
    required this.onSkinTap,
  });

  @override
  Widget build(BuildContext context) {
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
  final VoidCallback onTap;

  const _SkinCard({required this.skin, required this.isOwned, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              skin.parentName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
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
