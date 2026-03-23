import 'package:flutter_test/flutter_test.dart';
import 'package:habit_mastery_league/app/app.dart';
import 'package:habit_mastery_league/core/services/prefs_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Provide in-memory SharedPreferences so PrefsService.init() succeeds
    SharedPreferences.setMockInitialValues({});
    await PrefsService.instance.init();
  });

  testWidgets('App smoke test — HabitMasteryApp renders without error',
      (WidgetTester tester) async {
    await tester.pumpWidget(const HabitMasteryApp());
    // Advance past the 2.5s splash timer so no pending timers remain
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.byType(HabitMasteryApp), findsOneWidget);
  });
}
