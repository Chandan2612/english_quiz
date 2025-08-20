// test/home_page_widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:english_quiz/pages/home_page.dart';
import 'package:english_quiz/theme/theme_cubit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // 🧪 Mock SharedPreferences so HomePage->_load() has sane defaults
    SharedPreferences.setMockInitialValues({
      'isDark': false,
      'current_round': 1,
      'stage_r1': 0,          // 👈 match your Prefs key
      'completed_rounds': <int>[],
    });
  });

  testWidgets('shows title, completed pill, and Start/Continue CTA', (tester) async {
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => ThemeCubit(false),
        child: const MaterialApp(
          debugShowCheckedModeBanner: false,
          // ⛔️ Kill infinite animations so the test doesn’t hang
          home: TickerMode(enabled: false, child: HomePage()),
        ),
      ),
    );

    // Let initState/_load complete a tick
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // ✅ Title
    expect(find.text('English Quiz'), findsOneWidget);

    // ✅ We expect multiple "Completed:" (chip + hero card)
    expect(find.textContaining('Completed:'), findsWidgets);

    // ✅ CTA label exists (either Start or Continue)
    final start = find.text('Start Round');
    final cont  = find.text('Continue Round');
    final hasStartOrCont = start.evaluate().isNotEmpty || cont.evaluate().isNotEmpty;
    expect(hasStartOrCont, isTrue, reason: 'CTA label should be visible');

    // ✅ The label sits inside a Material button (Elevated/Filled/etc.)
    final labelFinder = start.evaluate().isNotEmpty ? start : cont;
    final buttonFinder = find.ancestor(
      of: labelFinder,
      matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
    );
    expect(buttonFinder, findsOneWidget, reason: 'CTA should be a Material button subtype');
  });
}
