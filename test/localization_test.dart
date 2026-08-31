import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habits_journaling_tracker_mobile/l10n/gen/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:habits_journaling_tracker_mobile/providers/locale_provider.dart';

void main() {
  testWidgets('Runtime locale switching', (WidgetTester tester) async {
    // 1. Setup SharedPreferences mock
    SharedPreferences.setMockInitialValues({'locale_language_code': 'en'});
    final prefs = await SharedPreferences.getInstance();

    // 2. Build the app
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const LocalizationTestApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 3. Verify English default
    expect(find.text('Journal'), findsOneWidget);
    expect(find.text('Habits'), findsOneWidget);
    expect(find.text('Jurnal'), findsNothing);

    // 4. Switch to Indonesian using ProviderContainer
    final BuildContext context = tester.element(find.byType(LocalizationTestApp));
    final container = ProviderScope.containerOf(context);
    
    container.read(localeProvider.notifier).setLocale(const Locale('id'));
    
    // 5. Pump to allow UI to rebuild with new locale
    await tester.pumpAndSettle();

    // 6. Verify Indonesian text
    expect(find.text('Jurnal'), findsOneWidget);
    expect(find.text('Journal'), findsNothing);
  });
}

class LocalizationTestApp extends ConsumerWidget {
  const LocalizationTestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    
    return MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('id'),
      ],
      home: Scaffold(
        body: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return Column(
              children: [
                Text(l10n.navJournal),
                Text(l10n.navHabits),
              ],
            );
          },
        ),
      ),
    );
  }
}
