import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/bundle_item.dart';
import '../../models/skin_item.dart';
import '../../theme/app_colors.dart';
import '../../utils/format_utils.dart';
import 'shop_shared.dart';

class BundleDetailModal extends StatelessWidget {
  final BundleItem bundle;
  final OwnedSkinIndex ownedIndex;
  final ValueChanged<SkinItem>? onSkinTap;

  const BundleDetailModal({
    super.key,
    required this.bundle,
    required this.ownedIndex,
    this.onSkinTap,
  });

  static void show(
    BuildContext context,
    BundleItem bundle, {
    required OwnedSkinIndex ownedIndex,
    ValueChanged<SkinItem>? onSkinTap,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1B1B26),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => BundleDetailModal(
        bundle: bundle,
        ownedIndex: ownedIndex,
        onSkinTap: onSkinTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.85;
    final ownedItems = bundle.items.where((item) => ownedIndex.contains(item)).toList();
    final int ownedCount = ownedItems.length;
    final int ownedVpValue = ownedItems.fold(0, (sum, item) => sum + item.cost);
    final int adjustedCost = (bundle.cost - ownedVpValue).clamp(0, bundle.cost);

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: Color(0xFF1B1B26),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                // Hero Banner
                if (bundle.displayIcon.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      height: 180,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: bundle.displayIcon,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => _imageFallback(),
                      ),
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              bundle.displayName.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 22,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                          if (bundle.cost > 0)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (ownedCount > 0 && adjustedCost < bundle.cost) ...[
                                  Text(
                                    '${bundle.cost} VP',
                                    style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 12,
                                      decoration: TextDecoration.lineThrough,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.success,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '$adjustedCost VP',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ] else
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${bundle.cost} VP',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined, color: Colors.white54, size: 16),
                          const SizedBox(width: 6),
                          const Text(
                            'EXPIRES IN:',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            FormatUtils.formatLongTimer(bundle.remainingSeconds),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                      if (ownedCount > 0) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.savings_outlined, color: AppColors.success, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'You own $ownedCount item(s). Bundle price reduced by $ownedVpValue VP!',
                                  style: const TextStyle(
                                    color: AppColors.success,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Text(
                        'BUNDLE CONTENT (${bundle.items.length})',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (bundle.items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'No items preview available for this bundle.',
                            style: TextStyle(color: Colors.white38, fontSize: 13),
                          ),
                        )
                      else
                        for (final item in bundle.items) ...[
                          _buildBundleItemRow(context, item),
                          const SizedBox(height: 8),
                        ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBundleItemRow(BuildContext context, SkinItem item) {
    final isOwned = ownedIndex.contains(item);

    return InkWell(
      onTap: onSkinTap != null ? () => onSkinTap!(item) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 60,
                height: 48,
                color: Colors.black26,
                child: item.displayIcon.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: item.displayIcon,
                        fit: BoxFit.contain,
                        errorWidget: (context, url, error) => _itemFallback(),
                      )
                    : _itemFallback(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (item.cost > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${item.cost} VP',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isOwned)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: OwnedBadge(fontSize: 10),
              ),
            const Icon(Icons.chevron_right, color: Colors.white38, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      color: AppColors.surface,
      child: const Center(
        child: Icon(Icons.inventory_2_outlined, color: Colors.white38, size: 48),
      ),
    );
  }

  Widget _itemFallback() {
    return const Center(
      child: Icon(Icons.style, color: Colors.white38, size: 24),
    );
  }
}
