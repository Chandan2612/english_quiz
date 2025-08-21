import 'dart:convert';

import 'package:english_quiz/pages/home_page.dart';
import 'package:english_quiz/quiz/quiz_bloc.dart';
import 'package:english_quiz/quiz/quiz_repository.dart';
import 'package:english_quiz/theme/theme_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget _wrap(Widget child) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit(false)),
        BlocProvider(create: (_) => QuizBloc(QuizRepository())),
      ],
      child: MaterialApp(home: child),
    );
  }

  testWidgets('Tapping a completed round shows its stored result', (tester) async {
    SharedPreferences.setMockInitialValues({
      'current_round': 1,
      'completed_rounds': <String>['3'],
      'result_round_3': jsonEncode({'c': 5, 't': 7}),
      'stage_round_1': 0,
    });

    await tester.pumpWidget(_wrap(const HomePage()));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Round 3'), findsOneWidget);
    await tester.tap(find.text('Round 3'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 400));

    // Title + numbers appear
    expect(find.text('Round 3 • Result'), findsOneWidget);
    expect(find.text('✅ Correct'), findsOneWidget);
    expect(find.text('❌ Wrong'), findsOneWidget);
    // 5 correct, 2 wrong shown somewhere in badges
    expect(find.text('5'), findsWidgets);
    expect(find.text('2'), findsWidgets);
    expect(find.text('Close'), findsOneWidget);
  });

  testWidgets('Completed round with NO stored result shows a fallback message', (tester) async {
    SharedPreferences.setMockInitialValues({
      'current_round': 1,
      'completed_rounds': <String>['4'],
      'stage_round_1': 0,
    });

    await tester.pumpWidget(_wrap(const HomePage()));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Round 4'), findsOneWidget);
    await tester.tap(find.text('Round 4'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 400));

    // Some apps still show the sheet title; others only show a fallback text.
    final hasSheetTitle = find.text('Round 4 • Result').evaluate().isNotEmpty;

    if (hasSheetTitle) {
      expect(find.text('Round 4 • Result'), findsOneWidget);
      // And we should see a fallback text somewhere (tweak this to your exact string):
      expect(
        find.textContaining('Result not available'),
        findsOneWidget,
      );
    } else {
      // No sheet title — assert we saw a fallback message (snack bar or sheet body)
      expect(
        find.textContaining('Result not available'),
        findsOneWidget,
      );
    }

    // Optional: if your UI also shows a Close button on fallback, you can assert it:
    // expect(find.text('Close'), findsOneWidget);
  });
}
