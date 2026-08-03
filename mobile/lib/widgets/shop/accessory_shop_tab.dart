import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/accessory_item.dart';
import '../../theme/app_colors.dart';
import '../../utils/format_utils.dart';
import 'shop_shared.dart';

class AccessoryShopTab extends StatelessWidget {
  final List<AccessoryItem> accessories;
  final int remainingSeconds;

  const AccessoryShopTab({
    super.key,
    required this.accessories,
    required this.remainingSeconds,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (accessories.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(
              child: Text('Accessory Shop is currently unavailable.', style: TextStyle(color: Colors.white54)),
            ),
          )
        else ...[
          CountdownRow(label: 'NEXT OFFER:', value: FormatUtils.formatLongTimer(remainingSeconds)),
          const SizedBox(height: 16),
          ...accessories.map((acc) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _AccessoryCard(accessory: acc),
              )),
        ],
      ],
    );
  }
}

class _AccessoryCard extends StatelessWidget {
  final AccessoryItem accessory;

  const _AccessoryCard({required this.accessory});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            accessory.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (accessory.displayIcon.isNotEmpty)
                CachedNetworkImage(imageUrl: accessory.displayIcon, height: 50, fit: BoxFit.contain)
              else
                const Icon(Icons.stars, color: Colors.white24, size: 40),
              Row(
                children: [
                  CachedNetworkImage(
                    imageUrl: 'https://media.valorant-api.com/currencies/85ca954a-41f2-ce94-9b45-8ca3dd39a00d/displayicon.png',
                    width: 16,
                    height: 16,
                    fit: BoxFit.contain,
                    errorWidget: (context, url, error) => const Icon(Icons.stars, color: Colors.white70, size: 14),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${accessory.costKC} KC',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
