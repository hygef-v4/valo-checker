import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valocheck/main.dart';

void main() {
  setUpAll(() {
    // No network in tests: use bundled fallback fonts and empty local storage.
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('boots to the login screen when no session is stored', (tester) async {
    await tester.pumpWidget(const ValoCheckApp());
    await tester.pumpAndSettle();

    expect(find.text('VALOCHECK'), findsOneWidget);
    expect(find.text('LOG IN WITH RIOT GAMES'), findsOneWidget);
  });
}
