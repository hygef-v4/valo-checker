import 'package:flutter_test/flutter_test.dart';
import 'package:valocheck/models/match_summary.dart';
import 'package:valocheck/models/user_profile.dart';
import 'package:valocheck/utils/match_team_helper.dart';

MatchSummary _summary({Map<String, dynamic>? raw}) {
  return MatchSummary(
    matchId: 'match-1',
    mapName: 'Ascent',
    mapIcon: '',
    agentName: 'Jett',
    agentIcon: 'https://example.com/jett.png',
    gameMode: 'competitive',
    isVictory: true,
    scoreText: '13 - 7',
    kills: 10,
    deaths: 5,
    assists: 2,
    isMvp: false,
    matchStartTime: 0,
    rawMatchDetails: raw,
  );
}

final _profile = UserProfile(
  puuid: 'me',
  gameName: 'Me',
  tagLine: 'TAG',
  region: 'AP',
);

void main() {
  group('MatchTeamHelper.generateMatchTeams', () {
    test('returns empty teams when raw match details are missing (no fabricated players)', () {
      final teams = MatchTeamHelper.generateMatchTeams(
        match: _summary(raw: null),
        profile: _profile,
        rankInfo: null,
      );

      expect(teams['teamA'], isEmpty);
      expect(teams['teamB'], isEmpty);
    });

    test('builds real player rows from raw match details', () {
      final raw = {
        'players': [
          {
            'subject': 'me',
            'teamId': 'Blue',
            'characterId': 'unknown-agent',
            'competitiveTier': 0,
            'gameName': 'Me',
            'tagLine': 'TAG',
            'stats': {'kills': 10, 'deaths': 5, 'assists': 2, 'score': 4000, 'roundsPlayed': 20},
          },
          {
            'subject': 'enemy1',
            'teamId': 'Red',
            'characterId': 'unknown-agent',
            'competitiveTier': 0,
            'gameName': 'Foe',
            'tagLine': 'X',
            'stats': {'kills': 8, 'deaths': 10, 'assists': 1, 'score': 3000, 'roundsPlayed': 20},
          },
        ],
        'roundResults': [
          {
            'playerStats': [
              {
                'subject': 'me',
                'damage': [
                  {'headshots': 2, 'bodyshots': 3, 'legshots': 0, 'damage': 300},
                ],
                'kills': [
                  {'killer': 'me', 'victim': 'enemy1', 'gameTime': 5000},
                ],
              },
              {'subject': 'enemy1', 'damage': [], 'kills': []},
            ],
          },
        ],
      };

      final teams = MatchTeamHelper.generateMatchTeams(
        match: _summary(raw: raw),
        profile: _profile,
        rankInfo: null,
      );

      final teamA = teams['teamA']!;
      final teamB = teams['teamB']!;

      expect(teamA, hasLength(1));
      expect(teamB, hasLength(1));

      final me = teamA.first;
      expect(me['isMe'], isTrue);
      expect(me['name'], 'Me#TAG');
      expect(me['k'], 10);
      expect(me['d'], 5);
      expect(me['a'], 2);
      // Real ACS: score 4000 over 20 rounds.
      expect(me['acs'], 200);
      // Real headshot rate: 2 of 5 hits.
      expect(me['hs'], '40%');
      // First kill of the only round belongs to "me".
      expect(me['fk'], 1);

      final enemy = teamB.first;
      expect(enemy['isMe'], isFalse);
      expect(enemy['name'], 'Foe#X');
      // Enemy died to the round's first kill.
      expect(enemy['fd'], 1);
    });
  });
}
