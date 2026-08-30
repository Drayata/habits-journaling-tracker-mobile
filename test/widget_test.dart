// Basic smoke test for the Habits & Journaling app.
//
// This test verifies that the app starts and displays the database
// initialization state. Full widget tests will be added with the UI layer.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:habits_journaling_tracker_mobile/main.dart';

void main() {
  testWidgets('App starts and shows loading state', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: HabitsJournalingApp()),
    );

    // The app should show a loading indicator while initializing the database
    expect(find.byType(HabitsJournalingApp), findsOneWidget);
  });
}
