import 'package:flutter/material.dart';

import '../../models/skin_item.dart';
import '../../theme/app_colors.dart';

/// "TIME LEFT: 12:34:56" row shown above store sections.
class CountdownRow extends StatelessWidget {
  final String label;
  final String value;

  const CountdownRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 1.2,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

class OwnedBadge extends StatelessWidget {
  final double fontSize;

  const OwnedBadge({super.key, this.fontSize = 10});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        'OWNED',
        style: TextStyle(
          color: AppColors.success,
          fontWeight: FontWeight.w900,
          fontSize: fontSize,
        ),
      ),
    );
  }
}

/// Fast owned-skin lookup shared by shop tabs. Built once per data load.
class OwnedSkinIndex {
  final Set<String> uuids;
  final Set<String> parentNames;

  OwnedSkinIndex.fromInventory(List<SkinItem> inventory)
      : uuids = inventory.map((s) => s.uuid).toSet(),
        parentNames = inventory.map((s) => s.parentName).where((n) => n.isNotEmpty).toSet();

  bool contains(SkinItem skin) {
    return uuids.contains(skin.uuid) || (skin.parentName.isNotEmpty && parentNames.contains(skin.parentName));
  }
}
