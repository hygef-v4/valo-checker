/// Pure formatting helpers shared across screens. Kept free of Flutter
/// imports so they are trivially unit-testable.
class FormatUtils {
  FormatUtils._();

  /// HH:MM:SS (daily shop countdown).
  static String formatTimer(int totalSeconds) {
    if (totalSeconds <= 0) return '00:00:00';
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  /// DD:HH:MM:SS (night market / accessory / bundle countdowns).
  static String formatLongTimer(int totalSeconds) {
    if (totalSeconds <= 0) return '00:00:00:00';
    final days = (totalSeconds ~/ 86400).toString().padLeft(2, '0');
    final hours = ((totalSeconds % 86400) ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$days:$hours:$minutes:$seconds';
  }

  /// Maps Riot queue/game-mode identifiers to a human-readable label.
  static String cleanGameMode(String rawMode) {
    if (rawMode.isEmpty) return 'Competitive';
    final lower = rawMode.toLowerCase();

    if (lower.contains('hurm') || lower.contains('tdm')) return 'Team Deathmatch';
    if (lower.contains('skirmish')) return 'Skirmish';
    if (lower.contains('competitive') || lower.contains('bomb_c') || lower == 'bomb_c') return 'Competitive';
    if (lower.contains('unrated') || lower.contains('bomb_u') || lower == 'bomb_u') return 'Unrated';
    if (lower.contains('swiftplay') || lower.contains('bomb_s') || lower == 'swift') return 'Swiftplay';
    if (lower.contains('spikerush') || lower.contains('spike_rush')) return 'Spike Rush';
    if (lower.contains('deathmatch') || lower.contains('dm')) return 'Deathmatch';
    if (lower.contains('gungame') || lower.contains('escalation')) return 'Escalation';
    if (lower.contains('oneforall') || lower.contains('replication')) return 'Replication';
    if (lower.contains('snowball')) return 'Snowball Fight';
    if (lower.contains('premier')) return 'Premier';
    if (lower.contains('bomb')) return 'Competitive';

    final cleaned = rawMode
        .replaceAll(RegExp(r'.*Gamemode\.', caseSensitive: false), '')
        .replaceAll(RegExp(r'GameMode', caseSensitive: false), '')
        .replaceAll('_C', '')
        .replaceAll('_U', '')
        .trim();

    return cleaned.isNotEmpty ? cleaned : 'Competitive';
  }
}
