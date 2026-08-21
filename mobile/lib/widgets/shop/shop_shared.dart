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
      : uuids = inventory
            .expand((s) => [
                  s.uuid.toLowerCase(),
                  if (s.cleanName.isNotEmpty) s.cleanName.toLowerCase(),
                ])
            .where((u) => u.isNotEmpty)
            .toSet(),
        parentNames = inventory
            .expand((s) => [
                  s.parentName.toLowerCase().trim(),
                  s.displayName.toLowerCase().trim(),
                  if (s.cleanName.isNotEmpty) s.cleanName.toLowerCase().trim(),
                ])
            .where((n) => n.isNotEmpty)
            .toSet();

  bool contains(SkinItem skin) {
    final u = skin.uuid.toLowerCase();
    final p = skin.parentName.toLowerCase().trim();
    final d = skin.displayName.toLowerCase().trim();
    final c = skin.cleanName.toLowerCase().trim();

    return uuids.contains(u) ||
        (p.isNotEmpty && parentNames.contains(p)) ||
        (d.isNotEmpty && parentNames.contains(d)) ||
        (c.isNotEmpty && parentNames.contains(c));
  }

  bool containsUuid(String uuid) {
    if (uuid.isEmpty) return false;
    return uuids.contains(uuid.toLowerCase());
  }

  bool containsName(String name) {
    if (name.isEmpty) return false;
    final lower = name.toLowerCase().trim();
    final clean = lower
        .replaceAll(RegExp(r'\s+level\s+\d+.*$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+variant\s+\d+.*$', caseSensitive: false), '')
        .trim();
    return parentNames.contains(lower) || parentNames.contains(clean);
  }
}
