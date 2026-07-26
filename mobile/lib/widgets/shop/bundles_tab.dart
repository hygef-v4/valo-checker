import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/bundle_item.dart';
import '../../theme/app_colors.dart';
import '../../utils/format_utils.dart';
import 'shop_shared.dart';

class BundlesTab extends StatelessWidget {
  final List<BundleItem> bundles;

  const BundlesTab({super.key, required this.bundles});

  @override
  Widget build(BuildContext context) {
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
                child: _BundleCard(bundle: b),
              )),
        ],
      ],
    );
  }
}

class _BundleCard extends StatelessWidget {
  final BundleItem bundle;

  const _BundleCard({required this.bundle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
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
                      Text(
                        '${bundle.cost} VP',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
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
    );
  }
}
