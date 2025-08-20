// 🔁 RoundPage: selecting once advances by exactly one (no skip)
import 'package:english_quiz/pages/round_page.dart';
import 'package:english_quiz/quiz/quiz_bloc.dart';
import 'package:english_quiz/quiz/quiz_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';


void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'current_round': 1,
      'stage_round_1': 0,
      'selected_round_1': '{}',
      'completed_rounds': <String>[],
    });
  });

  testWidgets('tap option -> go to Q2/10 (not Q3)', (tester) async {
    final repo = QuizRepository();
    final bloc = QuizBloc(repo)..add(LoadRound(1));

    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: const MaterialApp(home: RoundPage()),
      ),
    );
    await tester.pumpAndSettle();

    // AppBar should show Q1/10
    expect(find.textContaining('Q1/10'), findsOneWidget);

    // Tap first option tile
    final firstTile = find.byType(ListTile).first;
    await tester.tap(firstTile);

    // Allow SnackBar + state-driven navigation to complete
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    // Now it should be Q2/10, not Q3/10
    expect(find.textContaining('Q2/10'), findsOneWidget);
    expect(find.textContaining('Q3/10'), findsNothing);
  });
}
