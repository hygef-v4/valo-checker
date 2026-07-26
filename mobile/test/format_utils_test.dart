import 'package:flutter_test/flutter_test.dart';
import 'package:valocheck/utils/format_utils.dart';

void main() {
  group('FormatUtils.formatTimer', () {
    test('formats zero and negatives as 00:00:00', () {
      expect(FormatUtils.formatTimer(0), '00:00:00');
      expect(FormatUtils.formatTimer(-5), '00:00:00');
    });

    test('formats seconds into HH:MM:SS', () {
      expect(FormatUtils.formatTimer(1), '00:00:01');
      expect(FormatUtils.formatTimer(61), '00:01:01');
      expect(FormatUtils.formatTimer(3600), '01:00:00');
      expect(FormatUtils.formatTimer(43199), '11:59:59');
    });
  });

  group('FormatUtils.formatLongTimer', () {
    test('formats zero and negatives as 00:00:00:00', () {
      expect(FormatUtils.formatLongTimer(0), '00:00:00:00');
      expect(FormatUtils.formatLongTimer(-1), '00:00:00:00');
    });

    test('formats seconds into DD:HH:MM:SS', () {
      expect(FormatUtils.formatLongTimer(86400), '01:00:00:00');
      expect(FormatUtils.formatLongTimer(90061), '01:01:01:01');
      expect(FormatUtils.formatLongTimer(518400), '06:00:00:00');
    });
  });

  group('FormatUtils.cleanGameMode', () {
    test('maps queue ids to display names', () {
      expect(FormatUtils.cleanGameMode('competitive'), 'Competitive');
      expect(FormatUtils.cleanGameMode('unrated'), 'Unrated');
      expect(FormatUtils.cleanGameMode('swiftplay'), 'Swiftplay');
      expect(FormatUtils.cleanGameMode('spikerush'), 'Spike Rush');
      expect(FormatUtils.cleanGameMode('deathmatch'), 'Deathmatch');
      expect(FormatUtils.cleanGameMode('hurm'), 'Team Deathmatch');
      expect(FormatUtils.cleanGameMode('premier'), 'Premier');
    });

    test('maps internal gamemode paths', () {
      expect(FormatUtils.cleanGameMode('BombGameMode'), 'Competitive');
      expect(FormatUtils.cleanGameMode('QuickBomb_U'), 'Unrated');
    });

    test('falls back to Competitive for empty input', () {
      expect(FormatUtils.cleanGameMode(''), 'Competitive');
    });
  });
}
