import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valocheck/models/bundle_item.dart';
import 'package:valocheck/models/skin_item.dart';
import 'package:valocheck/widgets/shop/bundle_detail_modal.dart';
import 'package:valocheck/widgets/shop/bundles_tab.dart';
import 'package:valocheck/widgets/shop/shop_shared.dart';

void main() {
  group('Bundle Detail Modal & BundlesTab tests', () {
    final testItem1 = SkinItem(
      uuid: 'skin-1',
      displayName: 'Vandal Prime',
      displayIcon: '',
      cost: 1775,
    );

    final testItem2 = SkinItem(
      uuid: 'skin-2',
      displayName: 'Prime Karambit',
      displayIcon: '',
      cost: 3550,
    );

    final testBundle = BundleItem(
      uuid: 'bundle-1',
      displayName: 'Prime Collection',
      displayIcon: '',
      cost: 7100,
      remainingSeconds: 86400,
      items: [testItem1, testItem2],
    );

    testWidgets('BundlesTab renders bundle name and cost', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BundlesTab(bundles: [testBundle]),
          ),
        ),
      );

      expect(find.text('PRIME COLLECTION'), findsOneWidget);
      expect(find.text('7100 VP'), findsOneWidget);
    });

    testWidgets('BundleDetailModal renders bundle header and item list', (WidgetTester tester) async {
      final ownedIndex = OwnedSkinIndex.fromInventory([testItem1]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BundleDetailModal(
              bundle: testBundle,
              ownedIndex: ownedIndex,
            ),
          ),
        ),
      );

      expect(find.text('PRIME COLLECTION'), findsOneWidget);
      expect(find.text('BUNDLE CONTENT (2)'), findsOneWidget);
      expect(find.text('Vandal Prime'), findsOneWidget);
      expect(find.text('Prime Karambit'), findsOneWidget);
      expect(find.text('OWNED'), findsOneWidget);
    });
  });
}
