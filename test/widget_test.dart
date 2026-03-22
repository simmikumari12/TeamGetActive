import 'package:flutter_test/flutter_test.dart';
import 'package:habit_mastery_league/app/app.dart';

void main() {
  testWidgets('App smoke test — HabitMasteryApp renders without error',
      (WidgetTester tester) async {
    await tester.pumpWidget(const HabitMasteryApp());
    expect(find.byType(HabitMasteryApp), findsOneWidget);
  });
}
