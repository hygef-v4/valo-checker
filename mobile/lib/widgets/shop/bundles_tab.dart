import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/bundle_item.dart';
import '../../models/skin_item.dart';
import '../../theme/app_colors.dart';
import '../../utils/format_utils.dart';
import 'bundle_detail_modal.dart';
import 'shop_shared.dart';

class BundlesTab extends StatelessWidget {
  final List<BundleItem> bundles;
  final OwnedSkinIndex? ownedIndex;
  final ValueChanged<SkinItem>? onSkinTap;

  const BundlesTab({
    super.key,
    required this.bundles,
    this.ownedIndex,
    this.onSkinTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveOwnedIndex = ownedIndex ?? OwnedSkinIndex.fromInventory(const []);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (bundles.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(
              child: Text('No Featured Bundles active.', style: TextStyle(color: Colors.white54)),
            ),
          )
        else ...[
          CountdownRow(label: 'TIME LEFT:', value: FormatUtils.formatLongTimer(bundles.first.remainingSeconds)),
          const SizedBox(height: 16),
          ...bundles.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _BundleCard(
                  bundle: b,
                  ownedIndex: effectiveOwnedIndex,
                  onTap: () => BundleDetailModal.show(
                    context,
                    b,
                    ownedIndex: effectiveOwnedIndex,
                    onSkinTap: onSkinTap,
                  ),
                ),
              )),
        ],
      ],
    );
  }
}

class _BundleCard extends StatelessWidget {
  final BundleItem bundle;
  final OwnedSkinIndex ownedIndex;
  final VoidCallback onTap;

  const _BundleCard({
    required this.bundle,
    required this.ownedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ownedItems = bundle.items.where((item) => ownedIndex.contains(item)).toList();
    final int ownedCount = ownedItems.length;
    final int ownedVpValue = ownedItems.fold(0, (sum, item) => sum + item.cost);
    final int adjustedCost = (bundle.cost - ownedVpValue).clamp(0, bundle.cost);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (bundle.displayIcon.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: CachedNetworkImage(imageUrl: bundle.displayIcon, height: 180, fit: BoxFit.cover),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          bundle.displayName.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      if (bundle.cost > 0)
                        Row(
                          children: [
                            if (ownedCount > 0 && adjustedCost < bundle.cost) ...[
                              Text(
                                '${bundle.cost} VP',
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                  decoration: TextDecoration.lineThrough,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '$adjustedCost VP',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ] else
                              Text(
                                '${bundle.cost} VP',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (ownedCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$ownedCount owned (-$ownedVpValue VP)',
                            style: const TextStyle(
                              color: AppColors.success,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        const Text('EXPIRES IN:', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
                      Text(
                        FormatUtils.formatLongTimer(bundle.remainingSeconds),
                        style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

