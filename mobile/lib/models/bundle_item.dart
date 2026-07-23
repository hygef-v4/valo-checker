import 'skin_item.dart';

class BundleItem {
  final String uuid;
  final String displayName;
  final String displayIcon;
  final int cost;
  int remainingSeconds;
  final List<SkinItem> items;

  BundleItem({
    required this.uuid,
    required this.displayName,
    required this.displayIcon,
    required this.cost,
    required this.remainingSeconds,
    this.items = const [],
  });
}
