import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Adjust these imports to your project paths
import 'package:english_quiz/pages/home_page.dart';
import 'package:english_quiz/quiz/quiz_bloc.dart';
import 'package:english_quiz/quiz/quiz_repository.dart';
import 'package:english_quiz/theme/theme_cubit.dart';

Future<void> _pumpHome(
  WidgetTester tester, {
  required int completed,
  int currentRound = 1,
  int stage = 0,
}) async {
  // Fresh prefs for this test instance
  final completedList =
      List<String>.generate(completed, (i) => (i + 1).toString());
  SharedPreferences.setMockInitialValues({
    'current_round': currentRound,
    'completed_rounds': completedList,
    'stage_round_$currentRound': stage,
  });

  await tester.pumpWidget(
    MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ThemeCubit(false)),         // light mode
          BlocProvider(create: (_) => QuizBloc(QuizRepository())), // required by HomePage
        ],
        child: const HomePage(),
      ),
    ),
  );

  // Let initState -> _load() future complete, but don't use pumpAndSettle
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  testWidgets('LPI shows 25/500 = 0.05', (tester) async {
    await _pumpHome(tester, completed: 25);
    final lpi = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(lpi.value, isNotNull);
    expect(lpi.value!, closeTo(25 / 500.0, 1e-9));
  });

  testWidgets('LPI shows 0/500 = 0.0', (tester) async {
    await _pumpHome(tester, completed: 0);
    final lpi = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(lpi.value, 0.0);
  });

  testWidgets('LPI clamps when >500 -> 1.0', (tester) async {
    await _pumpHome(tester, completed: 600); // over the cap
    final lpi = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(lpi.value, 1.0);
  });
}
