import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/skin_item.dart';
import '../../theme/app_colors.dart';

class CollectionTab extends StatelessWidget {
  final List<SkinItem> inventory;
  final ValueChanged<SkinItem> onSkinTap;

  const CollectionTab({
    super.key,
    required this.inventory,
    required this.onSkinTap,
  });

  @override
  Widget build(BuildContext context) {
    // Deduplicate by skin family so variants/levels collapse into one card.
    final Map<String, SkinItem> uniqueInventory = {};
    for (var skin in inventory) {
      uniqueInventory.putIfAbsent(skin.parentName, () => skin);
    }
    final ownedSkins = uniqueInventory.values.toList();

    if (ownedSkins.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(
          child: Text('No owned skins found in collection.', style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ownedSkins.length,
      itemBuilder: (context, index) {
        final skin = ownedSkins[index];
        return _WeaponCard(skin: skin, onTap: () => onSkinTap(skin));
      },
    );
  }
}

class _WeaponCard extends StatelessWidget {
  final SkinItem skin;
  final VoidCallback onTap;

  const _WeaponCard({required this.skin, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final title = skin.displayName.startsWith('Standard')
        ? skin.parentName
        : (skin.cleanName.isNotEmpty ? skin.cleanName : skin.parentName);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: skin.displayIcon.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: skin.displayIcon,
                      height: 70,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const SizedBox(height: 70),
                      errorWidget: (context, url, error) => const Icon(Icons.shield, color: Colors.white24, size: 40),
                    )
                  : const Icon(Icons.shield, color: Colors.white24, size: 40),
            ),
          ],
        ),
      ),
    );
  }
}
