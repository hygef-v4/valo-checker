class SkinItem {
  final String uuid;
  final String displayName;
  final String displayIcon;
  final int cost;
  final String tierColor;
  final String tierName;
  final String videoUrl;
  final String cleanName;

  SkinItem({
    required this.uuid,
    required this.displayName,
    required this.displayIcon,
    required this.cost,
    this.tierColor = '#FFFFFF',
    this.tierName = 'Select',
    this.videoUrl = '',
    this.cleanName = '',
  });

  String get parentName {
    if (cleanName.isNotEmpty) return cleanName;
    return displayName
        .replaceAll(RegExp(r'\s+Level\s+\d+.*$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+Variant\s+\d+.*$', caseSensitive: false), '')
        .trim();
  }
}
