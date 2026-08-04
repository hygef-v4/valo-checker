import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valocheck/widgets/profile/weapons_tab.dart';

void main() {
  group('WeaponsTab Widget tests', () {
    testWidgets('renders WeaponsTab with search input and category chips', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WeaponsTab(),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Rifles'), findsOneWidget);
      expect(find.text('Sidearms'), findsOneWidget);
      expect(find.text('Melee'), findsOneWidget);
      expect(find.text('Snipers'), findsOneWidget);
    });

    testWidgets('filters list when searching skin name', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WeaponsTab(),
          ),
        ),
      );

      final searchInput = find.byType(TextField);
      await tester.enterText(searchInput, 'NonExistentSkinXYZ');
      await tester.pumpAndSettle();

      expect(find.text('No skins match your filters.'), findsOneWidget);
    });
  });
}
